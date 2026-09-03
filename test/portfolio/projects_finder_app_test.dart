import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/projects_app.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/widgets/apple_finder_scaffold.dart';

void main() {
  group('Finder형 Projects 화면', () {
    testWidgets('기본 경력 위치에서 분류된 폴더와 상세 뎁스를 탐색한다', (tester) async {
      await _pumpProjects(tester, size: const Size(900, 650));

      expect(find.byKey(const Key('projects-finder-toolbar')), findsOneWidget);
      expect(find.byKey(const Key('projects-finder-back')), findsOneWidget);
      expect(find.byKey(const Key('projects-finder-forward')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('projects-finder-current-location')),
          matching: find.text('경력'),
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
        '경력',
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

    testWidgets('iPhone은 2열 고정 폭 파일 목록과 별도 상세 뎁스를 스크롤한다', (tester) async {
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

    testWidgets('넓은 iPhone에서도 프로젝트 폴더를 132px 2열로 유지한다', (tester) async {
      for (final width in const <double>[448, 590]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProjects(tester, size: Size(width, 700), compact: true);

        final folders = <Finder>[
          for (var index = 0; index < 4; index++)
            find.byKey(Key('projects-career-folder-$index')),
        ];
        for (final folder in folders) {
          expect(tester.getSize(folder).width, 132, reason: '$width');
        }
        expect(
          tester.getTopLeft(folders[0]).dy,
          closeTo(tester.getTopLeft(folders[1]).dy, 0.01),
          reason: '$width',
        );
        expect(
          tester.getTopLeft(folders[2]).dy,
          greaterThan(tester.getTopLeft(folders[0]).dy),
          reason: '$width',
        );
        expect(tester.takeException(), isNull, reason: '$width');
      }
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
        for (var index = 0; index < 4; index++)
          find.byKey(Key('projects-career-folder-$index')),
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
