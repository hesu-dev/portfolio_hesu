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
    final dark = AppleTheme.isDark(context);
    final background = dark ? const Color(0xFF121315) : const Color(0xFFF5F5F7);
    final primary = dark ? const Color(0xFFE7E7EA) : const Color(0xFF242428);
    final accent = dark ? const Color(0xFF71D98A) : const Color(0xFF176B2D);

    return AppleAppSurface(
      key: const Key('terminal-app'),
      color: background,
      child: Column(
        children: <Widget>[
          _TerminalInput(
            key: const Key('terminal-input-area'),
            controller: _controller,
            focusNode: _focusNode,
            compact: widget.compact,
            prompt: _prompt,
            onSubmitted: _submit,
          ),
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
                          color: line.isCommand ? accent : primary,
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
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool compact;
  final String prompt;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final dark = AppleTheme.isDark(context);
    final accent = dark ? const Color(0xFF71D98A) : const Color(0xFF176B2D);
    final inputForeground = dark
        ? const Color(0xFFF3F3F5)
        : const Color(0xFF242428);
    final inputBackground = dark
        ? const Color(0xFF18191C)
        : const Color(0xFFFFFFFF);
    final inputBorder = dark
        ? const Color(0xFF34353A)
        : const Color(0xFFD8D8DC);
    final hint = dark ? const Color(0xFF74757B) : const Color(0xFF6E6E73);
    final promptLabel = Text(
      prompt,
      style: TextStyle(
        color: accent,
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
        color: inputForeground,
        fontFamily: 'monospace',
        fontSize: compact ? 13 : 13.5,
      ),
      cursorColor: accent,
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Enter a command',
        hintStyle: TextStyle(color: hint),
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
        icon: Icon(Icons.arrow_upward_rounded, color: accent, size: 20),
      ),
    );

    return Container(
      key: const Key('terminal-input-surface'),
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 18,
        10,
        compact ? 10 : 14,
        12,
      ),
      decoration: BoxDecoration(
        color: inputBackground,
        border: Border(bottom: BorderSide(color: inputBorder, width: 0.7)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = compact || constraints.maxWidth < 600;
          if (stacked) {
            return Column(
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
            );
          }
          return Row(
            children: <Widget>[
              promptLabel,
              const SizedBox(width: 9),
              Expanded(child: input),
              submit,
            ],
          );
        },
      ),
    );
  }
}

class _TerminalLine {
  const _TerminalLine(this.text, {this.isCommand = false});

  final String text;
  final bool isCommand;
}
