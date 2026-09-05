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

    testWidgets('desktop channels use the dated activity message feed', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpSkills(
        tester,
        size: const Size(900, 650),
        data: _mobileData,
        now: _fixedNow,
      );

      expect(find.byKey(const Key('skills-workspace-rail')), findsOneWidget);
      expect(find.byKey(const Key('skills-channel-sidebar')), findsOneWidget);
      expect(find.byKey(const Key('skills-channel-detail')), findsOneWidget);
      expect(find.text('# Development'), findsOneWidget);
      expect(find.text('1명의 멤버'), findsOneWidget);
      expect(find.text('1개의 탭'), findsOneWidget);
      expect(find.text('오늘 · 2026년 9월 5일'), findsOneWidget);
      expect(
        tester
            .getSemantics(
              find.byKey(const Key('skills-message-avatar-Flutter')),
            )
            .getSemanticsData()
            .flagsCollection
            .isImage,
        isTrue,
      );
      expect(
        find.byKey(const Key('skills-message-author-Flutter')),
        findsOneWidget,
      );
      expect(find.text('9:00 오전'), findsOneWidget);
      expect(find.textContaining('금일 업무 보고'), findsOneWidget);
      expect(find.textContaining('Flutter 개인 프로젝트 어플 개발'), findsOneWidget);

      await tester.tap(find.byKey(const Key('skills-category-Collaboration')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('skills-message-author-Notion')),
        findsOneWidget,
      );
      expect(find.text('프로젝트 문서 정리'), findsOneWidget);
      expect(
        find.byKey(const Key('skills-message-author-Flutter')),
        findsNothing,
      );
      expect(find.textContaining('금일 업무 보고'), findsNothing);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets('tablet channels use the same dated activity message feed', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpSkills(
        tester,
        size: const Size(600, 650),
        data: _mobileData,
        mobile: true,
        tablet: true,
        now: _fixedNow,
      );

      expect(find.byKey(const Key('skills-workspace-rail')), findsOneWidget);
      expect(find.byKey(const Key('skills-channel-sidebar')), findsOneWidget);
      expect(find.byKey(const Key('skills-channel-detail')), findsOneWidget);
      expect(
        find.byKey(const Key('skills-mobile-channel-detail')),
        findsNothing,
      );
      expect(find.text('# Development'), findsOneWidget);
      expect(find.text('1명의 멤버'), findsOneWidget);
      expect(find.text('1개의 탭'), findsOneWidget);
      expect(find.text('오늘 · 2026년 9월 5일'), findsOneWidget);
      expect(
        tester
            .getSemantics(
              find.byKey(const Key('skills-message-avatar-Flutter')),
            )
            .getSemanticsData()
            .flagsCollection
            .isImage,
        isTrue,
      );
      expect(
        find.byKey(const Key('skills-message-author-Flutter')),
        findsOneWidget,
      );
      expect(find.text('9:00 오전'), findsOneWidget);
      expect(find.textContaining('금일 업무 보고'), findsOneWidget);
      expect(find.textContaining('Flutter 개인 프로젝트 어플 개발'), findsOneWidget);

      await tester.tap(find.byKey(const Key('skills-category-Design & UI/UX')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('skills-message-author-Figma')),
        findsOneWidget,
      );
      expect(find.text('디자인 시스템 정리'), findsOneWidget);
      expect(
        find.byKey(const Key('skills-message-author-Flutter')),
        findsNothing,
      );
      expect(find.textContaining('금일 업무 보고'), findsNothing);
      expect(tester.takeException(), isNull);
      semantics.dispose();
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
    testWidgets('shows one injected certification above three group channels', (
      tester,
    ) async {
      await _pumpSkills(
        tester,
        size: const Size(320, 480),
        data: _mobileData,
        compact: true,
        mobile: true,
        textScaler: const TextScaler.linear(2),
      );

      expect(find.byKey(const Key('skills-workspace-rail')), findsNothing);
      expect(find.byKey(const Key('skills-channel-sidebar')), findsNothing);
      expect(find.byKey(const Key('skills-channel-detail')), findsNothing);
      expect(find.byKey(const Key('skills-channel-picker')), findsNothing);

      final cards = find.byKey(const Key('skills-mobile-certification-strip'));
      expect(cards, findsOneWidget);
      expect(
        tester.widget<SingleChildScrollView>(cards).scrollDirection,
        Axis.horizontal,
      );
      expect(
        find.byKey(const Key('skills-mobile-certification-정보처리기사')),
        findsOneWidget,
      );
      expect(find.text('정보처리기사'), findsOneWidget);
      expect(
        find.byKey(const Key('skills-mobile-summary-strip')),
        findsNothing,
      );

      expect(
        find.byKey(const Key('skills-mobile-channel-list')),
        findsOneWidget,
      );
      for (final group in _mobileData.skillGroups) {
        expect(
          find.byKey(Key('skills-mobile-channel-${group.title}')),
          findsOneWidget,
        );
        expect(find.text('# ${group.title}'), findsOneWidget);
        for (final skill in group.skills) {
          expect(find.byKey(Key('skills-mobile-channel-$skill')), findsNothing);
          expect(find.text('# $skill'), findsNothing);
        }
      }
      expect(
        find.byKey(const Key('skills-mobile-channel-detail')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps certification text at the full accessibility scale', (
      tester,
    ) async {
      await _pumpSkills(
        tester,
        size: const Size(320, 480),
        data: _mobileData,
        compact: true,
        mobile: true,
        textScaler: const TextScaler.linear(2),
      );

      final card = find.byKey(const Key('skills-mobile-certification-정보처리기사'));
      final certification = find.descendant(
        of: card,
        matching: find.text('정보처리기사'),
      );
      expect(
        find.descendant(of: card, matching: find.byType(FittedBox)),
        findsNothing,
      );
      expect(tester.widget<Text>(certification).maxLines, isNull);
      expect(tester.getSize(card).height, greaterThan(100));
      expect(tester.takeException(), isNull);
    });

    testWidgets('opens a channel as a second depth and returns to the list', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpSkills(
        tester,
        size: const Size(390, 700),
        data: _mobileData,
        compact: true,
        mobile: true,
      );

      final development = find.byKey(
        const Key('skills-mobile-channel-Development'),
      );
      expect(tester.getSize(development).height, greaterThanOrEqualTo(44));
      final channelSemantics = tester
          .getSemantics(development)
          .getSemanticsData();
      expect(channelSemantics.flagsCollection.isButton, isTrue);
      expect(channelSemantics.hasAction(ui.SemanticsAction.tap), isTrue);

      await tester.tap(development);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('skills-mobile-channel-detail')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('skills-mobile-channel-list')), findsNothing);
      expect(find.text('# Development'), findsOneWidget);
      expect(find.text('1명의 멤버'), findsOneWidget);
      expect(find.text('1개의 탭'), findsOneWidget);
      expect(find.text('# Collaboration'), findsNothing);
      expect(find.text('# Design & UI/UX'), findsNothing);

      final back = find.byKey(const Key('skills-mobile-detail-back'));
      expect(tester.getSize(back).height, greaterThanOrEqualTo(44));
      expect(tester.getSize(back).width, greaterThanOrEqualTo(44));
      final backSemantics = tester.getSemantics(back).getSemanticsData();
      expect(backSemantics.flagsCollection.isButton, isTrue);
      expect(backSemantics.hasAction(ui.SemanticsAction.tap), isTrue);

      await tester.tap(back);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('skills-mobile-channel-list')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('skills-mobile-channel-detail')),
        findsNothing,
      );
      for (final group in _mobileData.skillGroups) {
        expect(
          find.byKey(Key('skills-mobile-channel-${group.title}')),
          findsOneWidget,
        );
      }
      semantics.dispose();
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps the channel header fixed above a dated message feed', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpSkills(
        tester,
        size: const Size(320, 480),
        data: _mobileData,
        compact: true,
        mobile: true,
        textScaler: const TextScaler.linear(2),
        now: _fixedNow,
      );

      await tester.tap(
        find.byKey(const Key('skills-mobile-channel-Development')),
      );
      await tester.pumpAndSettle();

      final header = find.byKey(const Key('skills-mobile-channel-header'));
      final messages = find.byKey(const Key('skills-mobile-message-list'));
      final date = find.byKey(const Key('skills-mobile-message-date'));
      expect(header, findsOneWidget);
      expect(messages, findsOneWidget);
      expect(date, findsOneWidget);
      expect(find.text('오늘 · 2026년 9월 5일'), findsOneWidget);

      final avatar = find.byKey(const Key('skills-message-avatar-Flutter'));
      final avatarSemantics = tester.getSemantics(avatar).getSemanticsData();
      expect(avatarSemantics.flagsCollection.isImage, isTrue);
      expect(avatarSemantics.label, contains('Flutter'));
      expect(
        find.byKey(const Key('skills-message-author-Flutter')),
        findsOneWidget,
      );
      expect(find.text('Flutter'), findsOneWidget);
      expect(
        find.byKey(const Key('skills-message-time-Flutter')),
        findsOneWidget,
      );
      expect(find.text('9:00 오전'), findsOneWidget);
      expect(
        find.byKey(const Key('skills-message-content-Flutter')),
        findsOneWidget,
      );
      expect(find.textContaining('금일 업무 보고'), findsOneWidget);
      expect(find.textContaining('Flutter 개인 프로젝트 어플 개발'), findsOneWidget);
      expect(
        tester
            .getSemantics(
              find.byKey(const Key('skills-message-author-Flutter')),
            )
            .getSemanticsData()
            .label,
        contains('Flutter'),
      );
      expect(
        tester
            .getSemantics(find.byKey(const Key('skills-message-time-Flutter')))
            .getSemanticsData()
            .label,
        contains('9:00 오전'),
      );
      expect(
        tester
            .getSemantics(
              find.byKey(const Key('skills-message-content-Flutter')),
            )
            .getSemanticsData()
            .label,
        allOf(contains('금일 업무 보고'), contains('Flutter 개인 프로젝트 어플 개발')),
      );

      final headerTopBefore = tester.getTopLeft(header).dy;
      final dateTopBefore = tester.getTopLeft(date).dy;
      await tester.drag(messages, const Offset(0, -80));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(header).dy, closeTo(headerTopBefore, 0.01));
      expect(tester.getTopLeft(date).dy, lessThan(dateTopBefore));
      semantics.dispose();
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps non-mobile and tablet layouts on three panes', (
      tester,
    ) async {
      for (final width in <double>[679, 620]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpSkills(tester, size: Size(width, 600), data: _mobileData);
        expect(find.byKey(const Key('skills-workspace-rail')), findsOneWidget);
        expect(find.byKey(const Key('skills-channel-sidebar')), findsOneWidget);
        expect(find.byKey(const Key('skills-channel-detail')), findsOneWidget);
        expect(
          find.byKey(const Key('skills-mobile-certification-strip')),
          findsNothing,
        );
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpSkills(
        tester,
        size: const Size(600, 600),
        data: _mobileData,
        mobile: true,
        tablet: true,
      );
      expect(find.byKey(const Key('skills-workspace-rail')), findsOneWidget);
      expect(find.byKey(const Key('skills-channel-sidebar')), findsOneWidget);
      expect(find.byKey(const Key('skills-channel-detail')), findsOneWidget);
      expect(
        find.byKey(const Key('skills-mobile-certification-strip')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'renders accessible list and detail surfaces at 200% in both themes',
      (tester) async {
        Color? previous;
        for (final brightness in Brightness.values) {
          await tester.pumpWidget(const SizedBox.shrink());
          await _pumpSkills(
            tester,
            size: const Size(320, 480),
            data: _mobileData,
            compact: true,
            mobile: true,
            brightness: brightness,
            textScaler: const TextScaler.linear(2),
            now: _fixedNow,
          );

          final surface = tester.widget<ColoredBox>(
            find.byKey(const Key('skills-mobile-surface')),
          );
          expect(surface.color, isNot(previous));
          expect(find.text('정보처리기사'), findsOneWidget);

          final development = find.byKey(
            const Key('skills-mobile-channel-Development'),
          );
          expect(tester.getSize(development).height, greaterThanOrEqualTo(44));
          final channelSemantics = tester
              .getSemantics(development)
              .getSemanticsData();
          expect(channelSemantics.flagsCollection.isButton, isTrue);
          expect(channelSemantics.hasAction(ui.SemanticsAction.tap), isTrue);

          await tester.tap(development);
          await tester.pumpAndSettle();
          final back = find.byKey(const Key('skills-mobile-detail-back'));
          expect(tester.getSize(back).height, greaterThanOrEqualTo(44));
          expect(
            tester
                .getSemantics(back)
                .getSemanticsData()
                .flagsCollection
                .isButton,
            isTrue,
          );
          expect(find.text('오늘 · 2026년 9월 5일'), findsOneWidget);
          expect(tester.takeException(), isNull, reason: brightness.name);
          previous = surface.color;
        }
      },
    );
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

const PortfolioData _mobileData = PortfolioData.constant(
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
  certifications: <String>['정보처리기사'],
  skillGroups: <PortfolioSkillGroup>[
    PortfolioSkillGroup.constant(
      title: 'Development',
      skills: <String>['Flutter', 'Dart', 'React', 'Java'],
      activityDescriptions: <String, String>{
        'Flutter': '금일 업무 보고\nFlutter 개인 프로젝트 어플 개발',
        'Dart': 'Dart 코드 품질 개선',
        'React': 'React 화면 구조 검토',
        'Java': 'Java 서비스 유지보수',
      },
    ),
    PortfolioSkillGroup.constant(
      title: 'Collaboration',
      skills: <String>['Notion', 'Slack', 'Trello'],
      activityDescriptions: <String, String>{
        'Notion': '프로젝트 문서 정리',
        'Slack': '팀 진척 사항 공유',
        'Trello': '일정과 작업 상태 관리',
      },
    ),
    PortfolioSkillGroup.constant(
      title: 'Design & UI/UX',
      skills: <String>['Figma', 'Adobe Photoshop', 'Adobe Illustrator'],
      activityDescriptions: <String, String>{
        'Figma': '디자인 시스템 정리',
        'Adobe Photoshop': '비주얼 자산 보정',
        'Adobe Illustrator': '벡터 아이콘 제작',
      },
    ),
  ],
  projects: <PortfolioProject>[],
);

DateTime _fixedNow() => DateTime(2026, 9, 5, 9);

Future<void> _pumpSkills(
  WidgetTester tester, {
  required Size size,
  PortfolioData data = _data,
  bool compact = false,
  bool mobile = false,
  bool tablet = false,
  Brightness brightness = Brightness.light,
  TextScaler textScaler = TextScaler.noScaling,
  DateTime Function()? now,
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
          child: SkillsApp(
            data: data,
            compact: compact,
            mobile: mobile,
            tablet: tablet,
            now: now ?? _fixedNow,
          ),
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
