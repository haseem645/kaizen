import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class FastCircularProgressIndicator extends StatefulWidget {
  const FastCircularProgressIndicator({
    super.key,
    this.width,
    this.height,
    this.color = AppColors.textPrimary,
  });

  final double? width;
  final double? height;
  final Color color;

  @override
  State<FastCircularProgressIndicator> createState() => _FastCircularProgressIndicatorState();
}

class _FastCircularProgressIndicatorState extends State<FastCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // Decrease this duration to make it spin faster (default is 2 seconds)
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: Tween(begin: 0.0, end: 1.0).animate(_controller),
      child: Center(
        child: SizedBox(
          width: widget.width ?? 20,
          height: widget.height ?? 20,
          child: CircularProgressIndicator(
            strokeWidth: 4.0,
            valueColor: AlwaysStoppedAnimation(widget.color),
          ),
        ),
      ),
    );
  }
}
