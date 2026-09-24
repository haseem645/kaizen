import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../navigation/app_bottom_nav_item.dart';
import '../navigation/app_menu_type.dart';
import 'circular_dark_nav_bar.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.selectedMenu,
    required this.onSelected,
    this.isSandboxMode = false,
  });

  final AppMenuType? selectedMenu;
  final ValueChanged<AppMenuType> onSelected;
  final bool isSandboxMode;

  static const _destinations = [
    (
      menu: AppMenuType.library,
      label: AppStrings.trainingLibraryTitle,
      icon: Icons.video_library_outlined,
      selectedIcon: Icons.video_library_rounded,
    ),
    (
      menu: AppMenuType.audits,
      label: AppStrings.checkInTitle,
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check_rounded,
    ),
    (
      menu: AppMenuType.performanceSnapshot,
      label: AppStrings.bottomNavPerformance,
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
    ),
    (
      menu: AppMenuType.learningTracks,
      label: AppStrings.bottomNavLtc,
      icon: Icons.route_outlined,
      selectedIcon: Icons.route_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Swap the design function here to try another style with the same tabs.
    return circularDarkNavBar(items: _items);
  }

  List<AppBottomNavItem> get _items => _destinations.map((destination) {
    final enabled = !isSandboxMode || destination.menu == AppMenuType.library;
    return AppBottomNavItem(
      label: destination.label,
      icon: destination.icon,
      selectedIcon: destination.selectedIcon,
      isSelected: selectedMenu == destination.menu,
      onTap: enabled ? () => onSelected(destination.menu) : null,
    );
  }).toList();
}
