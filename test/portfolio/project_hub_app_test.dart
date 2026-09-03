import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/projects_app.dart';
import 'package:portfolio_hesu/portfolio/apps/system_apps.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/macos/mac_menu_bar.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/widgets/apple_app_artwork.dart';
import 'package:portfolio_hesu/portfolio/widgets/apple_app_icon.dart';
import 'package:portfolio_hesu/portfolio/widgets/apple_finder_scaffold.dart';

void main() {
  test('uses the exact project label and a project-hub glyph', () {
    expect(AppleAppIcon.labelFor(PortfolioAppId.thisMac), '프로젝트');
    expect(
      AppleAppArtwork.utilityIconFor(PortfolioAppId.thisMac),
      Icons.folder_copy_rounded,
    );
    expect(
      AppleAppArtwork.utilityIconFor(PortfolioAppId.thisMac),
      isNot(Icons.laptop_mac_rounded),
    );
  });

  testWidgets('system menu opens the project hub with Korean wording', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppleTheme.light(),
        home: Material(
          child: MacSystemMenuPanel(
            identityName: '테스트 사용자',
            onOpenAbout: () {},
            onOpenThisMac: () => opened = true,
          ),
        ),
      ),
    );

    final projectAction = find.byKey(const Key('system-menu-this-mac'));
    expect(
      find.descendant(of: projectAction, matching: find.text('프로젝트 열기')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: projectAction,
        matching: find.byIcon(Icons.folder_copy_rounded),
      ),
      findsOneWidget,
    );

    await tester.tap(projectAction);
    expect(opened, isTrue);
  });

  testWidgets('Projects and project hub share the Finder widget hierarchy', (
    tester,
  ) async {
    await _pumpProjects(tester);

    expect(find.byType(AppleFinderScaffold), findsOneWidget);
    expect(find.byType(AppleFinderToolbar), findsOneWidget);
    expect(find.byType(AppleFinderSidebar), findsOneWidget);
    expect(find.byType(AppleFinderFolderTile), findsNWidgets(2));

    await _pumpProjectHub(tester);

    expect(find.byType(AppleFinderScaffold), findsOneWidget);
    expect(find.byType(AppleFinderToolbar), findsOneWidget);
    expect(find.byType(AppleFinderSidebar), findsOneWidget);
    expect(find.byType(AppleFinderFolderTile), findsNWidgets(2));
  });

  testWidgets('shared Finder toolbar accepts leading controls and drag', (
    tester,
  ) async {
    var dragUpdates = 0;
    var viewPresses = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppleTheme.light(),
        home: Material(
          child: AppleFinderToolbar(
            key: const Key('finder-toolbar-api'),
            currentLocation: '프로젝트',
            compact: false,
            canGoBack: false,
            canGoForward: false,
            onBack: () {},
            onForward: () {},
            leadingControls: const SizedBox(
              key: Key('finder-leading-controls'),
              width: 32,
              height: 32,
            ),
            onDragUpdate: (_) => dragUpdates++,
            onViewPressed: () => viewPresses++,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('finder-leading-controls')), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('finder-current-location')),
      const Offset(30, 0),
    );
    expect(dragUpdates, greaterThan(0));

    await tester.tap(find.byKey(const Key('finder-view-options')));
    expect(viewPresses, 1);
  });

  testWidgets('lists injected project folders and navigates to local details', (
    tester,
  ) async {
    await _pumpProjectHub(tester);

    expect(find.byKey(const Key('project-hub-folder-list')), findsOneWidget);
    for (final entry in _projectData.projects.indexed) {
      expect(find.byKey(Key('project-hub-folder-${entry.$1}')), findsOneWidget);
      expect(find.text(entry.$2.title), findsOneWidget);
    }
    expect(find.text('About This Mac'), findsNothing);

    await tester.tap(find.byKey(const Key('project-hub-folder-1')));
    await tester.pumpAndSettle();

    final project = _projectData.projects[1];
    expect(find.byKey(const Key('project-hub-detail')), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('project-hub-detail-title')))
          .data,
      project.title,
    );
    expect(find.text(project.period), findsOneWidget);
    expect(find.text(project.description), findsOneWidget);
    for (final skill in project.technologies) {
      expect(find.text(skill), findsOneWidget);
    }
    expect(find.text('상세 화면은 추후 기획 예정'), findsOneWidget);

    await tester.tap(find.byKey(const Key('project-hub-finder-back')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('project-hub-folder-list')), findsOneWidget);
    expect(find.byKey(const Key('project-hub-detail')), findsNothing);
  });

  testWidgets(
    'is accessible and overflow-free across all target form factors',
    (tester) async {
      final semantics = tester.ensureSemantics();

      for (final scenario in const <({Size size, bool compact, bool tablet})>[
        (size: Size(1024, 700), compact: false, tablet: false),
        (size: Size(834, 600), compact: false, tablet: true),
        (size: Size(320, 480), compact: true, tablet: false),
      ]) {
        await _pumpProjectHub(
          tester,
          size: scenario.size,
          compact: scenario.compact,
          tablet: scenario.tablet,
          textScaler: const TextScaler.linear(2),
        );

        final firstFolder = find.byKey(const Key('project-hub-folder-0'));
        expect(firstFolder, findsOneWidget, reason: '${scenario.size}');
        expect(
          find.bySemanticsLabel('첫 번째 프로젝트 열기'),
          findsOneWidget,
          reason: '${scenario.size}',
        );
        final targetSize = tester.getSize(firstFolder);
        expect(targetSize.width, greaterThanOrEqualTo(44));
        expect(targetSize.height, greaterThanOrEqualTo(44));
        expect(tester.takeException(), isNull, reason: '${scenario.size} list');

        await tester.tap(firstFolder);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('project-hub-detail-scroll')),
          findsOneWidget,
        );
        final backButton = find.byKey(const Key('project-hub-finder-back'));
        expect(backButton, findsOneWidget);
        expect(
          tester.getSemantics(backButton).tooltip,
          contains('프로젝트 폴더 목록으로 돌아가기'),
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${scenario.size} detail',
        );
      }
      semantics.dispose();
    },
  );
}

const PortfolioData _projectData = PortfolioData.constant(
  identity: PortfolioIdentity(
    name: '테스트 사용자',
    englishName: 'Test User',
    email: 'test@example.com',
    githubUrl: 'https://example.com',
    headline: '테스트 헤드라인',
    biography: '테스트 소개',
  ),
  experiences: <PortfolioExperience>[],
  education: <PortfolioEducation>[],
  skillGroups: <PortfolioSkillGroup>[],
  projects: <PortfolioProject>[
    PortfolioProject.constant(
      title: '첫 번째 프로젝트',
      description: '첫 번째 프로젝트 설명',
      period: '2025.01 - 2025.06',
      technologies: <String>['Flutter', 'Dart'],
      links: <PortfolioProjectLink>[],
    ),
    PortfolioProject.constant(
      title: '두 번째 프로젝트',
      description: '두 번째 프로젝트 설명',
      period: '2026.01 - 진행 중',
      technologies: <String>['Riverpod', 'Firebase'],
      links: <PortfolioProjectLink>[],
    ),
  ],
);

Future<void> _pumpProjects(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.light(),
      home: ProjectsApp(data: _projectData, launcher: _FakeExternalLauncher()),
    ),
  );
  await tester.pump();
}

Future<void> _pumpProjectHub(
  WidgetTester tester, {
  Size size = const Size(900, 650),
  bool compact = false,
  bool tablet = false,
  TextScaler textScaler = TextScaler.noScaling,
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
          child: ThisMacApp(
            key: ValueKey<Size>(size),
            data: _projectData,
            compact: compact,
            tablet: tablet,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

final class _FakeExternalLauncher implements ExternalLauncher {
  @override
  Future<bool> launch(Uri uri) async => true;
}
