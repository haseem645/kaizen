import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_text_view.dart';

/// Reveals Delete without removing the row when a swipe completes.
class TrainingSwipeDeleteAction extends StatefulWidget {
  const TrainingSwipeDeleteAction({
    super.key,
    required this.child,
    required this.onDelete,
    this.deleteSemanticLabel = AppStrings.trainingDeleteQuestionAction,
    this.borderRadius = 16,
    this.backgroundColor = AppColors.trainingLessonActionSurface,
  });

  final Widget child;
  final VoidCallback? onDelete;
  final String deleteSemanticLabel;
  final double borderRadius;
  final Color backgroundColor;

  @override
  State<TrainingSwipeDeleteAction> createState() => _TrainingSwipeDeleteActionState();
}

class _TrainingSwipeDeleteActionState extends State<TrainingSwipeDeleteAction>
    with SingleTickerProviderStateMixin {
  static const double _actionWidth = 72;
  late final AnimationController _reveal;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
  }

  @override
  void didUpdateWidget(covariant TrainingSwipeDeleteAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onDelete == null) _reveal.value = 0;
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  void _startDrag(DragStartDetails details) {
    _reveal.stop();
    FocusScope.of(context).unfocus();
  }

  void _updateDrag(DragUpdateDetails details) {
    _reveal.value = (_reveal.value - details.delta.dx / _actionWidth).clamp(0.0, 1.0);
  }

  void _settle({double velocity = 0}) {
    final shouldOpen = velocity < -200 || (velocity <= 200 && _reveal.value >= 0.5);
    _reveal.animateTo(shouldOpen ? 1 : 0, curve: Curves.easeOut);
  }

  void _requestDelete() {
    final onDelete = widget.onDelete;
    if (onDelete == null) return;
    _reveal.reverse();
    onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onDelete != null;
    return Semantics(
      customSemanticsActions: isEnabled
          ? {CustomSemanticsAction(label: widget.deleteSemanticLabel): _requestDelete}
          : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: isEnabled ? _startDrag : null,
        onHorizontalDragUpdate: isEnabled ? _updateDrag : null,
        onHorizontalDragEnd: isEnabled
            ? (details) => _settle(velocity: details.velocity.pixelsPerSecond.dx)
            : null,
        onHorizontalDragCancel: isEnabled ? () => _settle() : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: AnimatedBuilder(
            animation: _reveal,
            child: Material(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: widget.child,
              ),
            ),
            builder: (context, child) => Stack(
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: _actionWidth,
                      height: double.infinity,
                      child: ExcludeSemantics(
                        excluding: !isEnabled || _reveal.value < 0.5,
                        child: IgnorePointer(
                          ignoring: !isEnabled || _reveal.value < 0.5,
                          child: Material(
                            color: AppColors.red,
                            child: InkWell(
                              onTap: _requestDelete,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    size: 20,
                                    color: AppColors.textPrimary,
                                  ),
                                  SizedBox(height: 2),
                                  AppTextView.body3(
                                    AppStrings.trainingDeleteQuestionAction,
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Transform.translate(offset: Offset(-_actionWidth * _reveal.value, 0), child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
