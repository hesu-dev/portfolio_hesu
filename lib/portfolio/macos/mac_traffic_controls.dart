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
    this.onMinimize,
    this.onMaximize,
    this.targetSize = defaultTargetSize,
    this.secondaryControlsInteractive = true,
    super.key,
  }) : assert(targetSize >= visualDiameter),
       assert(!secondaryControlsInteractive || onMinimize != null),
       assert(!secondaryControlsInteractive || onMaximize != null);

  static const Color closeColor = Color(0xFFFF5F57);
  static const Color minimizeColor = Color(0xFFFEBC2E);
  static const Color maximizeColor = Color(0xFF28C840);
  static const double visualDiameter = 14;
  static const double visualCenterSpacing = 24;
  static const double minimumTargetWidth = 28;
  static const double defaultTargetSize = 32;

  final PortfolioAppId appId;
  final String windowLabel;
  final bool maximized;
  final VoidCallback onClose;
  final VoidCallback? onMinimize;
  final VoidCallback? onMaximize;
  final double targetSize;
  final bool secondaryControlsInteractive;

  @override
  Widget build(BuildContext context) {
    final controls = <Widget>[
      _MacTrafficButton(
        controlKey: Key('window-close-${appId.name}'),
        visualKey: Key('window-close-${appId.name}-visual'),
        glyphKey: Key('window-close-${appId.name}-glyph'),
        focusKey: Key('window-close-${appId.name}-focus'),
        label: 'Close $windowLabel window',
        color: closeColor,
        glyph: Icons.close_rounded,
        onPressed: onClose,
        targetSize: targetSize,
        visualOffset: minimumTargetWidth - visualCenterSpacing,
      ),
      if (secondaryControlsInteractive) ...<Widget>[
        _MacTrafficButton(
          controlKey: Key('window-minimize-${appId.name}'),
          visualKey: Key('window-minimize-${appId.name}-visual'),
          glyphKey: Key('window-minimize-${appId.name}-glyph'),
          focusKey: Key('window-minimize-${appId.name}-focus'),
          label: 'Minimize $windowLabel window',
          color: minimizeColor,
          glyph: Icons.remove_rounded,
          onPressed: onMinimize!,
          targetSize: targetSize,
          visualOffset: 0,
        ),
        _MacTrafficButton(
          controlKey: Key('window-maximize-${appId.name}'),
          visualKey: Key('window-maximize-${appId.name}-visual'),
          glyphKey: Key('window-maximize-${appId.name}-glyph'),
          focusKey: Key('window-maximize-${appId.name}-focus'),
          label: maximized
              ? 'Restore $windowLabel window'
              : 'Maximize $windowLabel window',
          color: maximizeColor,
          glyph: null,
          onPressed: onMaximize!,
          targetSize: targetSize,
          visualOffset: visualCenterSpacing - minimumTargetWidth,
        ),
      ] else ...<Widget>[
        _MacTrafficDecoration(
          controlKey: Key('window-minimize-${appId.name}'),
          visualKey: Key('window-minimize-${appId.name}-visual'),
          glyphKey: Key('window-minimize-${appId.name}-glyph'),
          color: minimizeColor,
          glyph: Icons.remove_rounded,
          targetSize: targetSize,
          visualOffset: 0,
        ),
        _MacTrafficDecoration(
          controlKey: Key('window-maximize-${appId.name}'),
          visualKey: Key('window-maximize-${appId.name}-visual'),
          glyphKey: Key('window-maximize-${appId.name}-glyph'),
          color: maximizeColor,
          glyph: null,
          targetSize: targetSize,
          visualOffset: visualCenterSpacing - minimumTargetWidth,
        ),
      ],
    ];

    return SizedBox(
      key: Key('mac-traffic-controls-${appId.name}'),
      height: targetSize,
      child: Row(mainAxisSize: MainAxisSize.min, children: controls),
    );
  }
}

class _MacTrafficButton extends StatefulWidget {
  const _MacTrafficButton({
    required this.controlKey,
    required this.visualKey,
    required this.glyphKey,
    required this.focusKey,
    required this.label,
    required this.color,
    required this.glyph,
    required this.onPressed,
    required this.targetSize,
    required this.visualOffset,
  });

  final Key controlKey;
  final Key visualKey;
  final Key glyphKey;
  final Key focusKey;
  final String label;
  final Color color;
  final IconData? glyph;
  final VoidCallback onPressed;
  final double targetSize;
  final double visualOffset;

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
              child: SizedBox(
                width: MacTrafficControls.minimumTargetWidth,
                height: widget.targetSize,
                child: Transform.translate(
                  offset: Offset(widget.visualOffset, 0),
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
                        child: widget.glyph == null
                            ? null
                            : Icon(
                                widget.glyph,
                                key: widget.glyphKey,
                                size: 9,
                                color: const Color(0xA6000000),
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

class _MacTrafficDecoration extends StatelessWidget {
  const _MacTrafficDecoration({
    required this.controlKey,
    required this.visualKey,
    required this.glyphKey,
    required this.color,
    required this.glyph,
    required this.targetSize,
    required this.visualOffset,
  });

  final Key controlKey;
  final Key visualKey;
  final Key glyphKey;
  final Color color;
  final IconData? glyph;
  final double targetSize;
  final double visualOffset;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        key: controlKey,
        width: MacTrafficControls.minimumTargetWidth,
        height: targetSize,
        child: Transform.translate(
          offset: Offset(visualOffset, 0),
          child: Center(
            child: Container(
              key: visualKey,
              width: MacTrafficControls.visualDiameter,
              height: MacTrafficControls.visualDiameter,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: glyph == null
                  ? null
                  : Icon(
                      glyph,
                      key: glyphKey,
                      size: 9,
                      color: const Color(0xA6000000),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
