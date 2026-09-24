import 'package:flutter/material.dart';

import 'app_gradient_action_button.dart';

class AppBarGradientAction extends StatelessWidget {
  const AppBarGradientAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.endPadding = 16,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final double endPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(end: endPadding),
      child: Center(
        child: SizedBox.square(
          dimension: 35,
          child: AppGradientActionButton(
            label: label,
            icon: icon,
            iconOnly: true,
            iconSize: 24,
            minHeight: 40,
            borderRadius: 12,
            boxShadows: const <BoxShadow>[],
            padding: EdgeInsets.zero,
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
