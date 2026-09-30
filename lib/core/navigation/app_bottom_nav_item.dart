import 'package:flutter/material.dart';

/// Presentation data shared by bottom navigation designs.
class AppBottomNavItem {
  const AppBottomNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;

  /// A null callback renders a disabled destination.
  final VoidCallback? onTap;
}
