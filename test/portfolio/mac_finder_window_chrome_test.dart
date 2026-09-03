import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/macos/mac_traffic_controls.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';
import 'package:portfolio_hesu/portfolio/portfolio_app.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';

void main() {
  testWidgets(
    'desktop Projects Finder merges traffic controls into one public toolbar',
    (tester) async {
      await _pumpPortfolio(
        tester,
        size: const Size(1024, 700),
        textScaler: const TextScaler.linear(2),
      );
      await _openDesktopApp(tester, PortfolioAppId.projects);
      await _openProjectsFromSystemMenu(tester);

      const prefix = 'projects';
      final window = find.byKey(const Key('mac-window-projects'));
      final toolbar = find.descendant(
        of: window,
        matching: find.byKey(const Key('projects-finder-toolbar')),
      );

      expect(find.byKey(const Key('mac-window-thisMac')), findsNothing);
      expect(find.byKey(const Key('project-hub-finder-toolbar')), findsNothing);
      expect(
        find.byKey(const Key('mac-window-titlebar-projects')),
        findsNothing,
      );
      expect(toolbar, findsOneWidget);
      expect(
        tester.getTopLeft(toolbar).dy,
        closeTo(tester.getTopLeft(window).dy, 1),
      );
      final trafficControls = find.descendant(
        of: toolbar,
        matching: find.byKey(const Key('mac-traffic-controls-projects')),
      );
      expect(trafficControls, findsOneWidget);
      for (final control in const <String>[
        'back',
        'forward',
        'current-location',
        'view-options',
      ]) {
        expect(
          find.descendant(
            of: toolbar,
            matching: find.byKey(Key('$prefix-finder-$control')),
          ),
          findsOneWidget,
        );
      }
      final back = find.byKey(const Key('projects-finder-back'));
      final location = find.byKey(
        const Key('projects-finder-current-location'),
      );
      expect(
        tester.getCenter(trafficControls).dy,
        closeTo(tester.getCenter(back).dy, 1),
      );
      expect(
        tester.getCenter(back).dy,
        closeTo(tester.getCenter(location).dy, 1),
      );

      expect(find.byKey(const Key('finder-back')), findsNothing);
      expect(find.byKey(const Key('finder-forward')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('integrated Finder toolbar drags and controls its Mac window', (
    tester,
  ) async {
    await _pumpPortfolio(tester, size: const Size(1024, 700));
    await _openDesktopApp(tester, PortfolioAppId.projects);

    final window = find.byKey(const Key('mac-window-projects'));
    final beforeDrag = tester.getRect(window);
    await tester.drag(
      find.byKey(const Key('projects-finder-current-location')),
      const Offset(64, 18),
    );
    await tester.pumpAndSettle();

    final afterDrag = tester.getRect(window);
    expect(afterDrag.left, greaterThan(beforeDrag.left + 40));
    expect(afterDrag.top, greaterThan(beforeDrag.top + 10));

    await tester.tap(find.byKey(const Key('window-minimize-projects')));
    await tester.pumpAndSettle();
    expect(window, findsNothing);
    expect(find.byKey(const Key('dock-running-projects')), findsOneWidget);
  });

  testWidgets('iPad and iPhone use one integrated Projects Finder toolbar', (
    tester,
  ) async {
    for (final size in const <Size>[Size(834, 700), Size(390, 700)]) {
      await _pumpPortfolio(tester, size: size);
      await tester.tap(find.byKey(const Key('home-app-projects')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('mobile-app-navigation-bar')),
        findsNothing,
        reason: '$size',
      );
      expect(
        find.byKey(const Key('projects-finder-toolbar')),
        findsOneWidget,
        reason: '$size',
      );
      final finderToolbar = find.byKey(const Key('projects-finder-toolbar'));
      expect(
        find.descendant(
          of: finderToolbar,
          matching: find.byType(MacTrafficControls),
        ),
        findsOneWidget,
        reason: '$size',
      );
      expect(
        find.descendant(of: finderToolbar, matching: find.text('경력')),
        findsOneWidget,
        reason: '$size',
      );
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });
}

Future<void> _pumpPortfolio(
  WidgetTester tester, {
  required Size size,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: size, textScaler: textScaler),
      child: PortfolioApp(
        key: ValueKey<Size>(size),
        externalLauncher: _FakeLauncher(),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _openDesktopApp(WidgetTester tester, PortfolioAppId appId) async {
  final icon = find.byKey(Key('desktop-app-${appId.name}'));
  await tester.tap(icon);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(icon);
  await tester.pumpAndSettle();
  expect(find.byKey(Key('mac-window-${appId.name}')), findsOneWidget);
}

Future<void> _openProjectsFromSystemMenu(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('mac-system-menu-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('system-menu-this-mac')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('mac-window-projects')), findsOneWidget);
  expect(find.byKey(const Key('mac-window-thisMac')), findsNothing);
}

final class _FakeLauncher implements ExternalLauncher {
  @override
  Future<bool> launch(Uri uri) async => true;
}
