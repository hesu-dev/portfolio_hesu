import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/terminal_app.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';

void main() {
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
      final line = tester.widget<Text>(find.text(r'포트폴리오: ~$ help'));
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

double _contrast(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground.computeLuminance()
      : background.computeLuminance();
  final darker = foreground.computeLuminance() > background.computeLuminance()
      ? background.computeLuminance()
      : foreground.computeLuminance();
  return (lighter + 0.05) / (darker + 0.05);
}
