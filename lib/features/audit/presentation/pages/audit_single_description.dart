import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:sparrowkaizen/core/constants/app_colors.dart';
import 'package:sparrowkaizen/core/constants/app_strings.dart';
import 'package:sparrowkaizen/core/utils/custom_functions.dart';
import 'package:sparrowkaizen/core/widgets/app_button.dart';
import 'package:sparrowkaizen/core/widgets/app_overlay_close_button.dart';
import 'package:sparrowkaizen/core/widgets/app_text_view.dart';
import 'package:sparrowkaizen/core/widgets/fast_circular_progress.dart';
import 'package:sparrowkaizen/features/audit/domain/entities/audit_description_audit.dart';
import 'package:sparrowkaizen/features/audit/domain/entities/quarterly_audit.dart';
import 'package:sparrowkaizen/features/audit/presentation/providers/audit_controller.dart';
import 'package:sparrowkaizen/features/audit/presentation/providers/audit_media_upload_controller.dart';
import 'package:sparrowkaizen/features/audit/presentation/widgets/audit_media_preview.dart';
import 'package:sparrowkaizen/features/audit/presentation/widgets/description_media_comment_bottom_sheet.dart';

import '../../../training/domain/entities/seat_description_training_route.dart';
import '../../../training/presentation/pages/view_training_screen.dart';
import 'audit_media_comments_bottom_sheet.dart';
import 'audit_screen_recording_capture_screen.dart';

class SingleDescriptionDetails extends StatefulWidget {
  const SingleDescriptionDetails({
    super.key,
    required this.audit,
    required this.description,
    required this.date,
    required this.isOwner,
    this.isViewOnly = false,
    this.onAuditUpdated,
  });

  final QuarterlyAudit audit;
  final QuarterlyAuditDescription description;
  final String date;
  final bool isOwner;
  final bool isViewOnly;
  final Future<void> Function()? onAuditUpdated;

  @override
  State<SingleDescriptionDetails> createState() =>
      _SingleDescriptionDetailsState();
}

class _SingleDescriptionDetailsState extends State<SingleDescriptionDetails> {
  late final ValueNotifier<Future<AuditDescriptionAudit>>
  _auditDescriptionFutureNotifier;
  final ScrollController _scrollController = ScrollController();
  int _lastHandledAuditUploadEventSequence = 0;

  @override
  void initState() {
    super.initState();
    _auditDescriptionFutureNotifier =
        ValueNotifier<Future<AuditDescriptionAudit>>(_loadAuditDescription());
    _lastHandledAuditUploadEventSequence =
        AuditMediaUploadController.instance.latestTerminalEventSequence;
    AuditMediaUploadController.instance.addListener(
      _handleAuditMediaUploadChanged,
    );
  }

  @override
  void dispose() {
    AuditMediaUploadController.instance.removeListener(
      _handleAuditMediaUploadChanged,
    );
    _auditDescriptionFutureNotifier.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<AuditDescriptionAudit> _loadAuditDescription() {
    return context.read<AuditController>().loadAuditDescription(
      quarterlyAuditId: widget.audit.uuid,
      descriptionId: widget.description.uuid,
      date: widget.date,
    );
  }

  Future<void> _submitDescriptionAudit(
    String descriptionId,
    Map<String, int> audit,
  ) async {
    await context.read<AuditController>().submitAuditDescriptionSelection(
      descriptionId: descriptionId,
      audit: audit,
    );
    await widget.onAuditUpdated?.call();
  }

  Future<void> _saveCommentWithMedia(
    String descriptionId,
    String comment,
    File? mediaFile,
    String? mediaType,
  ) async {
    final shouldRefreshImmediately = await context
        .read<AuditController>()
        .createAuditDescriptionMediaComment(
          descriptionId: descriptionId,
          comment: comment,
          mediaFile: mediaFile,
          mediaType: mediaType,
        );
    if (shouldRefreshImmediately) {
      await _refreshAuditDescriptionSilently();
    }
  }

  Future<void> _saveCommentWithoutMedia(
    String descriptionId,
    String comment,
  ) async {
    await context.read<AuditController>().createAuditDescriptionComment(
      descriptionId: descriptionId,
      comment: comment,
    );
    await _refreshAuditDescriptionSilently();
  }

  Future<void> _refreshAuditDescriptionSilently() async {
    final refreshedAuditDescription = await _loadAuditDescription();
    _auditDescriptionFutureNotifier.value = Future<AuditDescriptionAudit>.value(
      refreshedAuditDescription,
    );
  }

  void _handleAuditMediaUploadChanged() {
    if (!mounted) {
      return;
    }

    final terminalTasks = AuditMediaUploadController.instance
        .terminalTasksSince(_lastHandledAuditUploadEventSequence);
    if (terminalTasks.isEmpty) {
      return;
    }

    _lastHandledAuditUploadEventSequence =
        terminalTasks.last.terminalEventSequence;
    var shouldRefresh = false;
    String? failureMessage;
    for (final task in terminalTasks) {
      if (task.flow != AuditMediaUploadFlow.descriptionComment ||
          task.descriptionId != widget.description.uuid) {
        continue;
      }

      if (task.isCompleted) {
        shouldRefresh = true;
        continue;
      }

      if (task.isFailed && failureMessage == null) {
        final message = task.errorMessage?.trim();
        if (message != null && message.isNotEmpty) {
          failureMessage = message;
        }
      }
    }

    if (shouldRefresh) {
      unawaited(_refreshAuditDescriptionSilently());
    }
    if (failureMessage != null) {
      _showSnackBar(failureMessage);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _scrollToCommentsSection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      Future<void> scrollToBottom({
        Duration duration = const Duration(milliseconds: 320),
      }) async {
        if (!mounted || !_scrollController.hasClients) {
          return;
        }

        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: duration,
          curve: Curves.easeOutCubic,
        );
      }

      scrollToBottom().then((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 180));
        await scrollToBottom(duration: const Duration(milliseconds: 220));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
              child: _buildHeader(context),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  children: [
                    _AuditProfileCard(
                      audit: widget.audit,
                      description: widget.description,
                      date: widget.date,
                    ),
                    const SizedBox(height: 18),
                    _SeatDescriptionCard(
                      widget.description.description.isEmpty
                          ? AppStrings.auditNoDescriptionAvailable
                          : widget.description.description,
                    ),
                    const SizedBox(height: 18),
                    _SeatSpecificsCard(description: widget.description),
                    const SizedBox(height: 18),
                    ValueListenableBuilder<Future<AuditDescriptionAudit>>(
                      valueListenable: _auditDescriptionFutureNotifier,
                      builder: (context, auditDescriptionFuture, _) {
                        return Column(
                          children: [
                            _PassSelectionCard(
                              description: widget.description,
                              date: widget.date,
                              isOwner: widget.isOwner,
                              isViewOnly: widget.isViewOnly,
                              auditDescriptionFuture: auditDescriptionFuture,
                              onSubmitAudit: _submitDescriptionAudit,
                            ),
                            const SizedBox(height: 18),
                            _CommentsCard(
                              description: widget.description,
                              date: widget.date,
                              isOwner: widget.isOwner,
                              isViewOnly: widget.isViewOnly,
                              auditDescriptionFuture: auditDescriptionFuture,
                              onCommentsChanged:
                                  _refreshAuditDescriptionSilently,
                              onCommentsSheetClosed: _scrollToCommentsSection,
                              onSaveCommentWithMedia: _saveCommentWithMedia,
                              onSaveCommentWithoutMedia:
                                  _saveCommentWithoutMedia,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: canAddComment
      //     ? SafeArea(
      //         top: false,
      //         bottom: false,
      //         child: Container(
      //           decoration: BoxDecoration(
      //             color: AppColors.mainBg,
      //             boxShadow: [
      //               BoxShadow(
      //                 color: Colors.black.withValues(alpha: 0.2),
      //                 spreadRadius: 10,
      //                 blurRadius: 10,
      //                 offset: const Offset(0, 5),
      //               ),
      //             ],
      //           ),
      //           padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      //           child: AppButton(text: 'Add Comment', onPressed: () {}),
      //         ),
      //       )
      //     : null,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SvgPicture.asset(
                  '${AppStrings.imagePath}back.svg',
                  height: 24,
                  width: 24,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          const AppTextView.body(
            AppStrings.auditDescriptionDetails,
            color: AppColors.secondaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }
}

class _AuditProfileCard extends StatelessWidget {
  const _AuditProfileCard({
    required this.audit,
    required this.description,
    required this.date,
  });

  final QuarterlyAudit audit;
  final QuarterlyAuditDescription? description;
  final String date;

  @override
  Widget build(BuildContext context) {
    final lastAuditDate = date;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextView.body1(
                  audit.jobTitle,
                  color: AppColors.secondaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                AppTextView.body(
                  audit.profileName.trim().isEmpty
                      ? AppStrings.noProfile
                      : audit.profileName,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13),
                    children: [
                      TextSpan(
                        text: '${AppStrings.lastAudit}: ',
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(
                            alpha: 0.78,
                          ),
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      TextSpan(
                        text: CustomFunctions.formatDate(lastAuditDate),
                        style: TextStyle(
                          color: AppColors.secondaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _Avatar(size: 82, imageUrl: audit.profileImage),
        ],
      ),
    );
  }
}

class _SeatDescriptionCard extends StatelessWidget {
  const _SeatDescriptionCard(this.seatDescription);

  final String seatDescription;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextView.body1(
            AppStrings.auditSeatDescription,
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 12),
          AppTextView.body(
            seatDescription,
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ExpandableCard extends StatefulWidget {
  const _ExpandableCard({
    required this.title,
    required this.body,
    this.trailing,
    this.footer,
  });

  final String title;
  final String body;
  final Widget? trailing;
  final Widget? footer;

  @override
  State<_ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<_ExpandableCard> {
  static const _collapsedLineCount = 4;
  static const _bodyTextStyle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  late final ValueNotifier<bool> _isExpandedNotifier = ValueNotifier<bool>(
    false,
  );

  @override
  void didUpdateWidget(covariant _ExpandableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.body != widget.body) {
      _isExpandedNotifier.value = false;
    }
  }

  @override
  void dispose() {
    _isExpandedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextView.body1(
                  widget.title,
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final hasMoreThanFourLines = _hasMoreThanFourLines(
                context,
                constraints.maxWidth,
              );

              return ValueListenableBuilder<bool>(
                valueListenable: _isExpandedNotifier,
                builder: (context, isExpanded, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextView.body(
                        widget.body,
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        maxLines: isExpanded ? null : _collapsedLineCount,
                        overflow: isExpanded ? null : TextOverflow.ellipsis,
                      ),
                      if (hasMoreThanFourLines) ...[
                        const SizedBox(height: 18),
                        Center(
                          child: _SeeAllAction(
                            isExpanded: isExpanded,
                            onTap: () {
                              _isExpandedNotifier.value = !isExpanded;
                            },
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      if (widget.footer != null) ...[
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: widget.footer!,
                        ),
                      ],
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  bool _hasMoreThanFourLines(BuildContext context, double maxWidth) {
    if (maxWidth <= 0 || widget.body.isEmpty) {
      return false;
    }

    final textPainter = TextPainter(
      text: TextSpan(text: widget.body, style: _bodyTextStyle),
      textDirection: Directionality.of(context),
      maxLines: _collapsedLineCount,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: maxWidth);

    return textPainter.didExceedMaxLines;
  }
}

class _SeatSpecificsCard extends StatelessWidget {
  const _SeatSpecificsCard({required this.description});

  final QuarterlyAuditDescription? description;

  @override
  Widget build(BuildContext context) {
    final trainingRoute = description?.trainingRoute;

    return _ExpandableCard(
      title: AppStrings.auditSeatSpecifics,
      body:
          description?.jobSpecifics ?? AppStrings.auditNoSeatSpecificsAvailable,
      trailing: _PillLabel(
        text: description?.auditFactorType ?? AppStrings.checkInTitle,
      ),
      footer: trainingRoute != null && trainingRoute.hasDescription
          ? _ViewTrainingAction(trainingRoute: trainingRoute)
          : null,
    );
  }
}

class _ViewTrainingAction extends StatelessWidget {
  const _ViewTrainingAction({required this.trainingRoute});

  final SeatDescriptionTrainingRoute trainingRoute;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ViewTrainingScreen(trainingRoute: trainingRoute),
          ),
        );
      },
      borderRadius: BorderRadius.circular(999),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextView.body2(
            AppStrings.seatProfileTrainings,
            color: AppColors.secondaryColor,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppColors.secondaryColor,
            size: 14,
          ),
        ],
      ),
    );
  }
}

enum _PassBlockState { great, almostThere, needsImprovement, defaultValue }

class _PassSelectionCard extends StatefulWidget {
  const _PassSelectionCard({
    required this.description,
    required this.date,
    required this.isOwner,
    required this.isViewOnly,
    required this.auditDescriptionFuture,
    required this.onSubmitAudit,
  });

  final QuarterlyAuditDescription? description;
  final String date;
  final bool isOwner;
  final bool isViewOnly;
  final Future<AuditDescriptionAudit> auditDescriptionFuture;
  final Future<void> Function(String descriptionId, Map<String, int> audit)
  onSubmitAudit;

  @override
  State<_PassSelectionCard> createState() => _PassSelectionCardState();
}

class _PassSelectionCardState extends State<_PassSelectionCard> {
  static const Duration _submitDebounceDuration = Duration(milliseconds: 180);

  late final ValueNotifier<_PassSelectionViewState> _viewStateNotifier;
  Timer? _submitDebounceTimer;

  @override
  void initState() {
    super.initState();
    _viewStateNotifier = ValueNotifier<_PassSelectionViewState>(
      _PassSelectionViewState(
        blocks: _initialBlocks(widget.description),
        hasLocalChanges: false,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant _PassSelectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.description?.uuid != widget.description?.uuid) {
      _viewStateNotifier.value = _PassSelectionViewState(
        blocks: _initialBlocks(widget.description),
        hasLocalChanges: false,
      );
    }
  }

  @override
  void dispose() {
    _submitDebounceTimer?.cancel();
    _viewStateNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canEditBlocks =
        !widget.isViewOnly &&
        widget.isOwner &&
        CustomFunctions.isAuditWithinContinueWindow(widget.date);
    return FutureBuilder<AuditDescriptionAudit>(
      future: widget.auditDescriptionFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _syncBlocksFromAudit(snapshot.data!.audit);
        }

        return ValueListenableBuilder<_PassSelectionViewState>(
          valueListenable: _viewStateNotifier,
          builder: (context, viewState, _) {
            final blocks = viewState.blocks;
            final isLoading = snapshot.connectionState != ConnectionState.done;
            final great = blocks
                .where((block) => block == _PassBlockState.great)
                .length;
            final almostThere = blocks
                .where((block) => block == _PassBlockState.almostThere)
                .length;
            final needsImprovement = blocks
                .where((block) => block == _PassBlockState.needsImprovement)
                .length;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextView.body(
                    'Select Ratings',
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  if (!isLoading) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 14,
                      runSpacing: 10,
                      children: [
                        _LegendItem(
                          color: AppColors.green1,
                          label: 'Great',
                          count: '$great',
                        ),
                        _LegendItem(
                          color: AppColors.orange1,
                          label: 'Almost There',
                          count: '$almostThere',
                        ),
                        _LegendItem(
                          color: AppColors.red1,
                          label: 'Needs Improvement',
                          count: '$needsImprovement',
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SelectionCounter(
                          color: canEditBlocks
                              ? AppColors.green1
                              : AppColors.green1.withValues(alpha: 0.5),
                          count: great,
                          showDecrementControl: widget.isOwner,
                          onTapCount: canEditBlocks
                              ? () => _incrementRating(_PassBlockState.great)
                              : null,
                          onTapArrow: canEditBlocks
                              ? () => _decrementRating(_PassBlockState.great)
                              : null,
                          canEditBlocks: canEditBlocks,
                        ),
                        SizedBox(width: 25),
                        _SelectionCounter(
                          color: canEditBlocks
                              ? AppColors.orange1
                              : AppColors.orange1.withValues(alpha: 0.5),
                          count: almostThere,
                          showDecrementControl: widget.isOwner,
                          onTapCount: canEditBlocks
                              ? () => _incrementRating(
                                  _PassBlockState.almostThere,
                                )
                              : null,
                          onTapArrow: canEditBlocks
                              ? () => _decrementRating(
                                  _PassBlockState.almostThere,
                                )
                              : null,
                          canEditBlocks: canEditBlocks,
                        ),
                        SizedBox(width: 25),
                        _SelectionCounter(
                          color: canEditBlocks
                              ? AppColors.red1
                              : AppColors.red1.withValues(alpha: 0.5),
                          count: needsImprovement,
                          showDecrementControl: widget.isOwner,
                          onTapCount: canEditBlocks
                              ? () => _incrementRating(
                                  _PassBlockState.needsImprovement,
                                )
                              : null,
                          onTapArrow: canEditBlocks
                              ? () => _decrementRating(
                                  _PassBlockState.needsImprovement,
                                )
                              : null,
                          canEditBlocks: canEditBlocks,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<_PassBlockState> _initialBlocks(QuarterlyAuditDescription? description) {
    final great = description?.great ?? 0;
    final almostThere = description?.almostThere ?? 0;
    final needsImprovement = description?.needsImprovement ?? 0;
    final blocks = <_PassBlockState>[
      for (var index = 0; index < great; index += 1) _PassBlockState.great,
      for (var index = 0; index < almostThere; index += 1)
        _PassBlockState.almostThere,
      for (var index = 0; index < needsImprovement; index += 1)
        _PassBlockState.needsImprovement,
    ];

    if (blocks.isEmpty) {
      blocks.add(_PassBlockState.defaultValue);
    }

    return blocks;
  }

  void _syncBlocksFromAudit(List<AuditRating> audit) {
    final currentState = _viewStateNotifier.value;
    if (audit.isEmpty || currentState.hasLocalChanges) {
      return;
    }

    final resolvedBlocks = audit
        .map(
          (value) => switch (value) {
            AuditRating.great => _PassBlockState.great,
            AuditRating.almostThere => _PassBlockState.almostThere,
            AuditRating.needsImprovement => _PassBlockState.needsImprovement,
          },
        )
        .toList();
    _viewStateNotifier.value = currentState.copyWith(blocks: resolvedBlocks);
  }

  void _decrementRating(_PassBlockState state) {
    final currentState = _viewStateNotifier.value;
    final updatedBlocks = List<_PassBlockState>.from(currentState.blocks);
    final index = updatedBlocks.lastIndexOf(state);
    if (index < 0) {
      return;
    }

    updatedBlocks.removeAt(index);
    _viewStateNotifier.value = _PassSelectionViewState(
      blocks: _normalizeDefaultBlocks(updatedBlocks),
      hasLocalChanges: true,
    );

    _scheduleAuditSubmission();
  }

  void _incrementRating(_PassBlockState state) {
    final currentState = _viewStateNotifier.value;
    final updatedBlocks = List<_PassBlockState>.from(currentState.blocks)
      ..removeWhere((block) => block == _PassBlockState.defaultValue)
      ..add(state);
    _viewStateNotifier.value = _PassSelectionViewState(
      blocks: updatedBlocks,
      hasLocalChanges: true,
    );

    _scheduleAuditSubmission();
  }

  void _scheduleAuditSubmission() {
    _submitDebounceTimer?.cancel();
    _submitDebounceTimer = Timer(_submitDebounceDuration, () {
      if (!mounted) {
        return;
      }
      _submitDescriptionAudit(_auditPayload());
    });
  }

  Map<String, int> _auditPayload() {
    final blocks = _viewStateNotifier.value.blocks;
    return <String, int>{
      'great': blocks.where((block) => block == _PassBlockState.great).length,
      'almost_there': blocks
          .where((block) => block == _PassBlockState.almostThere)
          .length,
      'needs_improvement': blocks
          .where((block) => block == _PassBlockState.needsImprovement)
          .length,
    };
  }

  Future<void> _submitDescriptionAudit(Map<String, int> audit) async {
    try {
      final descriptionAudit = await widget.auditDescriptionFuture;
      final descriptionId = descriptionAudit.uuid.trim();
      if (descriptionId.isEmpty) {
        return;
      }

      await widget.onSubmitAudit(descriptionId, audit);
    } catch (error) {
      debugPrint('Unable to submit description audit: $error');
    }
  }

  List<_PassBlockState> _normalizeDefaultBlocks(List<_PassBlockState> blocks) {
    final hasSelectedBlock = blocks.any(
      (block) => block != _PassBlockState.defaultValue,
    );
    if (hasSelectedBlock) {
      return blocks;
    }

    return <_PassBlockState>[_PassBlockState.defaultValue];
  }
}

class _PassSelectionViewState {
  const _PassSelectionViewState({
    required this.blocks,
    required this.hasLocalChanges,
  });

  final List<_PassBlockState> blocks;
  final bool hasLocalChanges;

  _PassSelectionViewState copyWith({
    List<_PassBlockState>? blocks,
    bool? hasLocalChanges,
  }) {
    return _PassSelectionViewState(
      blocks: blocks ?? this.blocks,
      hasLocalChanges: hasLocalChanges ?? this.hasLocalChanges,
    );
  }
}

class _CommentsCard extends StatefulWidget {
  const _CommentsCard({
    required this.description,
    required this.date,
    required this.isOwner,
    required this.isViewOnly,
    required this.auditDescriptionFuture,
    required this.onCommentsChanged,
    required this.onCommentsSheetClosed,
    required this.onSaveCommentWithMedia,
    required this.onSaveCommentWithoutMedia,
  });

  final QuarterlyAuditDescription description;
  final String date;
  final bool isOwner;
  final bool isViewOnly;
  final Future<AuditDescriptionAudit> auditDescriptionFuture;
  final Future<void> Function() onCommentsChanged;
  final VoidCallback onCommentsSheetClosed;
  final Future<void> Function(
    String descriptionId,
    String comment,
    File? mediaFile,
    String? mediaType,
  )
  onSaveCommentWithMedia;
  final Future<void> Function(String descriptionId, String comment)
  onSaveCommentWithoutMedia;

  @override
  State<_CommentsCard> createState() => _CommentsCardState();
}

class _CommentsCardState extends State<_CommentsCard> {
  late final ValueNotifier<bool> _isExpandedNotifier = ValueNotifier<bool>(
    false,
  );

  @override
  void dispose() {
    _isExpandedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canManageComments =
        !widget.isViewOnly &&
        widget.isOwner &&
        !CustomFunctions.isDateBeforeToday(widget.date);
    final canReplyToComments = !widget.isViewOnly && widget.isOwner;
    return FutureBuilder<AuditDescriptionAudit>(
      future: widget.auditDescriptionFuture,
      builder: (context, snapshot) {
        final media =
            snapshot.data?.auditMedia ?? const <AuditDescriptionMedia>[];
        final hasComments = media.isNotEmpty;

        return ValueListenableBuilder<bool>(
          valueListenable: _isExpandedNotifier,
          builder: (context, isExpanded, _) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppTextView.body(
                          AppStrings.comments,
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (canManageComments) ...[
                        _CommentIconButton(
                          isEnabled: snapshot.hasData,
                          icon: Icons.camera_alt_outlined,
                          onTap: snapshot.hasData
                              ? () => _openCreateCommentDialog(snapshot.data!)
                              : null,
                        ),
                      ],
                    ],
                  ),
                  if (snapshot.connectionState != ConnectionState.done) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: FastCircularProgressIndicator(),
                      ),
                    ),
                  ] else if (snapshot.hasError) ...[
                    const SizedBox(height: 12),
                    AppTextView.body2(
                      AppStrings.unableToLoadComments,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                    ),
                  ] else if (!hasComments) ...[
                    const SizedBox(height: 12),
                    AppTextView.body2(
                      AppStrings.noCommentsAvailable,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                    ),
                  ] else ...[
                    if (isExpanded) ...[
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: media.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _CommentMediaCard(
                            descriptionId: widget.description.uuid,
                            media: media[index],
                            mediaList: media,
                            isReadOnly: !canManageComments,
                            canReply: canReplyToComments,
                            onCommentsChanged: widget.onCommentsChanged,
                            onSheetClosed: widget.onCommentsSheetClosed,
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 18),
                    InkWell(
                      onTap: () {
                        _isExpandedNotifier.value = !isExpanded;
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppTextView.body2(
                            isExpanded
                                ? AppStrings.auditHideComments
                                : AppStrings.auditExpandComments,
                            color: AppColors.lightPurple1,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          Icon(
                            isExpanded
                                ? Icons.arrow_drop_up
                                : Icons.arrow_drop_down,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openCreateCommentDialog(AuditDescriptionAudit audit) async {
    await _showMediaTypeSelectionSheet(audit);
  }

  Future<bool> _openSelectedMediaCommentDialog(
    AuditDescriptionAudit audit,
    DescriptionMediaCommentContentType selectedType,
  ) async {
    if (selectedType == DescriptionMediaCommentContentType.screenRecording) {
      return _openScreenRecordingCommentDialog(audit);
    }

    final didSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DescriptionMediaCommentBottomSheet(
          contentType: selectedType,
          onSave: (comment, mediaFile, mediaType) =>
              widget.onSaveCommentWithMedia(
                audit.uuid,
                comment,
                mediaFile,
                mediaType,
              ),
        );
      },
    );

    return didSave ?? false;
  }

  Future<bool> _openScreenRecordingCommentDialog(
    AuditDescriptionAudit audit,
  ) async {
    final recordedMedia = await Navigator.of(context).push<File?>(
      MaterialPageRoute(
        builder: (_) => const AuditScreenRecordingCaptureScreen(),
      ),
    );
    if (!mounted || recordedMedia == null) {
      return false;
    }

    final didSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DescriptionMediaCommentBottomSheet(
          contentType: DescriptionMediaCommentContentType.screenRecording,
          initialMediaFile: recordedMedia,
          initialMediaType: 'screen_recording',
          allowInitialMediaRemoval: false,
          onSave: (comment, mediaFile, mediaType) =>
              widget.onSaveCommentWithMedia(
                audit.uuid,
                comment,
                mediaFile,
                mediaType,
              ),
        );
      },
    );

    return didSave ?? false;
  }

  Future<void> _showMediaTypeSelectionSheet(AuditDescriptionAudit audit) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _MediaTypeSelectionBottomSheet(
          onTypeSelected: (selectedType) =>
              _openSelectedMediaCommentDialog(audit, selectedType),
        );
      },
    );

    if (!mounted) {
      return;
    }

    widget.onCommentsSheetClosed();
  }
}

class _CommentIconButton extends StatelessWidget {
  const _CommentIconButton({
    required this.isEnabled,
    required this.icon,
    this.onTap,
  });

  final bool isEnabled;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isEnabled ? AppColors.secondaryColor : AppColors.grey1;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark3,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.6)),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
      ),
    );
  }
}

class _CreateTextCommentDialog extends StatefulWidget {
  const _CreateTextCommentDialog({required this.onSave});

  final Future<void> Function(String comment) onSave;

  @override
  State<_CreateTextCommentDialog> createState() =>
      _CreateTextCommentDialogState();
}

class _CreateTextCommentDialogState extends State<_CreateTextCommentDialog> {
  final TextEditingController _controller = TextEditingController();
  late final ValueNotifier<bool> _isSavingNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _isSavingNotifier.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _isSavingNotifier]),
      builder: (context, _) {
        final isSaving = _isSavingNotifier.value;
        final canSave = _controller.text.trim().isNotEmpty && !isSaving;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.grey2.withValues(alpha: 0.55),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: AppTextView.body1(
                        AppStrings.auditAddComment,
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AppOverlayCloseButton(
                      onTap: isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppTextView.body2(
                  AppStrings.comment,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  maxLines: 4,
                  minLines: 4,
                  enabled: !isSaving,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: AppColors.secondaryColor,
                  decoration: InputDecoration(
                    hintText: AppStrings.enterComment,
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    filled: true,
                    fillColor: AppColors.fieldFill,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.fieldBorder.withValues(alpha: 0.35),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.secondaryColor,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.grey1.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  text: AppStrings.saveComment,
                  onPressed: canSave ? _save : null,
                  isLoading: isSaving,
                  backgroundColor: canSave
                      ? AppColors.secondaryColor
                      : AppColors.grey1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    final comment = _controller.text.trim();
    if (comment.isEmpty || _isSavingNotifier.value) {
      return;
    }

    _isSavingNotifier.value = true;
    try {
      await widget.onSave(comment);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      debugPrint('Unable to create text comment: $error');
      _isSavingNotifier.value = false;
    }
  }
}

class _CommentMediaCard extends StatelessWidget {
  const _CommentMediaCard({
    required this.descriptionId,
    required this.media,
    required this.mediaList,
    required this.isReadOnly,
    required this.canReply,
    required this.onCommentsChanged,
    required this.onSheetClosed,
  });

  final String descriptionId;
  final AuditDescriptionMedia media;
  final List<AuditDescriptionMedia> mediaList;
  final bool isReadOnly;
  final bool canReply;
  final Future<void> Function() onCommentsChanged;
  final VoidCallback onSheetClosed;

  @override
  Widget build(BuildContext context) {
    final comment = media.comment?.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          _openCommentsDialog(context);
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark3,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.grey2.withValues(alpha: 0.45)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CommentMediaPreview(
                mediaUrl: media.media,
                mediaType: media.type,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextView.body2(
                  comment == null || comment.isEmpty
                      ? AppStrings.noComment
                      : comment,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCommentsDialog(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AuditMediaCommentsBottomSheet(
        descriptionId: descriptionId,
        selectedMedia: media,
        mediaList: mediaList,
        isReadOnly: isReadOnly,
        canReply: canReply,
        onMediaChanged: onCommentsChanged,
      ),
    );

    if (!context.mounted) {
      return;
    }

    onSheetClosed();
  }
}

class _CommentMediaPreview extends StatelessWidget {
  const _CommentMediaPreview({required this.mediaUrl, required this.mediaType});

  final String mediaUrl;
  final String? mediaType;

  @override
  Widget build(BuildContext context) {
    final normalizedType = mediaType?.trim().toLowerCase();
    if (normalizedType == 'screen_recording') {
      return const _ScreenRecordingCommentPreview();
    }

    final hasMedia =
        (normalizedType == 'image' ||
            normalizedType == 'video' ||
            normalizedType == 'screen_recording') &&
        mediaUrl.trim().isNotEmpty;

    return AuditMediaPreview(
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      width: 72,
      height: 72,
      borderRadius: 6,
      placeholder: hasMedia
          ? const _CommentMediaLoadingPlaceholder()
          : const AuditTextCommentPlaceholder(),
    );
  }
}

class _ScreenRecordingCommentPreview extends StatelessWidget {
  const _ScreenRecordingCommentPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.hex14182a,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.secondaryColor,
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _CommentMediaLoadingPlaceholder extends StatelessWidget {
  const _CommentMediaLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      '${AppStrings.imagePath}no_image.png',
      fit: BoxFit.cover,
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label, this.count});

  final Color color;
  final String label;
  final String? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 12),
            children: [
              TextSpan(
                text: label,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
              ),
              // TextSpan(
              //   text: count == null ? '' : '($count)',
              //   style: TextStyle(
              //     color: label == 'Great'
              //         ? AppColors.green1
              //         : label == 'Almost There'
              //         ? AppColors.orange1
              //         : label == 'Needs Improvement'
              //         ? AppColors.red1
              //         : Colors.transparent,
              //     fontWeight: FontWeight.w700,
              //   ),
              // ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SelectionCounter extends StatelessWidget {
  const _SelectionCounter({
    required this.color,
    required this.count,
    this.onTapCount,
    this.onTapArrow,
    required this.canEditBlocks,
    required this.showDecrementControl,
  });

  final Color color;
  final int count;
  final VoidCallback? onTapCount;
  final VoidCallback? onTapArrow;
  final bool canEditBlocks;
  final bool showDecrementControl;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTapCount,
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: AppTextView.body2(
              '$count',
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        if (showDecrementControl) ...[
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTapArrow,
            child: Container(
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: canEditBlocks
                    ? AppColors.grey1
                    : AppColors.grey1.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                canEditBlocks
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.lock_rounded,
                color: Colors.white,
                size: canEditBlocks ? 28 : 18,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PillLabel extends StatelessWidget {
  const _PillLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.orange1,
        borderRadius: BorderRadius.circular(50),
      ),
      child: AppTextView.body2(
        text,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 12,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _SeeAllAction extends StatelessWidget {
  const _SeeAllAction({this.isExpanded = false, this.onTap});

  final bool isExpanded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppTextView.body2(
              isExpanded ? AppStrings.auditShowLess : AppStrings.auditSeeAll,
              color: AppColors.lightPurple1,
              fontWeight: FontWeight.w500,
            ),
            Icon(
              isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaTypeSelectionBottomSheet extends StatefulWidget {
  const _MediaTypeSelectionBottomSheet({required this.onTypeSelected});

  final Future<bool> Function(DescriptionMediaCommentContentType selectedType)
  onTypeSelected;

  @override
  State<_MediaTypeSelectionBottomSheet> createState() =>
      _MediaTypeSelectionBottomSheetState();
}

class _MediaTypeSelectionBottomSheetState
    extends State<_MediaTypeSelectionBottomSheet> {
  late final ValueNotifier<bool> _isOpeningChildSheetNotifier =
      ValueNotifier<bool>(false);

  @override
  void dispose() {
    _isOpeningChildSheetNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return ValueListenableBuilder<bool>(
      valueListenable: _isOpeningChildSheetNotifier,
      builder: (context, isOpeningChildSheet, _) {
        return SafeArea(
          top: false,
          bottom: false,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(18, 14, 18, bottomPadding + 24),
            decoration: const BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const AppTextView.body1(
                  AppStrings.auditSelectMediaType,
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: 14),
                _MediaTypeOption(
                  title: AppStrings.auditPhoto,
                  onTap: isOpeningChildSheet
                      ? null
                      : () => _openChildSheet(
                          DescriptionMediaCommentContentType.photo,
                        ),
                ),
                const SizedBox(height: 10),
                _MediaTypeOption(
                  title: AppStrings.auditVideo,
                  onTap: isOpeningChildSheet
                      ? null
                      : () => _openChildSheet(
                          DescriptionMediaCommentContentType.video,
                        ),
                ),
                const SizedBox(height: 10),
                _MediaTypeOption(
                  title: AppStrings.auditUpload,
                  onTap: isOpeningChildSheet
                      ? null
                      : () => _openChildSheet(
                          DescriptionMediaCommentContentType.upload,
                        ),
                ),
                const SizedBox(height: 10),
                _MediaTypeOption(
                  title: AppStrings.auditScreenRecording,
                  onTap: isOpeningChildSheet
                      ? null
                      : () => _openChildSheet(
                          DescriptionMediaCommentContentType.screenRecording,
                        ),
                ),
                const SizedBox(height: 18),
                AppButton(
                  text: AppStrings.done,
                  onPressed: isOpeningChildSheet
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openChildSheet(
    DescriptionMediaCommentContentType selectedType,
  ) async {
    if (_isOpeningChildSheetNotifier.value) {
      return;
    }

    _isOpeningChildSheetNotifier.value = true;
    try {
      final didSave = await widget.onTypeSelected(selectedType);
      if (didSave && mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      _isOpeningChildSheetNotifier.value = false;
    }
  }
}

class _MediaTypeOption extends StatelessWidget {
  const _MediaTypeOption({required this.title, required this.onTap});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark3,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grey2.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Expanded(
                child: AppTextView.body2(
                  title,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.size, this.imageUrl});

  final double size;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final resolvedImageUrl = CustomFunctions.resolveImageUrl(imageUrl);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: resolvedImageUrl == null
              ? const AssetImage('lib/assets/images/dumy_pic.png')
              : NetworkImage(resolvedImageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
