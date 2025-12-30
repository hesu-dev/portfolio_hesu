import 'package:flutter/material.dart';

class BounceArrowButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool up; // true면 위쪽 화살표, false면 아래쪽

  const BounceArrowButton({super.key, required this.onTap, this.up = false});

  @override
  State<BounceArrowButton> createState() => _BounceArrowButtonState();
}

class _BounceArrowButtonState extends State<BounceArrowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _offsetAnim = Tween(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offsetAnim,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, widget.up ? -_offsetAnim.value : _offsetAnim.value),
        child: child,
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Icon(
          widget.up ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          size: 50,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }
}
