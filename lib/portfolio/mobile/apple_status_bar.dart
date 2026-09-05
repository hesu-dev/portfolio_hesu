import 'package:flutter/material.dart';

import '../theme/apple_theme.dart';
import '../widgets/apple_clock_format.dart';

/// Compact, platform-neutral rendering of the familiar iOS/iPadOS status area.
class AppleStatusBar extends StatelessWidget {
  const AppleStatusBar({required this.tablet, required this.now, super.key});

  final bool tablet;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final labelColor = AppleTheme.primaryLabel(context);

    return Semantics(
      key: const Key('apple-status-bar'),
      container: true,
      label: 'Status bar',
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tablet ? 24 : 18,
          tablet ? 7 : 5,
          tablet ? 24 : 18,
          5,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: tablet ? 24 : 22),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  formatApple12HourTime(now),
                  key: const Key('apple-status-time'),
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Icon(
                Icons.signal_cellular_alt_rounded,
                size: tablet ? 18 : 16,
                color: labelColor,
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.wifi_rounded,
                size: tablet ? 19 : 17,
                color: labelColor,
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.battery_full_rounded,
                size: tablet ? 21 : 19,
                color: labelColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
