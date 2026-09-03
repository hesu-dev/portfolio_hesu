import 'package:flutter/material.dart';

import '../theme/apple_theme.dart';

class AppleSelectionControl extends StatefulWidget {
  const AppleSelectionControl({
    required this.semanticsLabel,
    required this.selected,
    required this.onPressed,
    required this.borderRadius,
    required this.child,
    super.key,
  });

  final String semanticsLabel;
  final bool selected;
  final VoidCallback onPressed;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  State<AppleSelectionControl> createState() => _AppleSelectionControlState();
}

class _AppleSelectionControlState extends State<AppleSelectionControl> {
  bool _focused = false;

  void _handleFocusChange(bool focused) {
    if (_focused == focused) {
      return;
    }
    setState(() => _focused = focused);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: widget.semanticsLabel,
      selected: widget.selected,
      button: true,
      focusable: true,
      focused: _focused,
      onTap: widget.onPressed,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          onFocusChange: _handleFocusChange,
          borderRadius: widget.borderRadius,
          child: Stack(
            children: <Widget>[
              widget.child,
              if (_focused)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      key: const Key('apple-selection-focus'),
                      decoration: BoxDecoration(
                        borderRadius: widget.borderRadius,
                        border: Border.all(
                          color: AppleTheme.selectionForeground(context),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
