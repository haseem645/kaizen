import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;

import '../../features/login/domain/entities/user.dart';
import '../../features/organizations/domain/entities/organization.dart';
import '../../routes/app_router.dart';
import '../network/api_endpoints.dart';
import '../network/api_processor.dart';
import '../preference/app_preference.dart';
import 'app_manager_remote_data_source.dart';
import 'models/company_billing_details.dart';
import 'models/company_details.dart';

class AppManager extends ChangeNotifier {
  AppManager._();

  static final AppManager instance = AppManager._();

  bool _isLoadingOrganizations = false;
  bool _isShowingOrganizationsScreen = false;
  bool _isSettingActiveOrganization = false;
  bool _showOrganizationBanner = false;
  String? _activatingOrganizationId;
  CompanyDetails? _activeCompany;
  CompanyBillingDetails? _billingDetails;
  bool _isBillingBannerDismissed = false;
  String? _currentRouteName;
  User? _currentUser;
  String? _selectedOrganizationId;
  Future<void>? _refreshSessionContextOperation;
  bool _shouldSkipNextResumeSessionRefresh = false;
  bool _isHandlingOrganizationConflict = false;
  bool _didResolveOrganizationConflict = false;
  bool _isRefreshingOrganizationContext = false;
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
  CompanyDetails? get activeCompany => _activeCompany;
  User? get currentUser => _currentUser;
  bool get isRefreshingOrganizationContext => _isRefreshingOrganizationContext;
  bool get hasPendingOrganizationConflict =>
      _isHandlingOrganizationConflict && !_didResolveOrganizationConflict;
  bool get usesParentApiEndpoints {
    final selectedOrganizationId = _selectedOrganizationId;
    if (selectedOrganizationId != null) {
      if (selectedOrganizationId.isEmpty) {
        return true;
      }

      final selectedOrganization = _findOrganizationById(
        selectedOrganizationId,
      );
      if (selectedOrganization != null) {
        return _isSandboxOrganization(selectedOrganization);
      }

      return false;
    }

    final userOrganizationId = _currentUser?.organizationUuid?.trim() ?? '';
    if (_currentUser != null && userOrganizationId.isEmpty) {
      return true;
    }

    final resolvedOrganization = currentOrganization;
    if (resolvedOrganization != null &&
        _isSandboxOrganization(resolvedOrganization)) {
      return true;
    }

    final activeCompanyName = _activeCompany?.name.trim().toLowerCase() ?? '';
    return activeCompanyName.contains('sandbox');
  }

  Organization? get currentOrganization {
    final selectedOrganizationId = _selectedOrganizationId;
    if (selectedOrganizationId != null) {
      final selectedOrganization = _findOrganizationForSelection(
        selectedOrganizationId,
      );
      if (selectedOrganization != null) {
        return selectedOrganization;
      }
    }

    final userOrganizationId = _resolveUserBackedOrganizationSelectionId();
    if (userOrganizationId != null) {
      final userOrganization = _findOrganizationForSelection(
        userOrganizationId,
      );
      if (userOrganization != null) {
        return userOrganization;
      }
    }

    return _findOrganizationById(_activeCompany?.uuid);
  }

  String get currentOrganizationId {
    final resolvedOrganization = currentOrganization;
    if (resolvedOrganization != null) {
      return resolvedOrganization.id;
    }

    final selectedOrganizationId = _selectedOrganizationId;
    if (selectedOrganizationId != null) {
      return selectedOrganizationId;
    }

    final userOrganizationId = _resolveUserBackedOrganizationSelectionId();
    if (userOrganizationId != null) {
      return userOrganizationId;
    }

    return _activeCompany?.uuid.trim() ?? '';
  }

  List<Organization> get organizations =>
      List<Organization>.unmodifiable(_organizations);
  List<Organization> get visibleOrganizations =>
      List<Organization>.unmodifiable(
        _organizations.where(_shouldShowOrganization),
      );
  String get currentOrganizationName {
    final resolvedOrganization = currentOrganization;
    if (resolvedOrganization != null) {
      final organizationName = resolvedOrganization.name.trim();
      if (organizationName.isNotEmpty) {
        return organizationName;
      }
    }

    final activeCompanyName = _activeCompany?.name.trim() ?? '';
    if (activeCompanyName.isNotEmpty) {
      return activeCompanyName;
    }

    return '';
  }

  Future<void> initialize({bool forceRefresh = false}) async {
    await fetchOrganizations(forceRefresh: forceRefresh);
  }

  Future<void> refreshSessionContext({
    bool forceOrganizationsRefresh = true,
  }) async {
    final authToken = AppPreference.getAuthToken().trim();
    if (authToken.isEmpty) {
      return;
    }

    final existingOperation = _refreshSessionContextOperation;
    if (existingOperation != null) {
      await existingOperation;
      return;
    }

    final operation = _refreshSessionContextInternal(
      authToken,
      forceOrganizationsRefresh: forceOrganizationsRefresh,
    );
    _isRefreshingOrganizationContext = true;
    _notifyListenersSafely();
    _refreshSessionContextOperation = operation;

    try {
      await operation;
    } finally {
      if (identical(_refreshSessionContextOperation, operation)) {
        _refreshSessionContextOperation = null;
      }
      _isRefreshingOrganizationContext = false;
      _notifyListenersSafely();
    }
  }

  Future<void> hydrateCurrentUser() async {
    _currentUser = await AppPreference.getUser();
    _activeCompany = await AppPreference.getActiveCompany();
    _selectedOrganizationId =
        _resolveUserBackedOrganizationSelectionId() ??
        AppPreference.getSelectedOrganizationId();
    _syncParentApiEndpointMode();
    _notifyListenersSafely();
  }

  void skipNextResumeSessionRefresh() {
    _shouldSkipNextResumeSessionRefresh = true;
  }

  bool consumeResumeSessionRefreshSkip() {
    if (!_shouldSkipNextResumeSessionRefresh) {
      return false;
    }

    _shouldSkipNextResumeSessionRefresh = false;
    return true;
  }

  void updateCurrentUser(User? user) {
    _currentUser = user;
    _syncSelectedOrganizationWithUser(user);
    _syncParentApiEndpointMode();
    _notifyListenersSafely();
  }

  void saveBillingDetails(CompanyBillingDetails? billingDetails) {
    _billingDetails = billingDetails;
    if (billingDetails?.status != 'unpaid') {
      _isBillingBannerDismissed = false;
    }
    _notifyListenersSafely();
  }

  void saveActiveCompany(CompanyDetails? activeCompany) {
    final previousCompanyId = _activeCompany?.uuid.trim() ?? '';
    final nextCompanyId = activeCompany?.uuid.trim() ?? '';

    _activeCompany = activeCompany;
    _billingDetails = activeCompany?.billing;
    if (previousCompanyId != nextCompanyId ||
        activeCompany?.billing?.status != 'unpaid') {
      _isBillingBannerDismissed = false;
    }

    _syncParentApiEndpointMode();
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
    _shouldSkipNextResumeSessionRefresh = false;
    _isHandlingOrganizationConflict = false;
    _didResolveOrganizationConflict = false;
    _isRefreshingOrganizationContext = false;
    _showOrganizationBanner = false;
    _isShowingOrganizationsScreen = false;
    _isSettingActiveOrganization = false;
    _activatingOrganizationId = null;
    _activeCompany = null;
    _billingDetails = null;
    _isBillingBannerDismissed = false;
    _currentUser = null;
    _selectedOrganizationId = null;
    _organizations = const <Organization>[];
    _syncParentApiEndpointMode();
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
      final uri = ApiEndPoints.resolveUri(ApiEndPoints.organizations);

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
          _reconcileSelectedOrganization();
          _syncParentApiEndpointMode();
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
    _isHandlingOrganizationConflict = true;
    _didResolveOrganizationConflict = false;
    _showOrganizationBanner = false;
    await fetchOrganizations(forceRefresh: true);

    if (_isShowingOrganizationsScreen) {
      _notifyListenersSafely();
      return;
    }

    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) {
      _showOrganizationBanner = true;
      _notifyListenersSafely();
      return;
    }

    _notifyListenersSafely();
    await openOrganizationsScreen(openedForConflict: true);
  }

  Future<void> openOrganizationsScreen({bool openedForConflict = false}) async {
    if (openedForConflict) {
      _isHandlingOrganizationConflict = true;
      _didResolveOrganizationConflict = false;
      _showOrganizationBanner = false;
    }

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

  Future<void> resolveOrganizationConflictFromBack() async {
    final shouldRefreshContext = hasPendingOrganizationConflict;
    _showOrganizationBanner = false;
    _isHandlingOrganizationConflict = false;
    _didResolveOrganizationConflict = false;
    _notifyListenersSafely();

    if (!shouldRefreshContext) {
      return;
    }

    await _refreshCurrentOrganizationContext();
    await fetchOrganizations(forceRefresh: true);
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
      final uri = ApiEndPoints.resolveUri(ApiEndPoints.setActiveOrganization);

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

      ApiCallExecutor.clearGetCache();
      await _syncCurrentOrganization(organizationId);
      await _refreshActiveCompany();
      _didResolveOrganizationConflict = true;
      _isHandlingOrganizationConflict = false;
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

  Future<void> _syncCurrentOrganization(String organizationId) async {
    final normalizedOrganizationId = organizationId.trim();
    if (normalizedOrganizationId.isEmpty) {
      return;
    }

    final matchedOrganization = _findOrganizationById(normalizedOrganizationId);
    final persistedOrganizationId =
        matchedOrganization != null &&
            _isSandboxOrganization(matchedOrganization)
        ? ''
        : normalizedOrganizationId;
    if (_selectedOrganizationId != persistedOrganizationId) {
      _selectedOrganizationId = persistedOrganizationId;
      await AppPreference.setSelectedOrganizationId(persistedOrganizationId);
    }

    final currentUser = _currentUser;
    if (currentUser == null) {
      _syncParentApiEndpointMode();
      return;
    }

    if (currentUser.organizationUuid?.trim() == persistedOrganizationId) {
      _syncParentApiEndpointMode();
      return;
    }

    final updatedUser = currentUser.copyWith(
      organizationUuid: persistedOrganizationId,
    );
    _currentUser = updatedUser;
    await AppPreference.saveUser(updatedUser);
    _syncParentApiEndpointMode();
  }

  Future<void> _refreshActiveCompany() async {
    await _refreshActiveCompanyForToken();
  }

  Future<void> _refreshCurrentOrganizationContext() async {
    final authToken = AppPreference.getAuthToken().trim();
    if (authToken.isEmpty) {
      return;
    }

    try {
      ApiCallExecutor.clearGetCache();
      final remoteDataSource = AppManagerRemoteDataSource();
      final refreshedUser = await remoteDataSource.fetchUserDetail(
        accessToken: authToken,
      );
      await AppPreference.saveUser(refreshedUser);
      updateCurrentUser(refreshedUser);
      await _refreshActiveCompanyForToken(authToken: authToken);
    } catch (_) {
      // Keep organization conflict recovery resilient if the server cannot refresh context.
    }
  }

  Future<void> _refreshSessionContextInternal(
    String authToken, {
    required bool forceOrganizationsRefresh,
  }) async {
    try {
      ApiCallExecutor.clearGetCache();
      final remoteDataSource = AppManagerRemoteDataSource();
      final refreshedUser = await remoteDataSource.fetchUserDetail(
        accessToken: authToken,
      );
      await AppPreference.saveUser(refreshedUser);
      updateCurrentUser(refreshedUser);
      await _refreshActiveCompanyForToken(authToken: authToken);
      await fetchOrganizations(forceRefresh: forceOrganizationsRefresh);
    } catch (_) {
      // Keep foreground resume resilient if session context cannot refresh.
    }
  }

  Future<void> _refreshActiveCompanyForToken({String? authToken}) async {
    final resolvedAuthToken =
        authToken?.trim() ?? AppPreference.getAuthToken().trim();
    if (resolvedAuthToken.isEmpty) {
      return;
    }

    try {
      final companyDetails = await AppManagerRemoteDataSource()
          .fetchCompanyDetails(accessToken: resolvedAuthToken);
      await AppPreference.saveActiveCompany(companyDetails);
      saveActiveCompany(companyDetails);
    } catch (_) {
      // Keep organization switches resilient if company details cannot refresh.
    }
  }

  void _notifyListenersSafely() {
    if (_hasPendingNotification) {
      return;
    }

    _hasPendingNotification = true;
    void dispatchNotification() {
      _hasPendingNotification = false;
      notifyListeners();
    }

    final scheduler = SchedulerBinding.instance;
    final phase = scheduler.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      scheduleMicrotask(dispatchNotification);
      return;
    }

    scheduler.addPostFrameCallback((_) {
      dispatchNotification();
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

  Organization? _findOrganizationById(String? organizationId) {
    final normalizedOrganizationId = organizationId?.trim() ?? '';
    if (normalizedOrganizationId.isEmpty) {
      return null;
    }

    for (final organization in _organizations) {
      if (organization.id == normalizedOrganizationId) {
        return organization;
      }
    }

    return null;
  }

  Organization? _findOrganizationForSelection(String organizationId) {
    if (organizationId.isEmpty) {
      return _findSandboxOrganization();
    }

    return _findOrganizationById(organizationId);
  }

  Organization? _findSandboxOrganization() {
    for (final organization in _organizations) {
      if (_isSandboxOrganization(organization)) {
        return organization;
      }
    }

    return null;
  }

  bool _isSandboxOrganization(Organization organization) {
    return organization.name.trim().toLowerCase().contains('sandbox');
  }

  String? _resolveUserBackedOrganizationSelectionId() {
    if (_currentUser == null) {
      return null;
    }

    return _currentUser?.organizationUuid?.trim() ?? '';
  }

  void _syncSelectedOrganizationWithUser(User? user) {
    if (user == null) {
      if (_selectedOrganizationId == null) {
        return;
      }

      _selectedOrganizationId = null;
      unawaited(AppPreference.clearSelectedOrganizationId());
      return;
    }

    final nextSelectedOrganizationId = user.organizationUuid?.trim() ?? '';
    if (_selectedOrganizationId == nextSelectedOrganizationId) {
      return;
    }

    _selectedOrganizationId = nextSelectedOrganizationId;
    unawaited(
      AppPreference.setSelectedOrganizationId(nextSelectedOrganizationId),
    );
  }

  void _reconcileSelectedOrganization() {
    final selectedOrganizationId = _selectedOrganizationId;
    if (selectedOrganizationId != null &&
        _findOrganizationForSelection(selectedOrganizationId) != null) {
      return;
    }

    final fallbackOrganizationId = _resolveUserBackedOrganizationSelectionId();
    if (fallbackOrganizationId != null &&
        _findOrganizationForSelection(fallbackOrganizationId) != null) {
      if (fallbackOrganizationId == selectedOrganizationId) {
        return;
      }

      _selectedOrganizationId = fallbackOrganizationId;
      unawaited(
        AppPreference.setSelectedOrganizationId(fallbackOrganizationId),
      );
      return;
    }

    if (_selectedOrganizationId == null) {
      return;
    }

    _selectedOrganizationId = null;
    unawaited(AppPreference.clearSelectedOrganizationId());
  }

  void _syncParentApiEndpointMode() {
    unawaited(AppPreference.setUseParentApiEndpoints(usesParentApiEndpoints));
  }

  bool _shouldShowOrganization(Organization organization) {
    if (_currentUser?.isOwner == true) {
      return true;
    }

    return !_isSandboxOrganization(organization);
  }
}
