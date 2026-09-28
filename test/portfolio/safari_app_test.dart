import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/safari_app.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/portfolio_app.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';

import 'support/music_test_controller.dart';

void main() {
  testWidgets(
    'desktop Safari opens from its icon and bookmarks navigate projects',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        PortfolioApp(
          musicController: createTestMusicController(),
          externalLauncher: CallbackExternalLauncher((_) async => true),
        ),
      );
      await tester.pumpAndSettle();
      final safari = find.byKey(const Key('desktop-app-safari'));
      expect(
        find.descendant(of: safari, matching: find.text('프로젝트')),
        findsOneWidget,
      );
      await tester.tap(safari);
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tap(safari);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('safari-bookmarks')), findsOneWidget);
      expect(find.byKey(const Key('safari-sidebar')), findsNothing);
      final introduction = tester.getRect(
        find.byKey(const Key('safari-report-introduction')),
      );
      final page = tester.getRect(find.byKey(const Key('safari-page')));
      expect(introduction.bottom, lessThanOrEqualTo(page.top));
      expect(page.left, closeTo(introduction.left, .1));
      expect(page.width, closeTo(introduction.width, .1));
      for (final entry in portfolioData.projects.indexed) {
        final bookmark = find.byKey(Key('safari-bookmark-${entry.$1}'));
        final label = switch (entry.$2.title) {
          'ReadingLog' => '리딩로그',
          'PersonaChat AI Character Chat' => 'AI 챗',
          _ => entry.$2.title,
        };
        expect(bookmark, findsOneWidget);
        expect(
          find.descendant(of: bookmark, matching: find.text(label)),
          findsOneWidget,
        );
      }
      expect(find.text('회사'), findsNothing);
      expect(find.text('개인 프로젝트'), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(const Key('safari-project-title'))).data,
        portfolioData.projects.first.title,
      );
      await tester.tap(find.byKey(const Key('safari-bookmark-1')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('safari-project-title'))).data,
        portfolioData.projects[1].title,
      );
      await tester.tap(find.byKey(const Key('safari-back')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('safari-project-title'))).data,
        portfolioData.projects.first.title,
      );
      await tester.tap(find.byKey(const Key('safari-forward')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('safari-project-title'))).data,
        portfolioData.projects[1].title,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('desktop bookmarks share the full usable bar width', (
    tester,
  ) async {
    for (final (width, scale) in <(double, double)>[
      (800, 1),
      (1400, 1),
      (620, 2),
    ]) {
      await _pumpSafari(tester, Size(width, 700), scale: scale);
      final bar = tester.getRect(find.byKey(const Key('safari-bookmarks')));
      final bookmarks = <Rect>[
        for (final entry in portfolioData.projects.indexed)
          tester.getRect(find.byKey(Key('safari-bookmark-${entry.$1}'))),
      ];
      expect(bookmarks.first.left, closeTo(bar.left + 12, 0.1));
      expect(bookmarks.last.right, closeTo(bar.right - 12, 0.1));
      final itemWidth = (bar.width - 24) / bookmarks.length;
      for (final (index, bookmark) in bookmarks.indexed) {
        expect(bookmark.width, closeTo(itemWidth, 0.1));
        if (index > 0) {
          expect(bookmark.left, closeTo(bookmarks[index - 1].right, 0.1));
        }
      }
      expect(tester.takeException(), isNull, reason: '$width at $scale');
    }
  });

  testWidgets('tablet bookmarks navigate projects above the full-width page', (
    tester,
  ) async {
    await _pumpSafari(tester, const Size(834, 900), tablet: true);
    expect(find.byKey(const Key('safari-sidebar')), findsNothing);
    expect(find.byKey(const Key('safari-bookmarks')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('safari-page'))).width,
      834,
    );
    await tester.tap(find.byKey(const Key('safari-bookmark-1')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('safari-project-title'))).data,
      portfolioData.projects[1].title,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'phone bottom tabs picker switches projects and respects safe area',
    (tester) async {
      await _pumpSafari(
        tester,
        const Size(390, 844),
        compact: true,
        bottom: 34,
      );
      final tabs = find.byKey(const Key('safari-all-tabs'));
      expect(
        find.text('모든 탭(${portfolioData.projects.length})'),
        findsOneWidget,
      );
      expect(tester.getBottomLeft(tabs).dy, lessThanOrEqualTo(844 - 34 - 17));
      await tester.tap(tabs);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('safari-tabs-overview')), findsOneWidget);
      for (final entry in portfolioData.projects.indexed) {
        expect(find.byKey(Key('safari-tab-${entry.$1}')), findsOneWidget);
      }
      await tester.tap(find.byKey(const Key('safari-tab-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('safari-tabs-overview')), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(const Key('safari-project-title'))).data,
        portfolioData.projects[1].title,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('different projects have separate detail scroll positions', (
    tester,
  ) async {
    await _pumpSafari(tester, const Size(850, 650));
    await tester.drag(
      find.byKey(const Key('safari-page')),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('safari-project-title')).hitTestable(),
      findsNothing,
    );
    await tester.tap(find.byKey(const Key('safari-bookmark-1')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('safari-project-title')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone dark mode and enlarged text remain usable', (
    tester,
  ) async {
    await _pumpSafari(tester, const Size(320, 700), compact: true, scale: 2);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('safari-all-tabs')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('safari-tabs-overview')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpSafari(
  WidgetTester tester,
  Size size, {
  bool compact = false,
  bool tablet = false,
  double bottom = 0,
  double scale = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(scale),
          padding: EdgeInsets.only(bottom: bottom),
        ),
        child: SafariApp(
          data: portfolioData,
          compact: compact,
          tablet: tablet,
          launcher: CallbackExternalLauncher((_) async => true),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
