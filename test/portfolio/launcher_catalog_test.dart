import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/macos/mac_desktop.dart';
import 'package:portfolio_hesu/portfolio/macos/mac_dock.dart';
import 'package:portfolio_hesu/portfolio/mobile/apple_home_grid.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/portfolio_theme_controller.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';

void main() {
  test('desktop and mobile expose distinct ordered launcher catalogs', () {
    expect(portfolioLauncherAppIds.map((appId) => appId.name), <String>[
      'about',
      'skills',
      'projects',
      'terminal',
      'github',
      'mail',
      'settings',
      'trash',
    ]);
    expect(AppleHomeGrid.apps.map((appId) => appId.name), <String>[
      'skills',
      'projects',
      'terminal',
      'photos',
      'github',
      'mail',
      'settings',
      'trash',
    ]);
    expect(MacDock.launchableApps.map((appId) => appId.name), <String>[
      'about',
      'skills',
      'projects',
      'terminal',
      'github',
      'mail',
      'settings',
    ]);
  });

  testWidgets('mobile home hides About and exposes the Photos placeholder', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: AppleHomeGrid(data: portfolioData, tablet: false, onOpen: (_) {}),
      ),
    );

    expect(find.byKey(const Key('home-app-about')), findsNothing);
    expect(find.byKey(const Key('home-app-photos')), findsOneWidget);
  });

  testWidgets(
    'desktop shows the 포트폴리오 launcher without the duplicate project app',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final themeController = PortfolioThemeController();
      addTearDown(themeController.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: MacDesktop(
            data: portfolioData,
            externalLauncher: const _FakeLauncher(),
            themeController: themeController,
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('desktop-app-projects')), findsOneWidget);
      expect(find.byKey(const Key('desktop-app-thisMac')), findsNothing);
      expect(find.text('포트폴리오'), findsOneWidget);
      expect(find.text('Projects'), findsNothing);
      expect(find.text('프로젝트'), findsNothing);
    },
  );
}

final class _FakeLauncher implements ExternalLauncher {
  const _FakeLauncher();

  @override
  Future<bool> launch(Uri uri) async => true;
}
