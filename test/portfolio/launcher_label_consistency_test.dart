import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/projects_app.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';

void main() {
  testWidgets(
    'Trash and Printer grid labels use identical effective typography',
    (tester) async {
      for (final tablet in [false, true]) {
        for (final dark in [false, true]) {
          for (final scale in [1.0, 2.0]) {
            await tester.pumpWidget(const SizedBox.shrink());
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = tablet
                ? const Size(834, 700)
                : const Size(320, 568);
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
                    data: portfolioData,
                    compact: !tablet,
                    tablet: tablet,
                    launcher: CallbackExternalLauncher((_) async => true),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            await tester.ensureVisible(find.text('프린터'));
            await tester.pumpAndSettle();
            TextStyle style(String label) => tester
                .widget<RichText>(
                  find.descendant(
                    of: find.text(label),
                    matching: find.byType(RichText),
                  ),
                )
                .text
                .style!;
            expect(
              find.byKey(const Key('apple-finder-folder-label')),
              findsNWidgets(5),
            );
            expect(
              tester.getTopLeft(find.text('프린터')).dy,
              closeTo(tester.getTopLeft(find.text('휴지통')).dy, 0.1),
            );
            expect(
              style('프린터'),
              style('휴지통'),
              reason: 'tablet=$tablet dark=$dark scale=$scale',
            );
            expect(tester.takeException(), isNull);
          }
        }
      }
    },
  );
}
