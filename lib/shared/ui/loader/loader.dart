import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:flutter/material.dart';

class mypsyLoader extends StatefulWidget {
  final Color? backgroundColor;

  final Duration? animationDuration;
  final bool? reverseAnimation;
  final BoxShape? containerShape;
  const mypsyLoader({
    super.key,
    this.backgroundColor,
    this.animationDuration,
    this.reverseAnimation,
    this.containerShape,
  });

  @override
  State<mypsyLoader> createState() => _mypsyLoaderState();
}

class _mypsyLoaderState extends State<mypsyLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration ?? const Duration(seconds: 1),
    );
    _animationController.repeat(reverse: widget.reverseAnimation ?? true);

    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
        child: FadeTransition(
          opacity: _animationController,
          child: Container(
            alignment: Alignment.center,
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              shape: widget.containerShape ?? BoxShape.circle,
              color: widget.backgroundColor ?? AppColors.mypsyPrimary,
            ),
            child: Image.asset(
              'assets/logo.png',
              height: 35,
              width: 35,
            ),
          ),
        ),
      );
}
