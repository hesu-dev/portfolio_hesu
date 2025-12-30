import 'package:flutter/material.dart';
import 'package:portfolio_hesu/views/widgets/animation/bounce_arrow_btn.dart';

class Section extends StatelessWidget {
  final Widget child;
  final VoidCallback callback;
  final bool up;
  const Section({
    super.key,
    required this.child,
    required this.callback,
    required this.up,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(
                minHeight: screenHeight,
                // maxWidth: 1100,
              ),
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: child,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: BounceArrowButton(onTap: callback, up: up),
        ),
      ],
    );
  }
}
