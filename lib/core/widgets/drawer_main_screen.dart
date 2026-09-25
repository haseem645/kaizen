import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_router.dart' show AppRouter;
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../managers/app_manager.dart';
import '../navigation/app_menu_type.dart';
import '../navigation/main_navigation_controller.dart';
import '../utils/auth_controller.dart';
import '../utils/custom_functions.dart';
import 'app_back_button.dart';
import 'app_bottom_nav_bar.dart';
import 'app_confirmation_dialog.dart';
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
    this.navigationBarsVisible,
  });

  final String title;
  final String? image;
  final String? imageUrl;
  final AppMenuType? selectedMenu;
  final Widget child;
  final bool centerTitle;
  final List<Widget>? appBarActions;
  final bool? navigationBarsVisible;

  bool get _isBottomNavigationTab =>
      selectedMenu?.isBottomNavigationTab ?? false;

  @override
  Widget build(BuildContext context) {
    if (navigationBarsVisible == null) {
      return _buildScaffold(context);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: navigationBarsVisible! ? 1 : 0),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, visibility, _) =>
          _buildScaffold(context, appBarVisibility: visibility),
    );
  }

  Widget _buildScaffold(BuildContext context, {double? appBarVisibility}) {
    final hasNavigationShell =
        context.read<MainNavigationController?>() != null;

    return Scaffold(
      backgroundColor: AppColors.mainBg,
      extendBody: true,
      appBar: _buildAppBar(context, appBarVisibility),
      drawer: _isBottomNavigationTab ? _buildDrawer(context) : null,
      body: child,
      bottomNavigationBar:
          !_isBottomNavigationTab ||
              hasNavigationShell ||
              MediaQuery.viewInsetsOf(context).bottom > 0
          ? null
          : _buildBottomNavigation(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, double? visibility) {
    final appBar = AppBar(
      primary: visibility == null,
      backgroundColor: AppColors.mainBg,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      // Keep the returning toolbar matched to the status-bar background.
      scrolledUnderElevation: visibility == null ? null : 0,
      surfaceTintColor: visibility == null ? null : Colors.transparent,
      centerTitle: centerTitle,
      leading: _isBottomNavigationTab
          ? null
          : AppBackButton(onPressed: () => _goBack(context)),
      title: AppTextView.title1(
        title,
        color: AppColors.secondaryColor,
        fontWeight: FontWeight.w500,
        fontSize: 24,
      ),
      actions: appBarActions,
    );
    if (visibility == null) {
      return appBar;
    }
    // Keep the status-bar inset while the full-height toolbar slides upward.
    return PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight * visibility),
      child: SafeArea(
        bottom: false,
        child: ClipRect(
          child: SizedBox(
            height: kToolbarHeight * visibility,
            child: OverflowBox(
              alignment: Alignment.bottomCenter,
              minHeight: kToolbarHeight,
              maxHeight: kToolbarHeight,
              child: IgnorePointer(
                ignoring: navigationBarsVisible == false,
                child: ExcludeSemantics(
                  excluding: navigationBarsVisible == false,
                  child: appBar,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Consumer<AppManager>(
      builder: (consumerContext, appManager, _) {
        final user = appManager.currentUser;

        return AppDrawer(
          name: CustomFunctions.resolveName(user),
          currentOrganizationName: appManager.isRefreshingOrganizationContext
              ? AppStrings.organizationsFetching
              : appManager.currentOrganizationName,
          isSandboxMode: appManager.usesParentApiEndpoints,
          selectedMenu: selectedMenu,
          onProfileTap: () => _openProfile(context),
          onComplianceTap: () => _openCompliance(context),
          onSeatProfilesTap: () => _openSeatProfiles(context),
          onPaygradesTap: () => _openPaygrades(context),
          onDepartmentsTap: () => _openDepartments(context),
          onKaizenGptTap: () => _openKaizenGpt(context),
          onSettingTap: () => _openSetting(context),
          onDrawerHeaderTap: () => _openProfile(context),
          onOrganizationTap: () => appManager.openOrganizationsScreen(),
          onLogoutTap: () => _showLogoutConfirmation(context),
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

  Widget _buildBottomNavigation(BuildContext context) {
    return Consumer<AppManager>(
      builder: (_, appManager, _) => AppBottomNavBar(
        isVisible: navigationBarsVisible ?? true,
        selectedMenu: selectedMenu,
        isSandboxMode: appManager.usesParentApiEndpoints,
        onSelected: (menu) => _openBottomTab(context, menu),
      ),
    );
  }

  void _openBottomTab(BuildContext context, AppMenuType menu) {
    if (selectedMenu == menu) {
      return;
    }

    final routeName = switch (menu) {
      AppMenuType.library => AppRouter.trainingLibrary,
      AppMenuType.audits => AppRouter.checkIn,
      AppMenuType.performanceSnapshot => AppRouter.performanceSnapshot,
      AppMenuType.learningTracks => AppRouter.learningTracks,
      _ => null,
    };
    if (routeName != null) {
      _openMainMenu(context, menu, routeName);
    }
  }

  void _openSeatProfiles(BuildContext context) {
    _openMainMenu(context, AppMenuType.seatProfiles, AppRouter.seatProfiles);
  }

  void _openCompliance(BuildContext context) {
    _openMainMenu(context, AppMenuType.compliance, AppRouter.compliance);
  }

  void _openPaygrades(BuildContext context) {
    _openMainMenu(context, AppMenuType.paygrades, AppRouter.paygrades);
  }

  void _openDepartments(BuildContext context) {
    _openMainMenu(context, AppMenuType.departments, AppRouter.departments);
  }

  void _openKaizenGpt(BuildContext context) {
    _openMainMenu(context, AppMenuType.kaizenGpt, AppRouter.kaizenGpt);
  }

  void _openMainMenu(BuildContext context, AppMenuType menu, String routeName) {
    if (selectedMenu == menu) {
      return;
    }

    if (!menu.isBottomNavigationTab) {
      AppRouter.pushNamed<void>(context, routeName);
      return;
    }

    final navigation = context.read<MainNavigationController?>();
    if (navigation != null) {
      navigation.selectMenu(menu);
      return;
    }

    AppRouter.pushReplacementNamed<void, void>(context, routeName);
  }

  void _goBack(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.maybePop();
      return;
    }
    AppRouter.pushReplacementNamed<void, void>(
      context,
      AppRouter.defaultAuthenticatedRouteName,
    );
  }

  void _openSetting(BuildContext context) {
    if (selectedMenu == AppMenuType.setting) {
      return;
    }

    AppRouter.pushNamed(context, AppRouter.onboarding);
  }

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AppConfirmationDialog(
          title: AppStrings.authLogout,
          description: AppStrings.authLogoutConfirmationDescription,
          onCancelCallback: () async {
            Navigator.of(dialogContext, rootNavigator: true).pop();
          },
          onConfirmCallback: () async {
            Navigator.of(dialogContext, rootNavigator: true).pop();
            await AuthController.logout();
          },
        );
      },
    );
  }
}
