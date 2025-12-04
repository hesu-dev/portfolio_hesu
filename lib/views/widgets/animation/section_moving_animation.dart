import 'package:flutter/material.dart';

enum MovingFadeInDirection {
  leftToRight,
  rightToLeft,
  bottomToTop,
  topTobottom,
}

class SectionAnimation extends StatefulWidget {
  final Widget child;
  final MovingFadeInDirection direction;
  final Duration duration;
  final Curve curve;

  const SectionAnimation({
    super.key,
    required this.child,
    required this.direction,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOut,
  });

  @override
  State<SectionAnimation> createState() => _SectionAnimationState();
}

class _SectionAnimationState extends State<SectionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration);

    Offset beginOffset;

    switch (widget.direction) {
      case MovingFadeInDirection.leftToRight:
        beginOffset = const Offset(-0.3, 0);
        break;
      case MovingFadeInDirection.rightToLeft:
        beginOffset = const Offset(0.3, 0);
        break;
      case MovingFadeInDirection.bottomToTop:
        beginOffset = const Offset(0, 0.5);
        break;
      case MovingFadeInDirection.topTobottom:
        beginOffset = const Offset(0, -0.3);
        break;
    }

    _offsetAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    // 페이지 빌드 직후 자동 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _offsetAnimation, child: widget.child),
    );
  }
}
