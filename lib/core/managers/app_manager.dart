import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;

import '../../features/login/domain/entities/user.dart';
import '../../features/organizations/domain/entities/organization.dart';
import '../../routes/app_router.dart';
import '../network/api_endpoints.dart';
import '../preference/app_preference.dart';
import 'models/company_billing_details.dart';

class AppManager extends ChangeNotifier {
  AppManager._();

  static final AppManager instance = AppManager._();

  bool _isLoadingOrganizations = false;
  bool _isShowingOrganizationsScreen = false;
  bool _isSettingActiveOrganization = false;
  bool _showOrganizationBanner = false;
  String? _activatingOrganizationId;
  CompanyBillingDetails? _billingDetails;
  bool _isBillingBannerDismissed = false;
  String? _currentRouteName;
  User? _currentUser;
  bool _hasPendingNotification = false;
  List<Organization> _organizations = const <Organization>[];

  bool get isLoadingOrganizations => _isLoadingOrganizations;
  bool get isSettingActiveOrganization => _isSettingActiveOrganization;
  bool get showOrganizationBanner =>
      _showOrganizationBanner && !_isShowingOrganizationsScreen;
  bool get showBillingBanner =>
      _billingDetails?.status == 'unpaid' &&
      !_isBillingBannerDismissed &&
      _currentRouteName != AppRouter.splash;
  String? get currentRouteName => _currentRouteName;
  String? get activatingOrganizationId => _activatingOrganizationId;
  CompanyBillingDetails? get billingDetails => _billingDetails;
  User? get currentUser => _currentUser;
  List<Organization> get organizations =>
      List<Organization>.unmodifiable(_organizations);
  List<Organization> get visibleOrganizations =>
      List<Organization>.unmodifiable(
        _organizations.where(_shouldShowOrganization),
      );

  Future<void> initialize() async {
    await fetchOrganizations();
  }

  Future<void> hydrateCurrentUser() async {
    _currentUser = await AppPreference.getUser();
    _notifyListenersSafely();
  }

  void updateCurrentUser(User? user) {
    _currentUser = user;
    _notifyListenersSafely();
  }

  void saveBillingDetails(CompanyBillingDetails? billingDetails) {
    _billingDetails = billingDetails;
    if (billingDetails?.status != 'unpaid') {
      _isBillingBannerDismissed = false;
    }
    _notifyListenersSafely();
  }

  void dismissBillingBanner() {
    if (_isBillingBannerDismissed) {
      return;
    }

    _isBillingBannerDismissed = true;
    _notifyListenersSafely();
  }

  void resetBillingBannerDismissal() {
    if (!_isBillingBannerDismissed) {
      return;
    }

    _isBillingBannerDismissed = false;
    _notifyListenersSafely();
  }

  void updateCurrentRouteName(String? routeName) {
    if (_currentRouteName == routeName) {
      return;
    }

    _currentRouteName = routeName;
    _notifyListenersSafely();
  }

  void resetSessionState() {
    _showOrganizationBanner = false;
    _isShowingOrganizationsScreen = false;
    _isSettingActiveOrganization = false;
    _activatingOrganizationId = null;
    _billingDetails = null;
    _isBillingBannerDismissed = false;
    _currentUser = null;
    _organizations = const <Organization>[];
    _notifyListenersSafely();
  }

  Future<void> fetchOrganizations({bool forceRefresh = false}) async {
    if (_isLoadingOrganizations && !forceRefresh) {
      return;
    }

    _isLoadingOrganizations = true;
    _notifyListenersSafely();

    try {
      final token = AppPreference.getAuthToken();
      final uri = Uri.parse(
        '${ApiEndPoints.baseUrl}${ApiEndPoints.version}${ApiEndPoints.organizations}',
      );

      final response = await http.get(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        final decodedJson = jsonDecode(response.body);
        if (decodedJson is List) {
          _organizations = decodedJson
              .whereType<Map<String, dynamic>>()
              .map(_organizationFromJson)
              .toList(growable: false);
        }
      }
    } catch (_) {
      // Keep startup resilient if organizations cannot be fetched.
    } finally {
      _isLoadingOrganizations = false;
      _notifyListenersSafely();
    }
  }

  Future<void> handleConflict409() async {
    await fetchOrganizations(forceRefresh: true);
    _showOrganizationBanner = true;
    _notifyListenersSafely();
  }

  Future<void> openOrganizationsScreen() async {
    if (_isShowingOrganizationsScreen) {
      return;
    }

    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    _isShowingOrganizationsScreen = true;
    _notifyListenersSafely();

    await navigator.pushNamed(AppRouter.organizations);

    _isShowingOrganizationsScreen = false;
    _notifyListenersSafely();
  }

  Future<bool> setActiveOrganization(
    String organizationId, {
    bool resetNavigationStack = true,
  }) async {
    if (_isSettingActiveOrganization) {
      return false;
    }

    _isSettingActiveOrganization = true;
    _activatingOrganizationId = organizationId;
    _notifyListenersSafely();

    try {
      final token = AppPreference.getAuthToken();
      final uri = Uri.parse(
        '${ApiEndPoints.baseUrl}${ApiEndPoints.version}${ApiEndPoints.setActiveOrganization}',
      );

      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, String>{
          'type': 'organization',
          'uuid': organizationId,
        }),
      );

      if (response.statusCode < 200 || response.statusCode > 299) {
        return false;
      }

      _showOrganizationBanner = false;
      _isShowingOrganizationsScreen = false;
      final navigator = AppRouter.navigatorKey.currentState;
      if (resetNavigationStack && navigator != null) {
        navigator.pushNamedAndRemoveUntil(
          AppRouter.kaizengram,
          (route) => false,
        );
      }

      return true;
    } catch (_) {
      return false;
    } finally {
      _isSettingActiveOrganization = false;
      _activatingOrganizationId = null;
      _notifyListenersSafely();
    }
  }

  void _notifyListenersSafely() {
    if (_hasPendingNotification) {
      return;
    }

    _hasPendingNotification = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _hasPendingNotification = false;
      notifyListeners();
    });
  }

  Organization _organizationFromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['uuid']?.toString().trim() ?? '',
      name: json['name']?.toString().trim() ?? '',
      website: _readNullableString(json['website']),
      contactNo: _readNullableString(json['contact_no']),
      address: _readNullableString(json['address']),
      createdAt: json['created_at']?.toString().trim() ?? '',
      type: json['type']?.toString().trim() ?? '',
      logoUrl: _readNullableString(json['logo_url']),
    );
  }

  String? _readNullableString(dynamic value) {
    final resolved = value?.toString().trim();
    if (resolved == null || resolved.isEmpty || resolved == 'null') {
      return null;
    }

    return resolved;
  }

  bool _shouldShowOrganization(Organization organization) {
    final normalizedName = organization.name.trim().toLowerCase();
    return !normalizedName.contains('sandbox');
  }
}
