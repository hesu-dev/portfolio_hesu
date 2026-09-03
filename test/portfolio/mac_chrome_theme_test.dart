import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/macos/mac_window.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/theme/portfolio_theme_controller.dart';

void main() {
  group('macOS window chrome theme', () {
    testWidgets('preserves the light chrome and renders readable dark glass', (
      tester,
    ) async {
      await _pumpWindow(tester, brightness: Brightness.light);

      final lightSurface = _decorationAt(
        tester,
        const Key('mac-window-surface-skills'),
      );
      final lightTitleBar = _decorationAt(
        tester,
        const Key('mac-window-titlebar-surface-skills'),
      );
      final lightTitle = _windowTitle(tester);

      expect(
        lightSurface.color,
        const Color(0xFFF4F4F7).withValues(alpha: 0.93),
      );
      expect(
        (lightSurface.border! as Border).top.color,
        Colors.white.withValues(alpha: 0.76),
      );
      expect(lightTitleBar.color, Colors.white.withValues(alpha: 0.7));
      expect(
        (lightTitleBar.border! as Border).bottom.color,
        const Color(0x1F3C3C43),
      );
      expect(lightTitle.style?.color, const Color(0xFF252529));

      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpWindow(tester, brightness: Brightness.dark);

      final darkSurface = _decorationAt(
        tester,
        const Key('mac-window-surface-skills'),
      );
      final darkTitleBar = _decorationAt(
        tester,
        const Key('mac-window-titlebar-surface-skills'),
      );
      final darkTitle = _windowTitle(tester);
      final renderedTitleBar = Color.alphaBlend(
        darkTitleBar.color!,
        Color.alphaBlend(
          darkSurface.color!,
          AppleTheme.dark().scaffoldBackgroundColor,
        ),
      );

      expect(darkSurface.color, isNot(lightSurface.color));
      expect(darkSurface.color!.a, greaterThanOrEqualTo(0.85));
      expect(darkSurface.color!.computeLuminance(), lessThan(0.08));
      expect(darkTitleBar.color, isNot(lightTitleBar.color));
      expect(darkTitleBar.color!.computeLuminance(), lessThan(0.08));
      expect(
        (darkSurface.border! as Border).top.color,
        isNot((lightSurface.border! as Border).top.color),
      );
      expect(
        darkTitle.style?.color,
        AppleTheme.primaryLabel(tester.element(_windowTitleFinder)),
      );
      expect(
        _contrastRatio(darkTitle.style!.color!, renderedTitleBar),
        greaterThanOrEqualTo(4.5),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps inactive dark windows subdued but readable', (
      tester,
    ) async {
      await _pumpWindow(tester, brightness: Brightness.dark, active: false);

      final surface = _decorationAt(
        tester,
        const Key('mac-window-surface-skills'),
      );
      final titleBar = _decorationAt(
        tester,
        const Key('mac-window-titlebar-surface-skills'),
      );
      final title = _windowTitle(tester);
      final renderedTitleBar = Color.alphaBlend(
        titleBar.color!,
        Color.alphaBlend(
          surface.color!,
          AppleTheme.dark().scaffoldBackgroundColor,
        ),
      );

      expect(titleBar.color!.computeLuminance(), lessThan(0.08));
      expect(
        title.style?.color,
        AppleTheme.secondaryLabel(tester.element(_windowTitleFinder)),
      );
      expect(
        _contrastRatio(title.style!.color!, renderedTitleBar),
        greaterThanOrEqualTo(4.5),
      );
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _pumpWindow(
  WidgetTester tester, {
  required Brightness brightness,
  bool active = true,
}) async {
  final themeController = PortfolioThemeController(
    initial: brightness == Brightness.dark
        ? PortfolioThemePreference.dark
        : PortfolioThemePreference.light,
  );
  addTearDown(themeController.dispose);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 600);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.light(),
      darkTheme: AppleTheme.dark(),
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      home: SizedBox.expand(
        child: MacWindow(
          appId: PortfolioAppId.skills,
          data: portfolioData,
          launcher: CallbackExternalLauncher((_) async => true),
          themeController: themeController,
          active: active,
          maximized: false,
          onFocus: () {},
          onClose: () {},
          onMinimize: () {},
          onMaximize: () {},
          onDrag: (_) {},
        ),
      ),
    ),
  );
  await tester.pump();
}

BoxDecoration _decorationAt(WidgetTester tester, Key key) {
  final target = find.byKey(key);
  expect(target, findsOneWidget);
  final widget = tester.widget(target);
  return switch (widget) {
    DecoratedBox() => widget.decoration as BoxDecoration,
    Container() => widget.decoration! as BoxDecoration,
    _ => throw TestFailure('Expected a decorated surface at $key.'),
  };
}

Finder get _windowTitleFinder => find.descendant(
  of: find.byKey(const Key('mac-window-titlebar-surface-skills')),
  matching: find.text('Skills'),
);

Text _windowTitle(WidgetTester tester) =>
    tester.widget<Text>(_windowTitleFinder);

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
