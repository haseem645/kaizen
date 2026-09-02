import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_text_view.dart';

class FeedbackPostAttachmentPager extends StatefulWidget {
  const FeedbackPostAttachmentPager({super.key, required this.imageUrls});

  final List<String> imageUrls;

  @override
  State<FeedbackPostAttachmentPager> createState() =>
      _FeedbackPostAttachmentPagerState();
}

class _FeedbackPostAttachmentPagerState
    extends State<FeedbackPostAttachmentPager> {
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
                child: _FeedbackNetworkImage(
                  url: widget.imageUrls[index],
                  fit: BoxFit.contain,
                ),
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
        builder: (_) => _FeedbackFullScreenImageViewer(
          imageUrls: widget.imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class _FeedbackFullScreenImageViewer extends StatefulWidget {
  const _FeedbackFullScreenImageViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  final List<String> imageUrls;
  final int initialIndex;

  @override
  State<_FeedbackFullScreenImageViewer> createState() =>
      _FeedbackFullScreenImageViewerState();
}

class _FeedbackFullScreenImageViewerState
    extends State<_FeedbackFullScreenImageViewer> {
  late final ValueNotifier<int> _currentPage;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    final initialPage = widget.initialIndex.clamp(
      0,
      widget.imageUrls.length - 1,
    );
    _currentPage = ValueNotifier<int>(initialPage);
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _currentPage.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              physics: widget.imageUrls.length > 1
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) => _currentPage.value = index,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.fromLTRB(12, 56, 12, 24),
                child: Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 6,
                    boundaryMargin: const EdgeInsets.all(80),
                    clipBehavior: Clip.none,
                    child: SizedBox.expand(
                      child: _FeedbackNetworkImage(
                        url: widget.imageUrls[index],
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (widget.imageUrls.length > 1)
              Positioned(
                top: 12,
                right: 16,
                child: ValueListenableBuilder<int>(
                  valueListenable: _currentPage,
                  builder: (_, currentPage, _) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: AppTextView.body(
                      AppStrings.questionsFeedbackImagePageIndicator(
                        currentPage + 1,
                        widget.imageUrls.length,
                      ),
                      color: AppColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
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

        return const ColoredBox(
          color: AppColors.hex252a40,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppColors.secondaryColor,
                strokeWidth: 2,
              ),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: AppColors.hex252a40,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: AppColors.textSecondary,
            size: 28,
          ),
        ),
      ),
    );
  }
}
