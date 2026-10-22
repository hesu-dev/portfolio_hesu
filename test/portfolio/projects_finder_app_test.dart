import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/projects_app.dart';
import 'package:portfolio_hesu/portfolio/apps/safari_project_page.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/widgets/apple_finder_scaffold.dart';

void main() {
  group('Finder형 Projects 화면', () {
    testWidgets('회사 위치에서 분류된 폴더와 상세 뎁스를 탐색한다', (tester) async {
      await _pumpProjects(tester, size: const Size(900, 650));

      expect(find.byKey(const Key('projects-finder-toolbar')), findsOneWidget);
      expect(find.byKey(const Key('projects-finder-back')), findsOneWidget);
      expect(find.byKey(const Key('projects-finder-forward')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('projects-finder-current-location')),
          matching: find.text('회사'),
        ),
        findsOneWidget,
      );

      final sidebar = find.byKey(const Key('projects-finder-sidebar'));
      expect(sidebar, findsOneWidget);
      final orderedLabels = <String>[
        '최근 항목',
        '공유',
        '위치',
        'iCloud Drive',
        '데스크탑',
        '파일',
        '회사',
        '개인 프로젝트',
      ];
      var previousY = -1.0;
      for (final label in orderedLabels) {
        final item = find.descendant(of: sidebar, matching: find.text(label));
        expect(item, findsOneWidget, reason: label);
        final y = tester.getTopLeft(item).dy;
        expect(y, greaterThan(previousY), reason: '$label sidebar order');
        previousY = y;
      }

      final grid = find.byKey(const Key('projects-finder-grid'));
      expect(grid, findsOneWidget);
      final collectionScroll = find.byKey(
        const Key('projects-collection-scroll'),
      );
      expect(collectionScroll, findsOneWidget);
      expect(find.byKey(const Key('projects-detail-scroll')), findsNothing);
      expect(find.byKey(const Key('safari-project-title')), findsNothing);
      expect(
        tester.getSize(collectionScroll).height,
        closeTo(tester.getSize(sidebar).height, 1),
      );
      for (var index = 0; index < 6; index++) {
        expect(
          find.descendant(
            of: grid,
            matching: find.byKey(Key('projects-career-folder-$index')),
          ),
          findsOneWidget,
        );
      }
      expect(
        find.byKey(const Key('finder-file-portfolio-readme')),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('projects-career-folder-3')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('projects-finder-grid')), findsNothing);
      expect(find.byKey(const Key('projects-collection-scroll')), findsNothing);
      expect(find.byKey(const Key('projects-detail-scroll')), findsOneWidget);
      expect(find.byType(SafariProjectPage), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('safari-project-title'))).data,
        'IRIS',
      );

      await tester.tap(find.byKey(const Key('projects-finder-back')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AppleFinderFolderTile>(
              find.byKey(const Key('project-selector-5')),
            )
            .selected,
        isTrue,
      );
      expect(find.byKey(const Key('safari-project-title')), findsNothing);

      await tester.tap(find.byKey(const Key('projects-finder-forward')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('safari-project-title'))).data,
        'IRIS',
      );
    });

    testWidgets('iPad는 사이드바 없이 하단 탐색과 데스크톱형 전체 파일 목록을 표시한다', (tester) async {
      for (final contentWidth in const <double>[552, 696, 786]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProjects(
          tester,
          size: Size(contentWidth, 700),
          tablet: true,
        );

        expect(
          find.byKey(const Key('projects-finder-sidebar')),
          findsNothing,
          reason: '$contentWidth',
        );
        expect(
          find.byKey(const Key('projects-finder-locations')),
          findsNothing,
          reason: '$contentWidth',
        );
        expect(
          find.byKey(const Key('projects-finder-mobile-dock')),
          findsOneWidget,
          reason: '$contentWidth',
        );
        expect(
          find.byKey(const Key('projects-detail-scroll')),
          findsNothing,
          reason: '$contentWidth',
        );

        final grid = find.byKey(const Key('projects-finder-grid'));
        expect(grid, findsOneWidget, reason: '$contentWidth');
        for (var index = 0; index < 6; index++) {
          expect(
            find.descendant(
              of: grid,
              matching: find.byKey(Key('projects-career-folder-$index')),
            ),
            findsOneWidget,
          );
        }
        expect(
          find.descendant(
            of: grid,
            matching: find.byKey(const Key('finder-file-portfolio-readme')),
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull, reason: '$contentWidth');
      }
    });

    testWidgets('Projects 내부에는 가짜 traffic light 원을 다시 그리지 않는다', (tester) async {
      await _pumpProjects(tester, size: const Size(900, 650));

      const trafficColors = <Color>[
        Color(0xFFFF5F57),
        Color(0xFFFFBD2E),
        Color(0xFFFEBC2E),
        Color(0xFF28C840),
      ];
      final inlineTrafficLights = find.byWidgetPredicate((widget) {
        if (widget is! Container || widget.decoration is! BoxDecoration) {
          return false;
        }
        final decoration = widget.decoration! as BoxDecoration;
        return decoration.shape == BoxShape.circle &&
            trafficColors.contains(decoration.color);
      });

      expect(inlineTrafficLights, findsNothing);
    });

    testWidgets('좁은 iPhone은 2열 회사 목록에서 두 번째 AI Switch 상세를 연다', (tester) async {
      await _pumpProjects(
        tester,
        size: const Size(320, 480),
        compact: true,
        textScaler: const TextScaler.linear(2),
      );

      expect(find.byKey(const Key('projects-finder-toolbar')), findsOneWidget);
      expect(find.byKey(const Key('projects-finder-locations')), findsNothing);
      expect(find.byKey(const Key('projects-finder-sidebar')), findsNothing);
      expect(
        find.byKey(const Key('projects-finder-mobile-dock')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('projects-collection-scroll')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('projects-detail-scroll')), findsNothing);
      expect(find.byKey(const Key('safari-project-title')), findsNothing);

      final folders = <Finder>[
        for (var index = 0; index < 6; index++)
          find.byKey(Key('projects-career-folder-$index')),
      ];
      for (final folder in folders) {
        expect(tester.getSize(folder).width, 140);
        expect(tester.getRect(folder).left, greaterThanOrEqualTo(0));
        expect(tester.getRect(folder).right, lessThanOrEqualTo(320));
        final label = find.descendant(
          of: folder,
          matching: find.byKey(const Key('apple-finder-folder-label')),
        );
        expect(tester.widget<Text>(label).maxLines, 2);
        expect(tester.widget<Text>(label).overflow, TextOverflow.ellipsis);
      }
      expect(
        tester.getTopLeft(folders[0]).dy,
        closeTo(tester.getTopLeft(folders[1]).dy, 0.01),
      );
      expect(
        tester.getTopLeft(folders[2]).dy,
        greaterThan(tester.getTopLeft(folders[0]).dy),
      );
      expect(
        find.byKey(const Key('finder-file-portfolio-readme')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('projects-career-folder-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('projects-finder-grid')), findsNothing);
      expect(find.byKey(const Key('projects-detail-scroll')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('safari-project-title'))).data,
        'AI Switch',
      );
      expect(
        find.text('React와 TypeScript로 제작된 AI Switch 홈페이지 유지보수 업무입니다.'),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('safari-report-support')),
          matching: find.text('React'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('safari-report-support')),
          matching: find.text('TypeScript'),
        ),
        findsOneWidget,
      );
      expect(find.text('React·TypeScript 기반 홈페이지 유지보수'), findsOneWidget);
      expect(find.byKey(const Key('safari-project-link-0')), findsOneWidget);
      expect(find.byType(SafariProjectPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('넓은 iPhone은 열 너비를 균등하게 나눠 가용 폭을 채운다', (tester) async {
      for (final scenario in const <({double width, int columns})>[
        (width: 448, columns: 3),
        (width: 590, columns: 4),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProjects(
          tester,
          size: Size(scenario.width, 700),
          compact: true,
        );

        final folders = <Finder>[
          for (var index = 0; index < 6; index++)
            find.byKey(Key('projects-career-folder-$index')),
        ];
        final availableWidth = scenario.width - 32;
        final expectedTileWidth =
            (availableWidth - 8 * (scenario.columns - 1)) / scenario.columns;
        for (final folder in folders) {
          expect(
            tester.getSize(folder).width,
            closeTo(expectedTileWidth, 0.01),
            reason: '${scenario.width}',
          );
        }
        final firstRowY = tester.getTopLeft(folders.first).dy;
        for (final folder in folders.take(scenario.columns)) {
          expect(
            tester.getTopLeft(folder).dy,
            closeTo(firstRowY, 0.01),
            reason: '${scenario.width}',
          );
        }
        if (scenario.columns < folders.length) {
          expect(
            tester.getTopLeft(folders[scenario.columns]).dy,
            greaterThan(firstRowY),
            reason: '${scenario.width}',
          );
        }
        expect(tester.takeException(), isNull, reason: '${scenario.width}');
      }
    });

    testWidgets('desktop 창의 좁은 regular 본문도 같은 고정 폭과 간격으로 배치한다', (tester) async {
      await _pumpProjects(tester, size: const Size(766, 600));

      expect(
        find.byKey(const Key('projects-collection-scroll')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('projects-detail-scroll')), findsNothing);
      expect(find.byKey(const Key('safari-project-title')), findsNothing);

      final folders = <Finder>[
        for (var index = 0; index < 6; index++)
          find.byKey(Key('projects-career-folder-$index')),
      ];

      for (final folder in folders) {
        expect(
          tester.getSize(folder).width,
          112,
          reason: 'all Finder layouts share one dense folder width',
        );
      }

      final rowStarts = folders
          .map((folder) => tester.getTopLeft(folder).dy.round())
          .toSet();
      expect(rowStarts.length, greaterThan(1));
      expect(
        find.byKey(const Key('finder-file-portfolio-readme')),
        findsNothing,
      );

      final firstFolder = folders.first;
      final firstLabel = find.descendant(
        of: firstFolder,
        matching: find.byKey(const Key('apple-finder-folder-label')),
      );
      final secondFolder = folders[1];
      final secondLabel = find.descendant(
        of: secondFolder,
        matching: find.byKey(const Key('apple-finder-folder-label')),
      );
      expect(tester.widget<Text>(firstLabel).maxLines, 2);
      expect(tester.widget<Text>(firstLabel).overflow, TextOverflow.ellipsis);
      expect(
        tester.getTopLeft(firstLabel).dy,
        closeTo(tester.getTopLeft(secondLabel).dy, 0.01),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('폴더 상세는 Safari 프로젝트 리포트를 공통으로 사용한다', (tester) async {
      await _pumpProjects(
        tester,
        size: const Size(1200, 1600),
        data: _caseStudyData,
      );
      await tester.tap(find.byKey(const Key('projects-career-folder-0')));
      await tester.pumpAndSettle();

      final report = tester.widget<SafariProjectPage>(
        find.byType(SafariProjectPage),
      );
      expect(report.project, same(_caseStudyData.projects.single));
      expect(find.byKey(const Key('projects-detail-scroll')), findsOneWidget);
      expect(find.byKey(const Key('safari-toolbar')), findsNothing);
      expect(find.byKey(const Key('project-introduction')), findsNothing);
      expect(find.byKey(const Key('safari-project-link-0')), findsOneWidget);
      expect(find.text('Case study overview'), findsOneWidget);
      for (final heading in [
        '프로젝트 구조',
        '담당 업무 · 기여',
        'Troubleshooting',
        '기술 스택',
      ]) {
        expect(find.text(heading), findsOneWidget);
      }
      for (final section in _caseStudyData.projects.single.sections) {
        expect(find.text(section.body), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('프로젝트 목록의 아이콘과 선택한 리포트 데이터가 연결된다', (tester) async {
      await _pumpProjects(tester, size: const Size(900, 900));
      for (final (index, asset) in <(int, String)>[
        (2, 'assets/icons/projects/aiq.png'),
        (4, 'assets/icons/projects/blue-mentor.png'),
        (5, 'assets/icons/projects/iris.svg'),
      ]) {
        final tile = find.byKey(Key('project-selector-$index'));
        expect(
          find.descendant(
            of: tile,
            matching: find.byIcon(Icons.folder_rounded),
          ),
          findsNothing,
        );
        await tester.tap(tile);
        await tester.pumpAndSettle();
        final report = tester.widget<SafariProjectPage>(
          find.byType(SafariProjectPage),
        );
        expect(report.project, same(portfolioData.projects[index]));
        expect(report.project.appIconAsset, asset);
        expect(find.byKey(const Key('architecture-diagram')), findsOneWidget);
        await tester.tap(find.byKey(const Key('projects-finder-back')));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('좁은 Finder는 긴 리포트와 빈 메타데이터를 확대해도 잘리지 않는다', (tester) async {
      for (final data in [
        _minimalCaseStudyData,
        _stressCaseStudyData,
        _emptyTechnologyData,
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProjects(
          tester,
          size: const Size(320, 900),
          compact: true,
          textScaler: const TextScaler.linear(2),
          theme: AppleTheme.dark(),
          data: data,
        );
        await tester.tap(find.byKey(const Key('projects-career-folder-0')));
        await tester.pumpAndSettle();
        expect(find.byType(SafariProjectPage), findsOneWidget);
        expect(find.text(data.projects.single.description), findsOneWidget);
        final main = tester.getRect(
          find.byKey(const Key('safari-report-main')),
        );
        final support = tester.getRect(
          find.byKey(const Key('safari-report-support')),
        );
        expect(main.top, greaterThanOrEqualTo(support.bottom));
        if (data.projects.single.technologies.every(
          (item) => item.trim().isEmpty,
        )) {
          expect(find.text('등록된 기술 스택이 없습니다.'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('넓은 Finder는 820px 제한 없이 리포트와 보조 정보를 나란히 표시한다', (tester) async {
      await _pumpProjects(
        tester,
        size: const Size(1500, 1600),
        data: _caseStudyData,
      );
      await tester.tap(find.byKey(const Key('projects-career-folder-0')));
      await tester.pumpAndSettle();
      final page = tester.getRect(find.byKey(const Key('safari-project-page')));
      final main = tester.getRect(find.byKey(const Key('safari-report-main')));
      final support = tester.getRect(
        find.byKey(const Key('safari-report-support')),
      );
      expect(page.width, greaterThan(900));
      expect(support.left, greaterThan(main.right));
      expect(support.top, closeTo(main.top, 0.01));
      expect(tester.takeException(), isNull);
    });

    testWidgets('스크린리더는 공통 리포트 제목과 링크를 읽는다', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpProjects(
        tester,
        size: const Size(1500, 1600),
        data: _caseStudyData,
      );
      await tester.tap(find.byKey(const Key('projects-career-folder-0')));
      await tester.pumpAndSettle();
      expect(
        tester
            .getSemantics(find.byKey(const Key('safari-project-title')))
            .getSemanticsData()
            .flagsCollection
            .isHeader,
        isTrue,
      );
      final link = find.byKey(const Key('safari-project-link-0'));
      await tester.ensureVisible(link);
      final action = tester.getSemantics(link).getSemanticsData();
      expect(action.label, contains('App Store'));
      expect(action.flagsCollection.isButton, isTrue);
      semantics.dispose();
    });

    testWidgets('구성 요소 리포트는 선형 흐름으로 오해할 화살표를 그리지 않는다', (tester) async {
      await _pumpProjects(
        tester,
        size: const Size(900, 1200),
        data: _componentCaseStudyData,
      );
      await tester.tap(find.byKey(const Key('projects-career-folder-0')));
      await tester.pumpAndSettle();
      expect(find.text('Flutter\nAuth\nCloud API\nStorage'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
      expect(find.byIcon(Icons.arrow_downward_rounded), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AI 역량 검사 폴더에서 화면을 확대하고 상세로 돌아온다', (tester) async {
      for (final size in <Size>[const Size(320, 760), const Size(900, 900)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProjects(
          tester,
          size: size,
          compact: size.width < 600,
          textScaler: const TextScaler.linear(2),
        );
        final folder = find.byKey(const Key('projects-career-folder-0'));
        await tester.ensureVisible(folder);
        await tester.tap(folder);
        await tester.pumpAndSettle();

        expect(
          tester
              .widget<Text>(find.byKey(const Key('safari-project-title')))
              .data,
          'AI 역량 검사',
        );
        expect(find.text('2026.08 - 2026.09'), findsOneWidget);
        expect(find.byKey(const Key('safari-project-link-0')), findsOneWidget);
        expect(find.text('프로젝트 화면'), findsOneWidget);
        for (var index = 0; index < 3; index++) {
          expect(
            find.byKey(Key('safari-project-screenshot-$index')),
            findsOneWidget,
          );
        }

        final screenshot = find.byKey(const Key('safari-project-screenshot-0'));
        await tester.ensureVisible(screenshot);
        await tester.pumpAndSettle();
        await tester.tap(screenshot);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('safari-project-screenshot-preview')),
          findsOneWidget,
        );
        expect(find.byType(InteractiveViewer), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.byTooltip('닫기'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('safari-project-screenshot-preview')),
          findsNothing,
        );
        expect(find.byKey(const Key('safari-project-title')), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}

final class _FakeExternalLauncher implements ExternalLauncher {
  @override
  Future<bool> launch(Uri uri) async => true;
}

Future<void> _pumpProjects(
  WidgetTester tester, {
  required Size size,
  bool compact = false,
  bool tablet = false,
  TextScaler textScaler = TextScaler.noScaling,
  ThemeData? theme,
  PortfolioData data = portfolioData,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppleTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: SizedBox.expand(
          child: ProjectsApp(
            data: data,
            launcher: _FakeExternalLauncher(),
            compact: compact,
            tablet: tablet,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.tap(find.byKey(const Key('projects-finder-location-career')));
  await tester.pumpAndSettle();
}

const PortfolioIdentity _testIdentity = PortfolioIdentity(
  name: '테스트 사용자',
  englishName: 'Test User',
  email: 'test@example.com',
  githubUrl: 'https://example.com',
  headline: '테스트 헤드라인',
  biography: '테스트 소개',
);

const PortfolioData _caseStudyData = PortfolioData.constant(
  identity: _testIdentity,
  experiences: <PortfolioExperience>[],
  education: <PortfolioEducation>[],
  skillGroups: <PortfolioSkillGroup>[],
  projects: <PortfolioProject>[
    PortfolioProject.constant(
      title: 'Case Study Project',
      description: 'Case study overview',
      period: '2026.02 - 2026.05',
      technologies: <String>['Flutter', 'Dart'],
      links: <PortfolioProjectLink>[
        PortfolioProjectLink(
          label: 'App Store',
          url: 'https://example.com/app-store',
        ),
      ],
      highlights: <String>['첫 번째 핵심 포인트', '두 번째 핵심 포인트'],
      architecture: PortfolioProjectArchitecture.constant(
        title: '시스템 아키텍처',
        description: '클라이언트 요청이 서비스와 데이터 저장소로 이동합니다.',
        presentation: PortfolioArchitecturePresentation.flow,
        nodes: <String>['Client app', 'Service API', 'Database'],
      ),
      sections: <PortfolioProjectSection>[
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.work,
          body: '제품 설계와 구현을 담당했습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.problem,
          body: '사용자 흐름이 단절되어 있었습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.cause,
          body: '데이터와 화면의 책임이 섞여 있었습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.measurement,
          body: '완료 기준을 배포 가능한 사용자 흐름으로 정했습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.solution,
          body: '기능별 책임을 분리했습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.evaluation,
          body: '핵심 흐름을 하나의 제품으로 연결했습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.note,
          body: '공개 링크에서 결과를 확인할 수 있습니다.',
        ),
      ],
    ),
  ],
);

const PortfolioData _minimalCaseStudyData = PortfolioData.constant(
  identity: _testIdentity,
  experiences: <PortfolioExperience>[],
  education: <PortfolioEducation>[],
  skillGroups: <PortfolioSkillGroup>[],
  projects: <PortfolioProject>[
    PortfolioProject.constant(
      title: 'Minimal Case Study',
      description: 'Minimal overview',
      period: '2025',
      technologies: <String>['Flutter'],
      links: <PortfolioProjectLink>[
        PortfolioProjectLink(
          label: 'Google Play',
          url: 'https://example.com/google-play',
        ),
      ],
      highlights: <String>['검증된 핵심 포인트'],
      sections: <PortfolioProjectSection>[
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.work,
          body: '검증된 업무 내용만 표시합니다.',
        ),
      ],
    ),
  ],
);

const PortfolioData _componentCaseStudyData = PortfolioData.constant(
  identity: _testIdentity,
  experiences: <PortfolioExperience>[],
  education: <PortfolioEducation>[],
  skillGroups: <PortfolioSkillGroup>[],
  projects: <PortfolioProject>[
    PortfolioProject.constant(
      title: 'Component architecture',
      description: 'Branched system responsibilities',
      period: '2026',
      technologies: <String>['Flutter'],
      links: <PortfolioProjectLink>[],
      architecture: PortfolioProjectArchitecture.constant(
        title: '시스템 구성 요소',
        description: '서로 다른 책임을 가진 구성 요소입니다.',
        nodes: <String>['Flutter', 'Auth', 'Cloud API', 'Storage'],
      ),
    ),
  ],
);

const PortfolioData _stressCaseStudyData = PortfolioData.constant(
  identity: _testIdentity,
  experiences: <PortfolioExperience>[],
  education: <PortfolioEducation>[],
  skillGroups: <PortfolioSkillGroup>[],
  projects: <PortfolioProject>[
    PortfolioProject.constant(
      title: 'ReadingLog long content',
      description: '채팅 로그 리더기 앱과 파싱용 Chrome 확장 프로그램',
      period: '2026.02 - 2026.05',
      technologies: <String>['Flutter', 'Dart', 'JavaScript'],
      links: <PortfolioProjectLink>[
        PortfolioProjectLink(
          label: 'Google Play',
          url: 'https://example.com/1',
        ),
        PortfolioProjectLink(label: 'App Store', url: 'https://example.com/2'),
        PortfolioProjectLink(
          label: 'Chrome Web Store',
          url: 'https://example.com/3',
        ),
      ],
      highlights: <String>[
        '모바일 앱과 파싱용 Chrome 확장 프로그램을 함께 기획·개발',
        '세 개의 공개 배포 채널에서 결과물을 확인',
      ],
      architecture: PortfolioProjectArchitecture.constant(
        title: '로그 추출부터 모바일 열람까지',
        description: '브라우저에서 내보낸 로그를 모바일 앱에서 읽습니다.',
        presentation: PortfolioArchitecturePresentation.flow,
        nodes: <String>['채팅 로그', 'Chrome 확장', 'JSON 내보내기', 'ReadingLog 앱'],
      ),
      sections: <PortfolioProjectSection>[
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.work,
          body: '앱과 확장 프로그램을 함께 기획하고 개발했습니다.',
        ),
      ],
    ),
  ],
);

const PortfolioData _emptyTechnologyData = PortfolioData.constant(
  identity: _testIdentity,
  experiences: <PortfolioExperience>[],
  education: <PortfolioEducation>[],
  skillGroups: <PortfolioSkillGroup>[],
  projects: <PortfolioProject>[
    PortfolioProject.constant(
      title: 'No technology',
      description: '검증된 업무 내용',
      period: '설계 중',
      technologies: <String>['   '],
      links: <PortfolioProjectLink>[],
    ),
  ],
);
