import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/fast_circular_progress.dart';
import 'feedback_full_screen_image_viewer.dart';

class FeedbackPostAttachmentPager extends StatefulWidget {
  const FeedbackPostAttachmentPager({super.key, required this.imageUrls});

  final List<String> imageUrls;

  @override
  State<FeedbackPostAttachmentPager> createState() => _FeedbackPostAttachmentPagerState();
}

class _FeedbackPostAttachmentPagerState extends State<FeedbackPostAttachmentPager> {
  final ValueNotifier<int> _currentPage = ValueNotifier<int>(0);
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _currentPage.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: PageView.builder(
            controller: _pageController,
            physics: widget.imageUrls.length > 1
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) => _currentPage.value = index,
            itemBuilder: (context, index) => GestureDetector(
              onTap: () => _openFullScreen(context, index),
              child: ColoredBox(
                color: AppColors.hex252a40,
                child: _FeedbackNetworkImage(url: widget.imageUrls[index], fit: BoxFit.contain),
              ),
            ),
          ),
        ),
        if (widget.imageUrls.length > 1) ...[
          const SizedBox(height: 8),
          ValueListenableBuilder<int>(
            valueListenable: _currentPage,
            builder: (_, currentPage, _) => AppTextView.body(
              AppStrings.questionsFeedbackImagePageIndicator(
                currentPage + 1,
                widget.imageUrls.length,
              ),
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  void _openFullScreen(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            FeedbackFullScreenImageViewer(imageUrls: widget.imageUrls, initialIndex: initialIndex),
      ),
    );
  }
}

class _FeedbackNetworkImage extends StatelessWidget {
  const _FeedbackNetworkImage({required this.url, this.fit = BoxFit.contain});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return ColoredBox(
          color: AppColors.hex252a40,
          child: Center(
            child: SizedBox(width: 24, height: 24, child: FastCircularProgressIndicator()),
          ),
        );
      },
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: AppColors.hex252a40,
        child: Center(
          child: Icon(Icons.broken_image_outlined, color: AppColors.textSecondary, size: 28),
        ),
      ),
    );
  }
}
