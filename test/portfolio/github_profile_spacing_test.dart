import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/system_apps.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';

void main() {
  testWidgets('GitHub tech stack separates headings and badge rows at mobile text sizes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final scale in [1.0, 2.0]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppleTheme.light(),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: GitHubApp(
                data: portfolioData,
                launcher: CallbackExternalLauncher((_) async => true),
                compact: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Finder heading(String text) => find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText() == text,
      );
      final java = find.byWidgetPredicate(
        (widget) => widget is Image && widget.semanticLabel == 'java',
      );
      final unity = find.byWidgetPredicate(
        (widget) => widget is Image && widget.semanticLabel == 'unity',
      );
      expect(java, findsOneWidget);
      expect(
        tester.getRect(java).top -
            tester.getRect(heading('Language').first).bottom,
        greaterThanOrEqualTo(12),
      );
      expect(
        tester.getRect(heading('Framework & Library').first).top -
            tester.getRect(java).bottom,
        greaterThanOrEqualTo(12),
      );
      expect(
        tester.getRect(unity).top -
            tester.getRect(heading('Framework & Library').first).bottom,
        greaterThanOrEqualTo(12),
      );
      expect(tester.takeException(), isNull);
    }
  });
}
