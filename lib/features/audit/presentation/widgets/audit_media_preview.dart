import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/custom_functions.dart';
import '../../../../core/utils/webm_playback_helper.dart';

class AuditMediaPreview extends StatelessWidget {
  const AuditMediaPreview({
    super.key,
    required this.mediaUrl,
    required this.mediaType,
    required this.width,
    required this.height,
    required this.placeholder,
    this.borderRadius = 8,
    this.showVideoOverlay = true,
  });

  final String? mediaUrl;
  final String? mediaType;
  final double width;
  final double height;
  final double borderRadius;
  final Widget placeholder;
  final bool showVideoOverlay;

  @override
  Widget build(BuildContext context) {
    final normalizedType = mediaType?.trim().toLowerCase();

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: switch (normalizedType) {
          'image' => _AuditImagePreview(
            mediaUrl: mediaUrl,
            placeholder: placeholder,
          ),
          'video' || 'screen_recording' => _AuditVideoPreview(
            mediaUrl: mediaUrl,
            placeholder: placeholder,
            showVideoOverlay: showVideoOverlay,
          ),
          _ => placeholder,
        },
      ),
    );
  }
}

class _AuditImagePreview extends StatelessWidget {
  const _AuditImagePreview({required this.mediaUrl, required this.placeholder});

  final String? mediaUrl;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    final imageUrl = CustomFunctions.resolveImageUrl(mediaUrl);
    if (imageUrl == null) {
      return placeholder;
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => placeholder,
      errorWidget: (_, __, ___) => placeholder,
    );
  }
}

class _AuditVideoPreview extends StatefulWidget {
  const _AuditVideoPreview({
    required this.mediaUrl,
    required this.placeholder,
    required this.showVideoOverlay,
  });

  final String? mediaUrl;
  final Widget placeholder;
  final bool showVideoOverlay;

  @override
  State<_AuditVideoPreview> createState() => _AuditVideoPreviewState();
}

class _AuditVideoPreviewState extends State<_AuditVideoPreview> {
  VideoPlayerController? _controller;
  Future<void>? _initializeFuture;

  @override
  void initState() {
    super.initState();
    _setupController();
  }

  @override
  void didUpdateWidget(covariant _AuditVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaUrl != widget.mediaUrl) {
      _disposeController();
      _setupController();
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _setupController() {
    _initializeFuture = _initializeController();
  }

  Future<void> _initializeController() async {
    final source = await WebmPlaybackHelper.resolvePlayableSource(
      widget.mediaUrl,
    );
    if (!mounted || source == null) {
      return;
    }

    final controller = source.isFile
        ? VideoPlayerController.file(File(source.path))
        : VideoPlayerController.networkUrl(Uri.parse(source.path));
    _controller = controller;

    try {
      await controller.initialize();
      await controller.setLooping(false);
      await controller.setVolume(0);
    } catch (error) {
      debugPrint('Audit video preview initialization failed: $error');
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _disposeController() {
    final controller = _controller;
    _controller = null;
    _initializeFuture = null;
    controller?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final initializeFuture = _initializeFuture;
    if (controller == null || initializeFuture == null) {
      return widget.placeholder;
    }

    return FutureBuilder<void>(
      future: initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError || !controller.value.isInitialized) {
          return widget.placeholder;
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
            if (widget.showVideoOverlay)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [AppColors.hex40000000, AppColors.hex14000000],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class AuditTextCommentPlaceholder extends StatelessWidget {
  const AuditTextCommentPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.hexc8b0ff,
      child: const Center(
        child: Icon(
          Icons.text_fields_rounded,
          color: AppColors.mainBg,
          size: 30,
        ),
      ),
    );
  }
}
