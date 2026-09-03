import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/projects_app.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';
import 'package:portfolio_hesu/portfolio/portfolio_app.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';

void main() {
  group('Projects Finder locations', () {
    testWidgets(
      'defaults to 경력 and keeps Finder shortcuts above four locations',
      (tester) async {
        await _pumpProjects(tester, size: const Size(900, 650));

        final sidebar = find.byKey(const Key('projects-finder-sidebar'));
        expect(sidebar, findsOneWidget);
        for (final label in const <String>[
          'iCloud Drive',
          '데스크탑',
          '경력',
          '개인 프로젝트',
        ]) {
          expect(
            find.descendant(of: sidebar, matching: find.text(label)),
            findsOneWidget,
            reason: label,
          );
        }
        expect(
          find.descendant(of: sidebar, matching: find.text('최근 항목')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: sidebar, matching: find.text('공유')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: sidebar, matching: find.text(portfolioData.name)),
          findsNothing,
        );
        expect(_toolbarTitle(tester), '경력');
        expect(
          tester
              .getSemantics(
                find.byKey(const Key('projects-finder-location-career')),
              )
              .getSemanticsData()
              .flagsCollection
              .isSelected,
          ui.Tristate.isTrue,
        );
      },
    );

    testWidgets(
      'iCloud Drive is empty and 데스크탑 reuses the shared app catalog',
      (tester) async {
        PortfolioAppId? openedApp;
        await _pumpProjects(
          tester,
          size: const Size(900, 650),
          onOpenApp: (appId) => openedApp = appId,
        );

        await tester.tap(
          find.byKey(const Key('projects-finder-location-icloud-drive')),
        );
        await tester.pumpAndSettle();
        expect(_toolbarTitle(tester), 'iCloud Drive');
        expect(find.byKey(const Key('projects-icloud-empty')), findsOneWidget);
        expect(
          find.byKey(const Key('projects-connection-directory')),
          findsNothing,
        );

        await tester.tap(
          find.byKey(const Key('projects-finder-location-desktop')),
        );
        await tester.pumpAndSettle();
        expect(_toolbarTitle(tester), '데스크탑');
        expect(
          find.byKey(const Key('projects-desktop-app-grid')),
          findsOneWidget,
        );
        for (final appId in portfolioLauncherAppIds) {
          expect(
            find.byKey(Key('projects-desktop-app-${appId.name}')),
            findsOneWidget,
            reason: appId.name,
          );
        }

        await tester.tap(
          find.byKey(Key('projects-desktop-app-${PortfolioAppId.mail.name}')),
        );
        await tester.pump();
        expect(openedApp, PortfolioAppId.mail);
      },
    );

    testWidgets('경력 and 개인 프로젝트 share one folder and detail component', (
      tester,
    ) async {
      final data = _categorizedData();
      await _pumpProjects(tester, size: const Size(900, 650), data: data);

      final commonDirectory = find.byKey(
        const Key('projects-connection-directory'),
      );
      expect(commonDirectory, findsOneWidget);
      final directoryType = tester.widget(commonDirectory).runtimeType;
      expect(find.text('Career sample'), findsOneWidget);
      expect(find.text('Personal sample'), findsNothing);
      expect(find.byKey(const Key('project-detail-title')), findsNothing);

      await tester.tap(
        find.byKey(const Key('projects-finder-location-personal-projects')),
      );
      await tester.pumpAndSettle();
      expect(_toolbarTitle(tester), '개인 프로젝트');
      expect(tester.widget(commonDirectory).runtimeType, directoryType);
      expect(find.text('Career sample'), findsNothing);
      expect(find.text('Personal sample'), findsOneWidget);

      final folder = find.byKey(
        const Key('projects-personal-projects-folder-0'),
      );
      await tester.tap(folder);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('projects-detail-scroll')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('project-detail-title'))).data,
        'Personal sample',
      );
      expect(find.text('Project overview'), findsOneWidget);

      await tester.tap(find.byKey(const Key('projects-finder-back')));
      await tester.pumpAndSettle();
      expect(
        tester
            .getSemantics(find.byKey(const Key('project-selector-1')))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        ui.Tristate.isTrue,
      );
    });

    testWidgets(
      'iPhone and iPad use the same location set and selection flow',
      (tester) async {
        for (final scenario in const <({Size size, bool compact, bool tablet})>[
          (size: Size(390, 700), compact: true, tablet: false),
          (size: Size(834, 700), compact: false, tablet: true),
        ]) {
          await tester.pumpWidget(const SizedBox.shrink());
          await _pumpProjects(
            tester,
            size: scenario.size,
            compact: scenario.compact,
            tablet: scenario.tablet,
          );

          final locationSurface = scenario.compact
              ? find.byKey(const Key('projects-finder-locations'))
              : find.byKey(const Key('projects-finder-sidebar'));
          expect(locationSurface, findsOneWidget, reason: '${scenario.size}');
          for (final shortcut in const <String>['최근 항목', '공유']) {
            expect(
              find.descendant(
                of: locationSurface,
                matching: find.text(shortcut),
              ),
              findsOneWidget,
              reason: '${scenario.size} $shortcut',
            );
          }
          for (final label in const <String>[
            'iCloud Drive',
            '데스크탑',
            '경력',
            '개인 프로젝트',
          ]) {
            expect(
              find.descendant(of: locationSurface, matching: find.text(label)),
              findsOneWidget,
              reason: '${scenario.size} $label',
            );
          }

          final desktopLocation = find.byKey(
            const Key('projects-finder-location-desktop'),
          );
          await tester.ensureVisible(desktopLocation);
          await tester.tap(desktopLocation);
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('projects-desktop-app-grid')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull, reason: '${scenario.size}');
        }
      },
    );

    testWidgets('Finder back and forward traverse location history', (
      tester,
    ) async {
      await _pumpProjects(tester, size: const Size(900, 650));

      await tester.tap(
        find.byKey(const Key('projects-finder-location-desktop')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('projects-finder-location-icloud-drive')),
      );
      await tester.pumpAndSettle();
      expect(_toolbarTitle(tester), 'iCloud Drive');

      await tester.tap(find.byKey(const Key('projects-finder-back')));
      await tester.pumpAndSettle();
      expect(_toolbarTitle(tester), '데스크탑');
      await tester.tap(find.byKey(const Key('projects-finder-back')));
      await tester.pumpAndSettle();
      expect(_toolbarTitle(tester), '경력');
      await tester.tap(find.byKey(const Key('projects-finder-forward')));
      await tester.pumpAndSettle();
      expect(_toolbarTitle(tester), '데스크탑');
    });

    testWidgets('compact iCloud empty state remains usable at 200% text', (
      tester,
    ) async {
      await _pumpProjects(
        tester,
        size: const Size(320, 480),
        compact: true,
        textScaler: const TextScaler.linear(2),
      );

      final iCloudLocation = find.byKey(
        const Key('projects-finder-location-icloud-drive'),
      );
      await tester.ensureVisible(iCloudLocation);
      await tester.tap(iCloudLocation);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projects-icloud-empty')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('데스크탑 app shortcuts open apps from iPhone and iPad shells', (
      tester,
    ) async {
      for (final size in const <Size>[Size(390, 700), Size(834, 700)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpPortfolio(tester, size: size);

        await tester.tap(find.byKey(const Key('home-app-projects')));
        await tester.pumpAndSettle();
        final desktopLocation = find.byKey(
          const Key('projects-finder-location-desktop'),
        );
        await tester.ensureVisible(desktopLocation);
        await tester.tap(desktopLocation);
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(Key('projects-desktop-app-${PortfolioAppId.mail.name}')),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('mail-app')), findsOneWidget);
        expect(find.byKey(const Key('projects-app')), findsNothing);
        expect(tester.takeException(), isNull, reason: '$size');
      }
    });

    testWidgets('데스크탑 app shortcuts open another macOS window', (tester) async {
      await _pumpPortfolio(tester, size: const Size(1280, 720));

      final projectsIcon = find.byKey(const Key('desktop-app-projects'));
      await tester.tap(projectsIcon);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(projectsIcon);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('projects-finder-location-desktop')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(Key('projects-desktop-app-${PortfolioAppId.mail.name}')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mac-window-projects')), findsOneWidget);
      expect(find.byKey(const Key('mac-window-mail')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

String _toolbarTitle(WidgetTester tester) {
  final title = find.descendant(
    of: find.byKey(const Key('projects-finder-current-location')),
    matching: find.byType(Text),
  );
  return tester.widget<Text>(title).data!;
}

PortfolioData _categorizedData() {
  PortfolioProject project(String title, PortfolioProjectCategory category) {
    return PortfolioProject(
      title: title,
      description: 'Unused detail',
      period: '2026',
      technologies: const <String>['Flutter'],
      links: const <PortfolioProjectLink>[],
      category: category,
    );
  }

  return PortfolioData(
    identity: portfolioData.identity,
    experiences: portfolioData.experiences,
    education: portfolioData.education,
    skillGroups: portfolioData.skillGroups,
    projects: <PortfolioProject>[
      project('Career sample', PortfolioProjectCategory.career),
      project('Personal sample', PortfolioProjectCategory.personal),
    ],
  );
}

Future<void> _pumpProjects(
  WidgetTester tester, {
  required Size size,
  PortfolioData data = portfolioData,
  bool compact = false,
  bool tablet = false,
  TextScaler textScaler = TextScaler.noScaling,
  ValueChanged<PortfolioAppId>? onOpenApp,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(size: size, textScaler: textScaler),
        child: SizedBox.expand(
          child: ProjectsApp(
            data: data,
            launcher: const _FakeExternalLauncher(),
            compact: compact,
            tablet: tablet,
            onOpenApp: onOpenApp,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpPortfolio(WidgetTester tester, {required Size size}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: size),
      child: const PortfolioApp(externalLauncher: _FakeExternalLauncher()),
    ),
  );
  await tester.pump();
}

final class _FakeExternalLauncher implements ExternalLauncher {
  const _FakeExternalLauncher();

  @override
  Future<bool> launch(Uri uri) async => true;
}
