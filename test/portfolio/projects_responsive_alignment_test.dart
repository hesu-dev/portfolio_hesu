import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/projects_app.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';

void main() {
  group('Projects responsive alignment', () {
    testWidgets('390px Finder lays three project folders on the first row', (
      tester,
    ) async {
      await _pumpProjects(
        tester,
        size: const Size(390, 700),
        compact: true,
      );

      final folders = <Finder>[
        for (var index = 0; index < 4; index++)
          find.byKey(Key('projects-career-folder-$index')),
      ];
      final firstRowY = tester.getTopLeft(folders.first).dy;

      expect(tester.getTopLeft(folders[1]).dy, closeTo(firstRowY, 0.01));
      expect(tester.getTopLeft(folders[2]).dy, closeTo(firstRowY, 0.01));
      expect(tester.getTopLeft(folders[3]).dy, greaterThan(firstRowY));
      expect(tester.getSize(folders.first).width, lessThanOrEqualTo(116));
      expect(
        tester.getTopLeft(folders[1]).dx - tester.getRect(folders[0]).right,
        lessThanOrEqualTo(12),
      );
    });

    testWidgets('iPad Finder keeps all six recent projects on one dense row', (
      tester,
    ) async {
      await _pumpProjects(
        tester,
        size: const Size(834, 700),
        tablet: true,
      );
      await tester.tap(
        find.byKey(const Key('projects-finder-location-recent')),
      );
      await tester.pumpAndSettle();

      final folders = <Finder>[
        for (var index = 0; index < portfolioData.projects.length; index++)
          find.byKey(Key('projects-recent-folder-$index')),
      ];
      final firstRowY = tester.getTopLeft(folders.first).dy;

      for (final folder in folders.skip(1)) {
        expect(tester.getTopLeft(folder).dy, closeTo(firstRowY, 0.01));
      }
      for (var index = 1; index < folders.length; index++) {
        expect(
          tester.getTopLeft(folders[index]).dx -
              tester.getRect(folders[index - 1]).right,
          lessThanOrEqualTo(12),
        );
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
        final destinations = <({String id, IconData icon})>[
          (id: 'recent', icon: Icons.access_time_filled_rounded),
          (id: 'career', icon: Icons.business_center_rounded),
          (id: 'personal-projects', icon: Icons.folder_special_rounded),
        ];

        for (final indexed in destinations.indexed) {
          final control = find.byKey(
            Key('projects-finder-location-${indexed.$2.id}'),
          );
          final icon = find.descendant(
            of: control,
            matching: find.byIcon(indexed.$2.icon),
          );
          final expectedCenterX =
              dockRect.left + dockPadding + slotWidth * (indexed.$1 + 0.5);

          expect(
            tester.getCenter(icon).dx,
            closeTo(expectedCenterX, 0.5),
            reason: '${scenario.size} ${indexed.$2.id}',
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
