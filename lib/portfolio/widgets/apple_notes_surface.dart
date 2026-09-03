import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/apple_theme.dart';

enum AppleNotesSurfaceSize { compact, regular }

/// Shared paper layer used by the home Notes widget and the full About view.
class AppleNotesPaper extends StatelessWidget {
  const AppleNotesPaper({
    required this.child,
    this.paperKey,
    this.padding,
    this.darkPaper = false,
    super.key,
  });

  final Widget child;
  final Key? paperKey;
  final EdgeInsetsGeometry? padding;
  final bool darkPaper;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: paperKey,
      padding: padding,
      decoration: BoxDecoration(
        color: darkPaper ? const Color(0xFF1B2433) : const Color(0xFFFFFEFC),
      ),
      child: child,
    );
  }
}

class AppleNotesSurface extends StatefulWidget {
  const AppleNotesSurface({
    required this.body,
    this.size = AppleNotesSurfaceSize.regular,
    this.cardKey,
    this.headerKey,
    this.bodyKey,
    this.separatorKey,
    this.headerTitle = '메모',
    this.headerTrailing,
    this.bodyPadding,
    this.showSeparator = true,
    this.showBody = true,
    this.darkPaper = false,
    this.onTap,
    this.semanticLabel,
    this.excludeSemantics = false,
    super.key,
  });

  final Widget body;
  final AppleNotesSurfaceSize size;
  final Key? cardKey;
  final Key? headerKey;
  final Key? bodyKey;
  final Key? separatorKey;
  final String? headerTitle;
  final Widget? headerTrailing;
  final EdgeInsetsGeometry? bodyPadding;
  final bool showSeparator;
  final bool showBody;
  final bool darkPaper;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool excludeSemantics;

  @override
  State<AppleNotesSurface> createState() => _AppleNotesSurfaceState();
}

class _AppleNotesSurfaceState extends State<AppleNotesSurface> {
  final FocusNode _focusNode = FocusNode();
  bool _showFocus = false;

  bool get _compact => widget.size == AppleNotesSurfaceSize.compact;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = _compact ? 22.0 : 28.0;
    final paperGradient = widget.darkPaper
        ? const <Color>[Color(0xFF292C36), Color(0xFF1B2433)]
        : const <Color>[Color(0xFFFFFEFC), Color(0xFFFFF8E7)];

    final frame = Container(
      key: widget.cardKey,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: paperGradient,
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: _showFocus
              ? const Color(0xFF0066CC)
              : const Color(0xFFDDA51B).withValues(alpha: 0.76),
          width: _showFocus ? 3 : 0.9,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: widget.darkPaper
                ? Colors.black.withValues(alpha: 0.34)
                : AppleTheme.subtleShadow(context),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              key: widget.headerKey,
              padding: EdgeInsets.fromLTRB(
                _compact ? 15 : 24,
                _compact ? 11 : 17,
                _compact ? 15 : 24,
                widget.showSeparator ? 0 : (_compact ? 11 : 17),
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFFFFD95A), Color(0xFFFFB51A)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.folder_outlined,
                        color: Colors.white,
                        size: _compact ? 24 : 30,
                      ),
                      if (widget.headerTitle != null)
                        SizedBox(width: _compact ? 9 : 13),
                      if (widget.headerTitle != null)
                        Expanded(
                          child: Text(
                            widget.headerTitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: const Color(0xFF3A2700),
                                  fontSize: _compact ? 20 : 25,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        )
                      else
                        const Spacer(),
                      if (widget.headerTrailing
                          case final trailing?) ...<Widget>[
                        const SizedBox(width: 8),
                        Flexible(child: trailing),
                      ],
                    ],
                  ),
                  if (widget.showSeparator) ...<Widget>[
                    SizedBox(height: _compact ? 9 : 13),
                    SizedBox(
                      key: widget.separatorKey,
                      height: _compact ? 6 : 8,
                      child: const CustomPaint(
                        painter: AppleNotesDotsPainter(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.showBody)
              AppleNotesPaper(
                paperKey: widget.bodyKey,
                padding:
                    widget.bodyPadding ??
                    EdgeInsets.fromLTRB(
                      _compact ? 18 : 26,
                      _compact ? 18 : 24,
                      _compact ? 18 : 26,
                      _compact ? 22 : 28,
                    ),
                darkPaper: widget.darkPaper,
                child: widget.body,
              ),
          ],
        ),
      ),
    );

    if (widget.onTap == null) {
      return frame;
    }

    return Semantics(
      label: widget.semanticLabel,
      button: true,
      onTap: widget.onTap,
      excludeSemantics: widget.excludeSemantics,
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
              widget.onTap!();
              return null;
            },
          ),
        },
        onShowFocusHighlight: (value) {
          if (_showFocus != value) {
            setState(() => _showFocus = value);
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: frame,
        ),
      ),
    );
  }
}

class AppleNotesDotsPainter extends CustomPainter {
  const AppleNotesDotsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF8D6507);
    const radius = 1.2;
    const gap = 8.0;
    for (var x = radius; x <= size.width - radius; x += gap) {
      canvas.drawCircle(Offset(x, size.height / 2), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant AppleNotesDotsPainter oldDelegate) => false;
}
