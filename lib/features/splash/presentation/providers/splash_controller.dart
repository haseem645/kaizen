import 'package:flutter/material.dart';
import 'package:sparrowkaizen/core/managers/app_manager.dart';
import 'package:sparrowkaizen/core/managers/app_manager_remote_data_source.dart';
import 'package:sparrowkaizen/core/preference/app_preference.dart';
import 'package:sparrowkaizen/core/services/deep_link_service.dart';

import '../../../compliance/data/datasources/compliance_remote_data_source.dart';
import '../../../login/data/datasources/auth_remote_data_source.dart';
import '../../../../routes/app_router.dart';

class SplashController extends ChangeNotifier {
  SplashController({
    AuthRemoteDataSource? authRemoteDataSource,
    ComplianceRemoteDataSource? complianceRemoteDataSource,
    AppManagerRemoteDataSource? appManagerRemoteDataSource,
  }) : _authRemoteDataSource = authRemoteDataSource ?? AuthRemoteDataSource(),
       _complianceRemoteDataSource =
           complianceRemoteDataSource ?? ComplianceRemoteDataSource(),
       _appManagerRemoteDataSource =
           appManagerRemoteDataSource ?? AppManagerRemoteDataSource();

  final AuthRemoteDataSource _authRemoteDataSource;
  final ComplianceRemoteDataSource _complianceRemoteDataSource;
  final AppManagerRemoteDataSource _appManagerRemoteDataSource;
  bool _isLoading = true;

  bool get isLoading => _isLoading;

  Future<void> initialize(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    if (!context.mounted) {
      return;
    }

    final pendingDeepLinkTarget = await DeepLinkService.instance
        .consumeStartupTarget();
    if (!context.mounted) {
      return;
    }

    if (pendingDeepLinkTarget != null) {
      _isLoading = false;
      notifyListeners();

      AppRouter.pushReplacementNamed<void, void>(
        context,
        pendingDeepLinkTarget.routeName,
        arguments: pendingDeepLinkTarget.arguments,
      );
      return;
    }

    final authToken = AppPreference.getAuthToken().trim();

    if (authToken.isNotEmpty) {
      try {
        final user = await _authRemoteDataSource.fetchUserDetail(
          accessToken: authToken,
        );
        await AppPreference.saveUser(user);
        AppManager.instance.updateCurrentUser(user);
        await _loadCompanyDetails(authToken);
        await _primeOrganizationConflictCheck();
      } catch (_) {}

      await AppManager.instance.initialize();

      if (!context.mounted) {
        return;
      }

      _isLoading = false;
      notifyListeners();

      if (!context.mounted) {
        return;
      }
      if (DeepLinkService.instance.hasPendingAuthenticatedTarget) {
        await DeepLinkService.instance
            .openPendingAuthenticatedTargetAfterLogin();
        return;
      }

      AppRouter.pushReplacementNamed<void, void>(context, AppRouter.kaizengram);
    } else {
      _isLoading = false;
      notifyListeners();

      AppRouter.pushReplacementNamed<void, void>(context, AppRouter.login);
    }
  }

  Future<void> _primeOrganizationConflictCheck() async {
    try {
      await _complianceRemoteDataSource.getComplianceOverview(
        forceRefresh: true,
      );
    } catch (_) {
      // The compliance data source already handles startup-safe failures and
      // ApiCallExecutor will still raise the organization conflict banner on 409.
    }
  }

  Future<void> _loadCompanyDetails(String authToken) async {
    try {
      final companyDetails = await _appManagerRemoteDataSource
          .fetchCompanyDetails(accessToken: authToken);
      await AppPreference.saveActiveCompany(companyDetails);
      AppManager.instance.saveBillingDetails(companyDetails.billing);
    } catch (_) {
      // Keep startup resilient if company details cannot be fetched.
    }
  }
}
