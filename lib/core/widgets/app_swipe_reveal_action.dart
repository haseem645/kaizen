import 'package:flutter/material.dart';

class AppSwipeRevealAction extends StatefulWidget {
  const AppSwipeRevealAction({
    super.key,
    required this.child,
    required this.actionChild,
    this.onActionTap,
    this.isEnabled = true,
    this.borderRadius = 12,
    this.actionWidth = 64,
    this.actionGap = 10,
    this.openVelocityThreshold = -160,
    this.revealThreshold = 0.45,
  });

  final Widget child;
  final Widget actionChild;
  final VoidCallback? onActionTap;
  final bool isEnabled;
  final double borderRadius;
  final double actionWidth;
  final double actionGap;
  final double openVelocityThreshold;
  final double revealThreshold;

  @override
  State<AppSwipeRevealAction> createState() => _AppSwipeRevealActionState();
}

class _AppSwipeRevealActionState extends State<AppSwipeRevealAction> {
  late final ValueNotifier<double> _swipeOffsetNotifier;

  double get _revealWidth => widget.actionWidth + widget.actionGap;

  @override
  void initState() {
    super.initState();
    _swipeOffsetNotifier = ValueNotifier<double>(0);
  }

  @override
  void didUpdateWidget(covariant AppSwipeRevealAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isEnabled && _swipeOffsetNotifier.value != 0) {
      _swipeOffsetNotifier.value = 0;
    }
  }

  @override
  void dispose() {
    _swipeOffsetNotifier.dispose();
    super.dispose();
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (!widget.isEnabled) {
      return;
    }

    final nextOffset = (_swipeOffsetNotifier.value + details.delta.dx).clamp(
      -_revealWidth,
      0.0,
    );
    if (nextOffset == _swipeOffsetNotifier.value) {
      return;
    }

    _swipeOffsetNotifier.value = nextOffset;
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (!widget.isEnabled) {
      return;
    }

    final resolvedVelocity = details.primaryVelocity ?? 0;
    final shouldOpen =
        resolvedVelocity < widget.openVelocityThreshold ||
        _swipeOffsetNotifier.value.abs() >=
            _revealWidth * widget.revealThreshold;
    _swipeOffsetNotifier.value = shouldOpen ? -_revealWidth : 0;
  }

  void _handleActionTap() {
    _swipeOffsetNotifier.value = 0;
    widget.onActionTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _swipeOffsetNotifier,
      builder: (context, swipeOffset, _) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: widget.isEnabled
            ? _handleHorizontalDragUpdate
            : null,
        onHorizontalDragEnd: widget.isEnabled ? _handleHorizontalDragEnd : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Stack(
            children: [
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.isEnabled ? _handleActionTap : null,
                    child: SizedBox(
                      width: widget.actionWidth,
                      child: widget.actionChild,
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(swipeOffset, 0),
                child: widget.child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
