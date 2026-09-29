import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/portfolio_app_content.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/theme/portfolio_theme_controller.dart';
import 'package:portfolio_hesu/portfolio/widgets/adaptive_portfolio_shell.dart';

import 'support/music_test_controller.dart';

const _destinations = <String, PortfolioAppId>{
  '어떤 개발자인지 궁금하다면': PortfolioAppId.introduction,
  '프로젝트를 자세히 보고 싶다면': PortfolioAppId.safari,
  '사용하는 기술이 궁금하다면': PortfolioAppId.skills,
  '코드와 개발 기록을 보고 싶다면': PortfolioAppId.github,
  '키보드로 직접 체험하고 싶다면': PortfolioAppId.terminal,
};

void main() {
  for (final (width, pointer) in <(double, PointerDeviceKind)>[
    (1440, PointerDeviceKind.mouse),
    (834, PointerDeviceKind.touch),
    (390, PointerDeviceKind.touch),
  ]) {
    testWidgets('guide can be dragged with $pointer at width $width', (
      tester,
    ) async {
      await _pumpShell(tester, size: Size(width, 900));
      final button = find.byKey(const Key('portfolio-guide-button'));
      final initialCenter = tester.getCenter(button);

      final gesture = await tester.startGesture(initialCenter, kind: pointer);
      for (var step = 1; step <= 8; step++) {
        await gesture.moveTo(
          initialCenter + Offset(-20.0 * step, -24.0 * step),
        );
        await tester.pump();
      }
      await gesture.up();
      await tester.pumpAndSettle();
      final movedCenter = tester.getCenter(button);
      expect(movedCenter.dx, closeTo(initialCenter.dx - 160, 1));
      expect(movedCenter.dy, closeTo(initialCenter.dy - 192, 1));
      expect(find.text('포트폴리오 이용 안내'), findsNothing);

      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('포트폴리오 이용 안내'), findsOneWidget);
      await tester.tap(find.text(_destinations.keys.first));
      await tester.pumpAndSettle();
      expect(tester.getCenter(button), movedCenter);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is PortfolioAppContent &&
              widget.appId == PortfolioAppId.introduction,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('drag closes guide and keeps it within safe bounds on resize', (
    tester,
  ) async {
    const safePadding = EdgeInsets.fromLTRB(12, 44, 24, 24);
    await _pumpShell(
      tester,
      size: const Size(390, 900),
      safePadding: safePadding,
    );
    final button = find.byKey(const Key('portfolio-guide-button'));

    await tester.drag(button, const Offset(-2000, -2000));
    await tester.pumpAndSettle();
    expect(tester.getRect(button).left, greaterThanOrEqualTo(safePadding.left));
    expect(tester.getRect(button).top, greaterThanOrEqualTo(safePadding.top));
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('포트폴리오 이용 안내'), findsOneWidget);
    for (final label in _destinations.keys) {
      final rect = tester.getRect(find.text(label));
      expect(rect.left, greaterThanOrEqualTo(safePadding.left));
      expect(rect.right, lessThanOrEqualTo(390 - safePadding.right));
    }

    await tester.drag(button, const Offset(2000, 2000));
    await tester.pumpAndSettle();
    expect(find.text('포트폴리오 이용 안내'), findsNothing);
    expect(
      tester.getRect(button).right,
      lessThanOrEqualTo(390 - safePadding.right),
    );
    expect(
      tester.getRect(button).bottom,
      lessThanOrEqualTo(900 - safePadding.bottom),
    );

    tester.view.physicalSize = const Size(320, 650);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(button).right,
      lessThanOrEqualTo(320 - safePadding.right),
    );
    expect(
      tester.getRect(button).bottom,
      lessThanOrEqualTo(650 - safePadding.bottom),
    );
    final resizedCenter = tester.getCenter(button);
    await tester.drag(button, const Offset(-40, -60));
    await tester.pumpAndSettle();
    expect(tester.getCenter(button).dx, lessThan(resizedCenter.dx - 30));
    expect(tester.getCenter(button).dy, lessThan(resizedCenter.dy - 50));
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('포트폴리오 이용 안내'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in <double>[1440, 834, 390]) {
    testWidgets('guide opens each destination at width $width', (tester) async {
      await _pumpShell(tester, size: Size(width, 900));

      for (final entry in _destinations.entries) {
        await tester.tap(find.byKey(const Key('portfolio-guide-button')));
        await tester.pumpAndSettle();
        expect(find.text('포트폴리오 이용 안내'), findsOneWidget);
        for (final label in _destinations.keys) {
          expect(find.text(label), findsOneWidget);
        }

        await tester.tap(find.text(entry.key));
        await tester.pumpAndSettle();
        expect(find.text('포트폴리오 이용 안내'), findsNothing);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is PortfolioAppContent && widget.appId == entry.value,
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('guide dismisses with Escape, outside click, and its button', (
    tester,
  ) async {
    await _pumpShell(tester, size: const Size(1440, 900));
    final button = find.byKey(const Key('portfolio-guide-button'));

    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('포트폴리오 이용 안내'), findsNothing);

    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(500, 500));
    await tester.pumpAndSettle();
    expect(find.text('포트폴리오 이용 안내'), findsNothing);

    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('포트폴리오 이용 안내'), findsNothing);
  });

  testWidgets('narrow dark guide scrolls with large text and stays in bounds', (
    tester,
  ) async {
    await _pumpShell(
      tester,
      size: const Size(320, 568),
      dark: true,
      textScaler: const TextScaler.linear(1.8),
      safePadding: const EdgeInsets.only(right: 24, bottom: 24),
    );
    expect(
      tester.getRect(find.byKey(const Key('portfolio-guide-button'))).right,
      lessThanOrEqualTo(320 - 24 - 16),
    );
    await tester.tap(find.byKey(const Key('portfolio-guide-button')));
    await tester.pumpAndSettle();
    final lastRow = find.text(_destinations.keys.last);
    expect(MediaQuery.textScalerOf(tester.element(lastRow)).scale(10), 18);
    await tester.ensureVisible(lastRow);
    await tester.pumpAndSettle();
    expect(tester.getRect(lastRow).right, lessThanOrEqualTo(320));
    await tester.tap(lastRow);
    await tester.pumpAndSettle();
    expect(find.text('포트폴리오 이용 안내'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required Size size,
  bool dark = false,
  TextScaler textScaler = TextScaler.noScaling,
  EdgeInsets safePadding = EdgeInsets.zero,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final themeController = PortfolioThemeController();
  addTearDown(themeController.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? AppleTheme.dark() : AppleTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: textScaler,
          padding: safePadding,
          viewPadding: safePadding,
        ),
        child: child!,
      ),
      home: AdaptivePortfolioShell(
        externalLauncher: _UnusedLauncher(),
        themeController: themeController,
        musicController: createTestMusicController(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _UnusedLauncher implements ExternalLauncher {
  @override
  Future<bool> launch(Uri uri) async => true;
}
