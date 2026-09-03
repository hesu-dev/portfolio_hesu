import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/projects_app.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';
import 'package:portfolio_hesu/portfolio/portfolio_app.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/widgets/apple_finder_scaffold.dart';

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

        final recent = find.byKey(const Key('projects-finder-location-recent'));
        expect(recent, findsOneWidget);
        await tester.tap(recent);
        await tester.pumpAndSettle();

        expect(_toolbarTitle(tester), '최근 항목');
        for (var index = 0; index < portfolioData.projects.length; index++) {
          expect(
            find.byKey(Key('projects-recent-folder-$index')),
            findsOneWidget,
          );
        }
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

    testWidgets('개인 프로젝트의 긴 폴더 제목은 iPad에서도 두 줄로 개행된다', (tester) async {
      await _pumpProjects(tester, size: const Size(834, 700), tablet: true);

      await tester.tap(
        find.byKey(const Key('projects-finder-location-personal-projects')),
      );
      await tester.pumpAndSettle();

      final readingLog = find.text('ReadingLog');
      final personaChat = find.text('PersonaChat AI Character Chat');
      expect(
        tester.getTopLeft(readingLog).dx,
        lessThan(tester.getTopLeft(personaChat).dx),
      );
      expect(tester.getSize(personaChat).height, greaterThan(20));
    });

    testWidgets(
      'iPhone and iPad share recent, career, and personal bottom navigation',
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

          final dock = find.byKey(const Key('projects-finder-mobile-dock'));
          expect(dock, findsOneWidget, reason: '${scenario.size}');
          expect(
            find.byKey(const Key('projects-finder-sidebar')),
            findsNothing,
          );
          expect(
            find.byKey(const Key('projects-finder-locations')),
            findsNothing,
          );
          for (final label in const <String>['최근 항목', '경력', '개인']) {
            expect(
              find.descendant(of: dock, matching: find.text(label)),
              findsOneWidget,
              reason: '${scenario.size} $label',
            );
          }
          expect(
            find.descendant(of: dock, matching: find.text('공유')),
            findsNothing,
          );
          expect(
            find.descendant(of: dock, matching: find.text('iCloud Drive')),
            findsNothing,
          );
          expect(
            find.descendant(of: dock, matching: find.text('데스크탑')),
            findsNothing,
          );

          expect(
            _isSelected(tester, const Key('projects-finder-location-career')),
            isTrue,
          );

          await tester.tap(
            find.byKey(const Key('projects-finder-location-recent')),
          );
          await tester.pumpAndSettle();
          expect(_toolbarTitle(tester), '최근 항목');
          for (var index = 0; index < portfolioData.projects.length; index++) {
            expect(
              find.byKey(Key('projects-recent-folder-$index')),
              findsOneWidget,
            );
          }

          await tester.tap(
            find.byKey(const Key('projects-finder-location-personal-projects')),
          );
          await tester.pumpAndSettle();
          expect(_toolbarTitle(tester), '개인 프로젝트');
          expect(
            find.byKey(const Key('projects-personal-projects-folder-0')),
            findsOneWidget,
          );
          expect(find.text('ReadingLog'), findsOneWidget);
          expect(tester.takeException(), isNull, reason: '${scenario.size}');
        }
      },
    );

    testWidgets('iPhone and iPad Finder chrome follows light and dark themes', (
      tester,
    ) async {
      for (final scenario in const <({Size size, bool compact, bool tablet})>[
        (size: Size(390, 700), compact: true, tablet: false),
        (size: Size(834, 700), compact: false, tablet: true),
      ]) {
        final toolbarColors = <Brightness, Color>{};
        final dockColors = <Brightness, Color>{};

        for (final brightness in Brightness.values) {
          await tester.pumpWidget(const SizedBox.shrink());
          await _pumpProjects(
            tester,
            size: scenario.size,
            compact: scenario.compact,
            tablet: scenario.tablet,
            brightness: brightness,
          );

          final toolbar = find.byKey(const Key('projects-finder-toolbar'));
          final toolbarDecoration =
              tester
                      .widgetList<DecoratedBox>(
                        find.descendant(
                          of: toolbar,
                          matching: find.byType(DecoratedBox),
                        ),
                      )
                      .first
                      .decoration
                  as BoxDecoration;
          final dockDecoration =
              tester
                      .widget<Container>(
                        find.byKey(const Key('projects-finder-mobile-dock')),
                      )
                      .decoration
                  as BoxDecoration;
          final title = tester.widget<Text>(
            find.descendant(
              of: find.byKey(const Key('projects-finder-current-location')),
              matching: find.text('경력'),
            ),
          );

          expect(Theme.of(tester.element(toolbar)).brightness, brightness);
          expect(
            _contrast(title.style!.color!, toolbarDecoration.color!),
            greaterThanOrEqualTo(4.5),
          );
          toolbarColors[brightness] = toolbarDecoration.color!;
          dockColors[brightness] = dockDecoration.color!;
          expect(
            tester.takeException(),
            isNull,
            reason: '$scenario $brightness',
          );
        }

        expect(
          toolbarColors[Brightness.light],
          isNot(toolbarColors[Brightness.dark]),
        );
        expect(
          dockColors[Brightness.light],
          isNot(dockColors[Brightness.dark]),
        );
      }
    });

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

    testWidgets('compact recent projects remain usable at 200% text', (
      tester,
    ) async {
      await _pumpProjects(
        tester,
        size: const Size(320, 480),
        compact: true,
        textScaler: const TextScaler.linear(2),
      );

      final recent = find.byKey(const Key('projects-finder-location-recent'));
      await tester.tap(recent);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('projects-finder-mobile-dock')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('projects-recent-folder-0')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mobile bottom navigation exposes stable selected semantics', (
      tester,
    ) async {
      await _pumpProjects(tester, size: const Size(320, 700), compact: true);
      await tester.pumpAndSettle();

      expect(
        _isSelected(tester, const Key('projects-finder-location-career')),
        isTrue,
      );
      await tester.tap(
        find.byKey(const Key('projects-finder-location-recent')),
      );
      await tester.pumpAndSettle();

      expect(
        _isSelected(tester, const Key('projects-finder-location-recent')),
        isTrue,
      );
      expect(
        _isSelected(tester, const Key('projects-finder-location-career')),
        isFalse,
      );
    });

    testWidgets('configured Finder selection uses a stable location id', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppleTheme.light(),
          home: AppleFinderScaffold(
            surfaceKey: const Key('stable-id-finder'),
            keyPrefix: 'stable-id',
            currentLocation: '중복 이름',
            selectedLocationId: 'second',
            ownerName: '테스트 사용자',
            locations: const <AppleFinderLocation>[
              AppleFinderLocation(
                id: 'first',
                label: '중복 이름',
                icon: Icons.folder_rounded,
              ),
              AppleFinderLocation(
                id: 'second',
                label: '중복 이름',
                icon: Icons.folder_rounded,
              ),
            ],
            onLocationSelected: (_) {},
            compact: false,
            tablet: false,
            canGoBack: false,
            canGoForward: false,
            onBack: () {},
            onForward: () {},
            bodyBuilder: (_, _) => const SizedBox(),
          ),
        ),
      );

      expect(
        _isSelected(tester, const Key('stable-id-finder-location-first')),
        isFalse,
      );
      expect(
        _isSelected(tester, const Key('stable-id-finder-location-second')),
        isTrue,
      );
    });

    testWidgets(
      'replacing PortfolioData resets detail history to career root',
      (tester) async {
        await _pumpProjects(
          tester,
          size: const Size(900, 650),
          data: _categorizedData(),
        );
        await tester.tap(find.byKey(const Key('projects-career-folder-0')));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<Text>(find.byKey(const Key('project-detail-title')))
              .data,
          'Career sample',
        );

        await _pumpProjects(
          tester,
          size: const Size(900, 650),
          data: _categorizedData(careerTitle: 'Reordered career'),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('project-detail-title')), findsNothing);
        expect(
          find.byKey(const Key('projects-collection-scroll')),
          findsOneWidget,
        );
        expect(_toolbarTitle(tester), '경력');
        expect(find.text('Reordered career'), findsOneWidget);
        expect(
          tester
              .widget<IconButton>(find.byKey(const Key('projects-finder-back')))
              .onPressed,
          isNull,
        );
      },
    );

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

bool _isSelected(WidgetTester tester, Key key) {
  return tester
          .getSemantics(find.byKey(key))
          .getSemanticsData()
          .flagsCollection
          .isSelected ==
      ui.Tristate.isTrue;
}

PortfolioData _categorizedData({String careerTitle = 'Career sample'}) {
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
      project(careerTitle, PortfolioProjectCategory.career),
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
  Brightness brightness = Brightness.light,
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
      darkTheme: AppleTheme.dark(),
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
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

double _contrast(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
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
