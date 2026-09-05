import 'dart:ui';

import 'package:flutter/material.dart';

import '../apps/portfolio_app_content.dart';
import '../data/portfolio_data.dart';
import '../models/portfolio_app_id.dart';
import '../services/external_launcher.dart';
import '../theme/apple_theme.dart';
import '../theme/portfolio_theme_controller.dart';
import '../widgets/apple_app_icon.dart';
import '../widgets/apple_finder_scaffold.dart';
import 'mac_traffic_controls.dart';

class MacWindow extends StatelessWidget {
  const MacWindow({
    required this.appId,
    required this.data,
    required this.launcher,
    required this.themeController,
    required this.active,
    required this.maximized,
    required this.onFocus,
    required this.onClose,
    required this.onMinimize,
    required this.onMaximize,
    required this.onDrag,
    this.trashEmpty = false,
    this.onTrashEmptied,
    this.onOpenApp,
    super.key,
  });

  final PortfolioAppId appId;
  final PortfolioData data;
  final ExternalLauncher launcher;
  final PortfolioThemeController themeController;
  final bool active;
  final bool maximized;
  final VoidCallback onFocus;
  final VoidCallback onClose;
  final VoidCallback onMinimize;
  final VoidCallback onMaximize;
  final ValueChanged<Offset> onDrag;
  final bool trashEmpty;
  final VoidCallback? onTrashEmptied;
  final ValueChanged<PortfolioAppId>? onOpenApp;

  @override
  Widget build(BuildContext context) {
    final dark = AppleTheme.isDark(context);
    final shadowAlpha = active
        ? dark
              ? 0.5
              : 0.33
        : dark
        ? 0.34
        : 0.2;
    final borderAlpha = active
        ? dark
              ? 0.22
              : 0.76
        : dark
        ? 0.12
        : 0.48;
    final label = AppleAppIcon.labelFor(appId);
    final windowTitle = AppleAppIcon.windowTitleFor(appId);
    final radius = maximized ? 14.0 : 19.0;
    final integratesFinderToolbar = _integratesFinderToolbar(appId);
    final finderWindowChrome = integratesFinderToolbar
        ? AppleFinderWindowChrome(
            leadingControls: MacTrafficControls(
              appId: appId,
              windowLabel: label,
              maximized: maximized,
              onClose: onClose,
              onMinimize: onMinimize,
              onMaximize: onMaximize,
            ),
            onDragStart: (_) => onFocus(),
            onDragUpdate: (details) => onDrag(details.delta),
            cursor: maximized
                ? SystemMouseCursors.basic
                : SystemMouseCursors.move,
          )
        : null;

    return GestureDetector(
      onTapDown: (_) => onFocus(),
      child: AnimatedContainer(
        key: Key('mac-window-${appId.name}'),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: shadowAlpha),
              blurRadius: active ? 38 : 24,
              spreadRadius: active ? 1 : 0,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
            child: Stack(
              children: <Widget>[
                DecoratedBox(
                  key: Key('mac-window-surface-${appId.name}'),
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xFF1C1D21).withValues(alpha: 0.94)
                        : const Color(0xFFF4F4F7).withValues(alpha: 0.93),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: borderAlpha),
                      width: active ? 1 : 0.7,
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      if (!integratesFinderToolbar)
                        _MacWindowTitleBar(
                          appId: appId,
                          label: label,
                          title: windowTitle,
                          active: active,
                          maximized: maximized,
                          onFocus: onFocus,
                          onClose: onClose,
                          onMinimize: onMinimize,
                          onMaximize: onMaximize,
                          onDrag: onDrag,
                        ),
                      Expanded(
                        child: ClipRect(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return PortfolioAppContent(
                                appId: appId,
                                data: data,
                                launcher: launcher,
                                themeController: themeController,
                                compact: constraints.maxWidth < 650,
                                finderWindowChrome: finderWindowChrome,
                                onOpenApp: onOpenApp,
                                trashEmpty: trashEmpty,
                                onTrashEmptied: onTrashEmptied,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (active)
                  Positioned.fill(
                    child: IgnorePointer(
                      key: Key('mac-window-active-${appId.name}'),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius),
                          border: Border.all(
                            color: const Color(
                              0xFFBBDFFF,
                            ).withValues(alpha: 0.34),
                            width: 1,
                          ),
                        ),
                      ),
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

bool _integratesFinderToolbar(PortfolioAppId appId) => switch (appId) {
  PortfolioAppId.projects || PortfolioAppId.thisMac => true,
  _ => false,
};

class _MacWindowTitleBar extends StatelessWidget {
  const _MacWindowTitleBar({
    required this.appId,
    required this.label,
    required this.title,
    required this.active,
    required this.maximized,
    required this.onFocus,
    required this.onClose,
    required this.onMinimize,
    required this.onMaximize,
    required this.onDrag,
  });

  final PortfolioAppId appId;
  final String label;
  final String title;
  final bool active;
  final bool maximized;
  final VoidCallback onFocus;
  final VoidCallback onClose;
  final VoidCallback onMinimize;
  final VoidCallback onMaximize;
  final ValueChanged<Offset> onDrag;

  @override
  Widget build(BuildContext context) {
    final dark = AppleTheme.isDark(context);
    final background = active
        ? dark
              ? const Color(0xFF2C2D32).withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.7)
        : dark
        ? const Color(0xFF1F2024).withValues(alpha: 0.84)
        : const Color(0xFFE8E8EB).withValues(alpha: 0.72);
    final titleColor = active
        ? dark
              ? AppleTheme.primaryLabel(context)
              : const Color(0xFF252529)
        : dark
        ? AppleTheme.secondaryLabel(context)
        : const Color(0xFF747479);
    return GestureDetector(
      key: Key('mac-window-titlebar-${appId.name}'),
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => onFocus(),
      onPanUpdate: (details) => onDrag(details.delta),
      child: MouseRegion(
        cursor: maximized ? SystemMouseCursors.basic : SystemMouseCursors.move,
        child: Container(
          key: Key('mac-window-titlebar-surface-${appId.name}'),
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: background,
            border: Border(
              bottom: BorderSide(
                color: dark
                    ? Colors.white.withValues(alpha: 0.12)
                    : const Color(0x1F3C3C43),
                width: 0.7,
              ),
            ),
          ),
          child: Row(
            children: <Widget>[
              MacTrafficControls(
                appId: appId,
                windowLabel: label,
                maximized: maximized,
                onClose: onClose,
                onMinimize: onMinimize,
                onMaximize: onMaximize,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 60),
            ],
          ),
        ),
      ),
    );
  }
}
