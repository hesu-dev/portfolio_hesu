import 'package:flutter/material.dart';

class HoverUnderlineButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final TextStyle? style;
  final Color underlineColor;

  const HoverUnderlineButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.style,
    this.underlineColor = Colors.blue,
  });

  @override
  State<HoverUnderlineButton> createState() => _HoverUnderlineButtonState();
}

class _HoverUnderlineButtonState extends State<HoverUnderlineButton> {
  bool _hovering = false;
  final GlobalKey _textKey = GlobalKey();
  double _textWidth = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox renderBox =
          _textKey.currentContext!.findRenderObject() as RenderBox;
      setState(() {
        _textWidth = renderBox.size.width;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.text, key: _textKey, style: widget.style),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: _hovering ? _textWidth : 0,
              color: widget.underlineColor,
              alignment: Alignment.centerLeft,
            ),
          ],
        ),
      ),
    );
  }
}
