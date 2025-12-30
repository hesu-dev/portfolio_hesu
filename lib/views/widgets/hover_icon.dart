import 'package:flutter/material.dart';

class HoverIcon extends StatefulWidget {
  final IconData icon;
  final double size;

  const HoverIcon({super.key, required this.icon, this.size = 22});

  @override
  _HoverIconState createState() => _HoverIconState();
}

class _HoverIconState extends State<HoverIcon> {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black87;

    return MouseRegion(
      onEnter: (_) => setState(() => isHover = true),
      onExit: (_) => setState(() => isHover = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: isHover ? 1.25 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: Icon(widget.icon, size: widget.size, color: iconColor),
      ),
    );
  }
}
