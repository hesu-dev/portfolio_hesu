import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/terminal_app.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/macos/mac_dock.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';

void main() {
  testWidgets('Dock keeps Trash fixed after an always-visible separator', (
    tester,
  ) async {
    await _pumpDock(tester);

    for (final appId in _launchableApps) {
      expect(
        find.byKey(Key('dock-app-${appId.name}')),
        _persistentApps.contains(appId) ? findsOneWidget : findsNothing,
      );
    }
    expect(find.byKey(const Key('dock-app-trash')), findsOneWidget);
    expect(find.byKey(const Key('mac-dock-utility-separator')), findsOneWidget);
    expect(find.byKey(const Key('dock-running-trash')), findsNothing);

    final separatorCenter = tester.getCenter(
      find.byKey(const Key('mac-dock-utility-separator')),
    );
    for (final appId in _pinnedApps) {
      expect(
        tester.getCenter(find.byKey(Key('dock-app-${appId.name}'))).dx,
        lessThan(separatorCenter.dx),
      );
    }
    expect(
      separatorCenter.dx,
      lessThan(tester.getCenter(find.byKey(const Key('dock-app-trash'))).dx),
    );
  });

  testWidgets('Dock places its separator between running apps and Trash', (
    tester,
  ) async {
    const runningApps = <PortfolioAppId>{
      PortfolioAppId.github,
      PortfolioAppId.settings,
      PortfolioAppId.terminal,
      PortfolioAppId.about,
      PortfolioAppId.trash,
    };

    await _pumpDock(
      tester,
      runningApps: runningApps,
      activeApp: PortfolioAppId.github,
    );

    final centers = <double>[
      for (final appId in _launchableApps)
        if (_persistentApps.contains(appId) || runningApps.contains(appId))
          tester.getCenter(find.byKey(Key('dock-app-${appId.name}'))).dx,
    ];
    expect(centers, orderedEquals(centers.toList()..sort()));
    for (final appId in _launchableApps) {
      expect(
        find.byKey(Key('dock-app-${appId.name}')),
        _persistentApps.contains(appId) || runningApps.contains(appId)
            ? findsOneWidget
            : findsNothing,
      );
    }
    expect(find.byKey(const Key('dock-app-trash')), findsOneWidget);
    expect(find.byKey(const Key('dock-running-about')), findsOneWidget);
    expect(find.byKey(const Key('dock-running-projects')), findsNothing);
    expect(find.byKey(const Key('dock-running-trash')), findsOneWidget);
    expect(find.byKey(const Key('mac-dock-utility-separator')), findsOneWidget);

    final separatorCenter = tester.getCenter(
      find.byKey(const Key('mac-dock-utility-separator')),
    );
    for (final appId in const <PortfolioAppId>[
      PortfolioAppId.about,
      PortfolioAppId.projects,
      PortfolioAppId.terminal,
      PortfolioAppId.github,
      PortfolioAppId.settings,
    ]) {
      expect(
        tester.getCenter(find.byKey(Key('dock-app-${appId.name}'))).dx,
        lessThan(separatorCenter.dx),
        reason: '${appId.name} must stay before the Trash separator',
      );
    }
    expect(
      separatorCenter.dx,
      lessThan(tester.getCenter(find.byKey(const Key('dock-app-trash'))).dx),
    );
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
    for (final appId in _persistentApps) {
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

  testWidgets('Dock keeps folder, GitHub, and Trash frames transparent', (
    tester,
  ) async {
    await _pumpDock(
      tester,
      runningApps: const <PortfolioAppId>{
        PortfolioAppId.projects,
        PortfolioAppId.github,
      },
    );

    for (final appId in const <PortfolioAppId>[
      PortfolioAppId.projects,
      PortfolioAppId.trash,
      PortfolioAppId.github,
    ]) {
      final frame = find.byKey(Key('dock-app-artwork-frame-${appId.name}'));
      expect(frame, findsOneWidget);
      final decoration =
          tester.widget<Container>(frame).decoration! as BoxDecoration;
      expect(decoration.color, isNull);
      expect(decoration.gradient, isNull);
      expect(decoration.border, isNull);
      expect(decoration.boxShadow, isEmpty);
    }
  });

  testWidgets('Dock GitHub artwork stays black in every theme', (tester) async {
    for (final theme in <ThemeData>[AppleTheme.light(), AppleTheme.dark()]) {
      await _pumpDock(
        tester,
        theme: theme,
        runningApps: const <PortfolioAppId>{PortfolioAppId.github},
      );

      final picture = tester.widget<SvgPicture>(
        find.byKey(const Key('apple-app-artwork-github-svg')),
      );
      expect(
        (picture.bytesLoader as SvgAssetLoader).theme?.currentColor,
        Colors.black,
      );
    }
  });

  testWidgets('Dock keeps focus on an app when an earlier app starts running', (
    tester,
  ) async {
    final pressedApps = <PortfolioAppId>[];
    await _pumpDock(tester, onAppPressed: pressedApps.add);

    await tester.tap(find.byKey(const Key('dock-app-trash')));
    await tester.pump();
    pressedApps.clear();

    await _pumpDock(
      tester,
      runningApps: const <PortfolioAppId>{PortfolioAppId.skills},
      onAppPressed: pressedApps.add,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(pressedApps, <PortfolioAppId>[PortfolioAppId.trash]);
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

const _launchableApps = portfolioLauncherAppIds;

const _pinnedApps = <PortfolioAppId>[
  PortfolioAppId.about,
  PortfolioAppId.projects,
];

const _persistentApps = <PortfolioAppId>[..._pinnedApps, PortfolioAppId.trash];

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
