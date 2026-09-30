import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/terminal_app.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/macos/mac_dock.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';

void main() {
  testWidgets('Dock keeps profile and my files before the printer', (
    tester,
  ) async {
    await _pumpDock(tester);

    for (final appId in PortfolioAppId.values) {
      expect(
        find.byKey(Key('dock-app-${appId.name}')),
        _pinnedApps.contains(appId) ? findsOneWidget : findsNothing,
      );
    }
    expect(find.byTooltip('내파일'), findsOneWidget);
    expect(find.byKey(const Key('dock-printer')), findsOneWidget);
    expect(find.byKey(const Key('mac-dock-utility-separator')), findsOneWidget);

    final centers = <double>[
      tester.getCenter(find.byKey(const Key('dock-app-about'))).dx,
      tester.getCenter(find.byKey(const Key('dock-app-projects'))).dx,
      tester.getCenter(find.byKey(const Key('mac-dock-utility-separator'))).dx,
      tester.getCenter(find.byKey(const Key('dock-printer'))).dx,
    ];
    expect(centers, orderedEquals(centers.toList()..sort()));
  });

  testWidgets('Dock stays fixed when other apps are running', (tester) async {
    await _pumpDock(
      tester,
      runningApps: PortfolioAppId.values.toSet(),
      activeApp: PortfolioAppId.about,
    );

    for (final appId in PortfolioAppId.values) {
      expect(
        find.byKey(Key('dock-app-${appId.name}')),
        _pinnedApps.contains(appId) ? findsOneWidget : findsNothing,
      );
    }
    expect(find.byKey(const Key('dock-running-about')), findsOneWidget);
    expect(find.byKey(const Key('dock-running-projects')), findsOneWidget);
    expect(find.byKey(const Key('dock-printer')), findsOneWidget);
  });

  testWidgets('Dock printer opens the shared print flow', (tester) async {
    final pressedApps = <PortfolioAppId>[];
    await _pumpDock(tester, onAppPressed: pressedApps.add);

    await tester.tap(find.byKey(const Key('dock-printer')));
    await tester.pumpAndSettle();

    expect(find.text('인쇄 화면을 열지 못했어요'), findsOneWidget);
    expect(pressedApps, isEmpty);
  });

  testWidgets('Dock surface is borderless and uses 0.48 surface alpha', (
    tester,
  ) async {
    await _pumpDock(tester);

    final dock = tester.widget<Container>(find.byKey(const Key('mac-dock')));
    final decoration = dock.decoration! as BoxDecoration;
    expect(decoration.border, isNull);
    expect(decoration.color!.a, closeTo(0.48, 0.001));
  });

  testWidgets('Dock centers artwork and separator with equal vertical gaps', (
    tester,
  ) async {
    await _pumpDock(
      tester,
      runningApps: const <PortfolioAppId>{PortfolioAppId.about},
      activeApp: PortfolioAppId.about,
    );

    final dockRect = tester.getRect(find.byKey(const Key('mac-dock')));
    for (final appId in _pinnedApps) {
      final artworkRect = tester.getRect(
        find.byKey(Key('dock-app-artwork-frame-${appId.name}')),
      );
      expect(
        artworkRect.top - dockRect.top,
        closeTo(dockRect.bottom - artworkRect.bottom, 1),
        reason: '${appId.name} artwork must be vertically centered',
      );
    }

    final separatorRect = tester.getRect(
      find.byKey(const Key('mac-dock-utility-separator')),
    );
    expect(
      separatorRect.top - dockRect.top,
      closeTo(dockRect.bottom - separatorRect.bottom, 1),
    );
    final activeArtworkRect = tester.getRect(
      find.byKey(const Key('dock-app-artwork-frame-about')),
    );
    final runningDotRect = tester.getRect(
      find.byKey(const Key('dock-running-about')),
    );
    expect(runningDotRect.top, greaterThanOrEqualTo(activeArtworkRect.bottom));

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(
      tester.getCenter(find.byKey(const Key('dock-app-about'))),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .getRect(find.byKey(const Key('dock-app-artwork-frame-about')))
          .center
          .dy,
      closeTo(activeArtworkRect.center.dy - 6, 0.1),
    );
  });

  testWidgets('Dock keeps the my files artwork transparent', (tester) async {
    await _pumpDock(tester);

    final frame = find.byKey(const Key('dock-app-artwork-frame-projects'));
    final decoration =
        tester.widget<Container>(frame).decoration! as BoxDecoration;
    expect(decoration.color, isNull);
    expect(decoration.gradient, isNull);
    expect(decoration.border, isNull);
    expect(decoration.boxShadow, isEmpty);
  });

  testWidgets('Dock keeps focus on an app when an earlier app starts running', (
    tester,
  ) async {
    final pressedApps = <PortfolioAppId>[];
    await _pumpDock(tester, onAppPressed: pressedApps.add);

    await tester.tap(find.byKey(const Key('dock-app-projects')));
    await tester.pump();
    pressedApps.clear();

    await _pumpDock(
      tester,
      runningApps: const <PortfolioAppId>{PortfolioAppId.skills},
      onAppPressed: pressedApps.add,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(pressedApps, <PortfolioAppId>[PortfolioAppId.projects]);
  });

  testWidgets('Terminal content does not draw window traffic controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppleTheme.dark(),
        home: const Scaffold(body: TerminalApp(data: portfolioData)),
      ),
    );

    const trafficLightColors = <Color>[
      Color(0xFFFF5F57),
      Color(0xFFFFBD2E),
      Color(0xFF28C840),
    ];
    final fakeTrafficLights = find.descendant(
      of: find.byKey(const Key('terminal-app')),
      matching: find.byWidgetPredicate((widget) {
        if (widget is! Container || widget.decoration is! BoxDecoration) {
          return false;
        }
        final decoration = widget.decoration! as BoxDecoration;
        return decoration.shape == BoxShape.circle &&
            trafficLightColors.contains(decoration.color);
      }, description: 'Terminal traffic-light circle'),
    );

    expect(fakeTrafficLights, findsNothing);
  });
}

const _pinnedApps = <PortfolioAppId>[
  PortfolioAppId.about,
  PortfolioAppId.projects,
];

Future<void> _pumpDock(
  WidgetTester tester, {
  ThemeData? theme,
  Set<PortfolioAppId> runningApps = const <PortfolioAppId>{},
  PortfolioAppId? activeApp,
  ValueChanged<PortfolioAppId>? onAppPressed,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppleTheme.light(),
      home: Scaffold(
        body: Center(
          child: MacDock(
            data: portfolioData,
            runningApps: runningApps,
            activeApp: activeApp,
            onAppPressed: onAppPressed ?? (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
