import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/portfolio_app_id.dart';

/// Reusable macOS-style window controls with accessible interaction targets.
class MacTrafficControls extends StatelessWidget {
  const MacTrafficControls({
    required this.appId,
    required this.windowLabel,
    required this.maximized,
    required this.onClose,
    required this.onMinimize,
    required this.onMaximize,
    super.key,
  });

  static const Color closeColor = Color(0xFFFF5F57);
  static const Color minimizeColor = Color(0xFFFEBC2E);
  static const Color maximizeColor = Color(0xFF28C840);
  static const double visualDiameter = 14;
  static const double targetSize = 32;

  final PortfolioAppId appId;
  final String windowLabel;
  final bool maximized;
  final VoidCallback onClose;
  final VoidCallback onMinimize;
  final VoidCallback onMaximize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: Key('mac-traffic-controls-${appId.name}'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _MacTrafficButton(
            controlKey: Key('window-close-${appId.name}'),
            visualKey: Key('window-close-${appId.name}-visual'),
            focusKey: Key('window-close-${appId.name}-focus'),
            label: 'Close $windowLabel window',
            color: closeColor,
            onPressed: onClose,
          ),
          _MacTrafficButton(
            controlKey: Key('window-minimize-${appId.name}'),
            visualKey: Key('window-minimize-${appId.name}-visual'),
            focusKey: Key('window-minimize-${appId.name}-focus'),
            label: 'Minimize $windowLabel window',
            color: minimizeColor,
            onPressed: onMinimize,
          ),
          _MacTrafficButton(
            controlKey: Key('window-maximize-${appId.name}'),
            visualKey: Key('window-maximize-${appId.name}-visual'),
            focusKey: Key('window-maximize-${appId.name}-focus'),
            label: maximized
                ? 'Restore $windowLabel window'
                : 'Maximize $windowLabel window',
            color: maximizeColor,
            onPressed: onMaximize,
          ),
        ],
      ),
    );
  }
}

class _MacTrafficButton extends StatefulWidget {
  const _MacTrafficButton({
    required this.controlKey,
    required this.visualKey,
    required this.focusKey,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final Key controlKey;
  final Key visualKey;
  final Key focusKey;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  State<_MacTrafficButton> createState() => _MacTrafficButtonState();
}

class _MacTrafficButtonState extends State<_MacTrafficButton> {
  late final FocusNode _focusNode;
  bool _showFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: widget.label);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _activate() {
    _focusNode.requestFocus();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: widget.controlKey,
      label: widget.label,
      button: true,
      onTap: widget.onPressed,
      excludeSemantics: true,
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
        child: ExcludeSemantics(
          child: Tooltip(
            message: widget.label,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _activate,
              child: SizedBox.square(
                dimension: MacTrafficControls.targetSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    if (_showFocus)
                      Container(
                        key: widget.focusKey,
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF0A84FF),
                            width: 2,
                          ),
                        ),
                      ),
                    Container(
                      key: widget.visualKey,
                      width: MacTrafficControls.visualDiameter,
                      height: MacTrafficControls.visualDiameter,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                      ),
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
