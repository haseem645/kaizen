import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppDotDivider extends StatelessWidget {
  const AppDotDivider({
    super.key,
    this.color = AppColors.grey1,
    this.lineHeight = 1,
    this.dotSize = 7,
    this.opacity = 0.15,
  });

  final Color color;
  final double lineHeight;
  final double dotSize;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color.withValues(alpha: opacity);

    return Row(
      children: [
        _DividerDot(size: dotSize, color: resolvedColor),
        Expanded(
          child: Container(height: lineHeight, color: resolvedColor),
        ),
        _DividerDot(size: dotSize, color: resolvedColor),
      ],
    );
  }
}

class _DividerDot extends StatelessWidget {
  const _DividerDot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
