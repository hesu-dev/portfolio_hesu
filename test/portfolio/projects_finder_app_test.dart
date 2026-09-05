import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/projects_app.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/widgets/apple_finder_scaffold.dart';

void main() {
  group('Finder형 Projects 화면', () {
    testWidgets('기본 회사 위치에서 분류된 폴더와 상세 뎁스를 탐색한다', (tester) async {
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
      expect(find.byKey(const Key('project-detail-title')), findsNothing);
      expect(
        tester.getSize(collectionScroll).height,
        closeTo(tester.getSize(sidebar).height, 1),
      );
      for (var index = 0; index < 4; index++) {
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

      await tester.tap(find.byKey(const Key('projects-career-folder-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('projects-finder-grid')), findsNothing);
      expect(find.byKey(const Key('projects-collection-scroll')), findsNothing);
      expect(find.byKey(const Key('projects-detail-scroll')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('project-detail-title'))).data,
        'IRIS',
      );

      await tester.tap(find.byKey(const Key('projects-finder-back')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AppleFinderFolderTile>(
              find.byKey(const Key('project-selector-3')),
            )
            .selected,
        isTrue,
      );
      expect(find.byKey(const Key('project-detail-title')), findsNothing);

      await tester.tap(find.byKey(const Key('projects-finder-forward')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('project-detail-title'))).data,
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
        for (var index = 0; index < 4; index++) {
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

    testWidgets('좁은 iPhone은 가용 폭을 채운 2열과 별도 상세 뎁스를 스크롤한다', (tester) async {
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
      expect(find.byKey(const Key('project-detail-title')), findsNothing);

      final folders = <Finder>[
        for (var index = 0; index < 4; index++)
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
      expect(find.byKey(const Key('project-link-3-0')), findsOneWidget);
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
          for (var index = 0; index < 4; index++)
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
      expect(find.byKey(const Key('project-detail-title')), findsNothing);

      final folders = <Finder>[
        for (var index = 0; index < 4; index++)
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

    testWidgets('상세는 연도와 액션부터 문제 해결 서사까지 요청 순서로 표시한다', (tester) async {
      await _pumpProjects(
        tester,
        size: const Size(1024, 1600),
        data: _caseStudyData,
      );

      await tester.tap(find.byKey(const Key('projects-career-folder-0')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('project-detail-year')), findsOneWidget);
      expect(find.text('2026'), findsOneWidget);
      expect(find.byKey(const Key('project-detail-title')), findsOneWidget);
      expect(find.byKey(const Key('project-actions')), findsOneWidget);
      expect(find.byKey(const Key('project-link-0-0')), findsOneWidget);
      expect(find.byKey(const Key('project-technologies')), findsOneWidget);
      expect(find.text('#Flutter'), findsOneWidget);
      expect(find.text('#Dart'), findsOneWidget);
      expect(find.byKey(const Key('project-architecture')), findsOneWidget);
      expect(find.text('Client app'), findsOneWidget);
      expect(find.text('Service API'), findsOneWidget);
      expect(find.byKey(const Key('project-highlights')), findsOneWidget);

      final orderedKeys = <Key>[
        const Key('project-detail-header'),
        const Key('project-actions'),
        const Key('project-technologies'),
        const Key('project-architecture'),
        const Key('project-highlights'),
        const Key('project-narrative'),
      ];
      var previousTop = double.negativeInfinity;
      for (final key in orderedKeys) {
        final finder = find.byKey(key);
        expect(finder, findsOneWidget, reason: key.toString());
        final top = tester.getTopLeft(finder).dy;
        expect(top, greaterThan(previousTop), reason: key.toString());
        previousTop = top;
      }

      for (final kind in PortfolioProjectSectionKind.values) {
        final section = find.byKey(Key('project-section-${kind.name}'));
        expect(section, findsOneWidget, reason: kind.label);
        expect(
          find.descendant(of: section, matching: find.text(kind.label)),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('좁은 화면은 서사 라벨과 본문을 세로로 쌓고 빈 항목은 숨긴다', (tester) async {
      await _pumpProjects(
        tester,
        size: const Size(320, 900),
        compact: true,
        textScaler: const TextScaler.linear(2),
        data: _minimalCaseStudyData,
      );

      await tester.tap(find.byKey(const Key('projects-career-folder-0')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('project-section-work')));
      await tester.pumpAndSettle();

      final label = find.byKey(const Key('project-section-work-label'));
      final body = find.byKey(const Key('project-section-work-body'));
      expect(label, findsOneWidget);
      expect(body, findsOneWidget);
      expect(
        tester.getRect(body).top,
        greaterThanOrEqualTo(tester.getRect(label).bottom),
      );
      expect(find.byKey(const Key('project-section-problem')), findsNothing);
      expect(find.byKey(const Key('project-architecture')), findsNothing);
      expect(find.byKey(const Key('project-highlights')), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('project-link-0-0'))).height,
        greaterThanOrEqualTo(44),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('기본 데스크톱 Finder 폭은 아키텍처와 서사를 가로로 읽는다', (tester) async {
      await _pumpProjects(
        tester,
        size: const Size(900, 1400),
        data: _caseStudyData,
      );

      await tester.tap(find.byKey(const Key('projects-career-folder-0')));
      await tester.pumpAndSettle();

      final firstNode = tester.getRect(
        find.byKey(const Key('project-architecture-node-0')),
      );
      final secondNode = tester.getRect(
        find.byKey(const Key('project-architecture-node-1')),
      );
      expect(secondNode.left, greaterThan(firstNode.right));
      expect(secondNode.top, closeTo(firstNode.top, 0.01));

      final label = tester.getRect(
        find.byKey(const Key('project-section-work-label')),
      );
      final body = tester.getRect(
        find.byKey(const Key('project-section-work-body')),
      );
      expect(body.left, greaterThan(label.right));
      expect(body.top, closeTo(label.top, 0.01));
      expect(tester.takeException(), isNull);
    });

    testWidgets('스크린리더에는 헤더·태그·액션을 중복 없이 전달한다', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpProjects(
        tester,
        size: const Size(1024, 1600),
        data: _caseStudyData,
      );

      await tester.tap(find.byKey(const Key('projects-career-folder-0')));
      await tester.pumpAndSettle();

      expect(
        tester
            .getSemantics(find.byKey(const Key('project-detail-year')))
            .getSemanticsData()
            .label,
        '프로젝트 시작 연도 2026',
      );
      expect(
        tester
            .getSemantics(find.byKey(const Key('project-actions-heading')))
            .getSemanticsData()
            .flagsCollection
            .isHeader,
        isTrue,
      );
      expect(
        tester
            .getSemantics(find.byKey(const Key('project-technologies-heading')))
            .getSemanticsData()
            .flagsCollection
            .isHeader,
        isTrue,
      );
      expect(
        tester
            .getSemantics(find.byKey(const Key('project-technology-0')))
            .getSemanticsData()
            .label,
        '사용 기술 Flutter',
      );
      final action = tester
          .getSemantics(find.byKey(const Key('project-link-0-0')))
          .getSemanticsData();
      expect(action.label, 'App Store');
      expect(action.flagsCollection.isButton, isTrue);
      expect(
        find.bySemanticsLabel('Case Study Project App Store 새 탭에서 열기'),
        findsNothing,
      );
      semantics.dispose();
    });

    testWidgets('구성 요소는 선형 흐름으로 오해할 화살표를 그리지 않는다', (tester) async {
      await _pumpProjects(
        tester,
        size: const Size(900, 1200),
        data: _componentCaseStudyData,
      );

      await tester.tap(find.byKey(const Key('projects-career-folder-0')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
      expect(find.byIcon(Icons.arrow_downward_rounded), findsNothing);
      expect(
        find.byKey(const Key('project-architecture-node-3')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('실제 긴 콘텐츠는 다크 모드·200% 확대에서도 잘리지 않는다', (tester) async {
      await _pumpProjects(
        tester,
        size: const Size(320, 900),
        compact: true,
        textScaler: const TextScaler.linear(2),
        theme: AppleTheme.dark(),
        data: _stressCaseStudyData,
      );

      await tester.tap(find.byKey(const Key('projects-career-folder-0')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('project-highlight-index-0')),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .getSize(find.byKey(const Key('project-highlight-index-0')))
            .height,
        greaterThan(24),
      );
      expect(find.byKey(const Key('project-link-0-2')), findsOneWidget);
      expect(
        find.byKey(const Key('project-architecture-node-3')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('빈 기술 메타데이터는 제목만 남은 카드를 만들지 않는다', (tester) async {
      await _pumpProjects(
        tester,
        size: const Size(900, 900),
        data: _emptyTechnologyData,
      );

      await tester.tap(find.byKey(const Key('projects-career-folder-0')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('project-technologies')), findsNothing);
      expect(find.text('#'), findsNothing);
    });

    testWidgets('핵심 강조색은 라이트·다크 배경에서 텍스트 대비를 보장한다', (tester) async {
      for (final theme in <ThemeData>[AppleTheme.light(), AppleTheme.dark()]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProjects(
          tester,
          size: const Size(900, 1000),
          theme: theme,
          data: _caseStudyData,
        );
        await tester.tap(find.byKey(const Key('projects-career-folder-0')));
        await tester.pumpAndSettle();

        final year = tester.widget<Container>(
          find.byKey(const Key('project-detail-year')),
        );
        final gradient = (year.decoration! as BoxDecoration).gradient!;
        for (final color in gradient.colors) {
          expect(
            _contrastRatio(Colors.white, color),
            greaterThanOrEqualTo(4.5),
          );
        }

        final label = tester.widget<Text>(
          find.byKey(const Key('project-section-work-label')),
        );
        final surface = theme.brightness == Brightness.dark
            ? const Color(0xFF1C1D21)
            : Colors.white;
        expect(
          _contrastRatio(label.style!.color!, surface),
          greaterThanOrEqualTo(4.5),
        );
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
}

double _contrastRatio(Color first, Color second) {
  final lighter = first.computeLuminance() > second.computeLuminance()
      ? first.computeLuminance()
      : second.computeLuminance();
  final darker = first.computeLuminance() > second.computeLuminance()
      ? second.computeLuminance()
      : first.computeLuminance();
  return (lighter + 0.05) / (darker + 0.05);
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
