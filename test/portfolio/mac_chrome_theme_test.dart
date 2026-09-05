import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/macos/mac_menu_bar.dart';
import 'package:portfolio_hesu/portfolio/macos/mac_window.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/theme/portfolio_theme_controller.dart';

import 'support/music_test_controller.dart';

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

  group('macOS menu and panel chrome theme', () {
    testWidgets('preserves the light menu bar and themes dark controls', (
      tester,
    ) async {
      await _pumpMenuBar(tester, brightness: Brightness.light);

      final lightSurface = _decorationAt(
        tester,
        const Key('mac-menu-bar-surface'),
      );
      final lightFinder = tester.widget<Text>(find.text('Finder'));
      final lightWifi = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(const Key('mac-wifi-status')),
          matching: find.byType(Icon),
        ),
      );

      expect(lightSurface.color, Colors.white.withValues(alpha: 0.66));
      expect(
        (lightSurface.border! as Border).bottom.color,
        Colors.white.withValues(alpha: 0.48),
      );
      expect(lightFinder.style?.color, const Color(0xFF17171B));
      expect(lightWifi.color, const Color(0xFF17171B));

      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpMenuBar(tester, brightness: Brightness.dark);

      final darkSurface = _decorationAt(
        tester,
        const Key('mac-menu-bar-surface'),
      );
      final darkFinder = tester.widget<Text>(find.text('Finder'));
      final darkWifi = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(const Key('mac-wifi-status')),
          matching: find.byType(Icon),
        ),
      );
      final renderedSurface = Color.alphaBlend(
        darkSurface.color!,
        AppleTheme.dark().scaffoldBackgroundColor,
      );

      expect(darkSurface.color, isNot(lightSurface.color));
      expect(darkSurface.color!.computeLuminance(), lessThan(0.08));
      expect(
        darkFinder.style?.color,
        AppleTheme.primaryLabel(tester.element(find.text('Finder'))),
      );
      expect(darkWifi.color, darkFinder.style?.color);
      expect(
        _contrastRatio(darkFinder.style!.color!, renderedSurface),
        greaterThanOrEqualTo(4.5),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('themes every system panel and its nested glass cards', (
      tester,
    ) async {
      for (final scenario in _panelScenarios) {
        await _pumpPanel(
          tester,
          brightness: Brightness.light,
          panel: scenario.panel,
        );
        final lightSurface = _decorationAt(tester, scenario.surfaceKey);
        expect(
          lightSurface.color,
          const Color(0xFFF4F4F7).withValues(alpha: 0.83),
          reason: scenario.name,
        );

        Color? lightCardColor;
        if (scenario.cardKey case final cardKey?) {
          final lightCard = _decorationAt(tester, cardKey);
          lightCardColor = lightCard.color;
          expect(lightCardColor?.r, closeTo(1, 0.001), reason: scenario.name);
          expect(lightCardColor?.g, closeTo(1, 0.001), reason: scenario.name);
          expect(lightCardColor?.b, closeTo(1, 0.001), reason: scenario.name);
          expect(
            lightCardColor?.a,
            closeTo(scenario.lightCardAlpha!, 0.001),
            reason: scenario.name,
          );
        }

        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpPanel(
          tester,
          brightness: Brightness.dark,
          panel: scenario.panel,
        );
        final darkSurface = _decorationAt(tester, scenario.surfaceKey);
        final foreground = _foregroundFor(tester, scenario.foregroundKey);
        final renderedSurface = Color.alphaBlend(
          darkSurface.color!,
          AppleTheme.dark().scaffoldBackgroundColor,
        );

        expect(darkSurface.color, isNot(lightSurface.color));
        expect(darkSurface.color!.a, greaterThanOrEqualTo(0.8));
        expect(darkSurface.color!.computeLuminance(), lessThan(0.08));
        expect(
          _contrastRatio(foreground, renderedSurface),
          greaterThanOrEqualTo(4.5),
          reason: scenario.name,
        );

        if (scenario.cardKey case final cardKey?) {
          final darkCard = _decorationAt(tester, cardKey);
          final renderedCard = Color.alphaBlend(
            darkCard.color!,
            renderedSurface,
          );
          final cardForeground = tester
              .widget<Text>(find.text(scenario.cardText!))
              .style!
              .color!;
          expect(darkCard.color, isNot(lightCardColor));
          expect(darkCard.color!.computeLuminance(), lessThan(0.08));
          expect(
            _contrastRatio(cardForeground, renderedCard),
            greaterThanOrEqualTo(4.5),
            reason: '${scenario.name} nested card',
          );
        }
        expect(tester.takeException(), isNull, reason: scenario.name);
      }
    });

    testWidgets('describes appearance as a manual Light or Dark choice', (
      tester,
    ) async {
      await _pumpPanel(
        tester,
        brightness: Brightness.light,
        panel: _PanelKind.controlCenter,
      );

      final displayTile = find.byKey(const Key('mac-control-center-display'));
      expect(
        find.descendant(
          of: displayTile,
          matching: find.text('Choose Light or Dark in Settings'),
        ),
        findsOneWidget,
      );
      expect(find.text('Appearance follows your system'), findsNothing);
    });
  });
}

enum _PanelKind { systemMenu, controlCenter, notifications }

class _PanelScenario {
  const _PanelScenario({
    required this.name,
    required this.panel,
    required this.surfaceKey,
    required this.foregroundKey,
    this.cardKey,
    this.cardText,
    this.lightCardAlpha,
  });

  final String name;
  final _PanelKind panel;
  final Key surfaceKey;
  final Key foregroundKey;
  final Key? cardKey;
  final String? cardText;
  final double? lightCardAlpha;
}

const _panelScenarios = <_PanelScenario>[
  _PanelScenario(
    name: 'system menu',
    panel: _PanelKind.systemMenu,
    surfaceKey: Key('mac-system-menu-panel-surface'),
    foregroundKey: Key('system-menu-about'),
  ),
  _PanelScenario(
    name: 'control center',
    panel: _PanelKind.controlCenter,
    surfaceKey: Key('mac-control-center-panel-surface'),
    foregroundKey: Key('mac-control-center-title'),
    cardKey: Key('mac-control-center-wifi'),
    cardText: 'Network controls',
    lightCardAlpha: 0.58,
  ),
  _PanelScenario(
    name: 'notifications',
    panel: _PanelKind.notifications,
    surfaceKey: Key('mac-notifications-panel-surface'),
    foregroundKey: Key('mac-notifications-date'),
    cardKey: Key('mac-notifications-empty-card'),
    cardText: 'No new notifications',
    lightCardAlpha: 0.5,
  ),
];

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
          musicController: createTestMusicController(),
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
  await tester.pumpAndSettle();
}

Future<void> _pumpMenuBar(
  WidgetTester tester, {
  required Brightness brightness,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.light(),
      darkTheme: AppleTheme.dark(),
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      home: Align(
        alignment: Alignment.topCenter,
        child: MacMenuBar(
          activeApp: null,
          openPanel: MacSystemPanel.none,
          onSystemMenuPressed: () {},
          onControlCenterPressed: () {},
          onClockPressed: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  required Brightness brightness,
  required _PanelKind panel,
}) async {
  final child = switch (panel) {
    _PanelKind.systemMenu => MacSystemMenuPanel(
      identityName: 'Test Developer',
      onOpenAbout: () {},
      onOpenThisMac: () {},
    ),
    _PanelKind.controlCenter => const MacControlCenterPanel(),
    _PanelKind.notifications => const MacNotificationsPanel(),
  };
  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.light(),
      darkTheme: AppleTheme.dark(),
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      home: Center(child: child),
    ),
  );
  await tester.pumpAndSettle();
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

Color _foregroundFor(WidgetTester tester, Key key) {
  final target = find.byKey(key);
  expect(target, findsOneWidget);
  final widget = tester.widget(target);
  return switch (widget) {
    Text() => widget.style!.color!,
    TextButton() => widget.style!.foregroundColor!.resolve(<WidgetState>{})!,
    _ => throw TestFailure('Expected a text foreground at $key.'),
  };
}

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
