import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

import '../../../../../core/widgets/app_text_view.dart';

class ChatUserInitialAvatar extends StatelessWidget {
  const ChatUserInitialAvatar({
    super.key,
    required this.label,
    required this.accentColor,
    this.size = 44,
  });

  final String label;
  final Color accentColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accentColor.withValues(alpha: 0.18),
        border: Border.all(color: accentColor.withValues(alpha: 0.55)),
      ),
      child: Center(
        child: AppTextView.body2(
          label,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color kaizengramChatAccentColorForIndex(int index) {
  const palette = <Color>[
    AppColors.secondaryColor,
    AppColors.progressColor,
    AppColors.hexffb547,
    AppColors.hex7ea6ff,
    AppColors.hexff7d7d,
  ];

  return palette[index % palette.length];
}

String kaizengramChatInitialFor(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '?';
  }

  return trimmed.substring(0, 1).toUpperCase();
}
