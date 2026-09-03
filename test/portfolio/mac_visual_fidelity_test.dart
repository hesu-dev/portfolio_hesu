import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/portfolio_app.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/portfolio_theme_controller.dart';

void main() {
  group('macOS wallpaper', () {
    testWidgets('draws distinct code-native Light and Dark compositions', (
      tester,
    ) async {
      final controller = PortfolioThemeController();
      addTearDown(controller.dispose);

      await _pumpPortfolio(tester, controller: controller);

      final wallpaper = find.byKey(const Key('mac-wallpaper'));
      expect(wallpaper, findsOneWidget);
      expect(
        find.descendant(
          of: wallpaper,
          matching: find.byKey(const Key('mac-wallpaper-light')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: wallpaper, matching: find.byType(Image)),
        findsNothing,
        reason: 'The public build must not redistribute a wallpaper asset.',
      );

      controller.select(PortfolioThemePreference.dark);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: wallpaper,
          matching: find.byKey(const Key('mac-wallpaper-dark')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: wallpaper,
          matching: find.byKey(const Key('mac-wallpaper-light')),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps wallpaper and display notch on Mac desktop only', (
      tester,
    ) async {
      await _pumpPortfolio(tester, size: const Size(1023, 700));
      expect(find.byKey(const Key('mac-wallpaper')), findsNothing);
      expect(find.byKey(const Key('mac-display-notch')), findsNothing);

      await _pumpPortfolio(tester, size: const Size(1024, 700));
      expect(find.byKey(const Key('mac-wallpaper')), findsOneWidget);
      expect(find.byKey(const Key('mac-display-notch')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('macOS display notch', () {
    testWidgets('is centered, black, and rounded only at its lower edge', (
      tester,
    ) async {
      await _pumpPortfolio(tester, size: const Size(1024, 700));

      final notchFinder = find.byKey(const Key('mac-display-notch'));
      final notchRect = tester.getRect(notchFinder);
      final notch = tester.widget<Container>(notchFinder);
      final decoration = notch.decoration! as BoxDecoration;
      final radius = decoration.borderRadius! as BorderRadius;

      expect(notchRect.width, inInclusiveRange(170, 180));
      expect(notchRect.center.dx, closeTo(512, 0.01));
      expect(notchRect.top, 0);
      expect(notchRect.bottom, lessThanOrEqualTo(32));
      expect(decoration.color, Colors.black);
      expect(radius.topLeft, Radius.zero);
      expect(radius.topRight, Radius.zero);
      expect(radius.bottomLeft.x, greaterThan(0));
      expect(radius.bottomRight.x, greaterThan(0));
    });

    testWidgets('reserves non-overlapping menu regions at 200 percent text', (
      tester,
    ) async {
      await _pumpPortfolio(
        tester,
        size: const Size(1024, 700),
        textScaler: const TextScaler.linear(2),
      );

      final left = tester.getRect(
        find.byKey(const Key('mac-menu-left-region')),
      );
      final notch = tester.getRect(find.byKey(const Key('mac-display-notch')));
      final right = tester.getRect(
        find.byKey(const Key('mac-menu-right-region')),
      );

      expect(left.right, lessThanOrEqualTo(notch.left));
      expect(right.left, greaterThanOrEqualTo(notch.right));
      expect(left.intersect(notch).isEmpty, isTrue);
      expect(right.intersect(notch).isEmpty, isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _pumpPortfolio(
  WidgetTester tester, {
  Size size = const Size(1440, 900),
  PortfolioThemeController? controller,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: textScaler),
      child: PortfolioApp(
        externalLauncher: _FakeLauncher(),
        themeController: controller,
      ),
    ),
  );
  await tester.pump();
}

class _FakeLauncher implements ExternalLauncher {
  @override
  Future<bool> launch(Uri uri) async => true;
}
