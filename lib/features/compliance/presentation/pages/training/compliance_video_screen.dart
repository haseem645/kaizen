import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sparrowkaizen/core/widgets/fast_circular_progress.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/utils/custom_functions.dart';
import '../../../../../core/widgets/app_selection_sheet.dart';
import '../../../../../core/widgets/app_text_view.dart';
import '../../../domain/entities/compliance_track_item_detail.dart';
import '../../../domain/entities/compliance_video_transcript.dart';
import '../../providers/compliance_video_controller.dart';
import '../../widgets/compliance_video_player.dart';

class ComplianceVideoScreen extends StatelessWidget {
  const ComplianceVideoScreen({super.key, required this.detail});

  final ComplianceTrackItemDetail detail;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey((detail.uuid, detail.videoUrl, detail.videoTranscript)),
      create: (_) => ComplianceVideoController(detail.videoTranscript),
      child: _ComplianceVideoView(detail: detail),
    );
  }
}

class _ComplianceVideoView extends StatelessWidget {
  const _ComplianceVideoView({required this.detail});

  static const _videoHeight = 250.0;
  final ComplianceTrackItemDetail detail;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Short viewports scroll the panel instead of shrinking the video.
        final minimumViewportHeight =
            _videoHeight + MediaQuery.textScalerOf(context).scale(48) + 40;
        final maxHeight = constraints.maxHeight.clamp(minimumViewportHeight, double.infinity);
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Material(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: _videoHeight,
                    child: _VideoPlayerArea(detail: detail, height: _videoHeight),
                  ),
                  const Flexible(child: _ActiveTranscriptLine()),
                  const SizedBox(height: 4),
                  _TranscriptActions(onViewTranscript: () => _showTranscript(context)),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showTranscript(BuildContext context) {
    final controller = context.read<ComplianceVideoController>();
    controller.clearSeekError();

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider<ComplianceVideoController>.value(
        value: controller,
        child: const _TranscriptSheet(),
      ),
    );
  }
}

class _TranscriptActions extends StatelessWidget {
  const _TranscriptActions({required this.onViewTranscript});

  final VoidCallback onViewTranscript;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 8),
        const _CcToggleButton(),
        const SizedBox(width: 8),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            heightFactor: 1,
            child: _ViewTranscriptButton(onPressed: onViewTranscript),
          ),
        ),
      ],
    );
  }
}

class _CcToggleButton extends StatelessWidget {
  const _CcToggleButton();

  @override
  Widget build(BuildContext context) {
    final isEnabled = context.select<ComplianceVideoController, bool>(
      (controller) => controller.isCcEnabled,
    );
    return Tooltip(
      message: isEnabled
          ? AppStrings.trainingShowActiveTranscript
          : AppStrings.trainingHideActiveTranscript,
      child: Semantics(
        toggled: isEnabled,
        child: TextButton(
          onPressed: context.read<ComplianceVideoController>().toggleCc,
          style: TextButton.styleFrom(
            minimumSize: const Size(26, 22),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            foregroundColor: isEnabled ? AppColors.textPrimary : AppColors.secondaryColor,
            backgroundColor: isEnabled ? AppColors.secondaryColor : Colors.transparent,
            side: const BorderSide(color: AppColors.secondaryColor),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          child: const Text(AppStrings.trainingCc),
        ),
      ),
    );
  }
}

class _ViewTranscriptButton extends StatelessWidget {
  const _ViewTranscriptButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 28),
        alignment: Alignment.bottomRight,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text(
        AppStrings.trainingViewTranscript,
        textAlign: TextAlign.right,
        style: TextStyle(
          color: AppColors.secondaryColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.secondaryColor,
        ),
      ),
    );
  }
}

class _ActiveTranscriptLine extends StatelessWidget {
  const _ActiveTranscriptLine();

  @override
  Widget build(BuildContext context) {
    final (text, isCcEnabled) = context.select<ComplianceVideoController, (String?, bool)>(
      (controller) => (controller.activeTranscriptLine?.text, controller.isCcEnabled),
    );
    if (isCcEnabled) return const SizedBox.shrink();
    if (text == null) {
      return const SizedBox(height: 8);
    }

    return SingleChildScrollView(
      key: ValueKey(text),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: AppTextView.body3(
        text,
        color: AppColors.textPrimary,
        height: 1.4,
        textAlign: TextAlign.start,
      ),
    );
  }
}

class _VideoPlayerArea extends StatelessWidget {
  const _VideoPlayerArea({required this.detail, required this.height});

  final ComplianceTrackItemDetail detail;
  final double height;

  @override
  Widget build(BuildContext context) {
    final videoUrl = detail.videoUrl?.trim();
    if (videoUrl == null || videoUrl.isEmpty) {
      return const FastCircularProgressIndicator();
    }

    return ComplianceVideoPlayer(
      videoUrl: videoUrl,
      title: detail.title,
      thumbnailLink: detail.videoThumbnailLink,
      height: height,
      fillBounds: false,
      fit: BoxFit.contain,
      onPositionChanged: context.read<ComplianceVideoController>().updatePlaybackPosition,
      onSeekHandlerChanged: context.read<ComplianceVideoController>().setSeekHandler,
    );
  }
}

class _TranscriptSheet extends StatelessWidget {
  const _TranscriptSheet();

  @override
  Widget build(BuildContext context) {
    final seekError = context.select<ComplianceVideoController, String?>(
      (controller) => controller.seekError,
    );
    return AppSelectionSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppFilterSheetHeader(
            title: AppStrings.trainingTranscriptTitle,
            onClose: () => Navigator.of(context).pop(),
          ),
          const Expanded(child: _TranscriptSection()),
          AppSelectionError(message: seekError),
        ],
      ),
    );
  }
}

class _TranscriptSection extends StatefulWidget {
  const _TranscriptSection();

  @override
  State<_TranscriptSection> createState() => _TranscriptSectionState();
}

class _TranscriptSectionState extends State<_TranscriptSection> {
  final _scrollController = ScrollController();
  final _initialLineKey = GlobalKey();
  static const _centerSliverKey = ValueKey('transcript-center');
  int? _initialIndex;
  bool _didInitialize = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialize) return;
    _didInitialize = true;
    _initialIndex = context.read<ComplianceVideoController>().activeTranscriptIndex;
    if (_initialIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _initialLineKey.currentContext?.findRenderObject();
        if (mounted && _scrollController.hasClients && target is RenderBox) {
          final position = _scrollController.position;
          // Center within the real list bounds; early cues must not add top space.
          final offset = (target.size.height - position.viewportDimension) / 2;
          _scrollController.jumpTo(
            offset.clamp(position.minScrollExtent, position.maxScrollExtent),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ComplianceVideoController>();
    final lines = controller.transcriptLines;
    if (lines.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: AppTextView.body3(
            AppStrings.trainingNoTranscriptAvailable,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
      );
    }

    final initialIndex = _initialIndex;
    if (initialIndex == null) {
      return ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: lines.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, index) => _buildItem(controller, index),
      );
    }

    // Anchor the lazy list at the active cue, so even distant, variable-height
    // rows are mounted immediately without guessing the preceding rows' heights.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: CustomScrollView(
        controller: _scrollController,
        center: _centerSliverKey,
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 4)),
          SliverList.builder(
            itemCount: initialIndex,
            itemBuilder: (_, index) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildItem(controller, initialIndex - index - 1),
            ),
          ),
          SliverList.separated(
            key: _centerSliverKey,
            itemCount: lines.length - initialIndex,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (_, index) => _buildItem(controller, initialIndex + index),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildItem(ComplianceVideoController controller, int index) {
    return _TranscriptItem(
      key: index == _initialIndex ? _initialLineKey : ValueKey(index),
      line: controller.transcriptLines[index],
      isHighlighted: controller.activeTranscriptIndex == index,
      isSeeking: controller.seekingTranscriptIndex == index,
      onTap: controller.transcriptLines[index].start == null || controller.isSeeking
          ? null
          : () async {
              final didSeek = await controller.seekToTranscriptLine(index);
              if (didSeek && mounted && ModalRoute.of(context)?.isCurrent == true) {
                Navigator.of(context).pop();
              }
            },
    );
  }
}

class _TranscriptItem extends StatelessWidget {
  const _TranscriptItem({
    super.key,
    required this.line,
    required this.isHighlighted,
    required this.isSeeking,
    required this.onTap,
  });

  final ComplianceTranscriptLine line;
  final bool isHighlighted;
  final bool isSeeking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: _TranscriptLineContent(line: line, isHighlighted: isHighlighted, isSeeking: isSeeking),
    );
  }
}

class _TranscriptLineContent extends StatelessWidget {
  const _TranscriptLineContent({
    required this.line,
    required this.isHighlighted,
    required this.isSeeking,
  });

  final ComplianceTranscriptLine line;
  final bool isHighlighted;
  final bool isSeeking;

  @override
  Widget build(BuildContext context) {
    final start = line.start;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (start != null) ...[
          SizedBox(
            width: 84,
            child: Row(
              children: [
                Flexible(
                  child: AppTextView.body3(
                    CustomFunctions.formatDuration(start.inSeconds),
                    color: isHighlighted ? AppColors.secondaryColor : AppColors.textSecondary,
                    fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
                    height: 1.6,
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: isSeeking
                      ? const FastCircularProgressIndicator(width: 16, height: 16)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: AppTextView.body3(
            line.text,
            color: isHighlighted ? AppColors.secondaryColor : AppColors.textPrimary,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
