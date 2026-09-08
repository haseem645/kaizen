import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/utils/custom_functions.dart';
import '../../domain/entities/training_library_module.dart';
import '../controllers/training_library_controller.dart';

/// Keeps the thumbnail behind the content while allowing larger text to grow
/// the list card beyond its minimum image height.
class TrainingLibraryModuleCard extends StatelessWidget {
  const TrainingLibraryModuleCard({super.key, required this.module, required this.onTap});

  final TrainingLibraryModule module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Material(
          color: AppColors.surfaceDark3,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(child: _ModuleThumbnail(thumbnailLink: module.thumbnailLink)),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0, 0.4, 1],
                      colors: [
                        Colors.black.withValues(alpha: 0.04),
                        Colors.black.withValues(alpha: 0.2),
                        Colors.black.withValues(alpha: 0.88),
                      ],
                    ),
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.hasBoundedHeight
                      ? constraints.maxHeight
                      : (constraints.maxWidth / 1.9).clamp(176.0, 280.0) + 24,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ModuleSeatLabel(seatTitle: module.seat.title),
                      const SizedBox(height: 3),
                      AppTextView.body1(
                        TrainingLibraryController.displayModuleTitle(module),
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      _CardMetaRow(module: module),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    child: Semantics(
                      button: true,
                      label: TrainingLibraryController.displayModuleTitle(module),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ModuleSeatLabel extends StatelessWidget {
  const _ModuleSeatLabel({required this.seatTitle});

  final String seatTitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppTextView.body(
          AppStrings.trainingLibrarySeatPrefix,
          color: AppColors.secondaryColor,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        Expanded(
          child: AppTextView.body(
            TrainingLibraryController.displayModuleValue(seatTitle),
            color: AppColors.textPrimary,
            fontSize: 13,
            maxLines: 1,
            fontWeight: FontWeight.w400,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ModuleThumbnail extends StatelessWidget {
  const _ModuleThumbnail({required this.thumbnailLink});

  final String? thumbnailLink;

  @override
  Widget build(BuildContext context) {
    final imageUrl = CustomFunctions.resolveImageUrl(thumbnailLink);

    return imageUrl == null
        ? const _ImagePlaceholder()
        : CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => const _ImagePlaceholder(),
            errorWidget: (_, __, ___) => const _ImagePlaceholder(),
          );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      '${AppStrings.imagePath}fallback.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return const Center(
          child: Icon(Icons.video_library_rounded, color: AppColors.textSecondary, size: 30),
        );
      },
    );
  }
}

class _CardMetaRow extends StatelessWidget {
  const _CardMetaRow({required this.module});

  final TrainingLibraryModule module;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        AppTextView.body2(
          TrainingLibraryController.displayModuleLessonCount(module),
          color: AppColors.lightGrey1,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        const _MetaDot(),
        AppTextView.body2(
          TrainingLibraryController.displayModuleDuration(module),
          color: AppColors.lightGrey1,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ],
    );
  }
}

class _MetaDot extends StatelessWidget {
  const _MetaDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      decoration: const BoxDecoration(color: AppColors.textSecondary, shape: BoxShape.circle),
    );
  }
}
