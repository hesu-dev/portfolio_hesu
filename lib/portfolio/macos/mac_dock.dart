import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/portfolio_app_id.dart';
import '../widgets/apple_app_icon.dart';

class MacDock extends StatelessWidget {
  const MacDock({
    required this.runningApps,
    required this.activeApp,
    required this.onAppPressed,
    super.key,
  });

  static const List<PortfolioAppId> apps = <PortfolioAppId>[
    PortfolioAppId.thisMac,
    PortfolioAppId.about,
    PortfolioAppId.skills,
    PortfolioAppId.projects,
    PortfolioAppId.terminal,
    PortfolioAppId.github,
    PortfolioAppId.mail,
    PortfolioAppId.trash,
  ];

  final Set<PortfolioAppId> runningApps;
  final PortfolioAppId? activeApp;
  final ValueChanged<PortfolioAppId> onAppPressed;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            key: const Key('mac-dock'),
            height: 82,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF2F7).withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.62),
                width: 0.8,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.22),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                for (var index = 0; index < apps.length; index++) ...<Widget>[
                  if (index == apps.length - 1)
                    Container(
                      width: 1,
                      height: 50,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      color: const Color(0xFF3B3B40).withValues(alpha: 0.22),
                    ),
                  _MacDockItem(
                    appId: apps[index],
                    running: runningApps.contains(apps[index]),
                    active: activeApp == apps[index],
                    onPressed: () => onAppPressed(apps[index]),
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

class _MacDockItem extends StatefulWidget {
  const _MacDockItem({
    required this.appId,
    required this.running,
    required this.active,
    required this.onPressed,
  });

  final PortfolioAppId appId;
  final bool running;
  final bool active;
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
    final foreground = appId == PortfolioAppId.trash
        ? const Color(0xFF4D5058)
        : Colors.white;
    final lifted = _hovering || _showFocus;

    return Semantics(
      key: Key('dock-app-${appId.name}'),
      label: 'Open or restore $label',
      button: true,
      selected: widget.active,
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
                        bottom: lifted ? 10 : 4,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOutCubic,
                          scale: lifted ? 1.13 : 1,
                          child: Container(
                            width: 49,
                            height: 49,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: AppleAppIcon.colorsFor(appId),
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _showFocus
                                    ? const Color(0xFF0A84FF)
                                    : Colors.white.withValues(alpha: 0.46),
                                width: _showFocus ? 2.4 : 0.8,
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 11,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              AppleAppIcon.iconFor(appId),
                              color: foreground,
                              size: 25,
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
                                  ? const Color(0xFF17171B)
                                  : const Color(0xFF55555B),
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
