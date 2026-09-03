import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/projects_app.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/widgets/apple_finder_scaffold.dart';

void main() {
  group('Finder형 Projects 화면', () {
    testWidgets('기본 뎁스는 전체 파일 목록만 표시하고 폴더 탭으로 상세를 탐색한다', (tester) async {
      await _pumpProjects(tester, size: const Size(900, 650));

      expect(find.byKey(const Key('projects-finder-toolbar')), findsOneWidget);
      expect(find.byKey(const Key('projects-finder-back')), findsOneWidget);
      expect(find.byKey(const Key('projects-finder-forward')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('projects-finder-current-location')),
          matching: find.text('Projects'),
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
        portfolioData.identity.name,
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
      for (var index = 0; index < portfolioData.projects.length; index++) {
        expect(
          find.descendant(
            of: grid,
            matching: find.byKey(Key('project-selector-$index')),
          ),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(
          of: grid,
          matching: find.byKey(const Key('finder-file-portfolio-readme')),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('project-selector-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('projects-finder-grid')), findsNothing);
      expect(find.byKey(const Key('projects-collection-scroll')), findsNothing);
      expect(find.byKey(const Key('projects-detail-scroll')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('project-detail-title'))).data,
        portfolioData.projects[1].title,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('projects-finder-current-location')),
          matching: find.text(portfolioData.projects[1].title),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('projects-finder-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('projects-finder-grid')), findsOneWidget);
      expect(
        find.byKey(const Key('projects-collection-scroll')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('projects-detail-scroll')), findsNothing);
      expect(find.byKey(const Key('project-detail-title')), findsNothing);
      expect(
        tester
            .widget<AppleFinderFolderTile>(
              find.byKey(const Key('project-selector-1')),
            )
            .selected,
        isTrue,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('projects-finder-current-location')),
          matching: find.text('Projects'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('projects-finder-forward')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('project-detail-title'))).data,
        portfolioData.projects[1].title,
      );
    });

    testWidgets('iPad는 좁은 사이드바 옆에 데스크톱형 전체 파일 목록을 표시한다', (tester) async {
      await _pumpProjects(tester, size: const Size(834, 700), tablet: true);

      final sidebar = find.byKey(const Key('projects-finder-sidebar'));
      expect(sidebar, findsOneWidget);
      expect(tester.getSize(sidebar).width, 176);
      expect(find.byKey(const Key('projects-finder-locations')), findsNothing);
      expect(find.byKey(const Key('projects-detail-scroll')), findsNothing);

      final grid = find.byKey(const Key('projects-finder-grid'));
      expect(grid, findsOneWidget);
      for (var index = 0; index < portfolioData.projects.length; index++) {
        expect(
          find.descendant(
            of: grid,
            matching: find.byKey(Key('project-selector-$index')),
          ),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(
          of: grid,
          matching: find.byKey(const Key('finder-file-portfolio-readme')),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
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

    testWidgets('iPhone은 2열 고정 폭 파일 목록과 별도 상세 뎁스를 스크롤한다', (tester) async {
      await _pumpProjects(
        tester,
        size: const Size(320, 480),
        compact: true,
        textScaler: const TextScaler.linear(2),
      );

      expect(find.byKey(const Key('projects-finder-toolbar')), findsOneWidget);
      expect(
        find.byKey(const Key('projects-finder-locations')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('projects-finder-sidebar')), findsNothing);
      expect(
        find.byKey(const Key('projects-collection-scroll')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('projects-detail-scroll')), findsNothing);
      expect(find.byKey(const Key('project-detail-title')), findsNothing);

      final folders = <Finder>[
        for (var index = 0; index < portfolioData.projects.length; index++)
          find.byKey(Key('project-selector-$index')),
      ];
      for (final folder in folders) {
        expect(tester.getSize(folder).width, 132);
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
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('project-selector-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('projects-finder-grid')), findsNothing);
      expect(find.byKey(const Key('projects-collection-scroll')), findsNothing);
      expect(find.byKey(const Key('projects-detail-scroll')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('project-detail-title'))).data,
        portfolioData.projects[1].title,
      );
      expect(find.byKey(const Key('project-link-1-0')), findsOneWidget);

      await tester.drag(
        find.byKey(const Key('projects-detail-scroll')),
        const Offset(0, -260),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('desktop 창의 좁은 regular 본문에서도 폴더 폭을 유지하고 여러 행으로 배치한다', (
      tester,
    ) async {
      await _pumpProjects(tester, size: const Size(766, 600));

      expect(
        find.byKey(const Key('projects-collection-scroll')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('projects-detail-scroll')), findsNothing);
      expect(find.byKey(const Key('project-detail-title')), findsNothing);

      final folders = <Finder>[
        for (var index = 0; index < portfolioData.projects.length; index++)
          find.byKey(Key('project-selector-$index')),
      ];

      for (final folder in folders) {
        expect(
          tester.getSize(folder).width,
          greaterThanOrEqualTo(132),
          reason: 'regular Finder folders must remain readable',
        );
      }

      final rowStarts = folders
          .map((folder) => tester.getTopLeft(folder).dy.round())
          .toSet();
      expect(rowStarts.length, greaterThan(1));
      expect(
        find.byKey(const Key('finder-file-portfolio-readme')),
        findsOneWidget,
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
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: SizedBox.expand(
          child: ProjectsApp(
            data: portfolioData,
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
