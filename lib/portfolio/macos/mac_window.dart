import 'dart:ui';

import 'package:flutter/material.dart';

import '../apps/portfolio_app_content.dart';
import '../data/portfolio_data.dart';
import '../models/portfolio_app_id.dart';
import '../services/external_launcher.dart';
import '../theme/portfolio_theme_controller.dart';
import '../widgets/apple_app_artwork.dart';
import '../widgets/apple_app_icon.dart';

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

  @override
  Widget build(BuildContext context) {
    final label = AppleAppIcon.labelFor(appId);
    final radius = maximized ? 14.0 : 19.0;

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
              color: Colors.black.withValues(alpha: active ? 0.33 : 0.2),
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
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F7).withValues(alpha: 0.93),
                    border: Border.all(
                      color: active
                          ? Colors.white.withValues(alpha: 0.76)
                          : Colors.white.withValues(alpha: 0.48),
                      width: active ? 1 : 0.7,
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      _MacWindowTitleBar(
                        appId: appId,
                        label: label,
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

class _MacWindowTitleBar extends StatelessWidget {
  const _MacWindowTitleBar({
    required this.appId,
    required this.label,
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
  final bool active;
  final bool maximized;
  final VoidCallback onFocus;
  final VoidCallback onClose;
  final VoidCallback onMinimize;
  final VoidCallback onMaximize;
  final ValueChanged<Offset> onDrag;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('mac-window-titlebar-${appId.name}'),
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => onFocus(),
      onPanUpdate: (details) => onDrag(details.delta),
      child: MouseRegion(
        cursor: maximized ? SystemMouseCursors.basic : SystemMouseCursors.move,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: active
                ? Colors.white.withValues(alpha: 0.7)
                : const Color(0xFFE8E8EB).withValues(alpha: 0.72),
            border: const Border(
              bottom: BorderSide(color: Color(0x1F3C3C43), width: 0.7),
            ),
          ),
          child: Row(
            children: <Widget>[
              _TrafficButton(
                controlKey: Key('window-close-${appId.name}'),
                visualKey: Key('window-close-${appId.name}-visual'),
                label: 'Close $label window',
                color: const Color(0xFFFF5F57),
                icon: Icons.close_rounded,
                onPressed: onClose,
              ),
              _TrafficButton(
                controlKey: Key('window-minimize-${appId.name}'),
                visualKey: Key('window-minimize-${appId.name}-visual'),
                label: 'Minimize $label window',
                color: const Color(0xFFFFBD2E),
                icon: Icons.remove_rounded,
                onPressed: onMinimize,
              ),
              _TrafficButton(
                controlKey: Key('window-maximize-${appId.name}'),
                visualKey: Key('window-maximize-${appId.name}-visual'),
                label: maximized
                    ? 'Restore $label window'
                    : 'Maximize $label window',
                color: const Color(0xFF28C840),
                icon: maximized
                    ? Icons.close_fullscreen_rounded
                    : Icons.open_in_full_rounded,
                onPressed: onMaximize,
              ),
              const SizedBox(width: 13),
              AppleAppArtwork(appId: appId, size: 16),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active
                        ? const Color(0xFF252529)
                        : const Color(0xFF747479),
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

class _TrafficButton extends StatelessWidget {
  const _TrafficButton({
    required this.controlKey,
    required this.visualKey,
    required this.label,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  final Key controlKey;
  final Key visualKey;
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: controlKey,
      label: label,
      button: true,
      excludeSemantics: true,
      onTap: onPressed,
      child: Tooltip(
        message: label,
        child: InkResponse(
          onTap: onPressed,
          radius: 14,
          containedInkWell: true,
          highlightShape: BoxShape.circle,
          excludeFromSemantics: true,
          child: SizedBox.square(
            dimension: 28,
            child: Center(
              child: Container(
                key: visualKey,
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.12),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 8,
                  color: const Color(0xFF353539).withValues(alpha: 0.68),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
