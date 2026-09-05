import 'package:flutter/material.dart';

import '../apps/portfolio_app_content.dart';
import '../data/portfolio_data.dart';
import '../models/portfolio_app_id.dart';
import '../music/music_controller.dart';
import '../services/external_launcher.dart';
import '../theme/apple_theme.dart';
import '../theme/portfolio_theme_controller.dart';
import '../widgets/apple_app_icon.dart';
import '../widgets/apple_finder_scaffold.dart';
import '../widgets/apple_mobile_navigation_header.dart';
import 'apple_mobile_dock_geometry.dart';
import 'mobile_back_close_button.dart';

class MobileAppSurface extends StatefulWidget {
  const MobileAppSurface({
    required this.appId,
    required this.data,
    required this.launcher,
    required this.themeController,
    required this.musicController,
    required this.tablet,
    required this.onClose,
    this.trashEmpty = false,
    this.onTrashEmptied,
    this.onOpenApp,
    super.key,
  });

  final PortfolioAppId appId;
  final PortfolioData data;
  final ExternalLauncher launcher;
  final PortfolioThemeController themeController;
  final MusicController musicController;
  final bool tablet;
  final VoidCallback onClose;
  final bool trashEmpty;
  final VoidCallback? onTrashEmptied;
  final ValueChanged<PortfolioAppId>? onOpenApp;

  @override
  State<MobileAppSurface> createState() => _MobileAppSurfaceState();
}

class _MobileAppSurfaceState extends State<MobileAppSurface> {
  bool _photoDetailVisible = false;

  @override
  void didUpdateWidget(covariant MobileAppSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appId != widget.appId) {
      _photoDetailVisible = false;
    }
  }

  void _handlePhotoDetailVisibilityChanged(bool visible) {
    if (_photoDetailVisible == visible) {
      return;
    }
    setState(() => _photoDetailVisible = visible);
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.tablet ? 28.0 : 0.0;
    final label = AppleAppIcon.labelFor(widget.appId);
    final windowTitle = AppleAppIcon.windowTitleFor(widget.appId);
    final integratesFinderToolbar = widget.appId == PortfolioAppId.projects;
    final ownsNavigationHeader = widget.appId == PortfolioAppId.profile;
    final finderWindowChrome = integratesFinderToolbar
        ? AppleFinderWindowChrome(
            leadingControls: MobileBackCloseButton(
              appId: widget.appId,
              windowLabel: label,
              onPressed: widget.onClose,
            ),
            mobileLeadingControlsBuilder: (canGoBack, onBack) =>
                MobileBackCloseButton(
                  appId: widget.appId,
                  windowLabel: label,
                  action: canGoBack
                      ? MobileBackCloseAction.back
                      : MobileBackCloseAction.close,
                  onPressed: canGoBack ? onBack : widget.onClose,
                ),
            onDragUpdate: (_) {},
            cursor: MouseCursor.defer,
          )
        : null;

    return Padding(
      padding: widget.tablet
          ? const EdgeInsets.fromLTRB(24, 10, 24, 0)
          : EdgeInsets.zero,
      child: Container(
        key: const Key('mobile-app-surface'),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: widget.tablet
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.66),
                  width: AppleMobileDockGeometry.tabletAppSurfaceBorderWidth,
                )
              : null,
          boxShadow: widget.tablet
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
                if (!integratesFinderToolbar && !ownsNavigationHeader)
                  SizedBox(
                    key: const Key('mobile-app-navigation-slot'),
                    child: _photoDetailVisible
                        ? null
                        : _MobileAppNavigationBar(
                            appId: widget.appId,
                            label: label,
                            title: windowTitle,
                            onClose: widget.onClose,
                          ),
                  ),
                Expanded(
                  child: PortfolioAppContent(
                    appId: widget.appId,
                    data: widget.data,
                    launcher: widget.launcher,
                    themeController: widget.themeController,
                    musicController: widget.musicController,
                    compact: !widget.tablet,
                    mobile: true,
                    tablet: widget.tablet,
                    finderWindowChrome: finderWindowChrome,
                    onOpenApp: widget.onOpenApp,
                    onClose: widget.onClose,
                    onPhotoDetailVisibilityChanged:
                        _handlePhotoDetailVisibilityChanged,
                    trashEmpty: widget.trashEmpty,
                    onTrashEmptied: widget.onTrashEmptied,
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
    required this.onClose,
  });

  final PortfolioAppId appId;
  final String label;
  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return AppleMobileNavigationHeader(
      key: const Key('mobile-app-navigation-bar'),
      keyPrefix: 'mobile-app-${appId.name}',
      title: title,
      titleKey: const Key('mobile-app-title'),
      moreKey: Key('mobile-app-more-${appId.name}'),
      leading: MobileBackCloseButton(
        appId: appId,
        windowLabel: label,
        onPressed: onClose,
      ),
    );
  }
}
