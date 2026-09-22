import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_gradient_action_button.dart';

class TrainingLibraryCreateAction extends StatelessWidget {
  const TrainingLibraryCreateAction({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.fromLTRB(21, 12, 21, 0),
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: double.infinity,
          child: AppGradientActionButton(
            label: AppStrings.trainingLibraryCreate,
            icon: Icons.add_rounded,
            iconSize: 16,
            textSize: 14,
            minHeight: 40,
            borderRadius: 12,
            boxShadows: const <BoxShadow>[],
            iconSpacing: 8,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
