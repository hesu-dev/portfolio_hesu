import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/portfolio_app_id.dart';
import '../theme/apple_theme.dart';
import '../widgets/apple_app_icon.dart';

class AppleMobileDock extends StatelessWidget {
  const AppleMobileDock({
    required this.tablet,
    required this.onOpen,
    this.activeApp,
    super.key,
  });

  static const List<PortfolioAppId> phoneApps = <PortfolioAppId>[
    PortfolioAppId.about,
    PortfolioAppId.projects,
    PortfolioAppId.github,
    PortfolioAppId.mail,
  ];

  static const List<PortfolioAppId> tabletApps = <PortfolioAppId>[
    PortfolioAppId.about,
    PortfolioAppId.skills,
    PortfolioAppId.projects,
    PortfolioAppId.terminal,
    PortfolioAppId.github,
    PortfolioAppId.mail,
  ];

  final bool tablet;
  final PortfolioAppId? activeApp;
  final ValueChanged<PortfolioAppId> onOpen;

  @override
  Widget build(BuildContext context) {
    final apps = tablet ? tabletApps : phoneApps;
    final radius = tablet ? 26.0 : 23.0;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
          child: Container(
            key: const Key('mobile-dock'),
            constraints: BoxConstraints(maxWidth: tablet ? 540 : 318),
            padding: EdgeInsets.symmetric(
              horizontal: tablet ? 12 : 9,
              vertical: tablet ? 7 : 6,
            ),
            decoration: BoxDecoration(
              color: AppleTheme.surface(context).withValues(alpha: 0.63),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.64),
                width: 0.8,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (final appId in apps)
                  AppleAppIcon(
                    key: Key('mobile-dock-${appId.name}'),
                    appId: appId,
                    compact: true,
                    showLabel: false,
                    size: tablet ? 54 : 49,
                    selected: activeApp == appId,
                    onTap: () => onOpen(appId),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
