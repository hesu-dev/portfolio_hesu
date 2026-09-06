import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/terminal_app.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';

const _initialTerminalRevealDuration = Duration(milliseconds: 6900);
const _animationCompletionTick = Duration(microseconds: 1);

void main() {
  testWidgets('Terminal uses one typography system for every text role', (
    tester,
  ) async {
    for (final compact in <bool>[false, true]) {
      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpTerminal(tester, compact: compact);
      await tester.pump(_initialTerminalRevealDuration);
      await tester.pump(_animationCompletionTick);
      await tester.pump();

      final inputStyle = tester
          .widget<TextField>(find.byKey(const Key('terminal-input')))
          .style!;
      final promptStyle = tester
          .widget<Text>(find.text(r'portfolio: ~$'))
          .style!;

      await tester.enterText(find.byKey(const Key('terminal-input')), 'whoami');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();

      final styles = <TextStyle>[
        tester.widget<Text>(find.text(r'portfolio: ~$ help')).style!,
        tester.widget<Text>(find.text('flutter run')).style!,
        tester.widget<Text>(find.text('포트폴리오 개발 서버 실행')).style!,
        promptStyle,
        tester.widget<Text>(find.textContaining('Min He-su')).style!,
        inputStyle,
      ];

      for (final style in styles) {
        expect(style.fontFamily, 'monospace');
        expect(style.fontFamilyFallback, <String>['Menlo', 'Consolas']);
        expect(style.fontSize, compact ? 12.5 : 13.5);
        expect(style.fontWeight, FontWeight.w400);
        expect(style.height, 1.45);
      }
      expect(styles.map((style) => style.color).toSet().length, greaterThan(1));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Terminal reveals lines for 500ms with a 300ms pause', (
    tester,
  ) async {
    await _pumpTerminal(tester);

    final firstLine = find.byKey(const Key('terminal-line-reveal-0'));
    final secondLine = find.byKey(const Key('terminal-line-reveal-1'));

    expect(_opacity(tester, firstLine), 0);
    expect(_translationY(tester, firstLine), 5);
    expect(_opacity(tester, secondLine), 0);

    await tester.pump(const Duration(milliseconds: 250));
    expect(_opacity(tester, firstLine), inExclusiveRange(0, 1));
    expect(_translationY(tester, firstLine), inExclusiveRange(0, 5));
    expect(_opacity(tester, secondLine), 0);

    await tester.pump(const Duration(milliseconds: 250));
    expect(_opacity(tester, firstLine), 1);
    expect(_translationY(tester, firstLine), 0);
    expect(_opacity(tester, secondLine), 0);

    await tester.pump(const Duration(milliseconds: 299));
    expect(_opacity(tester, secondLine), 0);
    expect(_translationY(tester, secondLine), 5);

    await tester.pump(const Duration(milliseconds: 1));
    expect(_opacity(tester, secondLine), 0);

    await tester.pump(const Duration(milliseconds: 250));
    expect(_opacity(tester, secondLine), inExclusiveRange(0, 1));
    expect(_translationY(tester, secondLine), inExclusiveRange(0, 5));

    await tester.pump(const Duration(milliseconds: 250));
    expect(_opacity(tester, secondLine), 1);
    expect(_translationY(tester, secondLine), 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Terminal completes active output after one touch or click', (
    tester,
  ) async {
    await _pumpTerminal(tester);
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      _opacity(tester, find.byKey(const Key('terminal-line-reveal-8'))),
      0,
    );
    expect(find.byKey(const Key('terminal-input')), findsNothing);

    await tester.tap(
      find.byKey(const Key('terminal-app')),
      kind: ui.PointerDeviceKind.touch,
    );
    await tester.pump();

    for (var index = 0; index < 9; index++) {
      final line = find.byKey(Key('terminal-line-reveal-$index'));
      expect(_opacity(tester, line), 1);
      expect(_translationY(tester, line), 0);
    }
    expect(find.byKey(const Key('terminal-input')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('terminal-input')), 'whoami');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      _opacity(tester, find.byKey(const Key('terminal-line-reveal-13'))),
      0,
    );
    expect(find.byKey(const Key('terminal-input')), findsNothing);

    await tester.tap(
      find.byKey(const Key('terminal-app')),
      kind: ui.PointerDeviceKind.mouse,
    );
    await tester.pump();

    for (var index = 9; index < 14; index++) {
      final line = find.byKey(Key('terminal-line-reveal-$index'));
      expect(_opacity(tester, line), 1);
      expect(_translationY(tester, line), 0);
    }
    final input = tester.widget<TextField>(
      find.byKey(const Key('terminal-input')),
    );
    expect(input.focusNode!.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Terminal adds input only after the active output batch', (
    tester,
  ) async {
    await _pumpTerminal(tester);
    final inputReveal = find.byKey(const Key('terminal-input-reveal'));

    expect(inputReveal, findsOneWidget);
    expect(tester.getSize(inputReveal).height, 0);
    expect(find.byKey(const Key('terminal-input')), findsNothing);

    await tester.pump(
      _initialTerminalRevealDuration - const Duration(milliseconds: 1),
    );
    expect(tester.getSize(inputReveal).height, 0);
    expect(find.byKey(const Key('terminal-input')), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    expect(tester.getSize(inputReveal).height, 0);
    expect(find.byKey(const Key('terminal-input')), findsNothing);

    await tester.pump(_animationCompletionTick);
    await tester.pump();
    expect(tester.getSize(inputReveal).height, greaterThan(0));
    expect(find.byKey(const Key('terminal-input')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('terminal-input')), 'whoami');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    expect(tester.getSize(inputReveal).height, 0);
    expect(find.byKey(const Key('terminal-input')), findsNothing);

    await tester.pump(const Duration(milliseconds: 3699));
    expect(tester.getSize(inputReveal).height, 0);
    expect(find.byKey(const Key('terminal-input')), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    expect(tester.getSize(inputReveal).height, 0);
    expect(find.byKey(const Key('terminal-input')), findsNothing);

    await tester.pump(_animationCompletionTick);
    await tester.pump();
    expect(tester.getSize(inputReveal).height, greaterThan(0));
    expect(find.byKey(const Key('terminal-input')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Terminal does not hide completed output when motion is toggled',
    (tester) async {
      await _pumpTerminal(tester);
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const Key('terminal-input')), findsNothing);

      await _pumpTerminal(tester, disableAnimations: true);
      await tester.pump();
      expect(find.byKey(const Key('terminal-input')), findsOneWidget);
      expect(
        _opacity(tester, find.byKey(const Key('terminal-line-reveal-0'))),
        1,
      );

      await _pumpTerminal(tester);
      await tester.pump();
      expect(find.byKey(const Key('terminal-input')), findsOneWidget);
      expect(
        _opacity(tester, find.byKey(const Key('terminal-line-reveal-0'))),
        1,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Terminal renders distinct readable light and dark surfaces', (
    tester,
  ) async {
    final snapshots = <Brightness, ({Color surface, Color input})>{};

    for (final brightness in Brightness.values) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(
          theme: AppleTheme.light(),
          darkTheme: AppleTheme.dark(),
          themeMode: brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          home: const Scaffold(body: TerminalApp(data: portfolioData)),
        ),
      );
      await tester.pumpAndSettle();

      final terminal = find.byKey(const Key('terminal-app'));
      final surface = tester.widget<AppleAppSurface>(terminal).color!;
      final inputSurface = tester.widget<Container>(
        find.byKey(const Key('terminal-input-surface')),
      );
      final inputDecoration = inputSurface.decoration! as BoxDecoration;
      final line = tester.widget<Text>(find.text(r'portfolio: ~$ help'));
      final input = tester.widget<TextField>(
        find.byKey(const Key('terminal-input')),
      );

      expect(Theme.of(tester.element(terminal)).brightness, brightness);
      expect(_contrast(line.style!.color!, surface), greaterThanOrEqualTo(4.5));
      expect(
        _contrast(input.style!.color!, inputDecoration.color!),
        greaterThanOrEqualTo(4.5),
      );
      snapshots[brightness] = (surface: surface, input: inputDecoration.color!);
      expect(tester.takeException(), isNull);
    }

    expect(
      snapshots[Brightness.light]!.surface.computeLuminance(),
      greaterThan(0.75),
    );
    expect(
      snapshots[Brightness.dark]!.surface.computeLuminance(),
      lessThan(0.03),
    );
    expect(snapshots[Brightness.light], isNot(snapshots[Brightness.dark]));
  });
}

Future<void> _pumpTerminal(
  WidgetTester tester, {
  bool compact = false,
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
      home: Scaffold(
        body: TerminalApp(data: portfolioData, compact: compact),
      ),
    ),
  );
}

double _opacity(WidgetTester tester, Finder line) {
  return tester
      .widget<Opacity>(
        find.descendant(of: line, matching: find.byType(Opacity)),
      )
      .opacity;
}

double _translationY(WidgetTester tester, Finder line) {
  return tester
      .widget<Transform>(
        find.descendant(of: line, matching: find.byType(Transform)),
      )
      .transform
      .storage[13];
}

double _contrast(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground.computeLuminance()
      : background.computeLuminance();
  final darker = foreground.computeLuminance() > background.computeLuminance()
      ? background.computeLuminance()
      : foreground.computeLuminance();
  return (lighter + 0.05) / (darker + 0.05);
}
