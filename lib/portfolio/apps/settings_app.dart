import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/apple_theme.dart';
import '../theme/portfolio_theme_controller.dart';

/// The single-purpose appearance settings surface shared by every shell.
class SettingsApp extends StatelessWidget {
  const SettingsApp({
    required this.themeController,
    this.compact = false,
    this.tablet = false,
    super.key,
  });

  final PortfolioThemeController themeController;
  final bool compact;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    return AppleAppSurface(
      key: const Key('settings-app'),
      child: Column(
        children: <Widget>[
          AppleToolbar(
            title: '설정',
            subtitle: '포트폴리오 화면의 표시 방식을 선택합니다',
            compact: compact,
            leading: const Icon(Icons.settings_rounded, color: AppleTheme.blue),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = !compact && constraints.maxWidth >= 600;
                if (!wide) {
                  return _DisplayModePane(
                    controller: themeController,
                    compact: true,
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const _SettingsSidebar(),
                    Expanded(
                      child: _DisplayModePane(
                        controller: themeController,
                        compact: false,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSidebar extends StatelessWidget {
  const _SettingsSidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('settings-sidebar'),
      width: 208,
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
      decoration: BoxDecoration(
        color: AppleTheme.panel(context),
        border: Border(
          right: BorderSide(color: AppleTheme.separator(context), width: 0.7),
        ),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: AppleTheme.selectionBackground(context, AppleTheme.blue),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppleTheme.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.light_mode_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '화면 모드',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppleTheme.selectionForeground(context),
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

class _DisplayModePane extends StatelessWidget {
  const _DisplayModePane({required this.controller, required this.compact});

  final PortfolioThemeController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('settings-scroll'),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 30,
        compact ? 20 : 28,
        compact ? 16 : 30,
        compact ? 28 : 38,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            key: const Key('settings-display-mode'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('화면 모드', style: AppleTheme.title(context)),
              const SizedBox(height: 5),
              Text(
                '읽기 편한 화면을 선택하세요. 변경 사항은 바로 적용됩니다.',
                style: AppleTheme.body(
                  context,
                ).copyWith(color: AppleTheme.secondaryLabel(context)),
              ),
              SizedBox(height: compact ? 18 : 26),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stackChoices = compact || constraints.maxWidth < 430;
                  final light = _ThemeChoice(
                    preference: PortfolioThemePreference.light,
                    label: '라이트',
                    description: '밝고 선명한 화면',
                    selected:
                        controller.preference == PortfolioThemePreference.light,
                    onSelected: controller.select,
                  );
                  final dark = _ThemeChoice(
                    preference: PortfolioThemePreference.dark,
                    label: '다크',
                    description: '눈이 편안한 어두운 화면',
                    selected:
                        controller.preference == PortfolioThemePreference.dark,
                    onSelected: controller.select,
                  );
                  return stackChoices
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            light,
                            const SizedBox(height: 14),
                            dark,
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(child: light),
                            const SizedBox(width: 18),
                            Expanded(child: dark),
                          ],
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeChoice extends StatefulWidget {
  const _ThemeChoice({
    required this.preference,
    required this.label,
    required this.description,
    required this.selected,
    required this.onSelected,
  });

  final PortfolioThemePreference preference;
  final String label;
  final String description;
  final bool selected;
  final ValueChanged<PortfolioThemePreference> onSelected;

  @override
  State<_ThemeChoice> createState() => _ThemeChoiceState();
}

class _ThemeChoiceState extends State<_ThemeChoice> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'settings-theme-choice');
  bool _showFocus = false;

  String get _modeName => widget.preference.name;

  void _select() => widget.onSelected(widget.preference);

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (mounted && _showFocus != _focusNode.hasFocus) {
      setState(() => _showFocus = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final emphasisColor = AppleTheme.isDark(context)
        ? const Color(0xFF73B5FF)
        : AppleTheme.buttonBlue;
    final descriptionColor = selected
        ? AppleTheme.primaryLabel(context)
        : AppleTheme.secondaryLabel(context);
    return Semantics(
      key: Key('theme-$_modeName'),
      label: '${widget.label} 화면 모드',
      button: true,
      selected: selected,
      onTap: _select,
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
              _select();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _select,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 168),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected
                  ? AppleTheme.selectionBackground(context, AppleTheme.blue)
                  : AppleTheme.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _showFocus
                    ? emphasisColor
                    : selected
                    ? emphasisColor
                    : AppleTheme.separator(context),
                width: _showFocus ? 3 : (selected ? 2 : 0.8),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppleTheme.subtleShadow(context),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _AppearancePreview(
                  dark: widget.preference == PortfolioThemePreference.dark,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.label,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.description,
                            style: AppleTheme.caption(
                              context,
                            ).copyWith(color: descriptionColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedContainer(
                      key: selected ? Key('theme-selected-$_modeName') : null,
                      duration: const Duration(milliseconds: 160),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? AppleTheme.buttonBlue
                            : Colors.transparent,
                        border: Border.all(
                          color: selected
                              ? AppleTheme.buttonBlue
                              : AppleTheme.secondaryLabel(context),
                          width: 1.5,
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 15,
                            )
                          : null,
                    ),
                  ],
                ),
                if (_showFocus)
                  SizedBox(key: Key('theme-focus-$_modeName'), height: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppearancePreview extends StatelessWidget {
  const _AppearancePreview({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final canvas = dark ? const Color(0xFF24252A) : const Color(0xFFF0F1F4);
    final surface = dark ? const Color(0xFF111216) : Colors.white;
    final side = dark ? const Color(0xFF303137) : const Color(0xFFE4E5E8);
    final line = dark ? const Color(0xFF6D6E74) : const Color(0xFFB5B6BB);

    return AspectRatio(
      aspectRatio: 2.05,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: canvas,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: line.withValues(alpha: 0.45)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: <Widget>[
              Container(
                width: 26,
                decoration: BoxDecoration(
                  color: side,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: line,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppleTheme.blue.withValues(
                                    alpha: 0.82,
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: side,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
