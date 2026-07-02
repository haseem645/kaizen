import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class FastCircularProgressIndicator extends StatefulWidget {
  FastCircularProgressIndicator({this.width, this.height});
  double? width = 15;
  double? height = 15;
  @override
  _FastCircularProgressIndicatorState createState() => _FastCircularProgressIndicatorState();
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
        child: Container(
          width: widget.width ?? 20,
          height: widget.height ?? 20,
          child: const CircularProgressIndicator(
            strokeWidth: 4.0,
            valueColor: AlwaysStoppedAnimation(AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}
