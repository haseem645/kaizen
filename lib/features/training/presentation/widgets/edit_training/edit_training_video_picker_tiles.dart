part of 'package:sparrowkaizen/features/training/presentation/pages/edit_training_screen.dart';

class _TrainingVideoCameraTile extends StatelessWidget {
  const _TrainingVideoCameraTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.secondaryColor.withValues(alpha: 0.4),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videocam_rounded,
                color: AppColors.secondaryColor,
                size: 32,
              ),
              SizedBox(height: 10),
              AppTextView.body3(
                AppStrings.trainingRecordVideo,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainingVideoSystemPickerOptionTile extends StatelessWidget {
  const _TrainingVideoSystemPickerOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accentColor = AppColors.textPrimary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceDark2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextView.body3(
                      title,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    const SizedBox(height: 6),
                    AppTextView.body4(
                      subtitle,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainingVideoManageAccessTile extends StatelessWidget {
  const _TrainingVideoManageAccessTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.fieldBorder.withValues(alpha: 0.34),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.library_add_outlined,
                color: AppColors.textPrimary,
                size: 30,
              ),
              SizedBox(height: 10),
              AppTextView.body3(
                AppStrings.trainingManageGalleryAccess,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainingVideoGalleryTile extends StatelessWidget {
  const _TrainingVideoGalleryTile({required this.asset, required this.onTap});

  final AssetEntity asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark2,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FutureBuilder<Uint8List?>(
                future: asset.thumbnailDataWithSize(
                  const ThumbnailSize.square(420),
                ),
                builder: (context, snapshot) {
                  final thumbnail = snapshot.data;
                  if (thumbnail != null) {
                    return Image.memory(
                      thumbnail,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    );
                  }

                  return Container(
                    color: AppColors.surfaceDark,
                    child: const Center(
                      child: Icon(
                        Icons.video_library_rounded,
                        color: AppColors.textSecondary,
                        size: 28,
                      ),
                    ),
                  );
                },
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Row(
                  children: [
                    const Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _formatVideoDuration(asset.videoDuration),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatVideoDuration(Duration duration) {
  final hours = duration.inHours;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (hours > 0) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  return '${duration.inMinutes}:$seconds';
}
