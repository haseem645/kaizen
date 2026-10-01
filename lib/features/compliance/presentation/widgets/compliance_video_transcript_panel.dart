import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/custom_functions.dart';
import '../../../../core/widgets/app_selection_sheet.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/fast_circular_progress.dart';
import '../../domain/entities/compliance_video_transcript.dart';
import '../providers/compliance_video_controller.dart';
import 'compliance_video_player.dart';

/// Shared by LTC and the lesson editor/viewer so captions and seeking stay aligned.
class ComplianceVideoTranscriptPanel extends StatelessWidget {
  const ComplianceVideoTranscriptPanel({
    super.key,
    required this.videoId,
    required this.videoUrl,
    required this.title,
    required this.transcript,
    this.localVideoPath,
    this.thumbnailLink,
    this.videoHeight = 250,
    this.fillBounds = false,
    this.topRightActions = const <Widget>[],
  });

  final Object videoId;
  final String? videoUrl;
  final String title;
  final String? transcript;
  final String? localVideoPath;
  final String? thumbnailLink;
  final double videoHeight;
  final bool fillBounds;
  final List<Widget> topRightActions;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey((videoId, videoUrl, transcript)),
      create: (_) => ComplianceVideoController(transcript),
      child: _VideoTranscriptView(panel: this),
    );
  }
}

class _VideoTranscriptView extends StatelessWidget {
  const _VideoTranscriptView({required this.panel});

  final ComplianceVideoTranscriptPanel panel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minimumHeight = panel.videoHeight + MediaQuery.textScalerOf(context).scale(48) + 40;
        // Training owns its page scroll; LTC also supplies a bounded viewport.
        final availableHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height * 0.7;
        return SingleChildScrollView(
          primary: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: availableHeight.clamp(minimumHeight, double.infinity),
            ),
            child: Material(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: panel.videoHeight,
                    child: _VideoPlayerArea(panel: panel),
                  ),
                  const Flexible(child: _ActiveTranscriptLine()),
                  const SizedBox(height: 2),
                  _TranscriptActions(onViewTranscript: () => _showTranscript(context)),
                  const SizedBox(height: 2),
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

class _VideoPlayerArea extends StatelessWidget {
  const _VideoPlayerArea({required this.panel});

  final ComplianceVideoTranscriptPanel panel;

  @override
  Widget build(BuildContext context) {
    final videoUrl = panel.videoUrl?.trim();
    if (videoUrl == null || videoUrl.isEmpty) {
      return const FastCircularProgressIndicator();
    }
    return ComplianceVideoPlayer(
      videoUrl: videoUrl,
      localVideoPath: panel.localVideoPath,
      title: panel.title,
      thumbnailLink: panel.thumbnailLink,
      height: panel.videoHeight,
      fillBounds: panel.fillBounds,
      topRightActions: panel.topRightActions,
      onPositionChanged: context.read<ComplianceVideoController>().updatePlaybackPosition,
      onSeekHandlerChanged: context.read<ComplianceVideoController>().setSeekHandler,
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
            child: TextButton(
              onPressed: onViewTranscript,
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
            ),
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
            minimumSize: const Size(30, 22),
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

class _ActiveTranscriptLine extends StatelessWidget {
  const _ActiveTranscriptLine();

  @override
  Widget build(BuildContext context) {
    final (text, isCcEnabled) = context.select<ComplianceVideoController, (String?, bool)>(
      (controller) => (controller.activeTranscriptLine?.text, controller.isCcEnabled),
    );
    if (isCcEnabled) return const SizedBox.shrink();
    if (text == null) return const SizedBox(height: 4);
    return SingleChildScrollView(
      primary: false,
      key: ValueKey(text),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: AppTextView.body3(text, color: AppColors.textPrimary, height: 1.4),
    );
  }
}

class _TranscriptSheet extends StatelessWidget {
  const _TranscriptSheet();

  @override
  Widget build(BuildContext context) {
    final error = context.select<ComplianceVideoController, String?>(
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
          AppSelectionError(message: error),
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
  final _centerKey = GlobalKey();
  int? _initialIndex;
  bool _didInitialize = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialize) return;
    _didInitialize = true;
    _initialIndex = context.read<ComplianceVideoController>().activeTranscriptIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final row = _initialLineKey.currentContext?.findRenderObject();
      if (row is! RenderBox || !row.hasSize) return;
      final position = _scrollController.position;
      final offset = (row.size.height - position.viewportDimension) / 2;
      _scrollController.jumpTo(offset.clamp(position.minScrollExtent, position.maxScrollExtent));
    });
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
        separatorBuilder: (_, index) => const SizedBox(height: 14),
        itemBuilder: (_, index) => _buildItem(controller, index),
      );
    }
    // Start layout at the active cue so long, variable-height lists open immediately.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: CustomScrollView(
        controller: _scrollController,
        center: _centerKey,
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
            key: _centerKey,
            itemCount: lines.length - initialIndex,
            separatorBuilder: (_, index) => const SizedBox(height: 14),
            itemBuilder: (_, index) => _buildItem(
              controller,
              initialIndex + index,
              key: index == 0 ? _initialLineKey : null,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildItem(ComplianceVideoController controller, int index, {Key? key}) {
    final line = controller.transcriptLines[index];
    return _TranscriptItem(
      key: key,
      line: line,
      isHighlighted: controller.activeTranscriptIndex == index,
      isSeeking: controller.seekingIndex == index,
      onTap: line.start == null || controller.isSeeking
          ? null
          : () async {
              final didSeek = await controller.seekToTranscriptLine(index);
              if (mounted && didSeek) Navigator.of(context).pop();
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
    final start = line.start;
    return InkWell(
      onTap: onTap,
      child: Row(
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
                        ? const FastCircularProgressIndicator(width: 14, height: 14)
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
      ),
    );
  }
}
