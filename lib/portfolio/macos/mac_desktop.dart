import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/portfolio_data.dart';
import '../models/portfolio_app_id.dart';
import '../services/external_launcher.dart';
import '../theme/portfolio_theme_controller.dart';
import '../widgets/apple_app_artwork.dart';
import '../widgets/apple_app_icon.dart';
import 'mac_dock.dart';
import 'mac_menu_bar.dart';
import 'mac_wallpaper.dart';
import 'mac_window.dart';
import 'mac_window_state.dart';

class MacDesktop extends StatefulWidget {
  const MacDesktop({
    required this.data,
    required this.externalLauncher,
    required this.themeController,
    this.trashEmpty = false,
    this.onTrashEmptied,
    Key? key,
  }) : super(key: key ?? const Key('mac-shell'));

  final PortfolioData data;
  final ExternalLauncher externalLauncher;
  final PortfolioThemeController themeController;
  final bool trashEmpty;
  final VoidCallback? onTrashEmptied;

  @override
  State<MacDesktop> createState() => _MacDesktopState();
}

class _MacDesktopState extends State<MacDesktop> {
  static const List<PortfolioAppId> _desktopApps =
      portfolioMacDesktopLauncherAppIds;

  final Map<PortfolioAppId, MacWindowState> _windows =
      <PortfolioAppId, MacWindowState>{};
  final List<PortfolioAppId> _zOrder = <PortfolioAppId>[];
  PortfolioAppId? _selectedDesktopApp;
  MacSystemPanel _openPanel = MacSystemPanel.none;
  Size _viewport = const Size(1440, 900);
  int _cascadeIndex = 0;

  PortfolioAppId? get _activeApp {
    for (final appId in _zOrder.reversed) {
      final window = _windows[appId];
      if (window != null && !window.minimized) {
        return appId;
      }
    }
    return null;
  }

  void _selectDesktopApp(PortfolioAppId appId) {
    setState(() {
      _selectedDesktopApp = appId;
      _openPanel = MacSystemPanel.none;
    });
  }

  void _openApp(PortfolioAppId appId) {
    setState(() {
      _selectedDesktopApp = appId;
      _openPanel = MacSystemPanel.none;
      final existing = _windows[appId];
      if (existing == null) {
        _windows[appId] = MacWindowState.initial(
          appId: appId,
          cascadeIndex: _cascadeIndex,
          viewport: _viewport,
        );
        _cascadeIndex++;
      } else {
        _windows[appId] = existing.focused();
      }
      _bringToFront(appId);
    });
  }

  void _focusApp(PortfolioAppId appId) {
    if (_activeApp == appId && !(_windows[appId]?.minimized ?? true)) {
      return;
    }
    setState(() {
      final existing = _windows[appId];
      if (existing == null) {
        return;
      }
      _windows[appId] = existing.focused();
      _bringToFront(appId);
      _openPanel = MacSystemPanel.none;
    });
  }

  void _bringToFront(PortfolioAppId appId) {
    _zOrder.remove(appId);
    _zOrder.add(appId);
  }

  void _closeApp(PortfolioAppId appId) {
    setState(() {
      _windows.remove(appId);
      _zOrder.remove(appId);
    });
  }

  void _minimizeApp(PortfolioAppId appId) {
    setState(() {
      final existing = _windows[appId];
      if (existing != null) {
        _windows[appId] = existing.minimizedCopy();
      }
    });
  }

  void _toggleMaximize(PortfolioAppId appId) {
    setState(() {
      final existing = _windows[appId];
      if (existing != null) {
        _windows[appId] = existing.toggleMaximized(_viewport);
        _bringToFront(appId);
      }
    });
  }

  void _dragWindow(PortfolioAppId appId, Offset delta) {
    final existing = _windows[appId];
    if (existing == null || existing.maximized) {
      return;
    }
    setState(() {
      _windows[appId] = existing.draggedBy(delta, _viewport);
      _bringToFront(appId);
    });
  }

  void _togglePanel(MacSystemPanel panel) {
    setState(() {
      _openPanel = _openPanel == panel ? MacSystemPanel.none : panel;
      _selectedDesktopApp = null;
    });
  }

  void _dismissPanels() {
    if (_openPanel == MacSystemPanel.none) {
      return;
    }
    setState(() => _openPanel = MacSystemPanel.none);
  }

  void _clearDesktopSelection() {
    if (_selectedDesktopApp == null && _openPanel == MacSystemPanel.none) {
      return;
    }
    setState(() {
      _selectedDesktopApp = null;
      _openPanel = MacSystemPanel.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewport = Size(constraints.maxWidth, constraints.maxHeight);
        final activeApp = _activeApp;

        return CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.escape): _dismissPanels,
          },
          child: Focus(
            autofocus: true,
            child: Material(
              type: MaterialType.transparency,
              child: SizedBox.expand(
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: <Widget>[
                    const Positioned.fill(child: MacWallpaper()),
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _clearDesktopSelection,
                      ),
                    ),
                    _buildDesktopIcons(),
                    _buildDiscoverabilityHint(),
                    for (final appId in _zOrder)
                      if (_windows[appId] case final window?)
                        _buildWindow(window, active: activeApp == appId),
                    if (_openPanel != MacSystemPanel.none)
                      Positioned.fill(
                        child: GestureDetector(
                          key: const Key('mac-system-panel-barrier'),
                          behavior: HitTestBehavior.opaque,
                          onTap: _dismissPanels,
                          child: ColoredBox(
                            color: Colors.black.withValues(alpha: 0.035),
                          ),
                        ),
                      ),
                    Positioned(
                      key: const Key('mac-dock-layer'),
                      left: 0,
                      right: 0,
                      bottom: 12,
                      child: Center(
                        child: MacDock(
                          key: const Key('mac-dock-widget'),
                          runningApps: _windows.keys.toSet(),
                          activeApp: activeApp,
                          trashEmpty: widget.trashEmpty,
                          onAppPressed: _openApp,
                        ),
                      ),
                    ),
                    Positioned(
                      key: const Key('mac-menu-bar-layer'),
                      top: 0,
                      left: 0,
                      right: 0,
                      child: MacMenuBar(
                        key: const Key('mac-menu-bar-widget'),
                        activeApp: activeApp,
                        openPanel: _openPanel,
                        onSystemMenuPressed: () =>
                            _togglePanel(MacSystemPanel.systemMenu),
                        onControlCenterPressed: () =>
                            _togglePanel(MacSystemPanel.controlCenter),
                        onClockPressed: () =>
                            _togglePanel(MacSystemPanel.notifications),
                      ),
                    ),
                    if (_openPanel == MacSystemPanel.controlCenter)
                      const Positioned(
                        top: 42,
                        right: 12,
                        child: MacControlCenterPanel(),
                      ),
                    if (_openPanel == MacSystemPanel.systemMenu)
                      Positioned(
                        top: 38,
                        left: 8,
                        child: MacSystemMenuPanel(
                          identityName: widget.data.identity.englishName,
                          onOpenAbout: () => _openApp(PortfolioAppId.about),
                          onOpenThisMac: () =>
                              _openApp(PortfolioAppId.projects),
                        ),
                      ),
                    if (_openPanel == MacSystemPanel.notifications)
                      const Positioned(
                        top: 42,
                        right: 12,
                        child: MacNotificationsPanel(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopIcons() {
    // Eight launchers render as four rows while clearing the Dock on the
    // minimum desktop size. Trash lives in the Dock's utility area.
    final availableHeight = (_viewport.height - 158).clamp(360.0, 560.0);
    return Positioned(
      top: 48,
      right: 17,
      width: 190,
      height: availableHeight,
      child: GridView.builder(
        key: const Key('mac-desktop-icons'),
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.88,
          mainAxisSpacing: 2,
          crossAxisSpacing: 4,
        ),
        itemCount: _desktopApps.length,
        itemBuilder: (context, index) {
          final appId = _desktopApps[index];
          return _MacDesktopIcon(
            appId: appId,
            selected: _selectedDesktopApp == appId,
            onSelect: () => _selectDesktopApp(appId),
            onOpen: () => _openApp(appId),
          );
        },
      ),
    );
  }

  Widget _buildDiscoverabilityHint() {
    return Positioned(
      left: 22,
      bottom: 108,
      child: IgnorePointer(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              key: const Key('desktop-discoverability-hint'),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10152B).withValues(alpha: 0.38),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.ads_click_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 7),
                  Text(
                    'Double-click an icon to explore',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWindow(MacWindowState window, {required bool active}) {
    final frame = window.frameFor(_viewport);
    final appId = window.appId;
    return Positioned(
      key: ValueKey<PortfolioAppId>(appId),
      left: frame.left,
      top: frame.top,
      width: frame.width,
      height: frame.height,
      child: Visibility(
        visible: !window.minimized,
        maintainState: true,
        child: MacWindow(
          appId: appId,
          data: widget.data,
          launcher: widget.externalLauncher,
          themeController: widget.themeController,
          active: active,
          maximized: window.maximized,
          onFocus: () => _focusApp(appId),
          onClose: () => _closeApp(appId),
          onMinimize: () => _minimizeApp(appId),
          onMaximize: () => _toggleMaximize(appId),
          onDrag: (delta) => _dragWindow(appId, delta),
          onOpenApp: _openApp,
          trashEmpty: widget.trashEmpty,
          onTrashEmptied: widget.onTrashEmptied,
        ),
      ),
    );
  }
}

class _MacDesktopIcon extends StatefulWidget {
  const _MacDesktopIcon({
    required this.appId,
    required this.selected,
    required this.onSelect,
    required this.onOpen,
  });

  final PortfolioAppId appId;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onOpen;

  @override
  State<_MacDesktopIcon> createState() => _MacDesktopIconState();
}

class _MacDesktopIconState extends State<_MacDesktopIcon> {
  final FocusNode _focusNode = FocusNode();
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
    final artwork = AppleAppArtworkFrame(
      appId: appId,
      size: 50,
      frameKey: Key('desktop-app-artwork-frame-${appId.name}'),
      foregroundColor: appId == PortfolioAppId.github ? Colors.black : null,
    );
    final labelText = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        shadows: <Shadow>[
          Shadow(color: Color(0xB3000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
    );

    return Semantics(
      key: Key('desktop-app-${appId.name}'),
      label: 'Open $label',
      button: true,
      selected: widget.selected,
      onTap: widget.onOpen,
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
              widget.onOpen();
              return null;
            },
          ),
        },
        onShowFocusHighlight: (value) {
          if (_showFocus != value) {
            setState(() => _showFocus = value);
          }
        },
        child: ExcludeSemantics(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _focusNode.requestFocus();
              widget.onSelect();
            },
            onDoubleTap: widget.onOpen,
            child: Center(
              child: AnimatedContainer(
                key: widget.selected
                    ? Key('desktop-app-selection-${appId.name}')
                    : null,
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutCubic,
                width: 83,
                padding: const EdgeInsets.fromLTRB(6, 7, 6, 5),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox.square(
                      dimension: 50,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          Positioned(
                            left: -5,
                            top: -5,
                            right: -5,
                            bottom: -5,
                            child: AnimatedContainer(
                              key: Key(
                                'desktop-app-artwork-selection-${appId.name}',
                              ),
                              duration: const Duration(milliseconds: 140),
                              curve: Curves.easeOutCubic,
                              decoration: BoxDecoration(
                                color: widget.selected
                                    ? Colors.black.withValues(alpha: 0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                          ),
                          Positioned.fill(child: artwork),
                          Positioned(
                            left: -5,
                            top: -5,
                            right: -5,
                            bottom: -5,
                            child: AnimatedContainer(
                              key: Key('desktop-app-focus-${appId.name}'),
                              duration: const Duration(milliseconds: 140),
                              curve: Curves.easeOutCubic,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: _showFocus
                                    ? Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.82,
                                        ),
                                        width: 2,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      key: Key('desktop-app-label-selection-${appId.name}'),
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: widget.selected
                            ? Colors.black.withValues(alpha: 0.46)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: labelText,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
