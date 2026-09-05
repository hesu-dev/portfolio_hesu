import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/projects_app.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';

void main() {
  group('Projects responsive alignment', () {
    testWidgets(
      '375px Finder keeps equal visual margins and left-aligned rows',
      (tester) async {
        await _pumpProjects(tester, size: const Size(375, 700), compact: true);

        final folders = <Finder>[
          for (var index = 0; index < 4; index++)
            find.byKey(Key('projects-career-folder-$index')),
        ];
        final firstRowY = tester.getTopLeft(folders.first).dy;
        final firstRow = folders
            .takeWhile(
              (folder) =>
                  (tester.getTopLeft(folder).dy - firstRowY).abs() < 0.01,
            )
            .toList(growable: false);
        final firstArtwork = find.descendant(
          of: firstRow.first,
          matching: find.byKey(
            const Key('apple-finder-folder-artwork-background'),
          ),
        );
        final lastArtwork = find.descendant(
          of: firstRow.last,
          matching: find.byKey(
            const Key('apple-finder-folder-artwork-background'),
          ),
        );
        final collectionRect = tester.getRect(
          find.byKey(const Key('projects-collection-scroll')),
        );
        const horizontalPadding = 16.0;
        final leadingGap =
            tester.getRect(firstArtwork).left -
            (collectionRect.left + horizontalPadding);
        final trailingGap =
            (collectionRect.right - horizontalPadding) -
            tester.getRect(lastArtwork).right;

        expect(firstRow, hasLength(3));
        expect(
          tester.getRect(folders.first).left,
          closeTo(collectionRect.left + horizontalPadding, 0.01),
        );
        expect(leadingGap, closeTo(trailingGap, 0.01));
        expect(
          tester.getRect(folders[firstRow.length]).left,
          closeTo(tester.getRect(folders.first).left, 0.01),
        );
      },
    );

    testWidgets('390px Finder lays three project folders on the first row', (
      tester,
    ) async {
      await _pumpProjects(tester, size: const Size(390, 700), compact: true);

      final folders = <Finder>[
        for (var index = 0; index < 4; index++)
          find.byKey(Key('projects-career-folder-$index')),
      ];
      final firstRowY = tester.getTopLeft(folders.first).dy;

      expect(tester.getTopLeft(folders[1]).dy, closeTo(firstRowY, 0.01));
      expect(tester.getTopLeft(folders[2]).dy, closeTo(firstRowY, 0.01));
      expect(tester.getTopLeft(folders[3]).dy, greaterThan(firstRowY));
      expect(tester.getSize(folders.first).width, closeTo(114, 0.01));
      expect(
        tester.getTopLeft(folders[1]).dx - tester.getRect(folders[0]).right,
        closeTo(8, 0.01),
      );
    });

    testWidgets(
      '375px Finder keeps three-column slots when a location has two folders',
      (tester) async {
        await _pumpProjects(tester, size: const Size(375, 700), compact: true);

        final careerFolder = find.byKey(const Key('projects-career-folder-0'));
        final careerRect = tester.getRect(careerFolder);
        await tester.tap(
          find.byKey(const Key('projects-finder-location-personal-projects')),
        );
        await tester.pumpAndSettle();

        final personalFolders = <Finder>[
          find.byKey(const Key('projects-personal-projects-folder-0')),
          find.byKey(const Key('projects-personal-projects-folder-1')),
        ];
        final firstPersonalRect = tester.getRect(personalFolders.first);
        final secondPersonalRect = tester.getRect(personalFolders.last);

        expect(firstPersonalRect.width, closeTo(careerRect.width, 0.01));
        expect(firstPersonalRect.left, closeTo(careerRect.left, 0.01));
        expect(secondPersonalRect.width, closeTo(careerRect.width, 0.01));
        expect(
          secondPersonalRect.left - firstPersonalRect.right,
          closeTo(8, 0.01),
        );
      },
    );

    testWidgets(
      'short iPhone scrolls the last folder above the overlaid Dock',
      (tester) async {
        await _pumpProjects(tester, size: const Size(320, 480), compact: true);
        await tester.tap(
          find.byKey(const Key('projects-finder-location-recent')),
        );
        await tester.pumpAndSettle();

        final scroll = find.byKey(const Key('projects-collection-scroll'));
        await tester.drag(scroll, const Offset(0, -1000));
        await tester.pumpAndSettle();

        final lastFolder = find.byKey(
          Key('projects-recent-folder-${portfolioData.projects.length - 1}'),
        );
        final dock = find.byKey(const Key('projects-finder-mobile-dock'));
        expect(
          tester.getRect(lastFolder).bottom,
          lessThanOrEqualTo(tester.getRect(dock).top),
        );
      },
    );

    testWidgets('mobile Dock fade overlaps the project file viewport', (
      tester,
    ) async {
      for (final scenario in const <({Size size, bool tablet})>[
        (size: Size(390, 700), tablet: false),
        (size: Size(834, 700), tablet: true),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProjects(
          tester,
          size: scenario.size,
          compact: !scenario.tablet,
          tablet: scenario.tablet,
        );

        final viewportRect = tester.getRect(
          find.byKey(const Key('projects-collection-scroll')),
        );
        final fadeRect = tester.getRect(
          find.byKey(
            const Key('projects-finder-mobile-dock-backdrop-gradient'),
          ),
        );

        expect(viewportRect.overlaps(fadeRect), isTrue);
        expect(fadeRect.bottom, lessThanOrEqualTo(viewportRect.bottom));
      }
    });

    testWidgets('iPad Finder keeps all six recent projects on one dense row', (
      tester,
    ) async {
      await _pumpProjects(tester, size: const Size(834, 700), tablet: true);
      await tester.tap(
        find.byKey(const Key('projects-finder-location-recent')),
      );
      await tester.pumpAndSettle();

      final folders = <Finder>[
        for (var index = 0; index < portfolioData.projects.length; index++)
          find.byKey(Key('projects-recent-folder-$index')),
      ];
      final firstRowY = tester.getTopLeft(folders.first).dy;

      expect(tester.getSize(folders.first).width, closeTo(112, 0.01));
      for (final folder in folders.skip(1)) {
        expect(tester.getTopLeft(folder).dy, closeTo(firstRowY, 0.01));
        expect(tester.getSize(folder).width, closeTo(112, 0.01));
      }
      for (var index = 1; index < folders.length; index++) {
        expect(
          tester.getTopLeft(folders[index]).dx -
              tester.getRect(folders[index - 1]).right,
          closeTo(8, 0.01),
        );
      }
    });

    testWidgets('프로젝트 폴더의 모든 행을 파일 영역 왼쪽에 정렬한다', (tester) async {
      for (final scenario
          in const <
            ({
              Size size,
              bool compact,
              bool tablet,
              double horizontalPadding,
              List<int> rowLengths,
            })
          >[
            (
              size: Size(900, 650),
              compact: false,
              tablet: false,
              horizontalPadding: 30,
              rowLengths: <int>[4],
            ),
            (
              size: Size(834, 700),
              compact: false,
              tablet: true,
              horizontalPadding: 30,
              rowLengths: <int>[4],
            ),
            (
              size: Size(1366, 900),
              compact: false,
              tablet: true,
              horizontalPadding: 30,
              rowLengths: <int>[4],
            ),
            (
              size: Size(390, 700),
              compact: true,
              tablet: false,
              horizontalPadding: 16,
              rowLengths: <int>[3, 1],
            ),
          ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProjects(
          tester,
          size: scenario.size,
          compact: scenario.compact,
          tablet: scenario.tablet,
        );

        final gridRect = tester.getRect(
          find.byKey(const Key('projects-finder-grid')),
        );
        final collectionRect = tester.getRect(
          find.byKey(const Key('projects-collection-scroll')),
        );
        expect(
          gridRect.left,
          closeTo(collectionRect.left + scenario.horizontalPadding, 0.01),
          reason: '${scenario.size} grid leading edge',
        );
        final folders = <Finder>[
          for (var index = 0; index < 4; index++)
            find.byKey(Key('projects-career-folder-$index')),
        ];
        var rowStart = 0;
        for (final rowLength in scenario.rowLengths) {
          final firstRect = tester.getRect(folders[rowStart]);
          expect(
            firstRect.left,
            closeTo(gridRect.left, 0.01),
            reason: '${scenario.size} row starting at $rowStart',
          );
          rowStart += rowLength;
        }
      }
    });

    testWidgets('mobile Finder navigation centers every icon in its third', (
      tester,
    ) async {
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
        final dockRect = tester.getRect(dock);
        const dockPadding = 5.0;
        final slotWidth = (dockRect.width - dockPadding * 2) / 3;
        final destinations = <({String id, String label, IconData icon})>[
          (
            id: 'recent',
            label: '최근 항목',
            icon: Icons.access_time_filled_rounded,
          ),
          (id: 'career', label: '회사', icon: Icons.business_center_rounded),
          (
            id: 'personal-projects',
            label: '개인',
            icon: Icons.folder_special_rounded,
          ),
        ];

        for (final indexed in destinations.indexed) {
          final control = find.byKey(
            Key('projects-finder-location-${indexed.$2.id}'),
          );
          final icon = find.descendant(
            of: control,
            matching: find.byIcon(indexed.$2.icon),
          );
          final label = find.descendant(
            of: control,
            matching: find.text(indexed.$2.label),
          );
          final expectedCenterX =
              dockRect.left + dockPadding + slotWidth * (indexed.$1 + 0.5);

          expect(
            tester.getCenter(icon).dx,
            closeTo(expectedCenterX, 1),
            reason: '${scenario.size} ${indexed.$2.id}',
          );
          expect(
            tester.getCenter(label).dx,
            closeTo(expectedCenterX, 1),
            reason: '${scenario.size} ${indexed.$2.id} label',
          );
        }
      }
    });
  });
}

Future<void> _pumpProjects(
  WidgetTester tester, {
  required Size size,
  bool compact = false,
  bool tablet = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: SizedBox.expand(
          child: ProjectsApp(
            data: portfolioData,
            launcher: const _FakeExternalLauncher(),
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
  const _FakeExternalLauncher();

  @override
  Future<bool> launch(Uri uri) async => true;
}
