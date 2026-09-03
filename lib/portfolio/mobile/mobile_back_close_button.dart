import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/portfolio_app_id.dart';
import '../theme/apple_theme.dart';

enum MobileBackCloseAction { back, close }

/// Shared iPhone/iPad back-shaped control used to dismiss a mobile surface.
///
/// The visual intentionally has no hover or pressed transition. Keyboard focus
/// remains visible so the control is still usable without a pointer.
class MobileBackCloseButton extends StatefulWidget {
  const MobileBackCloseButton({
    required this.appId,
    required this.windowLabel,
    required this.onPressed,
    this.action = MobileBackCloseAction.close,
    super.key,
  });

  final PortfolioAppId appId;
  final String windowLabel;
  final VoidCallback onPressed;
  final MobileBackCloseAction action;

  @override
  State<MobileBackCloseButton> createState() => _MobileBackCloseButtonState();
}

class _MobileBackCloseButtonState extends State<MobileBackCloseButton> {
  late final FocusNode _focusNode;
  bool _showFocus = false;

  String get _actionLabel => switch (widget.action) {
    MobileBackCloseAction.back => 'Back in ${widget.windowLabel}',
    MobileBackCloseAction.close => 'Close ${widget.windowLabel} window',
  };

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(
      debugLabel: '${widget.windowLabel} mobile navigation',
    );
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
    final key = Key('mobile-back-close-${widget.appId.name}');
    return Semantics(
      key: key,
      container: true,
      label: _actionLabel,
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
            message: _actionLabel,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _activate,
              child: SizedBox.square(
                dimension: 44,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppleTheme.panel(context),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _showFocus
                            ? AppleTheme.blue
                            : AppleTheme.separator(context),
                        width: _showFocus ? 2 : 0.8,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppleTheme.primaryLabel(context),
                      size: 19,
                    ),
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
