import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/mobile/apple_home_grid.dart';
import 'package:portfolio_hesu/portfolio/mobile/apple_mobile_dock.dart';
import 'package:portfolio_hesu/portfolio/mobile/apple_mobile_dock_geometry.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/widgets/portfolio_printer_shortcut.dart';

void main() {
  for (final scenario in <(String, Size, bool)>[
    ('iPhone', const Size(390, 844), false),
    ('iPad', const Size(834, 1112), true),
  ]) {
    testWidgets(
      '${scenario.$1} home opens the shared printer with current data',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = scenario.$2;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final data = PortfolioData(
          identity: portfolioData.identity,
          experiences: const <PortfolioExperience>[],
          education: const <PortfolioEducation>[],
          skillGroups: const <PortfolioSkillGroup>[],
          projects: const <PortfolioProject>[],
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

        final printer = find.byKey(const Key('home-app-printer'));
        expect(printer, findsOneWidget);
        expect(find.text('프린터'), findsOneWidget);
        final shortcut = tester.widget<PortfolioPrinterShortcut>(
          find.descendant(
            of: printer,
            matching: find.byType(PortfolioPrinterShortcut),
          ),
        );
        expect(shortcut.data, same(data));
        expect(printer.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(printer);
        await tester.pumpAndSettle();

        expect(openedApps, isEmpty);
        expect(find.text('인쇄 화면을 열지 못했어요'), findsOneWidget);
        expect(
          find.text('PDF 저장과 인쇄는 웹 브라우저에서 포트폴리오를 열어 이용해 주세요.'),
          findsOneWidget,
        );
        await tester.tap(find.text('확인'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(printer.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      '${scenario.$1} Dock opens the shared printer without changing its height',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = scenario.$2;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final data = PortfolioData(
          identity: portfolioData.identity,
          experiences: const <PortfolioExperience>[],
          education: const <PortfolioEducation>[],
          skillGroups: const <PortfolioSkillGroup>[],
          projects: const <PortfolioProject>[],
        );
        final openedApps = <PortfolioAppId>[];

        await tester.pumpWidget(
          MaterialApp(
            theme: AppleTheme.light(),
            home: Scaffold(
              body: Center(
                child: AppleMobileDock(
                  data: data,
                  tablet: scenario.$3,
                  onOpen: openedApps.add,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final printer = find.byKey(const Key('mobile-dock-printer'));
        final shortcut = tester.widget<PortfolioPrinterShortcut>(
          find.byType(PortfolioPrinterShortcut),
        );
        expect(shortcut.data, same(data));
        expect(find.text('프린터'), findsNothing);
        expect(printer.hitTestable(), findsOneWidget);
        expect(
          tester.getSize(find.byKey(const Key('mobile-dock'))).height,
          closeTo(AppleMobileDockGeometry.height(tablet: scenario.$3), 0.1),
        );

        await tester.tap(printer);
        await tester.pumpAndSettle();

        expect(openedApps, isEmpty);
        expect(find.text('인쇄 화면을 열지 못했어요'), findsOneWidget);
        await tester.tap(find.text('확인'));
        await tester.pumpAndSettle();
        expect(printer.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
