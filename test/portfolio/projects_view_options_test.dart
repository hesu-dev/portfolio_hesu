import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/projects_app.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/widgets/apple_finder_list_row.dart';

void main() {
  testWidgets(
    'Files rows share layout and dates/tags also sort recent shortcuts',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      PortfolioAppId? opened;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppleTheme.light(),
          home: Scaffold(
            body: ProjectsApp(
              data: portfolioData,
              compact: true,
              launcher: CallbackExternalLauncher((_) async => true),
              onOpenApp: (app) => opened = app,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> choose(String option) async {
        await tester.tap(find.byKey(const Key('projects-finder-more')));
        await tester.pumpAndSettle();
        final choice = find.byKey(Key('projects-$option'));
        await tester.ensureVisible(choice);
        await tester.pumpAndSettle();
        await tester.tap(choice);
        await tester.pumpAndSettle();
      }

      List<AppleFinderListRow> rows(String prefix) =>
          (tester
                      .widget<ListView>(find.byKey(Key('$prefix-app-list')))
                      .childrenDelegate
                  as SliverChildListDelegate)
              .children
              .cast<AppleFinderListRow>();
      List<String> labels(String prefix) =>
          rows(prefix).map((row) => row.title).toList();
      await choose('view-list');
      expect(
        tester.widget(find.byKey(const Key('projects-files-app-printer'))),
        isA<AppleFinderListRow>(),
      );
      expect(find.text('앱 바로가기'), findsNothing);
      final trash = find.text('휴지통');
      final printer = find.text('프린터');
      expect(tester.getTopLeft(printer).dx, tester.getTopLeft(trash).dx);
      expect(
        DefaultTextStyle.of(tester.element(printer)).style,
        DefaultTextStyle.of(tester.element(trash)).style,
      );
      await tester.tap(printer);
      await tester.pumpAndSettle();
      expect(find.text('인쇄 화면을 열지 못했어요'), findsOneWidget);
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      final original = labels('projects-files');
      await choose('sort-date');
      final dateOrder = labels('projects-files');
      expect(dateOrder, isNot(orderedEquals(original)));
      final dates = rows(
        'projects-files',
      ).map((row) => DateTime.parse(row.subtitle!)).toList();
      expect(dates, hasLength(5));
      expect(dates.every((date) => date.isBefore(DateTime(2020, 12))), isTrue);
      for (var i = 1; i < dates.length; i++) {
        expect(dates[i].isAfter(dates[i - 1]), isTrue);
      }
      await choose('sort-tags');
      expect(labels('projects-files'), isNot(orderedEquals(dateOrder)));
      expect(
        rows('projects-files').map((row) => row.subtitle).toSet().length,
        5,
      );
      await choose('sort-date');
      expect(labels('projects-files'), dateOrder);
      await tester.tap(
        find.byKey(const Key('projects-finder-location-recent')),
      );
      await tester.pumpAndSettle();
      await choose('view-list');
      expect(
        rows('projects-recent'),
        hasLength(portfolioData.projects.length + 5),
      );
      expect(
        labels('projects-recent'),
        containsAll([
          ...portfolioData.projects.map((project) => project.title),
          '프린터',
          '휴지통',
          '이메일',
          '사진',
          '음악',
        ]),
      );
      final mail = find.byKey(const Key('projects-recent-app-mail'));
      await tester.ensureVisible(mail);
      await tester.pumpAndSettle();
      await tester.tap(mail);
      expect(opened, PortfolioAppId.mail);
      await choose('sort-date');
      expect(labels('projects-recent').take(5), orderedEquals(dateOrder));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('iOS menu includes its Cupertino symbol font', (tester) async {
    final font = await rootBundle.load(
      'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    );
    expect(font.lengthInBytes, greaterThan(0));
  });
  testWidgets('iOS popover scrolls at 200 percent text in both themes', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      for (final tablet in [false, true]) {
        await tester.pumpWidget(const SizedBox.shrink());
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = tablet
            ? const Size(834, 700)
            : const Size(320, 568);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pumpWidget(
          MaterialApp(
            theme: brightness == Brightness.light
                ? AppleTheme.light()
                : AppleTheme.dark(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: ProjectsApp(
                data: portfolioData,
                compact: !tablet,
                tablet: tablet,
                launcher: CallbackExternalLauncher((_) async => true),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('projects-finder-more')));
        await tester.pumpAndSettle();
        expect(find.byType(CupertinoPopupSurface), findsOneWidget);
        final tags = find.byKey(const Key('projects-sort-tags'));
        await tester.ensureVisible(tags);
        await tester.pumpAndSettle();
        expect(tags.hitTestable(), findsOneWidget);
        await tester.tap(tags);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('projects-finder-more')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('projects-view-list')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('projects-files-app-list')),
          findsOneWidget,
        );
        final printer = find.byKey(const Key('projects-files-app-printer'));
        await tester.ensureVisible(printer);
        await tester.pumpAndSettle();
        expect(printer.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$tablet $brightness');
      }
    }
  });
  for (final mobile in [true, false]) {
    testWidgets(
      '${mobile ? 'mobile More' : 'desktop view'} remembers each folder and sorts real entries',
      (tester) async {
        final size = Size(mobile ? 390 : 900, 844);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        PortfolioAppId? opened;
        final data = PortfolioData(
          identity: portfolioData.identity,
          experiences: const [],
          education: const [],
          skillGroups: const [],
          projects: [
            PortfolioProject(
              title: 'Zulu',
              description: 'Zulu detail',
              period: '2025.10 – 2026',
              technologies: ['Dart'],
              links: [],
            ),
            PortfolioProject(
              title: 'Personal',
              description: '',
              period: '2024',
              technologies: [],
              links: [],
              category: PortfolioProjectCategory.personal,
            ),
            PortfolioProject(
              title: 'Alpha',
              description: 'Alpha detail',
              period: '2025.2 – 2026',
              technologies: ['Swift'],
              links: [],
            ),
          ],
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: AppleTheme.light(),
            home: Scaffold(
              body: ProjectsApp(
                data: data,
                compact: mobile,
                launcher: CallbackExternalLauncher((_) async => true),
                onOpenApp: (app) => opened = app,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        Future<void> menu() async {
          await tester.tap(
            find.byKey(
              Key('projects-finder-${mobile ? 'more' : 'view-options'}'),
            ),
          );
          await tester.pumpAndSettle();
        }

        Future<void> choose(String option) async {
          await menu();
          await tester.tap(find.byKey(Key('projects-$option')));
          await tester.pumpAndSettle();
        }

        Future<void> location(String id) async {
          await tester.tap(find.byKey(Key('projects-finder-location-$id')));
          await tester.pumpAndSettle();
        }

        void order(int first, int second) => expect(
          tester.getTopLeft(find.byKey(Key('project-selector-$first'))).dy,
          lessThan(
            tester.getTopLeft(find.byKey(Key('project-selector-$second'))).dy,
          ),
        );

        await menu();
        expect(find.byType(CupertinoPopupSurface), findsOneWidget);
        expect(find.byType(CheckedPopupMenuItem<Object>), findsNothing);
        for (final option in ['view-icons', 'sort-kind']) {
          expect(
            tester
                .getSemantics(find.byKey(Key('projects-$option')))
                .getSemanticsData()
                .flagsCollection
                .isSelected,
            ui.Tristate.isTrue,
          );
        }
        expect(
          tester
              .getSemantics(find.byKey(const Key('projects-sort-size')))
              .getSemanticsData()
              .flagsCollection
              .isEnabled,
          ui.Tristate.isFalse,
        );
        await tester.tap(find.byKey(const Key('projects-view-list')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('projects-files-app-list')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('projects-files-app-mail')));
        expect(opened, PortfolioAppId.mail);

        await location('career');
        expect(find.byKey(const Key('projects-finder-grid')), findsOneWidget);
        await choose('view-list');
        await choose('sort-name');
        order(2, 0);
        await location('personal-projects');
        expect(find.byKey(const Key('projects-finder-grid')), findsOneWidget);
        await location('career');
        expect(find.byKey(const Key('projects-finder-list')), findsOneWidget);
        order(2, 0);
        await choose('sort-date');
        order(2, 0); // February precedes October, regardless of string padding.
        await choose('sort-tags');
        order(0, 2);
        await tester.tap(find.byKey(const Key('project-selector-2')));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<Text>(find.byKey(const Key('safari-project-title')))
              .data,
          'Alpha',
        );
        await location('files');
        expect(
          find.byKey(const Key('projects-files-app-list')),
          findsOneWidget,
        );
        await location('recent');
        await choose('view-list');
        order(1, 0); // 개인 프로젝트 precedes 회사 프로젝트.
        order(0, 2); // Equal kinds retain their original order.
        expect(tester.takeException(), isNull);
      },
    );
  }
}
