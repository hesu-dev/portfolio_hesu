import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/safari_app.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/portfolio_app.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';

import 'support/music_test_controller.dart';

void main() {
  testWidgets('Safari shows portfolio and opens the current app architecture', (
    tester,
  ) async {
    await _pumpSafari(tester, const Size(1000, 900));
    await tester.enterText(
      find.byKey(const Key('safari-search-field')),
      'Portfolio',
    );
    await tester.pumpAndSettle();
    expect(find.text('PersonaChat AI Character Chat'), findsNothing);
    final card = find.byKey(const Key('safari-project-card-1'));
    expect(
      find.descendant(of: card, matching: find.text('Portfolio')),
      findsOneWidget,
    );
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    _expectProject(tester, 'Portfolio');
    expect(find.byKey(const Key('architecture-diagram')), findsOneWidget);
    expect(find.textContaining('SafariProjectPage'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets('desktop project icon opens the Safari project start page', (
    tester,
  ) async {
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

    expect(find.byKey(const Key('safari-start-page')), findsOneWidget);
    expect(find.byKey(const Key('safari-search-field')), findsOneWidget);
    expect(find.byKey(const Key('safari-project-title')), findsNothing);
    for (final entry in portfolioData.projects.indexed) {
      final card = find.byKey(Key('safari-project-card-${entry.$1}'));
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.text(entry.$2.title)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text(entry.$2.description)),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'project cards and browser navigation preserve start page history',
    (tester) async {
      await _pumpSafari(tester, const Size(1000, 900), data: _searchData);
      final firstCard = find.byKey(const Key('safari-project-card-0'));
      await tester.ensureVisible(firstCard);
      await tester.tap(firstCard);
      await tester.pumpAndSettle();
      _expectProject(tester, 'Atlas');

      await tester.tap(find.byKey(const Key('safari-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('safari-start-page')), findsOneWidget);
      await tester.tap(find.byKey(const Key('safari-forward')));
      await tester.pumpAndSettle();
      _expectProject(tester, 'Atlas');

      await tester.tap(find.byKey(const Key('safari-home')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('safari-start-page')), findsOneWidget);
      await tester.tap(find.byKey(const Key('safari-favorite-1')));
      await tester.pumpAndSettle();
      _expectProject(tester, 'Boreal');
      await tester.tap(find.byKey(const Key('safari-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('safari-start-page')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('search filters project titles descriptions and technologies', (
    tester,
  ) async {
    await _pumpSafari(tester, const Size(1000, 900), data: _searchData);
    final search = find.byKey(const Key('safari-search-field'));
    for (final (query, expectedIndex) in [
      ('ATLas', 0),
      ('  바다 관측  ', 1),
      ('rust', 1),
    ]) {
      await tester.enterText(search, query);
      await tester.pumpAndSettle();
      expect(
        find.byKey(Key('safari-project-card-$expectedIndex')),
        findsOneWidget,
        reason: query,
      );
      expect(
        find.byKey(Key('safari-project-card-${1 - expectedIndex}')),
        findsNothing,
        reason: query,
      );
    }

    await tester.enterText(search, 'no-such-project');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('safari-project-card-0')), findsNothing);
    expect(find.byKey(const Key('safari-project-card-1')), findsNothing);
    expect(find.textContaining('검색 결과'), findsWidgets);
    await tester.tap(find.byKey(const Key('safari-search-clear')));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(search).controller!.text, isEmpty);
    expect(find.byKey(const Key('safari-project-card-0')), findsOneWidget);
    expect(find.byKey(const Key('safari-project-card-1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('typing in a project detail returns to searchable cards', (
    tester,
  ) async {
    await _pumpSafari(tester, const Size(1000, 900), data: _searchData);
    await tester.tap(find.byKey(const Key('safari-favorite-0')));
    await tester.pumpAndSettle();
    _expectProject(tester, 'Atlas');
    await tester.enterText(
      find.byKey(const Key('safari-search-field')),
      'Boreal',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('safari-start-page')), findsOneWidget);
    expect(find.byKey(const Key('safari-project-card-0')), findsNothing);
    final card = find.byKey(const Key('safari-project-card-1'));
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    _expectProject(tester, 'Boreal');
    expect(tester.takeException(), isNull);
  });

  for (final (name, size, compact, tablet, scale) in [
    ('tablet', const Size(834, 900), false, true, 1.0),
    ('phone', const Size(390, 844), true, false, 1.0),
    ('phone with enlarged text', const Size(320, 700), true, false, 2.0),
  ]) {
    testWidgets('$name keeps search above usable project cards', (
      tester,
    ) async {
      await _pumpSafari(
        tester,
        size,
        compact: compact,
        tablet: tablet,
        bottom: 34,
        scale: scale,
        data: _searchData,
      );
      final search = find.byKey(const Key('safari-search-field'));
      final startPage = find.byKey(const Key('safari-start-page'));
      expect(search.hitTestable(), findsOneWidget);
      expect(
        tester.getBottomLeft(search).dy,
        lessThanOrEqualTo(tester.getTopLeft(startPage).dy),
      );
      expect(find.byKey(const Key('safari-all-tabs')), findsNothing);
      expect(find.byKey(const Key('safari-phone-toolbar')), findsNothing);
      expect(tester.takeException(), isNull);
      final lastCard = find.byKey(const Key('safari-project-card-1'));
      await tester.ensureVisible(lastCard);
      await tester.pumpAndSettle();
      expect(lastCard.hitTestable(), findsOneWidget);
      await tester.tap(lastCard);
      await tester.pumpAndSettle();
      _expectProject(tester, 'Boreal');
      expect(search.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('different projects have separate detail scroll positions', (
    tester,
  ) async {
    await _pumpSafari(tester, const Size(850, 650));
    await tester.tap(find.byKey(const Key('safari-favorite-0')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('safari-page')),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('safari-project-title')).hitTestable(),
      findsNothing,
    );
    await tester.tap(find.byKey(const Key('safari-home')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('safari-favorite-1')));
    await tester.pumpAndSettle();
    _expectProject(tester, portfolioData.projects[1].title);
    expect(
      find.byKey(const Key('safari-project-title')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('removing the current project returns safely to start page', (
    tester,
  ) async {
    await _pumpSafari(tester, const Size(1000, 900), data: _searchData);
    await tester.tap(find.byKey(const Key('safari-favorite-0')));
    await tester.pumpAndSettle();
    _expectProject(tester, 'Atlas');
    await _pumpSafari(
      tester,
      const Size(1000, 900),
      data: _dataWithProjects([_searchData.projects[1]]),
    );
    expect(find.byKey(const Key('safari-start-page')), findsOneWidget);
    expect(find.byKey(const Key('safari-project-title')), findsNothing);
    expect(find.byKey(const Key('safari-project-card-0')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _expectProject(WidgetTester tester, String title) {
  expect(find.byKey(const Key('safari-start-page')), findsNothing);
  expect(
    tester.widget<Text>(find.byKey(const Key('safari-project-title'))).data,
    title,
  );
}

final _searchData = _dataWithProjects(const [
  PortfolioProject.constant(
    title: 'Atlas',
    description: '여행 일정을 정리하는 지도',
    period: '2026',
    technologies: ['Dart'],
    links: [],
  ),
  PortfolioProject.constant(
    title: 'Boreal',
    description: '바다 관측 기록을 보여주는 도구',
    period: '2026',
    technologies: ['Rust'],
    category: PortfolioProjectCategory.personal,
    links: [],
  ),
]);

PortfolioData _dataWithProjects(List<PortfolioProject> projects) =>
    PortfolioData(
      identity: portfolioData.identity,
      experiences: portfolioData.experiences,
      education: portfolioData.education,
      skillGroups: portfolioData.skillGroups,
      projects: projects,
    );

Future<void> _pumpSafari(
  WidgetTester tester,
  Size size, {
  bool compact = false,
  bool tablet = false,
  double bottom = 0,
  double scale = 1,
  PortfolioData? data,
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
          data: data ?? portfolioData,
          compact: compact,
          tablet: tablet,
          launcher: CallbackExternalLauncher((_) async => true),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
