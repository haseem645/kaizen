import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../providers/kaizengram_chat_controller.dart';
import 'chat_video_preview.dart';

class KaizengramChatFullScreenMediaView extends StatefulWidget {
  const KaizengramChatFullScreenMediaView({
    super.key,
    required this.attachments,
    this.initialIndex = 0,
    this.autoPlayInitialVideo = false,
  });

  final List<KaizengramChatMediaAttachment> attachments;
  final int initialIndex;
  final bool autoPlayInitialVideo;

  @override
  State<KaizengramChatFullScreenMediaView> createState() =>
      _KaizengramChatFullScreenMediaViewState();
}

class _KaizengramChatFullScreenMediaViewState
    extends State<KaizengramChatFullScreenMediaView> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.attachments.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            PageView.builder(
              controller: _pageController,
              physics: widget.attachments.length > 1
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              itemCount: widget.attachments.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                final attachment = widget.attachments[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 56, 12, 24),
                  child: Center(
                    child: attachment.isVideo
                        ? ChatVideoPreview(
                            videoPath: attachment.path,
                            maxHeight: mediaSize.height * 0.8,
                            fit: BoxFit.contain,
                            autoPlay:
                                widget.autoPlayInitialVideo &&
                                index == widget.initialIndex,
                          )
                        : _FullScreenChatImage(imagePath: attachment.path),
                  ),
                );
              },
            ),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                ),
              ),
            ),
            if (widget.attachments.length > 1)
              Positioned(
                top: 12,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.textPrimary.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${widget.attachments.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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

class _FullScreenChatImage extends StatelessWidget {
  const _FullScreenChatImage({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final image = imagePath.startsWith('http')
        ? Image.network(
            imagePath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const _FullScreenMediaFallback(
              icon: Icons.broken_image_outlined,
            ),
          )
        : Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const _FullScreenMediaFallback(
              icon: Icons.broken_image_outlined,
            ),
          );

    return InteractiveViewer(minScale: 1, maxScale: 4, child: image);
  }
}

class _FullScreenMediaFallback extends StatelessWidget {
  const _FullScreenMediaFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 220),
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.textSecondary, size: 32),
    );
  }
}
