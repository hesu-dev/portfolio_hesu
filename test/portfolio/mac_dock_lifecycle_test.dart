import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/terminal_app.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/macos/mac_dock.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';

void main() {
  testWidgets('Dock exposes only running launchable apps in stable order', (
    tester,
  ) async {
    await _pumpDock(tester);

    for (final appId in _launchableApps) {
      expect(find.byKey(Key('dock-app-${appId.name}')), findsNothing);
    }
    expect(find.byKey(const Key('dock-app-trash')), findsOneWidget);

    const runningApps = <PortfolioAppId>{
      PortfolioAppId.github,
      PortfolioAppId.settings,
      PortfolioAppId.terminal,
      PortfolioAppId.about,
    };
    await _pumpDock(
      tester,
      runningApps: runningApps,
      activeApp: PortfolioAppId.github,
    );

    final centers = <double>[
      for (final appId in _launchableApps)
        if (runningApps.contains(appId))
          tester.getCenter(find.byKey(Key('dock-app-${appId.name}'))).dx,
    ];
    expect(centers, orderedEquals(centers.toList()..sort()));
    for (final appId in _launchableApps) {
      expect(
        find.byKey(Key('dock-app-${appId.name}')),
        runningApps.contains(appId) ? findsOneWidget : findsNothing,
      );
    }
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

const _launchableApps = <PortfolioAppId>[
  PortfolioAppId.about,
  PortfolioAppId.skills,
  PortfolioAppId.projects,
  PortfolioAppId.terminal,
  PortfolioAppId.mail,
  PortfolioAppId.settings,
  PortfolioAppId.thisMac,
  PortfolioAppId.github,
];

Future<void> _pumpDock(
  WidgetTester tester, {
  Set<PortfolioAppId> runningApps = const <PortfolioAppId>{},
  PortfolioAppId? activeApp,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.light(),
      home: Scaffold(
        body: Center(
          child: MacDock(
            runningApps: runningApps,
            activeApp: activeApp,
            onAppPressed: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
