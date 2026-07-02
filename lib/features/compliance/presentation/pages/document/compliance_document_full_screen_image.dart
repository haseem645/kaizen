import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_text_view.dart';

class ComplianceDocumentFullScreenImage extends StatelessWidget {
  const ComplianceDocumentFullScreenImage({super.key, required this.title, required this.image});

  final String title;
  final File image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 18, 8, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: SvgPicture.asset(
                      '${AppStrings.imagePath}back.svg',
                      width: 24,
                      height: 24,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: AppTextView.title1(
                      title,
                      color: AppColors.secondaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Spacer(),
              Padding(
                padding: EdgeInsets.only(left: 8, right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(image, width: double.infinity, height: 250, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: AppColors.fieldBorder.withValues(alpha: 0.16)),
              const SizedBox(height: 6),

              Padding(
                padding: EdgeInsets.only(left: 8, right: 8),
                child: AppButton(
                  text: AppStrings.reUpload,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
