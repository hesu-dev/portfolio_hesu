import 'package:flutter/material.dart';
import 'package:portfolio_hesu/views/widgets/animation/bounce_arrow_btn.dart';

class Section extends StatelessWidget {
  final Widget child;
  final VoidCallback? callback;
  final bool up;
  final bool printMode;

  const Section({
    super.key,
    required this.child,
    this.callback,
    this.up = false,
    this.printMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final content = Container(
      constraints: printMode ? null : BoxConstraints(minHeight: screenHeight),
      alignment: Alignment.topCenter,
      padding: EdgeInsets.symmetric(
        horizontal: 15,
        vertical: printMode ? 24 : 40,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: child,
      ),
    );

    if (printMode) {
      return content;
    }

    return Stack(
      children: [
        Positioned.fill(child: SingleChildScrollView(child: content)),
        if (callback != null)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: BounceArrowButton(onTap: callback!, up: up),
          ),
      ],
    );
  }
}
