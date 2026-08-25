import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/managers/app_manager.dart';
import '../../../../core/utils/custom_functions.dart';
import '../../../../core/widgets/app_dot_divider.dart';
import '../../../../core/widgets/app_overlay_close_button.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/fast_circular_progress.dart';
import '../../../check_in/data/datasources/audit_remote_data_source.dart';
import '../../../check_in/data/repositories/audit_repository_impl.dart';
import '../../data/datasources/training_library_remote_data_source.dart';
import '../../data/repositories/training_library_repository_impl.dart';
import '../../domain/entities/seat_description_training_route.dart';
import '../../domain/entities/training_library_module.dart';
import '../../domain/usecases/get_training_library_modules_usecase.dart';
import '../controllers/training_library_detail_controller.dart';
import 'edit_training_screen.dart';
import 'view_training_screen.dart';

const List<_TrainingLibraryVisibilityOptionData>
_trainingLibraryVisibilityOptions = <_TrainingLibraryVisibilityOptionData>[
  _TrainingLibraryVisibilityOptionData(
    value: true,
    icon: Icons.public_rounded,
    label: AppStrings.trainingLibraryAllVisibility,
    description: AppStrings.trainingVisibilityAllDescription,
  ),
  _TrainingLibraryVisibilityOptionData(
    value: false,
    icon: Icons.lock_outline_rounded,
    label: AppStrings.trainingLibraryRestrictedVisibility,
    description: AppStrings.trainingVisibilityUplineDescription,
  ),
];

class TrainingLibraryDetailScreen extends StatefulWidget {
  const TrainingLibraryDetailScreen({
    super.key,
    required this.module,
    required this.view,
  });

  final TrainingLibraryModule module;
  final String view;

  @override
  State<TrainingLibraryDetailScreen> createState() =>
      _TrainingLibraryDetailScreenState();
}

class _TrainingLibraryDetailScreenState
    extends State<TrainingLibraryDetailScreen> {
  var _shouldRefreshOnExit = false;
  late final TrainingLibraryDetailController _detailController;
  late final _TrainingLibraryLessonVisibilityController _visibilityController;

  @override
  void initState() {
    super.initState();
    _detailController = TrainingLibraryDetailController(
      initialModule: widget.module,
      getTrainingLibraryModules: GetTrainingLibraryModulesUseCase(
        createTrainingLibraryRepository(
          createTrainingLibraryRemoteDataSource(),
        ),
      ),
      view: widget.view,
    );
    _visibilityController = _TrainingLibraryLessonVisibilityController(
      AuditRepositoryImpl(AuditRemoteDataSource()),
    );
  }

  @override
  void dispose() {
    _detailController.dispose();
    _visibilityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }

        _handleBack();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_detailController, _visibilityController]),
        builder: (context, _) {
          final module = _detailController.module;
          final hasOwnerOverrideAccess =
              AppManager.instance.currentUserHasOwnerOverrideAccess;
          final canEditModules =
              module.id.trim().isNotEmpty &&
              (hasOwnerOverrideAccess ||
                  (module.seat.id.trim().isNotEmpty &&
                      AppManager.instance
                          .canCurrentUserManageTrainingForSeatProfile(
                            seatProfileId: module.seat.id,
                          )));
          final isBusy =
              _visibilityController.isUpdatingAnyLesson ||
              _detailController.isRefreshing;

          return Scaffold(
            backgroundColor: AppColors.mainBg,
            appBar: AppBar(
              backgroundColor: AppColors.mainBg,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: isBusy
                  ? null
                  : IconButton(
                      onPressed: _handleBack,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
              title: const AppTextView.title1(
                AppStrings.trainingLibraryTitle,
                color: AppColors.secondaryColor,
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),
            body: SafeArea(
              top: false,
              bottom: false,
              child: isBusy
                  ? Center(
                      child: FastCircularProgressIndicator(
                        width: 24,
                        height: 24,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                      children: [
                        _LibrarySummaryCard(module: module),
                        const SizedBox(height: 20),
                        if (module.lessons.isEmpty)
                          const _MessageCard(
                            message: AppStrings.trainingLibraryNoLessonsFound,
                          )
                        else
                          for (
                            var index = 0;
                            index < module.lessons.length;
                            index++
                          ) ...[
                            _TrainingLessonCard(
                              lesson: module.lessons[index],
                              isPubliclyAvailable: _visibilityController
                                  .isLessonPubliclyAvailable(
                                    module.lessons[index],
                                  ),
                              isUpdatingVisibility: _visibilityController
                                  .isUpdatingLesson(module.lessons[index].id),
                              onTap: () => _openLessonViewer(
                                context,
                                module,
                                module.lessons[index],
                              ),
                              canEdit: canEditModules,
                              onEditTap: canEditModules
                                  ? () => _openLessonEditor(
                                      context,
                                      module,
                                      module.lessons[index],
                                    )
                                  : null,
                              onVisibilityChanged: canEditModules
                                  ? (value) => _updateLessonVisibility(
                                      lesson: module.lessons[index],
                                      isPubliclyAvailable: value,
                                    )
                                  : null,
                            ),
                            if (index != module.lessons.length - 1)
                              const SizedBox(height: 12),
                          ],
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  void _handleBack() {
    Navigator.of(context).pop(_shouldRefreshOnExit ? true : null);
  }

  Future<void> _openLessonViewer(
    BuildContext context,
    TrainingLibraryModule module,
    TrainingLibraryLesson lesson,
  ) async {
    final lessonId = lesson.id.trim();
    if (lessonId.isEmpty) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ViewTrainingScreen(
          trainingRoute: SeatDescriptionTrainingRoute(
            job: module.seat.id,
            category: module.category.id,
            description: module.id,
            initialModuleId: lessonId,
          ),
        ),
      ),
    );
  }

  Future<void> _openLessonEditor(
    BuildContext context,
    TrainingLibraryModule module,
    TrainingLibraryLesson lesson,
  ) async {
    final lessonId = lesson.id.trim();
    if (lessonId.isEmpty) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => EditTrainingScreen(
          trainingRoute: SeatDescriptionTrainingRoute(
            job: module.seat.id,
            category: module.category.id,
            description: module.id,
          ),
          initialModuleId: lessonId,
          canManageTraining:
              AppManager.instance.currentUserHasOwnerOverrideAccess ||
              AppManager.instance.canCurrentUserManageTrainingForSeatProfile(
                seatProfileId: module.seat.id,
              ),
          useNonBlockingVideoUpload: true,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    _shouldRefreshOnExit = true;
    final didRefresh = await _detailController.refreshModule();
    if (!mounted || didRefresh) {
      if (didRefresh) {
        _visibilityController.syncWithLessons(_detailController.module.lessons);
      }
      return;
    }

    ScaffoldMessenger.of(this.context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _detailController.errorMessage ??
                AppStrings.loginSomethingWentWrong,
          ),
        ),
      );
  }

  Future<void> _updateLessonVisibility({
    required TrainingLibraryLesson lesson,
    required bool isPubliclyAvailable,
  }) async {
    try {
      final didUpdate = await _visibilityController.updateLessonVisibility(
        lesson: lesson,
        isPubliclyAvailable: isPubliclyAvailable,
      );
      if (didUpdate) {
        _shouldRefreshOnExit = true;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(_resolveVisibilityErrorMessage(error))),
        );
    }
  }

  String _resolveVisibilityErrorMessage(Object error) {
    final resolvedMessage = error.toString().trim();
    if (resolvedMessage.isEmpty) {
      return AppStrings.loginSomethingWentWrong;
    }

    return resolvedMessage;
  }
}

class _LibrarySummaryCard extends StatelessWidget {
  const _LibrarySummaryCard({required this.module});

  final TrainingLibraryModule module;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: AppColors.fieldBorder.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 18, 8, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextView.body(
              _displayValue(
                module.title,
                fallback: AppStrings.trainingLibraryUntitledModule,
              ),
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            _LibraryMetaRow(
              lessonsCount: module.lessonsCount,
              totalDuration: module.totalDuration,
            ),
            const SizedBox(height: 16),
            const AppDotDivider(
              color: AppColors.fieldBorder,
              lineHeight: 1.2,
              dotSize: 8,
              opacity: 0.35,
            ),
            const SizedBox(height: 16),
            _SummaryValueRow(
              label: AppStrings.trainingLibrarySeat,
              value: _displayValue(
                module.seat.title,
                fallback: AppStrings.trainingLibraryNotAvailable,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryValueRow extends StatelessWidget {
  const _SummaryValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextView.body2(
          "$label:",
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AppTextView.body2(
            value,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TrainingLessonCard extends StatefulWidget {
  const _TrainingLessonCard({
    required this.lesson,
    required this.isPubliclyAvailable,
    required this.isUpdatingVisibility,
    required this.onTap,
    required this.canEdit,
    this.onEditTap,
    this.onVisibilityChanged,
  });

  final TrainingLibraryLesson lesson;
  final bool isPubliclyAvailable;
  final bool isUpdatingVisibility;
  final VoidCallback onTap;
  final bool canEdit;
  final VoidCallback? onEditTap;
  final ValueChanged<bool>? onVisibilityChanged;

  @override
  State<_TrainingLessonCard> createState() => _TrainingLessonCardState();
}

class _TrainingLessonCardState extends State<_TrainingLessonCard> {
  final ValueNotifier<bool> _isExpandedNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _isExpandedNotifier.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    _isExpandedNotifier.value = !_isExpandedNotifier.value;
  }

  Future<void> _showSummaryDialog() async {
    final summary = widget.lesson.description.trim();
    if (summary.isEmpty) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.56),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (_) => _LessonSummarySheet(
        lessonTitle: _displayValue(
          widget.lesson.title,
          fallback: AppStrings.trainingLibraryUntitledModule,
        ),
        summary: summary,
      ),
    );
  }

  Future<void> _showVisibilitySheet() async {
    if (widget.onVisibilityChanged == null || widget.isUpdatingVisibility) {
      return;
    }

    final selectedValue = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.56),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (_) =>
          _LessonVisibilitySheet(selectedValue: widget.isPubliclyAvailable),
    );

    if (!mounted ||
        selectedValue == null ||
        selectedValue == widget.isPubliclyAvailable) {
      return;
    }

    widget.onVisibilityChanged?.call(selectedValue);
  }

  @override
  Widget build(BuildContext context) {
    final visibilityLabel = widget.isPubliclyAvailable
        ? AppStrings.trainingLibraryAllVisibility
        : AppStrings.trainingLibraryRestrictedVisibility;
    final visibilityIcon = widget.isPubliclyAvailable
        ? Icons.public_rounded
        : Icons.lock_outline_rounded;

    return ValueListenableBuilder<bool>(
      valueListenable: _isExpandedNotifier,
      builder: (context, isExpanded, _) => Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.fieldBorder.withValues(alpha: 0.45),
            ),
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: widget.onTap,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: _LessonHeroThumbnail(
                    thumbnailLink: widget.lesson.thumbnailLink,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: widget.onTap,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: AppTextView.body(
                                  _displayValue(
                                    widget.lesson.title,
                                    fallback: AppStrings
                                        .trainingLibraryUntitledModule,
                                  ),
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          if (widget.canEdit && widget.onEditTap != null) ...[
                            const SizedBox(width: 10),
                            _LessonEditIconButton(onTap: widget.onEditTap!),
                          ],
                          const SizedBox(width: 10),
                          _LessonExpandButton(
                            isExpanded: isExpanded,
                            onTap: _toggleExpanded,
                          ),
                        ],
                      ),
                      if (widget.lesson.hasDescription) ...[
                        const SizedBox(height: 8),
                        _LessonSummaryText(
                          text: widget.lesson.description,
                          onShowTap: _showSummaryDialog,
                        ),
                      ],
                      if (isExpanded) ...[
                        const SizedBox(height: 16),
                        const AppDotDivider(
                          color: AppColors.fieldBorder,
                          lineHeight: 1.2,
                          dotSize: 8,
                          opacity: 0.3,
                        ),
                        const SizedBox(height: 16),
                        _LessonVisibilityField(
                          label: AppStrings.trainingVisibilityLabel,
                          value: visibilityLabel,
                          icon: visibilityIcon,
                          isLoading: widget.isUpdatingVisibility,
                          onTap:
                              widget.canEdit &&
                                  widget.onVisibilityChanged != null
                              ? _showVisibilitySheet
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonHeroThumbnail extends StatelessWidget {
  const _LessonHeroThumbnail({required this.thumbnailLink});

  final String? thumbnailLink;

  @override
  Widget build(BuildContext context) {
    final imageUrl = CustomFunctions.resolveImageUrl(thumbnailLink);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: AspectRatio(
        aspectRatio: 16 / 8.6,
        child: imageUrl == null
            ? const _LibraryPlaceholder(icon: Icons.play_circle_outline_rounded)
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => const _LibraryPlaceholder(
                  icon: Icons.play_circle_outline_rounded,
                ),
                errorWidget: (_, __, ___) => const _LibraryPlaceholder(
                  icon: Icons.play_circle_outline_rounded,
                ),
              ),
      ),
    );
  }
}

class _LibraryPlaceholder extends StatelessWidget {
  const _LibraryPlaceholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      '${AppStrings.imagePath}fallback.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Center(
          child: Icon(icon, color: AppColors.textSecondary, size: 28),
        );
      },
    );
  }
}

class _LibraryMetaRow extends StatelessWidget {
  const _LibraryMetaRow({
    required this.lessonsCount,
    required this.totalDuration,
  });

  final int lessonsCount;
  final int totalDuration;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        AppTextView.body3(
          AppStrings.trainingLibraryLessonsCount(lessonsCount),
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        const _MetaDot(),
        AppTextView.body3(
          CustomFunctions.formatDuration(totalDuration),
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ],
    );
  }
}

class _LessonExpandButton extends StatelessWidget {
  const _LessonExpandButton({required this.isExpanded, required this.onTap});

  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedRotation(
        turns: isExpanded ? 0.25 : 0,
        duration: const Duration(milliseconds: 220),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.mainBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.fieldBorder.withValues(alpha: 0.28),
            ),
          ),
          child: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _LessonEditIconButton extends StatelessWidget {
  const _LessonEditIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.mainBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.fieldBorder.withValues(alpha: 0.28),
          ),
        ),
        child: const Icon(
          Icons.edit_outlined,
          color: AppColors.secondaryColor,
          size: 18,
        ),
      ),
    );
  }
}

class _LessonSummaryText extends StatefulWidget {
  const _LessonSummaryText({required this.text, required this.onShowTap});

  final String text;
  final VoidCallback onShowTap;

  @override
  State<_LessonSummaryText> createState() => _LessonSummaryTextState();
}

class _LessonSummaryTextState extends State<_LessonSummaryText> {
  late final TapGestureRecognizer _showTapRecognizer;

  @override
  void initState() {
    super.initState();
    _showTapRecognizer = TapGestureRecognizer()..onTap = widget.onShowTap;
  }

  @override
  void didUpdateWidget(covariant _LessonSummaryText oldWidget) {
    super.didUpdateWidget(oldWidget);
    _showTapRecognizer.onTap = widget.onShowTap;
  }

  @override
  void dispose() {
    _showTapRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedText = widget.text.trim();
    const bodyStyle = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1.5,
    );
    const showStyle = TextStyle(
      color: AppColors.secondaryColor,
      fontSize: 13,
      fontWeight: FontWeight.w700,
      height: 1.5,
    );

    if (resolvedText.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.maxWidth.isFinite) {
          return Text(
            resolvedText,
            style: bodyStyle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          );
        }

        final textDirection = Directionality.of(context);
        final fullTextPainter = TextPainter(
          text: TextSpan(text: resolvedText, style: bodyStyle),
          textDirection: textDirection,
          maxLines: 3,
        )..layout(maxWidth: constraints.maxWidth);

        if (!fullTextPainter.didExceedMaxLines) {
          return Text(resolvedText, style: bodyStyle, maxLines: 3);
        }

        final collapsedText = _resolveCollapsedLessonSummaryText(
          text: resolvedText,
          bodyStyle: bodyStyle,
          showStyle: showStyle,
          maxWidth: constraints.maxWidth,
          textDirection: textDirection,
        );

        return RichText(
          maxLines: 3,
          overflow: TextOverflow.clip,
          text: TextSpan(
            children: [
              TextSpan(text: '$collapsedText... ', style: bodyStyle),
              TextSpan(
                text: AppStrings.trainingLibraryShowAction,
                style: showStyle,
                recognizer: _showTapRecognizer,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LessonVisibilityField extends StatelessWidget {
  const _LessonVisibilityField({
    required this.label,
    required this.value,
    required this.icon,
    required this.isLoading,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark3,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.fieldBorder.withValues(alpha: 0.26),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.secondaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextView.body4(
                        label,
                        color: AppColors.purple1,
                        fontWeight: FontWeight.w700,
                      ),
                      const SizedBox(height: 4),
                      AppTextView.body2(
                        value,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (isLoading)
                  FastCircularProgressIndicator(width: 16, height: 16)
                else if (onTap != null)
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonSummarySheet extends StatelessWidget {
  const _LessonSummarySheet({required this.lessonTitle, required this.summary});

  final String lessonTitle;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 620),
          decoration: const BoxDecoration(
            color: AppColors.mainBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTextView.body4(
                              AppStrings.trainingSummaryLabel,
                              color: AppColors.purple1,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _SheetCloseButton(
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                    ),
                    child: SingleChildScrollView(
                      child: AppTextView.body2(
                        summary,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonVisibilitySheet extends StatelessWidget {
  const _LessonVisibilitySheet({required this.selectedValue});

  final bool selectedValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 620),
          decoration: const BoxDecoration(
            color: AppColors.mainBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextView.body1(
                          AppStrings.trainingEditFieldTitle(
                            AppStrings.trainingVisibilityLabel,
                          ),
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _SheetCloseButton(
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AppTextView.body3(
                    AppStrings.trainingLibraryVisibilitySheetDescription,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                  const SizedBox(height: 18),
                  for (
                    var index = 0;
                    index < _trainingLibraryVisibilityOptions.length;
                    index++
                  ) ...[
                    _LessonVisibilitySheetOptionCard(
                      option: _trainingLibraryVisibilityOptions[index],
                      isSelected:
                          _trainingLibraryVisibilityOptions[index].value ==
                          selectedValue,
                      onTap: () => Navigator.of(
                        context,
                      ).pop(_trainingLibraryVisibilityOptions[index].value),
                    ),
                    if (index != _trainingLibraryVisibilityOptions.length - 1)
                      const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonVisibilitySheetOptionCard extends StatelessWidget {
  const _LessonVisibilitySheetOptionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _TrainingLibraryVisibilityOptionData option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.secondaryColor.withValues(alpha: 0.12)
                : AppColors.surfaceDark3,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.secondaryColor.withValues(alpha: 0.42)
                  : AppColors.fieldBorder.withValues(alpha: 0.26),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.secondaryColor.withValues(alpha: 0.16)
                            : AppColors.mainBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        option.icon,
                        color: AppColors.secondaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextView.body1(
                        option.label,
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: isSelected
                          ? AppColors.secondaryColor
                          : AppColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppTextView.body3(
                  option.description,
                  color: isSelected
                      ? AppColors.hexd9deff
                      : AppColors.textSecondary,
                  height: 1.45,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetCloseButton extends StatelessWidget {
  const _SheetCloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppOverlayCloseButton(onTap: onTap);
  }
}

class _TrainingLibraryVisibilityOptionData {
  const _TrainingLibraryVisibilityOptionData({
    required this.value,
    required this.icon,
    required this.label,
    required this.description,
  });

  final bool value;
  final IconData icon;
  final String label;
  final String description;
}

String _resolveCollapsedLessonSummaryText({
  required String text,
  required TextStyle bodyStyle,
  required TextStyle showStyle,
  required double maxWidth,
  required TextDirection textDirection,
}) {
  bool fits(String candidate) {
    final painter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(text: '${candidate.trimRight()}... ', style: bodyStyle),
          TextSpan(
            text: AppStrings.trainingLibraryShowAction,
            style: showStyle,
          ),
        ],
      ),
      textDirection: textDirection,
      maxLines: 3,
    )..layout(maxWidth: maxWidth);

    return !painter.didExceedMaxLines;
  }

  var low = 0;
  var high = text.length;

  while (low < high) {
    final mid = (low + high + 1) ~/ 2;
    if (fits(text.substring(0, mid))) {
      low = mid;
    } else {
      high = mid - 1;
    }
  }

  var resolved = text.substring(0, low).trimRight();
  final lastSpaceIndex = resolved.lastIndexOf(' ');
  if (lastSpaceIndex > 0 && low < text.length) {
    resolved = resolved.substring(0, lastSpaceIndex).trimRight();
  }

  while (resolved.isNotEmpty && !fits(resolved)) {
    final lastWordBreak = resolved.lastIndexOf(' ');
    if (lastWordBreak > 0) {
      resolved = resolved.substring(0, lastWordBreak).trimRight();
    } else {
      resolved = resolved.substring(0, resolved.length - 1).trimRight();
    }
  }

  if (resolved.isEmpty) {
    return text.substring(0, 1);
  }

  return resolved;
}

class _MetaDot extends StatelessWidget {
  const _MetaDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: AppColors.textSecondary,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: AppTextView.body(
        message,
        color: AppColors.textSecondary,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TrainingLibraryLessonVisibilityController extends ChangeNotifier {
  _TrainingLibraryLessonVisibilityController(this._auditRepository);

  final AuditRepositoryImpl _auditRepository;
  final Map<String, bool> _visibilityOverrides = <String, bool>{};
  final Set<String> _updatingLessonIds = <String>{};

  bool get isUpdatingAnyLesson => _updatingLessonIds.isNotEmpty;

  bool isLessonPubliclyAvailable(TrainingLibraryLesson lesson) {
    return _visibilityOverrides[lesson.id.trim()] ?? lesson.isPubliclyAvailable;
  }

  bool isUpdatingLesson(String lessonId) {
    return _updatingLessonIds.contains(lessonId.trim());
  }

  void syncWithLessons(List<TrainingLibraryLesson> lessons) {
    final resolvedVisibilityByLessonId = <String, bool>{
      for (final lesson in lessons)
        lesson.id.trim(): lesson.isPubliclyAvailable,
    };
    var didChange = false;

    _visibilityOverrides.removeWhere((lessonId, visibility) {
      final resolvedVisibility = resolvedVisibilityByLessonId[lessonId];
      final shouldRemove =
          resolvedVisibility == null || resolvedVisibility == visibility;
      if (shouldRemove) {
        didChange = true;
      }
      return shouldRemove;
    });

    if (didChange) {
      notifyListeners();
    }
  }

  Future<bool> updateLessonVisibility({
    required TrainingLibraryLesson lesson,
    required bool isPubliclyAvailable,
  }) async {
    final lessonId = lesson.id.trim();
    if (lessonId.isEmpty ||
        _updatingLessonIds.contains(lessonId) ||
        isLessonPubliclyAvailable(lesson) == isPubliclyAvailable) {
      return false;
    }

    _updatingLessonIds.add(lessonId);
    notifyListeners();

    try {
      await _auditRepository.updateSeatDescriptionTrainingModuleVisibility(
        moduleId: lessonId,
        isPubliclyAvailable: isPubliclyAvailable,
      );

      if (lesson.isPubliclyAvailable == isPubliclyAvailable) {
        _visibilityOverrides.remove(lessonId);
      } else {
        _visibilityOverrides[lessonId] = isPubliclyAvailable;
      }
      return true;
    } finally {
      _updatingLessonIds.remove(lessonId);
      notifyListeners();
    }
  }
}

String _displayValue(String value, {required String fallback}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return fallback;
  }

  return trimmed;
}
