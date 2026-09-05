import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/portfolio_app_id.dart';
import '../widgets/apple_app_artwork.dart';
import '../widgets/apple_app_icon.dart';

class MacDock extends StatelessWidget {
  const MacDock({
    required this.runningApps,
    required this.activeApp,
    required this.onAppPressed,
    this.trashEmpty = false,
    super.key,
  });

  static const List<PortfolioAppId> launchableApps = portfolioLauncherAppIds;

  static const List<PortfolioAppId> pinnedApps = <PortfolioAppId>[
    PortfolioAppId.about,
    PortfolioAppId.projects,
  ];

  static const List<PortfolioAppId> utilityApps = <PortfolioAppId>[
    PortfolioAppId.trash,
  ];

  final Set<PortfolioAppId> runningApps;
  final PortfolioAppId? activeApp;
  final ValueChanged<PortfolioAppId> onAppPressed;
  final bool trashEmpty;

  @override
  Widget build(BuildContext context) {
    // Utility apps have a permanent position after the separator.
    final runningLaunchableApps = launchableApps
        .where(
          (appId) => runningApps.contains(appId) && !pinnedApps.contains(appId),
        )
        .where((appId) => !utilityApps.contains(appId))
        .toList(growable: false);
    final theme = Theme.of(context);

    return RepaintBoundary(
      child: Container(
        key: const Key('mac-dock'),
        height: 82,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.48),
          borderRadius: BorderRadius.circular(24),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.34 : 0.24,
              ),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  for (final appId in pinnedApps) _buildDockItem(appId),
                  for (final appId in runningLaunchableApps)
                    _buildDockItem(appId),
                  const _DockSeparator(key: Key('mac-dock-utility-separator')),
                  for (final appId in utilityApps) _buildDockItem(appId),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDockItem(PortfolioAppId appId) {
    return _MacDockItem(
      key: ValueKey<PortfolioAppId>(appId),
      appId: appId,
      running: runningApps.contains(appId),
      active: activeApp == appId,
      trashEmpty: trashEmpty,
      onPressed: () => onAppPressed(appId),
    );
  }
}

class _DockSeparator extends StatelessWidget {
  const _DockSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.5,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.34),
    );
  }
}

class _MacDockItem extends StatefulWidget {
  const _MacDockItem({
    required this.appId,
    required this.running,
    required this.active,
    required this.trashEmpty,
    required this.onPressed,
    super.key,
  });

  final PortfolioAppId appId;
  final bool running;
  final bool active;
  final bool trashEmpty;
  final VoidCallback onPressed;

  @override
  State<_MacDockItem> createState() => _MacDockItemState();
}

class _MacDockItemState extends State<_MacDockItem> {
  final FocusNode _focusNode = FocusNode();
  bool _hovering = false;
  bool _showFocus = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appId = widget.appId;
    final label = AppleAppIcon.labelFor(appId);
    final lifted = _hovering || _showFocus;
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      key: Key('dock-app-${appId.name}'),
      label: 'Open or restore $label',
      button: true,
      selected: widget.active,
      value: appId == PortfolioAppId.trash
          ? (widget.trashEmpty ? 'Empty' : 'Contains items')
          : null,
      onTap: widget.onPressed,
      child: FocusableActionDetector(
        focusNode: _focusNode,
        mouseCursor: SystemMouseCursors.click,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed();
              return null;
            },
          ),
        },
        onShowFocusHighlight: (value) {
          if (_showFocus != value) {
            setState(() => _showFocus = value);
          }
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: ExcludeSemantics(
            child: Tooltip(
              message: label,
              verticalOffset: -72,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _focusNode.requestFocus();
                  widget.onPressed();
                },
                child: SizedBox(
                  width: 61,
                  height: 69,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOutCubic,
                        bottom: lifted ? 16 : 10,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOutCubic,
                          scale: lifted ? 1.13 : 1,
                          child: SizedBox.square(
                            dimension: 49,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: <Widget>[
                                AppleAppArtworkFrame(
                                  appId: appId,
                                  size: 49,
                                  foregroundColor:
                                      appId == PortfolioAppId.github
                                      ? Colors.black
                                      : null,
                                  frameKey: Key(
                                    'dock-app-artwork-frame-${appId.name}',
                                  ),
                                  trashEmpty: widget.trashEmpty,
                                ),
                                if (_showFocus)
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFF0A84FF),
                                            width: 2.5,
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
                      if (widget.running)
                        Positioned(
                          key: Key('dock-running-${appId.name}'),
                          bottom: 0,
                          child: Container(
                            width: widget.active ? 5.5 : 4.5,
                            height: widget.active ? 5.5 : 4.5,
                            decoration: BoxDecoration(
                              color: widget.active
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
