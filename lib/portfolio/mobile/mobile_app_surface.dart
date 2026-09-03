import 'package:flutter/material.dart';

import '../apps/portfolio_app_content.dart';
import '../data/portfolio_data.dart';
import '../macos/mac_traffic_controls.dart';
import '../models/portfolio_app_id.dart';
import '../services/external_launcher.dart';
import '../theme/apple_theme.dart';
import '../theme/portfolio_theme_controller.dart';
import '../widgets/apple_app_icon.dart';
import '../widgets/apple_finder_scaffold.dart';

class MobileAppSurface extends StatelessWidget {
  const MobileAppSurface({
    required this.appId,
    required this.data,
    required this.launcher,
    required this.themeController,
    required this.tablet,
    required this.onClose,
    this.onOpenApp,
    super.key,
  });

  final PortfolioAppId appId;
  final PortfolioData data;
  final ExternalLauncher launcher;
  final PortfolioThemeController themeController;
  final bool tablet;
  final VoidCallback onClose;
  final ValueChanged<PortfolioAppId>? onOpenApp;

  @override
  Widget build(BuildContext context) {
    final radius = tablet ? 28.0 : 0.0;
    final label = AppleAppIcon.labelFor(appId);
    final windowTitle = AppleAppIcon.windowTitleFor(appId);
    final integratesFinderToolbar = appId == PortfolioAppId.projects;
    final finderWindowChrome = integratesFinderToolbar
        ? AppleFinderWindowChrome(
            leadingControls: MacTrafficControls(
              appId: appId,
              windowLabel: label,
              maximized: !tablet,
              onClose: onClose,
              targetSize: 32,
              secondaryControlsInteractive: false,
            ),
            onDragUpdate: (_) {},
            cursor: MouseCursor.defer,
          )
        : null;

    return Padding(
      padding: tablet
          ? const EdgeInsets.fromLTRB(24, 10, 24, 14)
          : EdgeInsets.zero,
      child: Container(
        key: const Key('mobile-app-surface'),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: tablet
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.66),
                  width: 0.9,
                )
              : null,
          boxShadow: tablet
              ? <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 34,
                    offset: const Offset(0, 16),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          key: const Key('mobile-app-clip'),
          borderRadius: BorderRadius.circular(radius),
          child: ColoredBox(
            color: AppleTheme.surface(context),
            child: Column(
              children: <Widget>[
                if (!integratesFinderToolbar)
                  _MobileAppNavigationBar(
                    appId: appId,
                    label: label,
                    title: windowTitle,
                    tablet: tablet,
                    onClose: onClose,
                  ),
                Expanded(
                  child: PortfolioAppContent(
                    appId: appId,
                    data: data,
                    launcher: launcher,
                    themeController: themeController,
                    compact: !tablet,
                    tablet: tablet,
                    finderWindowChrome: finderWindowChrome,
                    onOpenApp: onOpenApp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileAppNavigationBar extends StatelessWidget {
  const _MobileAppNavigationBar({
    required this.appId,
    required this.label,
    required this.title,
    required this.tablet,
    required this.onClose,
  });

  final PortfolioAppId appId;
  final String label;
  final String title;
  final bool tablet;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('mobile-app-navigation-bar'),
      decoration: BoxDecoration(
        color: AppleTheme.surface(context).withValues(alpha: 0.96),
        border: Border(
          bottom: BorderSide(color: AppleTheme.separator(context), width: 0.7),
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: tablet ? 54 : 50),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tablet ? 12 : 8,
            vertical: 4,
          ),
          child: Row(
            children: <Widget>[
              MacTrafficControls(
                appId: appId,
                windowLabel: label,
                maximized: !tablet,
                onClose: onClose,
                targetSize: 32,
                secondaryControlsInteractive: false,
              ),
              SizedBox(width: tablet ? 10 : 6),
              Expanded(
                child: Text(
                  title,
                  key: const Key('mobile-app-title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
