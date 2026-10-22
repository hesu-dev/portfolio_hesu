import 'package:flutter/material.dart';

import '../theme/apple_theme.dart';

class ResumeBullet extends StatelessWidget {
  const ResumeBullet({required this.text, required this.accent, super.key});

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.textScalerOf(context).scale(10),
            right: 10,
          ),
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: AppleTheme.body(
              context,
            ).copyWith(color: AppleTheme.primaryLabel(context), height: 1.65),
          ),
        ),
      ],
    );
  }
}
