import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/skills_app.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';

void main() {
  group('Slack-inspired Skills wide layout', () {
    testWidgets('uses portfolio groups in a three-pane workspace', (
      tester,
    ) async {
      await _pumpSkills(tester, size: const Size(900, 650));

      expect(find.byKey(const Key('skills-workspace-rail')), findsOneWidget);
      expect(find.byKey(const Key('skills-channel-sidebar')), findsOneWidget);
      expect(find.byKey(const Key('skills-channel-detail')), findsOneWidget);
      expect(find.byKey(const Key('skills-channel-picker')), findsNothing);

      for (final group in _data.skillGroups) {
        expect(
          find.byKey(Key('skills-category-${group.title}')),
          findsOneWidget,
        );
      }
      for (final skill in _data.skillGroups.first.skills) {
        expect(find.byKey(Key('skill-item-$skill')), findsOneWidget);
        expect(find.byKey(Key('skills-message-row-$skill')), findsOneWidget);
      }

      expect(find.text('Flutter'), findsNothing);
      expect(find.text('(주)상상력집단'), findsNothing);
      expect(find.text('업무보고'), findsNothing);
      expect(find.text('구매대행공급'), findsNothing);
    });

    testWidgets('supports tap, Enter, Space, focus, and selected semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpSkills(tester, size: const Size(900, 650));

      final first = find.byKey(const Key('skills-category-Mobile Systems'));
      final second = find.byKey(const Key('skills-category-Team Tools'));
      final third = find.byKey(const Key('skills-category-Visual Craft'));

      for (final target in <Finder>[first, second, third]) {
        expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
        final data = tester.getSemantics(target).getSemanticsData();
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
      }
      expect(
        tester
            .getSemantics(first)
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        ui.Tristate.isTrue,
      );

      await tester.tap(second);
      await tester.pumpAndSettle();
      expect(find.text('Planning Board'), findsOneWidget);
      expect(find.text('Dart VM'), findsNothing);
      expect(
        tester
            .getSemantics(second)
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        ui.Tristate.isTrue,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        tester.getSemantics(first).getSemanticsData().flagsCollection.isFocused,
        ui.Tristate.isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Dart VM'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.text('Vector Layout'), findsOneWidget);
      expect(
        find.descendant(
          of: third,
          matching: find.byKey(const Key('apple-selection-focus')),
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('keeps navigation text AA-readable in Light and Dark', (
      tester,
    ) async {
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpSkills(
          tester,
          size: const Size(900, 650),
          brightness: brightness,
        );

        final sidebar = tester.widget<Container>(
          find.byKey(const Key('skills-channel-sidebar')),
        );
        final background = (sidebar.decoration! as BoxDecoration).color!;
        final channelText = tester.widget<Text>(
          find.descendant(
            of: find.byKey(const Key('skills-channel-sidebar')),
            matching: find.text('Channels'),
          ),
        );
        final foreground = channelText.style!.color!;

        expect(
          _contrastRatio(background, foreground),
          greaterThanOrEqualTo(4.5),
          reason: brightness.name,
        );
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('Slack-inspired Skills compact layout', () {
    testWidgets('uses a horizontal picker and vertical message rows', (
      tester,
    ) async {
      await _pumpSkills(
        tester,
        size: const Size(320, 480),
        compact: true,
        textScaler: const TextScaler.linear(2),
      );

      expect(find.byKey(const Key('skills-workspace-rail')), findsNothing);
      expect(find.byKey(const Key('skills-channel-sidebar')), findsNothing);
      expect(find.byKey(const Key('skills-channel-detail')), findsNothing);
      final picker = find.byKey(const Key('skills-channel-picker'));
      expect(picker, findsOneWidget);
      expect(
        tester.widget<SingleChildScrollView>(picker).scrollDirection,
        Axis.horizontal,
      );

      final first = tester.getRect(
        find.byKey(const Key('skills-message-row-Dart VM')),
      );
      final second = tester.getRect(
        find.byKey(const Key('skills-message-row-Widget Lab')),
      );
      expect(second.top, greaterThan(first.bottom));
      expect(second.left, first.left);

      final scrollable = find.byKey(const Key('skills-list'));
      final before = tester.getTopLeft(
        find.byKey(const Key('skills-message-row-Dart VM')),
      );
      await tester.drag(scrollable, const Offset(0, -180));
      await tester.pumpAndSettle();
      final after = tester.getTopLeft(
        find.byKey(const Key('skills-message-row-Dart VM')),
      );
      expect(after.dy, lessThan(before.dy));
      expect(tester.takeException(), isNull);
    });

    testWidgets('switches to compact structure below the wide threshold', (
      tester,
    ) async {
      await _pumpSkills(tester, size: const Size(679, 600));
      expect(find.byKey(const Key('skills-channel-picker')), findsOneWidget);
      expect(find.byKey(const Key('skills-workspace-rail')), findsNothing);

      await _pumpSkills(tester, size: const Size(680, 600));
      expect(find.byKey(const Key('skills-workspace-rail')), findsOneWidget);
      expect(find.byKey(const Key('skills-channel-picker')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('resets the message list to the top when changing channels', (
      tester,
    ) async {
      await _pumpSkills(
        tester,
        size: const Size(320, 480),
        compact: true,
        textScaler: const TextScaler.linear(2),
      );

      final list = find.byKey(const Key('skills-list'));
      final scrollable = find.descendant(
        of: list,
        matching: find.byType(Scrollable),
      );
      await tester.drag(list, const Offset(0, -260));
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(scrollable).position.pixels,
        greaterThan(0),
      );

      final nextCategory = find.byKey(const Key('skills-category-Team Tools'));
      await tester.ensureVisible(nextCategory);
      await tester.tap(nextCategory);
      await tester.pumpAndSettle();

      expect(tester.state<ScrollableState>(scrollable).position.pixels, 0);
      final listRect = tester.getRect(list);
      final firstSkillRect = tester.getRect(
        find.byKey(const Key('skills-message-row-Planning Board')),
      );
      expect(listRect.overlaps(firstSkillRect), isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}

const PortfolioData _data = PortfolioData.constant(
  identity: PortfolioIdentity(
    name: '테스트',
    englishName: 'Test',
    email: 'test@example.com',
    githubUrl: 'https://example.com',
    headline: 'Test headline',
    biography: 'Test biography',
  ),
  experiences: <PortfolioExperience>[],
  education: <PortfolioEducation>[],
  skillGroups: <PortfolioSkillGroup>[
    PortfolioSkillGroup.constant(
      title: 'Mobile Systems',
      skills: <String>['Dart VM', 'Widget Lab', 'Release Pipeline'],
    ),
    PortfolioSkillGroup.constant(
      title: 'Team Tools',
      skills: <String>[
        'Planning Board',
        'Async Review',
        'Review Queue',
        'Shared Notes',
      ],
    ),
    PortfolioSkillGroup.constant(
      title: 'Visual Craft',
      skills: <String>['Vector Layout', 'Motion Study'],
    ),
  ],
  projects: <PortfolioProject>[],
);

Future<void> _pumpSkills(
  WidgetTester tester, {
  required Size size,
  bool compact = false,
  Brightness brightness = Brightness.light,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.light(),
      darkTheme: AppleTheme.dark(),
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: SizedBox.expand(
          child: SkillsApp(data: _data, compact: compact),
        ),
      ),
    ),
  );
  await tester.pump();
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
