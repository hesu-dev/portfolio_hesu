import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/projects_app.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/widgets/apple_finder_list_row.dart';

void main() {
  testWidgets(
    'Recent list gives projects, Music and Printer equal row geometry',
    (tester) async {
      for (final dark in [false, true]) {
        for (final scale in [1.0, 2.0]) {
          await tester.pumpWidget(const SizedBox.shrink());
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(320, 3600);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppleTheme.dark() : AppleTheme.light(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Scaffold(
                body: ProjectsApp(
                  compact: true,
                  data: portfolioData,
                  launcher: CallbackExternalLauncher((_) async => true),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const Key('projects-finder-location-recent')),
          );
          await tester.pumpAndSettle();
          Future<void> choose(String option) async {
            await tester.tap(find.byKey(const Key('projects-finder-more')));
            await tester.pumpAndSettle();
            final choice = find.byKey(Key('projects-$option'));
            await tester.ensureVisible(choice);
            await tester.tap(choice);
            await tester.pumpAndSettle();
          }

          await choose('view-list');
          for (final sort in ['kind', 'date', 'tags']) {
            await choose('sort-$sort');
            final keys = [
              for (var i = 0; i < portfolioData.projects.length; i++)
                Key('project-selector-$i'),
              for (final app in ['music', 'photos', 'mail', 'trash', 'printer'])
                Key('projects-recent-app-$app'),
            ];
            final rows = [for (final key in keys) find.byKey(key)];
            final reference = tester.getRect(rows.first);
            final referenceTitle = tester.getRect(
              find
                  .descendant(of: rows.first, matching: find.byType(Text))
                  .first,
            );
            for (final row in rows) {
              expect(tester.widget(row), isA<AppleFinderListRow>());
              final bounds = tester.getRect(row);
              final title = find
                  .descendant(of: row, matching: find.byType(Text))
                  .first;
              final text = tester.getRect(title);
              expect(
                bounds.height,
                closeTo(reference.height, 0.1),
                reason: '$sort/$dark/$scale/$row',
              );
              expect(
                text.left - bounds.left,
                closeTo(referenceTitle.left - reference.left, 0.1),
              );
              expect(
                text.top - bounds.top,
                closeTo(referenceTitle.top - reference.top, 0.1),
              );
              final titleWidget = tester.widget<Text>(title);
              expect(titleWidget.maxLines, 1);
              expect(titleWidget.overflow, TextOverflow.ellipsis);
            }
            expect(tester.takeException(), isNull);
          }
          for (final location in ['files', 'career', 'personal-projects']) {
            await tester.tap(
              find.byKey(Key('projects-finder-location-$location')),
            );
            await tester.pumpAndSettle();
            await choose('view-list');
            expect(find.byType(AppleFinderListRow), findsWidgets);
            expect(find.byType(ListTile), findsNothing);
            expect(tester.takeException(), isNull);
          }
        }
      }
    },
  );
}
