import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_router.dart' show AppRouter;
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../managers/app_manager.dart';
import '../navigation/app_menu_type.dart';
import '../utils/custom_functions.dart';
import 'app_drawer.dart';
import 'app_text_view.dart';

class DrawerMainScreen extends StatelessWidget {
  const DrawerMainScreen({
    super.key,
    required this.title,
    this.image,
    this.imageUrl,
    required this.selectedMenu,
    required this.child,
    this.centerTitle = false,
    this.appBarActions,
  });

  final String title;
  final String? image;
  final String? imageUrl;
  final AppMenuType? selectedMenu;
  final Widget child;
  final bool centerTitle;
  final List<Widget>? appBarActions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBg,
      appBar: AppBar(
        backgroundColor: AppColors.mainBg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: centerTitle,
        title: AppTextView.title1(
          title,
          color: AppColors.secondaryColor,
          fontWeight: FontWeight.w500,
          fontSize: 24,
        ),
        actions: appBarActions,
      ),
      drawer: _buildDrawer(context),
      body: child,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Consumer<AppManager>(
      builder: (context, appManager, _) {
        final user = appManager.currentUser;

        return AppDrawer(
          name: CustomFunctions.resolveName(user),
          currentOrganizationName: appManager.isRefreshingOrganizationContext
              ? AppStrings.organizationsFetching
              : appManager.currentOrganizationName,
          isSandboxMode: appManager.usesParentApiEndpoints,
          selectedMenu: selectedMenu,
          onHomeTap: () => _openHome(context),
          onProfileTap: () => _openProfile(context),
          onLearningTracksTap: () => _openLearningTracks(context),
          onComplianceTap: () => _openCompliance(context),
          onLibraryTap: () => _openLibrary(context),
          onAuditsTap: () => _openAudit(context),
          onPerformanceSnapshotTap: () => _openPerformanceSnapshot(context),
          onSeatProfilesTap: () => _openSeatProfiles(context),
          onPaygradesTap: () => _openPaygrades(context),
          onKaizenGptTap: () => _openKaizenGpt(context),
          onSettingTap: () => _openSetting(context),
          onDrawerHeaderTap: () => _openProfile(context),
          onOrganizationTap: () => appManager.openOrganizationsScreen(),
          image: image ?? user?.image,
          imageUrl: imageUrl ?? user?.imageUrl,
        );
      },
    );
  }

  void _openProfile(BuildContext context) {
    if (selectedMenu == AppMenuType.profile) {
      return;
    }

    AppRouter.pushNamed(context, AppRouter.profile);
  }

  void _openHome(BuildContext context) {
    if (selectedMenu == AppMenuType.home) {
      return;
    }

    AppRouter.pushReplacementNamed<void, void>(context, AppRouter.kaizengram);
  }

  void _openLearningTracks(BuildContext context) {
    if (selectedMenu == AppMenuType.learningTracks) {
      return;
    }

    AppRouter.pushReplacementNamed<void, void>(
      context,
      AppRouter.learningTracks,
    );
  }

  void _openCompliance(BuildContext context) {
    if (selectedMenu == AppMenuType.compliance) {
      return;
    }

    AppRouter.pushReplacementNamed<void, void>(context, AppRouter.compliance);
  }

  void _openLibrary(BuildContext context) {
    if (selectedMenu == AppMenuType.library) {
      return;
    }

    AppRouter.pushReplacementNamed<void, void>(
      context,
      AppRouter.trainingLibrary,
    );
  }

  void _openAudit(BuildContext context) {
    if (selectedMenu == AppMenuType.audits) {
      return;
    }

    AppRouter.pushReplacementNamed<void, void>(context, AppRouter.audit);
  }

  void _openSeatProfiles(BuildContext context) {
    if (selectedMenu == AppMenuType.seatProfiles) {
      return;
    }

    AppRouter.pushReplacementNamed<void, void>(context, AppRouter.seatProfiles);
  }

  void _openPerformanceSnapshot(BuildContext context) {
    if (selectedMenu == AppMenuType.performanceSnapshot) {
      return;
    }

    AppRouter.pushReplacementNamed<void, void>(
      context,
      AppRouter.performanceSnapshot,
    );
  }

  void _openPaygrades(BuildContext context) {
    if (selectedMenu == AppMenuType.paygrades) {
      return;
    }

    AppRouter.pushReplacementNamed<void, void>(context, AppRouter.paygrades);
  }

  void _openKaizenGpt(BuildContext context) {
    if (selectedMenu == AppMenuType.kaizenGpt) {
      return;
    }

    AppRouter.pushReplacementNamed<void, void>(context, AppRouter.kaizenGpt);
  }

  void _openSetting(BuildContext context) {
    if (selectedMenu == AppMenuType.setting) {
      return;
    }

    AppRouter.pushNamed(context, AppRouter.onboarding);
  }
}
