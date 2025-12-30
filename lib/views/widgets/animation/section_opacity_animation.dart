import 'package:flutter/material.dart';

enum OpacityFadeInDirection { fadein, fadeout }

class OpacityFade extends StatefulWidget {
  final Widget child;
  final OpacityFadeInDirection direction;
  final Duration duration;
  final Curve curve;

  const OpacityFade({
    super.key,
    required this.child,
    required this.direction,
    this.duration = const Duration(milliseconds: 2000),
    this.curve = Curves.easeOut,
  });

  @override
  State<OpacityFade> createState() => _OpacityFadeState();
}

class _OpacityFadeState extends State<OpacityFade>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration);

    _opacity = Tween<double>(
      begin: widget.direction == OpacityFadeInDirection.fadein ? 0.0 : 1.0,
      end: widget.direction == OpacityFadeInDirection.fadein ? 1.0 : 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

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
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}
