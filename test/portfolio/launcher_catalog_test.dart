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
  const visibleApps = <PortfolioAppId>[
    PortfolioAppId.about,
    PortfolioAppId.skills,
    PortfolioAppId.projects,
    PortfolioAppId.terminal,
    PortfolioAppId.github,
    PortfolioAppId.mail,
    PortfolioAppId.settings,
    PortfolioAppId.trash,
  ];

  test(
    'home and Dock catalogs keep Projects and hide the duplicate project hub',
    () {
      expect(AppleHomeGrid.apps, visibleApps);
      expect(AppleHomeGrid.apps, contains(PortfolioAppId.projects));
      expect(AppleHomeGrid.apps, isNot(contains(PortfolioAppId.thisMac)));
      expect(MacDock.launchableApps, contains(PortfolioAppId.projects));
      expect(MacDock.launchableApps, isNot(contains(PortfolioAppId.thisMac)));
    },
  );

  testWidgets(
    'desktop shows the English Projects launcher without the Korean duplicate',
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
      expect(find.text('Projects'), findsOneWidget);
      expect(find.text('프로젝트'), findsNothing);
    },
  );
}

final class _FakeLauncher implements ExternalLauncher {
  const _FakeLauncher();

  @override
  Future<bool> launch(Uri uri) async => true;
}
