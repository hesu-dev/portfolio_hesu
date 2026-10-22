import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../models/portfolio_app_id.dart';
import '../theme/apple_theme.dart';
import '../widgets/apple_app_artwork.dart';
import '../widgets/apple_app_icon.dart';
import 'apple_mobile_dock_geometry.dart';

class AppleMobileDock extends StatelessWidget {
  const AppleMobileDock({
    required this.data,
    required this.tablet,
    required this.onOpen,
    this.activeApp,
    super.key,
  });

  static const List<PortfolioAppId> apps = <PortfolioAppId>[
    PortfolioAppId.profile,
    PortfolioAppId.projects,
    PortfolioAppId.settings,
  ];

  final PortfolioData data;
  final bool tablet;
  final PortfolioAppId? activeApp;
  final ValueChanged<PortfolioAppId> onOpen;

  @override
  Widget build(BuildContext context) {
    final radius = tablet ? 26.0 : 23.0;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
          child: Container(
            key: const Key('mobile-dock'),
            constraints: BoxConstraints(
              maxWidth: tablet ? 540 : 318,
              minHeight: AppleMobileDockGeometry.height(tablet: tablet),
            ),
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
                for (final appId in apps) ...[
                  if (appId == PortfolioAppId.settings)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Container(
                        key: const Key('mobile-dock-separator'),
                        width: 1,
                        height: tablet ? 38 : 34,
                        color: AppleTheme.secondaryLabel(
                          context,
                        ).withValues(alpha: 0.24),
                      ),
                    ),
                  AppleAppIcon(
                    key: Key('mobile-dock-${appId.name}'),
                    appId: appId,
                    label: appId == PortfolioAppId.projects ? '내파일' : null,
                    compact: true,
                    showLabel: false,
                    size: tablet ? 54 : 49,
                    selected: activeApp == appId,
                    artworkSurface: AppleAppArtworkSurface.mobile,
                    onTap: () => onOpen(appId),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
