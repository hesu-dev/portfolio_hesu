import 'package:flutter/material.dart';

import '../theme/apple_theme.dart';

/// Shared launcher caption, independent of surrounding button typography.
class AppleAppLabel extends StatelessWidget {
  const AppleAppLabel({
    required this.label,
    this.compact = false,
    this.selected = false,
    this.color,
    super.key,
  });

  final String label;
  final bool compact;
  final bool selected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 70 : 84),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
          inherit: false,
          color: color ?? AppleTheme.primaryLabel(context),
          fontSize: compact ? 10.5 : 11.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          shadows: <Shadow>[
            Shadow(
              color: AppleTheme.canvas(context).withValues(alpha: 0.5),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
