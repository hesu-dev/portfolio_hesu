import 'package:flutter/material.dart';

import '../models/portfolio_app_id.dart';
import '../theme/apple_theme.dart';

class AppleAppIcon extends StatelessWidget {
  const AppleAppIcon({
    required this.appId,
    this.onTap,
    this.compact = false,
    this.selected = false,
    this.running = false,
    this.showLabel = true,
    this.size,
    super.key,
  });

  final PortfolioAppId appId;
  final VoidCallback? onTap;
  final bool compact;
  final bool selected;
  final bool running;
  final bool showLabel;
  final double? size;

  static String labelFor(PortfolioAppId appId) => switch (appId) {
    PortfolioAppId.about => 'About',
    PortfolioAppId.skills => 'Skills',
    PortfolioAppId.projects => 'Projects',
    PortfolioAppId.terminal => 'Terminal',
    PortfolioAppId.thisMac => 'This Mac',
    PortfolioAppId.trash => 'Trash',
    PortfolioAppId.github => 'GitHub',
    PortfolioAppId.mail => 'Mail',
  };

  static IconData iconFor(PortfolioAppId appId) => switch (appId) {
    PortfolioAppId.about => Icons.person_rounded,
    PortfolioAppId.skills => Icons.auto_awesome_rounded,
    PortfolioAppId.projects => Icons.folder_rounded,
    PortfolioAppId.terminal => Icons.terminal_rounded,
    PortfolioAppId.thisMac => Icons.laptop_mac_rounded,
    PortfolioAppId.trash => Icons.delete_rounded,
    PortfolioAppId.github => Icons.code_rounded,
    PortfolioAppId.mail => Icons.mail_rounded,
  };

  static List<Color> colorsFor(PortfolioAppId appId) => switch (appId) {
    PortfolioAppId.about => const <Color>[Color(0xFF6DD5FA), Color(0xFF367CF5)],
    PortfolioAppId.skills => const <Color>[
      Color(0xFFB66DFF),
      Color(0xFF6B4EFF),
    ],
    PortfolioAppId.projects => const <Color>[
      Color(0xFF67D8FF),
      Color(0xFF0A84FF),
    ],
    PortfolioAppId.terminal => const <Color>[
      Color(0xFF4A4B51),
      Color(0xFF17181B),
    ],
    PortfolioAppId.thisMac => const <Color>[
      Color(0xFF8C8C91),
      Color(0xFF3B3C42),
    ],
    PortfolioAppId.trash => const <Color>[Color(0xFFF4F5F7), Color(0xFFA9ADB5)],
    PortfolioAppId.github => const <Color>[
      Color(0xFF42454D),
      Color(0xFF111216),
    ],
    PortfolioAppId.mail => const <Color>[Color(0xFF57C7FF), Color(0xFF126BFF)],
  };

  @override
  Widget build(BuildContext context) {
    final label = labelFor(appId);
    final tileSize = size ?? (compact ? 48.0 : 58.0);
    final cornerRadius = compact ? 13.0 : 16.0;
    final foreground = appId == PortfolioAppId.trash
        ? const Color(0xFF555860)
        : Colors.white;

    return Semantics(
      key: Key('apple-app-icon-${appId.name}'),
      label: 'Open $label',
      button: true,
      enabled: onTap != null,
      selected: selected,
      onTap: onTap,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 5 : 7,
              vertical: compact ? 4 : 6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  key: Key('apple-app-icon-tile-${appId.name}'),
                  width: tileSize,
                  height: tileSize,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Positioned.fill(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: colorsFor(appId),
                            ),
                            borderRadius: BorderRadius.circular(cornerRadius),
                            border: Border.all(
                              color: Colors.white.withValues(
                                alpha: selected ? 0.9 : 0.34,
                              ),
                              width: selected ? 1.8 : 0.7,
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: colorsFor(
                                  appId,
                                ).last.withValues(alpha: 0.24),
                                blurRadius: selected ? 18 : 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            iconFor(appId),
                            color: foreground,
                            size: tileSize * 0.5,
                          ),
                        ),
                      ),
                      if (selected)
                        Positioned.fill(
                          key: Key('apple-app-icon-selection-${appId.name}'),
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  cornerRadius + 2,
                                ),
                                border: Border.all(
                                  color: AppleTheme.blue.withValues(alpha: 0.9),
                                  width: 2.4,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (showLabel) ...<Widget>[
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: compact ? 70 : 84),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppleTheme.primaryLabel(context),
                        fontSize: compact ? 10.5 : 11.5,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        shadows: <Shadow>[
                          Shadow(
                            color: AppleTheme.canvas(
                              context,
                            ).withValues(alpha: 0.5),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                SizedBox(
                  height: 7,
                  child: running
                      ? Container(
                          key: Key('apple-app-icon-running-${appId.name}'),
                          width: 4.5,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: AppleTheme.primaryLabel(context),
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
