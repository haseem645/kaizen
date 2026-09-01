import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../routes/app_router.dart';
import '../questions_feedback_overlay_visibility.dart';

class QuestionsFeedbackShortcutButton extends StatefulWidget {
  const QuestionsFeedbackShortcutButton({
    super.key,
    required this.currentRouteName,
  });

  final String? currentRouteName;

  @override
  State<QuestionsFeedbackShortcutButton> createState() =>
      _QuestionsFeedbackShortcutButtonState();
}

class _QuestionsFeedbackShortcutButtonState
    extends State<QuestionsFeedbackShortcutButton> {
  static const double _buttonSize = 60;
  static const double _screenMargin = 16;

  final ValueNotifier<Offset?> _position = ValueNotifier<Offset?>(null);

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_shouldHideShortcut) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: QuestionsFeedbackOverlayVisibility.isCreateSheetOpen,
      builder: (context, isCreateSheetOpen, _) {
        if (isCreateSheetOpen) {
          return const SizedBox.shrink();
        }

        final screenSize = MediaQuery.sizeOf(context);
        final mediaPadding = MediaQuery.paddingOf(context);
        final viewInsets = MediaQuery.viewInsetsOf(context);
        final initialPosition = Offset(
          _screenMargin,
          screenSize.height -
              mediaPadding.bottom -
              viewInsets.bottom -
              _buttonSize -
              _screenMargin,
        );

        return ValueListenableBuilder<Offset?>(
          valueListenable: _position,
          builder: (context, position, _) {
            final resolvedPosition = _clampPosition(
              position ?? initialPosition,
              screenSize: screenSize,
              mediaPadding: mediaPadding,
              viewInsets: viewInsets,
            );

            return Positioned(
              left: resolvedPosition.dx,
              top: resolvedPosition.dy,
              child: Semantics(
                button: true,
                label: AppStrings.questionsFeedbackTriggerTooltip,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    _position.value = _clampPosition(
                      resolvedPosition + details.delta,
                      screenSize: screenSize,
                      mediaPadding: mediaPadding,
                      viewInsets: viewInsets,
                    );
                  },
                  child: Material(
                    type: MaterialType.transparency,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _openQuestionsFeedbackScreen,
                      child: Ink(
                        width: _buttonSize,
                        height: _buttonSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              AppColors.secondaryColor,
                              AppColors.hex7756da,
                            ],
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppColors.secondaryColor.withValues(
                                alpha: 0.28,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.help_outline_rounded,
                          color: AppColors.textPrimary,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Offset _clampPosition(
    Offset position, {
    required Size screenSize,
    required EdgeInsets mediaPadding,
    required EdgeInsets viewInsets,
  }) {
    final minimumX = mediaPadding.left + _screenMargin;
    final maximumX =
        screenSize.width - mediaPadding.right - _buttonSize - _screenMargin;
    final minimumY = mediaPadding.top + _screenMargin;
    final maximumY =
        screenSize.height -
        mediaPadding.bottom -
        viewInsets.bottom -
        _buttonSize -
        _screenMargin;

    return Offset(
      position.dx.clamp(minimumX, maximumX).toDouble(),
      position.dy.clamp(minimumY, maximumY).toDouble(),
    );
  }

  void _openQuestionsFeedbackScreen() {
    if (_isQuestionsFeedbackRoute) {
      return;
    }

    AppRouter.navigatorKey.currentState?.pushNamed(AppRouter.questionsFeedback);
  }

  bool get _isQuestionsFeedbackRoute {
    return widget.currentRouteName == AppRouter.questionsFeedback ||
        widget.currentRouteName == AppRouter.questionsFeedbackDetail;
  }

  bool get _shouldHideShortcut {
    return widget.currentRouteName == null ||
        _isQuestionsFeedbackRoute ||
        AppRouter.isPublicRoute(widget.currentRouteName);
  }
}
