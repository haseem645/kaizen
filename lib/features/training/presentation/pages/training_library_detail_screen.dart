import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/managers/app_manager.dart';
import '../../../../core/utils/custom_functions.dart';
import '../../../../core/widgets/app_dot_divider.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/fast_circular_progress.dart';
import '../../../audit/data/datasources/audit_remote_data_source.dart';
import '../../../audit/data/repositories/audit_repository_impl.dart';
import '../../domain/entities/seat_description_training_route.dart';
import '../../domain/entities/training_library_module.dart';
import 'edit_training_screen.dart';
import 'view_training_screen.dart';

const List<_TrainingLibraryVisibilityOptionData> _trainingLibraryVisibilityOptions =
    <_TrainingLibraryVisibilityOptionData>[
      _TrainingLibraryVisibilityOptionData(
        value: true,
        label: AppStrings.trainingLibraryAllVisibility,
        description: AppStrings.trainingVisibilityAllDescription,
      ),
      _TrainingLibraryVisibilityOptionData(
        value: false,
        label: AppStrings.trainingLibraryRestrictedVisibility,
        description: AppStrings.trainingVisibilityUplineDescription,
      ),
    ];

class TrainingLibraryDetailScreen extends StatefulWidget {
  const TrainingLibraryDetailScreen({super.key, required this.module});

  final TrainingLibraryModule module;

  @override
  State<TrainingLibraryDetailScreen> createState() => _TrainingLibraryDetailScreenState();
}

class _TrainingLibraryDetailScreenState extends State<TrainingLibraryDetailScreen> {
  var _shouldRefreshOnExit = false;
  late final _TrainingLibraryLessonVisibilityController _visibilityController;

  @override
  void initState() {
    super.initState();
    _visibilityController = _TrainingLibraryLessonVisibilityController(
      AuditRepositoryImpl(AuditRemoteDataSource()),
    );
  }

  @override
  void dispose() {
    _visibilityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canEditModules =
        AppManager.instance.canCurrentUserManageTrainingForSeatProfile(
          seatProfileId: widget.module.seat.id,
        ) &&
        widget.module.id.trim().isNotEmpty &&
        widget.module.seat.id.trim().isNotEmpty;

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }

        _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.mainBg,
        appBar: AppBar(
          backgroundColor: AppColors.mainBg,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          leading: IconButton(
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
          child: AnimatedBuilder(
            animation: _visibilityController,
            builder: (context, _) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                const SizedBox(height: 8),
                _LibrarySummaryCard(module: widget.module),
                const SizedBox(height: 20),
                if (widget.module.lessons.isEmpty)
                  const _MessageCard(message: AppStrings.trainingLibraryNoLessonsFound)
                else
                  for (var index = 0; index < widget.module.lessons.length; index++) ...[
                    _TrainingLessonCard(
                      lesson: widget.module.lessons[index],
                      isPubliclyAvailable: _visibilityController.isLessonPubliclyAvailable(
                        widget.module.lessons[index],
                      ),
                      isUpdatingVisibility: _visibilityController.isUpdatingLesson(
                        widget.module.lessons[index].id,
                      ),
                      onTap: () => _openLessonViewer(context, widget.module.lessons[index]),
                      canEdit: canEditModules,
                      onEditTap: canEditModules
                          ? () => _openLessonEditor(context, widget.module.lessons[index])
                          : null,
                      onVisibilityChanged: canEditModules
                          ? (value) => _updateLessonVisibility(
                              lesson: widget.module.lessons[index],
                              isPubliclyAvailable: value,
                            )
                          : null,
                    ),
                    if (index != widget.module.lessons.length - 1) const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleBack() {
    Navigator.of(context).pop(_shouldRefreshOnExit ? true : null);
  }

  Future<void> _openLessonViewer(BuildContext context, TrainingLibraryLesson lesson) async {
    final lessonId = lesson.id.trim();
    if (lessonId.isEmpty) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ViewTrainingScreen(
          trainingRoute: SeatDescriptionTrainingRoute(
            job: widget.module.seat.id,
            category: widget.module.category.id,
            description: widget.module.id,
            initialModuleId: lessonId,
          ),
        ),
      ),
    );
  }

  Future<void> _openLessonEditor(BuildContext context, TrainingLibraryLesson lesson) async {
    final lessonId = lesson.id.trim();
    if (lessonId.isEmpty) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => EditTrainingScreen(
          trainingRoute: SeatDescriptionTrainingRoute(
            job: widget.module.seat.id,
            category: widget.module.category.id,
            description: widget.module.id,
          ),
          initialModuleId: lessonId,
          canManageTraining: AppManager.instance.canCurrentUserManageTrainingForSeatProfile(
            seatProfileId: widget.module.seat.id,
          ),
          useNonBlockingVideoUpload: true,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    _shouldRefreshOnExit = true;
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
        ..showSnackBar(SnackBar(content: Text(_resolveVisibilityErrorMessage(error))));
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

class _TrainingLibraryHero extends StatelessWidget {
  const _TrainingLibraryHero({
    required this.module,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
  });

  final TrainingLibraryModule module;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = CustomFunctions.resolveImageUrl(module.thumbnailLink);

    return ClipRRect(
      borderRadius: borderRadius,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: thumbnailUrl == null
            ? const _LibraryPlaceholder(icon: Icons.video_library_rounded)
            : CachedNetworkImage(
                imageUrl: thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const _LibraryPlaceholder(icon: Icons.video_library_rounded),
                errorWidget: (_, __, ___) =>
                    const _LibraryPlaceholder(icon: Icons.video_library_rounded),
              ),
      ),
    );
  }
}

class _LibrarySummaryCard extends StatelessWidget {
  const _LibrarySummaryCard({required this.module});

  final TrainingLibraryModule module;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.fieldBorder.withValues(alpha: 0.45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TrainingLibraryHero(
              module: module,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextView.body(
                    _displayValue(module.title, fallback: AppStrings.trainingLibraryUntitledModule),
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // if (module.description.trim().isNotEmpty) ...[
                  //   const SizedBox(height: 8),
                  //   AppTextView.body2(
                  //     module.description.trim(),
                  //     color: AppColors.textSecondary,
                  //     fontSize: 14,
                  //     maxLines: 3,
                  //     overflow: TextOverflow.ellipsis,
                  //   ),
                  // ],
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
                    label: AppStrings.trainingLibraryDepartment,
                    value: _displayValue(
                      module.department.name,
                      fallback: AppStrings.trainingLibraryNotAvailable,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SummaryValueRow(
                    label: AppStrings.trainingLibrarySeat,
                    value: _displayValue(
                      module.seat.title,
                      fallback: AppStrings.trainingLibraryNotAvailable,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SummaryValueRow(
                    label: AppStrings.trainingLibraryCategory,
                    value: _displayValue(
                      module.category.title,
                      fallback: AppStrings.trainingLibraryNotAvailable,
                    ),
                  ),
                ],
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
        SizedBox(
          width: 92,
          child: AppTextView.body3(label, color: AppColors.purple1, fontWeight: FontWeight.w700),
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

class _TrainingLessonCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final visibilityLabel = isPubliclyAvailable
        ? AppStrings.trainingLibraryAllVisibility
        : AppStrings.trainingLibraryRestrictedVisibility;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.fieldBorder.withValues(alpha: 0.45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LessonThumbnail(thumbnailLink: lesson.thumbnailLink),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppTextView.body(
                                _displayValue(
                                  lesson.title,
                                  fallback: AppStrings.trainingLibraryUntitledModule,
                                ),
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (lesson.hasDescription) ...[
                                const SizedBox(height: 6),
                                AppTextView.body3(
                                  lesson.description,
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const AppDotDivider(
                      color: AppColors.fieldBorder,
                      lineHeight: 1.2,
                      dotSize: 8,
                      opacity: 0.3,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  canEdit && onVisibilityChanged != null
                      ? IntrinsicWidth(
                          child: _LessonVisibilityDropdown(
                            value: isPubliclyAvailable,
                            isLoading: isUpdatingVisibility,
                            onChanged: onVisibilityChanged!,
                          ),
                        )
                      : _LessonVisibilityChip(label: visibilityLabel),
                  if (canEdit && onEditTap != null) ...[
                    const Spacer(),
                    const SizedBox(width: 12),
                    _LessonEditButton(onTap: onEditTap!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonEditButton extends StatelessWidget {
  const _LessonEditButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit_outlined, size: 18, color: AppColors.secondaryColor),
              const SizedBox(width: 6),
              AppTextView.body1(
                AppStrings.trainingEditAssignment,
                color: AppColors.secondaryColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonThumbnail extends StatelessWidget {
  const _LessonThumbnail({required this.thumbnailLink});

  final String? thumbnailLink;

  @override
  Widget build(BuildContext context) {
    final imageUrl = CustomFunctions.resolveImageUrl(thumbnailLink);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 112,
        height: 78,
        child: imageUrl == null
            ? const _LibraryPlaceholder(icon: Icons.play_circle_outline_rounded)
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const _LibraryPlaceholder(icon: Icons.play_circle_outline_rounded),
                errorWidget: (_, __, ___) =>
                    const _LibraryPlaceholder(icon: Icons.play_circle_outline_rounded),
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
      '${AppStrings.imagePath}fallback_image.png',
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        return Center(child: Icon(icon, color: AppColors.textSecondary, size: 28));
      },
    );
  }
}

class _LibraryMetaRow extends StatelessWidget {
  const _LibraryMetaRow({required this.lessonsCount, required this.totalDuration});

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

class _LessonVisibilityChip extends StatelessWidget {
  const _LessonVisibilityChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.secondaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AppTextView.body2(
        label,
        color: AppColors.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _LessonVisibilityDropdown extends StatelessWidget {
  const _LessonVisibilityDropdown({
    required this.value,
    required this.isLoading,
    required this.onChanged,
  });

  final bool value;
  final bool isLoading;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<bool>(
      key: ValueKey<bool>(value),
      initialValue: value,
      onChanged: isLoading
          ? null
          : (nextValue) {
              if (nextValue != null) {
                onChanged(nextValue);
              }
            },
      isExpanded: false,
      dropdownColor: AppColors.surfaceDark,
      icon: isLoading
          ? Padding(
              padding: const EdgeInsets.only(right: 10),
              child: FastCircularProgressIndicator(width: 14, height: 14),
            )
          : const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.secondaryColor,
            ),
      style: const TextStyle(
        color: AppColors.secondaryColor,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.secondaryColor.withValues(alpha: 0.08),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.secondaryColor.withValues(alpha: 0.28)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.secondaryColor.withValues(alpha: 0.28)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.secondaryColor),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.fieldBorder.withValues(alpha: 0.18)),
        ),
      ),
      selectedItemBuilder: (context) => _trainingLibraryVisibilityOptions
          .map(
            (option) => Align(
              alignment: Alignment.centerLeft,
              child: AppTextView.body2(
                option.label,
                color: AppColors.secondaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(growable: false),
      items: _trainingLibraryVisibilityOptions
          .map(
            (option) => DropdownMenuItem<bool>(
              value: option.value,
              child: _LessonVisibilityDropdownItem(
                option: option,
                isSelected: option.value == value,
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _LessonVisibilityDropdownItem extends StatelessWidget {
  const _LessonVisibilityDropdownItem({required this.option, required this.isSelected});

  final _TrainingLibraryVisibilityOptionData option;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 220),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.secondaryColor.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppColors.secondaryColor.withValues(alpha: 0.26) : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextView.body3(
            option.label,
            color: isSelected ? AppColors.secondaryColor : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 4),
          AppTextView.body4(
            option.description,
            color: isSelected ? AppColors.hexd9deff : AppColors.textSecondary,
            fontSize: 11,
            height: 1.45,
          ),
        ],
      ),
    );
  }
}

class _TrainingLibraryVisibilityOptionData {
  const _TrainingLibraryVisibilityOptionData({
    required this.value,
    required this.label,
    required this.description,
  });

  final bool value;
  final String label;
  final String description;
}

class _MetaDot extends StatelessWidget {
  const _MetaDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(color: AppColors.textSecondary, shape: BoxShape.circle),
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
      child: AppTextView.body(message, color: AppColors.textSecondary, textAlign: TextAlign.center),
    );
  }
}

class _TrainingLibraryLessonVisibilityController extends ChangeNotifier {
  _TrainingLibraryLessonVisibilityController(this._auditRepository);

  final AuditRepositoryImpl _auditRepository;
  final Map<String, bool> _visibilityOverrides = <String, bool>{};
  final Set<String> _updatingLessonIds = <String>{};

  bool isLessonPubliclyAvailable(TrainingLibraryLesson lesson) {
    return _visibilityOverrides[lesson.id.trim()] ?? lesson.isPubliclyAvailable;
  }

  bool isUpdatingLesson(String lessonId) {
    return _updatingLessonIds.contains(lessonId.trim());
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
