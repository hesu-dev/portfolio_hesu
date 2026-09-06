import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../terminal/terminal_engine.dart';
import '../theme/apple_theme.dart';

const _terminalLineRevealDuration = Duration(milliseconds: 500);
const _terminalLinePauseDuration = Duration(milliseconds: 300);
const _terminalLineTravel = 5.0;

class TerminalApp extends StatefulWidget {
  const TerminalApp({
    required this.data,
    this.compact = false,
    this.tablet = false,
    super.key,
  });

  final PortfolioData data;
  final bool compact;
  final bool tablet;

  @override
  State<TerminalApp> createState() => _TerminalAppState();
}

class _TerminalAppState extends State<TerminalApp> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  late final List<_TerminalLine> _transcript;
  int _activeRevealBatch = 0;
  bool _inputVisible = false;

  late TerminalEngine _engine;

  String get _prompt => widget.data.terminalPrompt;

  @override
  void initState() {
    super.initState();
    _engine = TerminalEngine(widget.data);
    _transcript = <_TerminalLine>[
      _TerminalLine(
        '$_prompt help',
        isCommand: true,
        revealBatch: _activeRevealBatch,
        revealOrder: 0,
      ),
      ..._linesFor(
        _engine.execute('help'),
        revealBatch: _activeRevealBatch,
        revealOrderStart: 1,
      ),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) && !_inputVisible) {
      _inputVisible = true;
      _restoreInputAfterReveal(_activeRevealBatch);
    }
  }

  @override
  void didUpdateWidget(covariant TerminalApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.data, widget.data)) {
      _engine = TerminalEngine(widget.data);
    }
  }

  void _submit([String? _]) {
    final input = _controller.text;
    final result = _engine.execute(input);
    _controller.clear();

    if (result.clear) {
      setState(() {
        _transcript.clear();
        _inputVisible = true;
      });
      _focusNode.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.minScrollExtent);
        }
      });
      return;
    }
    if (input.trim().isEmpty) {
      _focusNode.requestFocus();
      return;
    }

    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    setState(() {
      _activeRevealBatch++;
      _inputVisible = disableAnimations;
      _transcript.add(
        _TerminalLine(
          '$_prompt ${input.trim()}',
          isCommand: true,
          revealBatch: _activeRevealBatch,
          revealOrder: 0,
        ),
      );
      _transcript.addAll(
        _linesFor(result, revealBatch: _activeRevealBatch, revealOrderStart: 1),
      );
    });
    if (disableAnimations) {
      _restoreInputAfterReveal(_activeRevealBatch);
    }
  }

  Iterable<_TerminalLine> _linesFor(
    TerminalResult result, {
    required int revealBatch,
    required int revealOrderStart,
  }) sync* {
    var revealOrder = revealOrderStart;
    if (result.helpEntries.isNotEmpty) {
      for (final entry in result.helpEntries) {
        yield _TerminalLine.help(
          entry,
          revealBatch: revealBatch,
          revealOrder: revealOrder++,
        );
      }
      return;
    }
    for (final line in result.lines) {
      yield _TerminalLine(
        line,
        revealBatch: revealBatch,
        revealOrder: revealOrder++,
      );
    }
  }

  void _completeReveal(int revealBatch) {
    if (!mounted || revealBatch != _activeRevealBatch || _inputVisible) {
      return;
    }
    setState(() => _inputVisible = true);
    _restoreInputAfterReveal(revealBatch);
  }

  void _restoreInputAfterReveal(int revealBatch) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || revealBatch != _activeRevealBatch || !_inputVisible) {
        return;
      }
      _focusNode.requestFocus();
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppleTheme.isDark(context);
    final background = dark ? const Color(0xFF121315) : const Color(0xFFF5F5F7);
    final primary = dark ? const Color(0xFFE7E7EA) : const Color(0xFF242428);
    final accent = dark ? const Color(0xFF71D98A) : const Color(0xFF176B2D);

    return AppleAppSurface(
      key: const Key('terminal-app'),
      color: background,
      child: TextFieldTapRegion(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) {
            if (!_inputVisible) {
              _completeReveal(_activeRevealBatch);
              return;
            }
            _focusNode.requestFocus();
          },
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: !widget.compact,
            child: ListView(
              key: const Key('terminal-transcript'),
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                widget.compact ? 14 : 22,
                18,
                widget.compact ? 14 : 22,
                24,
              ),
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Column(
                      key: const Key('terminal-output'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        for (final entry in _transcript.indexed)
                          _TerminalLineReveal(
                            key: ValueKey<String>(
                              'terminal-line-reveal-${entry.$1}',
                            ),
                            animate:
                                entry.$2.revealBatch == _activeRevealBatch &&
                                !_inputVisible,
                            order: entry.$2.revealOrder,
                            onRevealComplete:
                                entry.$1 == _transcript.length - 1 &&
                                    entry.$2.revealBatch ==
                                        _activeRevealBatch &&
                                    !_inputVisible
                                ? () => _completeReveal(entry.$2.revealBatch)
                                : null,
                            child: Padding(
                              key: ValueKey<String>(
                                'terminal-transcript-entry-${entry.$1}',
                              ),
                              padding: const EdgeInsets.only(bottom: 5),
                              child: entry.$2.helpEntry != null
                                  ? _TerminalHelpRow(
                                      entry: entry.$2.helpEntry!,
                                      compact: widget.compact,
                                      color: primary,
                                    )
                                  : Text(
                                      entry.$2.text,
                                      style: _terminalTextStyle(
                                        color: entry.$2.isCommand
                                            ? accent
                                            : primary,
                                        compact: widget.compact,
                                      ),
                                    ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(
                      key: const Key('terminal-input-reveal'),
                      child: _inputVisible
                          ? _TerminalInput(
                              key: const Key('terminal-input-area'),
                              controller: _controller,
                              focusNode: _focusNode,
                              compact: widget.compact,
                              prompt: _prompt,
                              background: background,
                              onSubmitted: _submit,
                            )
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle _terminalTextStyle({required Color color, required bool compact}) {
  return TextStyle(
    color: color,
    fontFamily: 'monospace',
    fontFamilyFallback: const <String>['Menlo', 'Consolas'],
    fontSize: compact ? 12.5 : 13.5,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );
}

class _TerminalLineReveal extends StatelessWidget {
  const _TerminalLineReveal({
    required this.animate,
    required this.order,
    required this.onRevealComplete,
    required this.child,
    super.key,
  });

  final bool animate;
  final int order;
  final VoidCallback? onRevealComplete;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!animate || MediaQuery.disableAnimationsOf(context)) {
      return _buildReveal(value: 1);
    }

    final delay = Duration(
      milliseconds:
          (_terminalLineRevealDuration.inMilliseconds +
              _terminalLinePauseDuration.inMilliseconds) *
          order,
    );
    final totalDuration = delay + _terminalLineRevealDuration;
    final delayFraction = delay.inMicroseconds / totalDuration.inMicroseconds;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: totalDuration,
      curve: Interval(delayFraction, 1, curve: Curves.easeOutCubic),
      onEnd: onRevealComplete,
      builder: (context, value, child) => _buildReveal(value: value),
      child: child,
    );
  }

  Widget _buildReveal({required double value}) {
    return Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, _terminalLineTravel * (1 - value)),
        child: child,
      ),
    );
  }
}

class _TerminalHelpRow extends StatelessWidget {
  const _TerminalHelpRow({
    required this.entry,
    required this.compact,
    required this.color,
  });

  final TerminalHelpEntry entry;
  final bool compact;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '${entry.command}, ${entry.description}',
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final stacked = textScale > 1.4 && constraints.maxWidth < 560;
            final command = Text(
              entry.command,
              style: _terminalTextStyle(color: color, compact: compact),
            );
            final description = Text(
              entry.description,
              style: _terminalTextStyle(color: color, compact: compact),
            );
            if (stacked) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    command,
                    Padding(
                      padding: const EdgeInsets.only(left: 14),
                      child: description,
                    ),
                  ],
                ),
              );
            }
            final commandWidth = (constraints.maxWidth * 0.42).clamp(
              112.0,
              168.0,
            );
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(width: commandWidth, child: command),
                Expanded(child: description),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TerminalInput extends StatelessWidget {
  const _TerminalInput({
    required this.controller,
    required this.focusNode,
    required this.compact,
    required this.prompt,
    required this.background,
    required this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool compact;
  final String prompt;
  final Color background;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final dark = AppleTheme.isDark(context);
    final accent = dark ? const Color(0xFF71D98A) : const Color(0xFF176B2D);
    final inputForeground = dark
        ? const Color(0xFFF3F3F5)
        : const Color(0xFF242428);
    final promptLabel = Text(
      prompt,
      maxLines: 1,
      style: _terminalTextStyle(color: accent, compact: compact),
    );
    final input = MergeSemantics(
      child: Semantics(
        label: '터미널 명령 입력',
        child: TextField(
          key: const Key('terminal-input'),
          controller: controller,
          focusNode: focusNode,
          onSubmitted: onSubmitted,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          enableInteractiveSelection: false,
          cursorOpacityAnimates: true,
          textInputAction: TextInputAction.send,
          style: _terminalTextStyle(color: inputForeground, compact: compact),
          cursorColor: accent,
          decoration: const InputDecoration(
            isDense: true,
            filled: false,
            hoverColor: Colors.transparent,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: focusNode.requestFocus,
      child: Container(
        key: const Key('terminal-input-surface'),
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: background),
        child: Row(
          children: <Widget>[
            Flexible(
              flex: 0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 190),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: promptLabel,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(child: input),
          ],
        ),
      ),
    );
  }
}

class _TerminalLine {
  const _TerminalLine(
    this.text, {
    required this.revealBatch,
    required this.revealOrder,
    this.isCommand = false,
  }) : helpEntry = null;

  const _TerminalLine.help(
    TerminalHelpEntry entry, {
    required this.revealBatch,
    required this.revealOrder,
  }) : text = '',
       isCommand = false,
       helpEntry = entry;

  final String text;
  final bool isCommand;
  final int revealBatch;
  final int revealOrder;
  final TerminalHelpEntry? helpEntry;
}
