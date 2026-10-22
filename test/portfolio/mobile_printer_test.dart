import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/projects_app.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/mobile/apple_home_grid.dart';
import 'package:portfolio_hesu/portfolio/mobile/apple_mobile_dock.dart';
import 'package:portfolio_hesu/portfolio/mobile/apple_mobile_dock_geometry.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/widgets/portfolio_printer_shortcut.dart';

void main() {
  for (final scenario in <(String, Size, bool)>[
    ('iPhone', const Size(390, 844), false),
    ('iPad', const Size(834, 1112), true),
  ]) {
    testWidgets(
      '${scenario.$1} moves Printer into Files and Settings onto Home',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = scenario.$2;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final data = PortfolioData(
          identity: portfolioData.identity,
          experiences: const [],
          education: const [],
          skillGroups: const [],
          projects: const [],
        );
        final openedApps = <PortfolioAppId>[];
        await tester.pumpWidget(
          MaterialApp(
            theme: AppleTheme.light(),
            home: Scaffold(
              body: AppleHomeGrid(
                data: data,
                tablet: scenario.$3,
                onOpen: openedApps.add,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('home-app-printer')), findsNothing);
        final settings = find.byKey(const Key('home-app-settings'));
        expect(settings.hitTestable(), findsOneWidget);
        await tester.tap(settings);
        expect(openedApps, [PortfolioAppId.settings]);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppleTheme.light(),
            home: Scaffold(
              body: ProjectsApp(
                data: data,
                compact: !scenario.$3,
                tablet: scenario.$3,
                launcher: CallbackExternalLauncher((_) async => true),
                onOpenApp: openedApps.add,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('projects-files-app-grid')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('projects-files-app-settings')),
          findsNothing,
        );
        final printer = find.byKey(const Key('projects-files-app-printer'));
        await tester.ensureVisible(printer);
        await tester.pumpAndSettle();
        await tester.tap(printer);
        await tester.pumpAndSettle();
        expect(find.text('인쇄 화면을 열지 못했어요'), findsOneWidget);
        expect(
          find.text('PDF 저장과 인쇄는 웹 브라우저에서 포트폴리오를 열어 이용해 주세요.'),
          findsOneWidget,
        );
        await tester.tap(find.text('확인'));
        await tester.pumpAndSettle();
        expect(printer.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '${scenario.$1} Dock replaces Printer with Settings at the same height',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = scenario.$2;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final openedApps = <PortfolioAppId>[];
        await tester.pumpWidget(
          MaterialApp(
            theme: AppleTheme.light(),
            home: Scaffold(
              body: Center(
                child: AppleMobileDock(
                  data: portfolioData,
                  tablet: scenario.$3,
                  onOpen: openedApps.add,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(PortfolioPrinterShortcut), findsNothing);
        final settings = find.byKey(const Key('mobile-dock-settings'));
        expect(settings.hitTestable(), findsOneWidget);
        expect(
          tester.getSize(find.byKey(const Key('mobile-dock'))).height,
          closeTo(AppleMobileDockGeometry.height(tablet: scenario.$3), 0.1),
        );
        await tester.tap(settings);
        await tester.pumpAndSettle();
        expect(openedApps, [PortfolioAppId.settings]);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
