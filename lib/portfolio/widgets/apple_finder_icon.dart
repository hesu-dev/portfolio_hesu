import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/apple_theme.dart';

/// Shared alignment, with a themed tile only for artwork without a background.
class AppleFinderIcon extends StatelessWidget {
  const AppleFinderIcon({
    required this.size,
    required this.child,
    this.selected = false,
    this.hasOwnBackground = false,
    super.key,
  });

  final double size;
  final Widget child;
  final bool selected;
  final bool hasOwnBackground;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    key: const Key('apple-finder-icon-background'),
    duration: const Duration(milliseconds: 160),
    width: size,
    height: size,
    padding: hasOwnBackground ? EdgeInsets.zero : EdgeInsets.all(size * 0.1),
    clipBehavior: hasOwnBackground ? Clip.none : Clip.antiAlias,
    decoration: BoxDecoration(
      color: hasOwnBackground
          ? null
          : selected
          ? AppleTheme.finderSelectionBackground(context)
          : AppleTheme.surface(context),
      borderRadius: hasOwnBackground
          ? null
          : BorderRadius.circular(size * 0.24),
    ),
    foregroundDecoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * 0.24),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.44),
        width: math.max(0.5, size * 0.014),
      ),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x38FFFFFF), Color(0x00FFFFFF)],
        stops: [0, 0.62],
      ),
    ),
    child: hasOwnBackground
        ? FittedBox(fit: BoxFit.contain, child: child)
        : ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.16),
            child: FittedBox(fit: BoxFit.contain, child: child),
          ),
  );
}
