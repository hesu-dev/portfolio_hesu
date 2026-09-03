import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../terminal/terminal_engine.dart';
import '../theme/apple_theme.dart';

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
  final List<_TerminalLine> _transcript = <_TerminalLine>[
    const _TerminalLine('Portfolio Terminal — type "help" to begin.'),
  ];

  late TerminalEngine _engine = TerminalEngine(widget.data);

  String get _prompt => widget.data.terminalPrompt;

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
      setState(_transcript.clear);
      _focusNode.requestFocus();
      return;
    }
    if (input.trim().isEmpty) {
      _focusNode.requestFocus();
      return;
    }

    setState(() {
      _transcript.add(
        _TerminalLine('$_prompt ${input.trim()}', isCommand: true),
      );
      _transcript.addAll(result.lines.map((line) => _TerminalLine(line)));
    });
    _focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    return Theme(
      data: AppleTheme.dark(),
      child: Builder(
        builder: (context) {
          return AppleAppSurface(
            key: const Key('terminal-app'),
            color: const Color(0xFF121315),
            child: Column(
              children: <Widget>[
                _TerminalToolbar(compact: widget.compact),
                Expanded(
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
                        for (final line in _transcript)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Text(
                              line.text,
                              style: TextStyle(
                                color: line.isCommand
                                    ? const Color(0xFF71D98A)
                                    : const Color(0xFFE7E7EA),
                                fontFamily: 'monospace',
                                fontFamilyFallback: const <String>[
                                  'Menlo',
                                  'Consolas',
                                ],
                                fontSize: widget.compact ? 12.5 : 13.5,
                                height: 1.45,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                AnimatedPadding(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: _TerminalInput(
                    controller: _controller,
                    focusNode: _focusNode,
                    compact: widget.compact,
                    prompt: _prompt,
                    onSubmitted: _submit,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TerminalToolbar extends StatelessWidget {
  const _TerminalToolbar({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 52 : 58,
      padding: EdgeInsets.symmetric(horizontal: compact ? 13 : 18),
      decoration: const BoxDecoration(
        color: Color(0xFF202125),
        border: Border(
          bottom: BorderSide(color: Color(0xFF38393D), width: 0.7),
        ),
      ),
      child: Row(
        children: <Widget>[
          for (final color in const <Color>[
            Color(0xFFFF5F57),
            Color(0xFFFFBD2E),
            Color(0xFF28C840),
          ]) ...<Widget>[
            Container(
              width: compact ? 10 : 11,
              height: compact ? 10 : 11,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: compact ? 6 : 8),
          ],
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.terminal_rounded,
                  size: 16,
                  color: Color(0xFFA8A8AD),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    'portfolio — zsh',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFFC9C9CD),
                      fontSize: compact ? 11.5 : 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: compact ? 42 : 49),
        ],
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
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool compact;
  final String prompt;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final promptLabel = Text(
      prompt,
      style: TextStyle(
        color: const Color(0xFF71D98A),
        fontFamily: 'monospace',
        fontSize: compact ? 12.5 : 13,
        fontWeight: FontWeight.w600,
      ),
    );
    final input = TextField(
      key: const Key('terminal-input'),
      controller: controller,
      focusNode: focusNode,
      onSubmitted: onSubmitted,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.send,
      style: TextStyle(
        color: const Color(0xFFF3F3F5),
        fontFamily: 'monospace',
        fontSize: compact ? 13 : 13.5,
      ),
      cursorColor: const Color(0xFF71D98A),
      decoration: const InputDecoration(
        isDense: true,
        hintText: 'Enter a command',
        hintStyle: TextStyle(color: Color(0xFF74757B)),
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(vertical: 8),
      ),
    );
    final submit = SizedBox.square(
      dimension: 44,
      child: IconButton(
        key: const Key('terminal-submit'),
        onPressed: () => onSubmitted(controller.text),
        tooltip: 'Run command',
        visualDensity: VisualDensity.compact,
        icon: const Icon(
          Icons.arrow_upward_rounded,
          color: Color(0xFF71D98A),
          size: 20,
        ),
      ),
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 18,
        10,
        compact ? 10 : 14,
        12,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF18191C),
        border: Border(top: BorderSide(color: Color(0xFF34353A), width: 0.7)),
      ),
      child: compact
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                promptLabel,
                const SizedBox(height: 3),
                Row(
                  children: <Widget>[
                    Expanded(child: input),
                    submit,
                  ],
                ),
              ],
            )
          : Row(
              children: <Widget>[
                promptLabel,
                const SizedBox(width: 9),
                Expanded(child: input),
                submit,
              ],
            ),
    );
  }
}

class _TerminalLine {
  const _TerminalLine(this.text, {this.isCommand = false});

  final String text;
  final bool isCommand;
}
