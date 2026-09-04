import 'dart:ui' show PointerDeviceKind;
import 'dart:ui' as ui show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/mobile/apple_mobile_shell.dart';
import 'package:portfolio_hesu/portfolio/portfolio_app.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/theme/portfolio_theme_controller.dart';

void main() {
  group('모바일 Instagram형 프로필 앱', () {
    testWidgets('iPhone과 iPad는 About과 분리된 프로필 앱을 연다', (tester) async {
      final semantics = tester.ensureSemantics();

      for (final scenario in const <(Size, bool)>[
        (Size(390, 844), false),
        (Size(834, 1194), true),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProfileShell(tester, size: scenario.$1, tablet: scenario.$2);

        final launcher = find.byKey(const Key('home-app-profile'));
        expect(launcher, findsOneWidget);
        expect(find.bySemanticsLabel('Open 프로필'), findsOneWidget);
        expect(find.byKey(const Key('about-app')), findsNothing);

        await tester.tap(launcher);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('profile-app')), findsOneWidget);
        expect(find.byKey(const Key('about-app')), findsNothing);
        expect(
          find.byKey(const Key('mobile-app-navigation-bar')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('mobile-app-more-profile')),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('Close 프로필 window'), findsOneWidget);
      }

      semantics.dispose();
    });

    testWidgets('피드는 identity와 연락처를 유지하고 게시물·경력·교육만 집계한다', (tester) async {
      final semantics = tester.ensureSemantics();
      final data = _injectedProfileData();
      final launcher = _RecordingLauncher();
      await _pumpProfileShell(
        tester,
        size: const Size(390, 844),
        tablet: false,
        data: data,
        launcher: launcher,
      );

      await _openProfile(tester);

      final profile = find.byKey(const Key('profile-app'));
      expect(profile, findsOneWidget);
      for (final text in <String>[
        data.identity.name,
        data.identity.englishName,
        data.identity.headline,
        data.identity.biography,
      ]) {
        expect(
          find.descendant(of: profile, matching: find.text(text)),
          findsOneWidget,
          reason: text,
        );
      }
      expect(find.bySemanticsLabel('게시물 5개'), findsOneWidget);
      expect(find.bySemanticsLabel('경력 3개'), findsOneWidget);
      expect(find.bySemanticsLabel('교육 2개'), findsOneWidget);
      expect(find.bySemanticsLabel('프로젝트 1개'), findsNothing);
      expect(find.bySemanticsLabel('스킬 2개'), findsNothing);
      expect(find.byKey(const Key('profile-github-action')), findsOneWidget);
      expect(find.byKey(const Key('profile-mail-action')), findsOneWidget);
      expect(find.byKey(const Key('profile-history-grid')), findsOneWidget);
      expect(find.byKey(const Key('profile-highlights')), findsNothing);
      expect(find.byKey(const Key('profile-project-grid')), findsNothing);
      expect(find.text(_sentinelSkillGroup), findsNothing);
      expect(find.text(_sentinelSkill), findsNothing);
      expect(find.text(_sentinelProjectTitle), findsNothing);
      expect(find.text(_sentinelProjectDescription), findsNothing);
      expect(_fakeSocialMetricTextInside(profile), findsNothing);

      await tester.ensureVisible(
        find.byKey(const Key('profile-github-action')),
      );
      await tester.tap(find.byKey(const Key('profile-github-action')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('profile-mail-action')));
      await tester.tap(find.byKey(const Key('profile-mail-action')));
      await tester.pumpAndSettle();

      expect(launcher.uris, <Uri>[
        Uri.parse(data.identity.githubUrl),
        Uri.parse('mailto:${data.identity.email}'),
      ]);
      semantics.dispose();
    });

    testWidgets('경력 다음 교육 순서의 버튼을 3열 정사각형 피드로 배치한다', (tester) async {
      final semantics = tester.ensureSemantics();
      final data = _injectedProfileData();
      for (final scenario in const <(String, Size, bool)>[
        ('iPhone', Size(390, 844), false),
        ('iPad', Size(834, 1194), true),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProfileShell(
          tester,
          size: scenario.$2,
          tablet: scenario.$3,
          data: data,
        );
        await _openProfile(tester);

        final cards = <Finder>[
          for (var index = 0; index < data.experiences.length; index++)
            find.byKey(Key('profile-history-card-experience-$index')),
          for (var index = 0; index < data.education.length; index++)
            find.byKey(Key('profile-history-card-education-$index')),
        ];
        final labels = <String>[
          for (final experience in data.experiences) experience.role,
          for (final education in data.education) education.program,
        ];
        final grid = find.byKey(const Key('profile-history-grid'));
        expect(grid, findsOneWidget, reason: scenario.$1);

        for (var index = 0; index < cards.length; index++) {
          final card = cards[index];
          await _ensureCardBuilt(tester, card);
          expect(
            card,
            findsOneWidget,
            reason: '${scenario.$1} ${labels[index]}',
          );
          expect(
            find.descendant(of: grid, matching: card),
            findsOneWidget,
            reason: '${scenario.$1} ${labels[index]}',
          );
          final semanticsLabel = index < data.experiences.length
              ? 'Open 경력: ${labels[index]}'
              : 'Open 교육: ${labels[index]}';
          final semanticsFinder = find.bySemanticsLabel(semanticsLabel);
          expect(
            find.descendant(
              of: card,
              matching: semanticsFinder,
              matchRoot: true,
            ),
            findsOneWidget,
            reason: '${scenario.$1} ${labels[index]}',
          );
          final semanticsData = tester
              .getSemantics(semanticsFinder)
              .getSemanticsData();
          expect(
            semanticsData.flagsCollection.isButton,
            isTrue,
            reason: '${scenario.$1} ${labels[index]}',
          );
          expect(
            semanticsData.hasAction(ui.SemanticsAction.tap),
            isTrue,
            reason: '${scenario.$1} ${labels[index]}',
          );
          expect(semanticsData.label, semanticsLabel);
        }
        await _expectThreeColumnSquareGrid(tester, cards);
      }
      semantics.dispose();
    });

    testWidgets('경력 카드는 실제 계정과 긴 소개를 담은 Reels형 상세를 연다', (tester) async {
      final semantics = tester.ensureSemantics();
      final data = _injectedProfileData();
      final experience = data.experiences.first;
      await _pumpProfileShell(
        tester,
        size: const Size(390, 844),
        tablet: false,
        data: data,
      );
      await _openProfile(tester);
      await _openHistoryCard(
        tester,
        const Key('profile-history-card-experience-0'),
      );

      final caption = find.byKey(const Key('profile-reel-caption'));
      _expectReelTemplate(
        tester,
        data: data,
        expectedCaption: experience.description,
      );
      for (final text in <String>[
        experience.role,
        experience.organization,
        experience.period,
        experience.description,
      ]) {
        expect(
          find.descendant(of: caption, matching: find.text(text)),
          findsOneWidget,
          reason: text,
        );
      }
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets('교육 상세는 실제 내용과 선택적 링크의 정확한 URI를 사용한다', (tester) async {
      final semantics = tester.ensureSemantics();
      final data = _injectedProfileData();
      final launcher = _RecordingLauncher();
      final linkedEducation = data.education.first;
      final link = linkedEducation.link!;
      await _pumpProfileShell(
        tester,
        size: const Size(390, 844),
        tablet: false,
        data: data,
        launcher: launcher,
      );
      await _openProfile(tester);
      await _openHistoryCard(
        tester,
        const Key('profile-history-card-education-0'),
      );

      final caption = find.byKey(const Key('profile-reel-caption'));
      _expectReelTemplate(
        tester,
        data: data,
        expectedCaption: linkedEducation.program,
      );
      for (final text in <String>[
        linkedEducation.program,
        linkedEducation.institution,
        linkedEducation.period,
      ]) {
        expect(
          find.descendant(of: caption, matching: find.text(text)),
          findsOneWidget,
          reason: text,
        );
      }
      final linkButton = find.bySemanticsLabel('Open ${link.label}');
      expect(linkButton, findsOneWidget);
      final linkSemantics = tester.getSemantics(linkButton).getSemanticsData();
      expect(linkSemantics.flagsCollection.isButton, isTrue);
      expect(linkSemantics.hasAction(ui.SemanticsAction.tap), isTrue);
      await tester.ensureVisible(linkButton);
      await tester.tap(linkButton);
      await tester.pumpAndSettle();
      expect(launcher.uris, <Uri>[link.uri]);

      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpProfileShell(
        tester,
        size: const Size(390, 844),
        tablet: false,
        data: data,
        launcher: launcher,
      );
      await _openProfile(tester);
      await _openHistoryCard(
        tester,
        const Key('profile-history-card-education-1'),
      );
      final unlinkedEducation = data.education[1];
      expect(find.text(unlinkedEducation.program), findsOneWidget);
      expect(find.text(unlinkedEducation.institution), findsOneWidget);
      expect(find.text(unlinkedEducation.period), findsOneWidget);
      expect(find.bySemanticsLabel('Open ${link.label}'), findsNothing);
      semantics.dispose();
    });

    testWidgets('공용 헤더는 상세에서 뒤로 가고 피드 루트에서 앱을 닫는다', (tester) async {
      final semantics = tester.ensureSemantics();
      final data = _injectedProfileData();
      final experience = data.experiences.first;
      for (final scenario in const <(String, Size, bool)>[
        ('iPhone', Size(390, 844), false),
        ('iPad', Size(834, 1194), true),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProfileShell(
          tester,
          size: scenario.$2,
          tablet: scenario.$3,
          data: data,
        );
        await _openProfile(tester);

        final control = find.byKey(const Key('mobile-back-close-profile'));
        expect(
          find.byKey(const Key('mobile-app-navigation-bar')),
          findsOneWidget,
          reason: scenario.$1,
        );
        expect(control, findsOneWidget, reason: scenario.$1);
        expect(
          tester.getSemantics(control).getSemanticsData().label,
          'Close 프로필 window',
          reason: scenario.$1,
        );

        await _openHistoryCard(
          tester,
          const Key('profile-history-card-experience-0'),
        );
        expect(
          find.byKey(const Key('mobile-app-navigation-bar')),
          findsOneWidget,
          reason: scenario.$1,
        );
        expect(find.byKey(const Key('profile-history-detail')), findsOneWidget);
        expect(
          tester.getSemantics(control).getSemanticsData().label,
          'Back in 프로필',
          reason: scenario.$1,
        );
        expect(find.bySemanticsLabel('Close 프로필 window'), findsNothing);
        final detail = find.byKey(const Key('profile-history-detail'));
        expect(find.byKey(const Key('profile-history-grid')), findsNothing);
        expect(find.byKey(const Key('profile-app')), findsOneWidget);
        expect(find.byKey(const Key('mobile-app-surface')), findsOneWidget);
        _expectReelTemplate(
          tester,
          data: data,
          expectedCaption: experience.description,
        );
        expect(_fakeSocialMetricTextInside(detail), findsNothing);
        expect(_fakeSocialMetricSemanticsInside(detail), findsNothing);

        await tester.tap(control);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('profile-history-detail')), findsNothing);
        expect(find.byKey(const Key('profile-history-grid')), findsOneWidget);
        expect(find.byKey(const Key('mobile-app-surface')), findsOneWidget);
        expect(
          find.byKey(const Key('mobile-app-navigation-bar')),
          findsOneWidget,
          reason: scenario.$1,
        );
        expect(
          tester.getSemantics(control).getSemanticsData().label,
          'Close 프로필 window',
          reason: scenario.$1,
        );

        await tester.tap(control);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('mobile-home')), findsOneWidget);
        expect(find.byKey(const Key('mobile-app-surface')), findsNothing);
      }
      semantics.dispose();
    });

    testWidgets('라이트와 다크의 iPhone·iPad 200% 피드와 상세가 넘치지 않는다', (tester) async {
      for (final formFactor in const <(Size, bool)>[
        (Size(320, 480), false),
        (Size(834, 620), true),
      ]) {
        final backgroundColors = <Brightness, Color>{};
        for (final brightness in Brightness.values) {
          final data = _injectedProfileData();
          await tester.pumpWidget(const SizedBox.shrink());
          await _pumpProfileShell(
            tester,
            size: formFactor.$1,
            tablet: formFactor.$2,
            brightness: brightness,
            textScaler: const TextScaler.linear(2),
            data: data,
          );

          await _openProfile(tester);

          final profile = find.byKey(const Key('profile-app'));
          expect(profile, findsOneWidget);
          final background = find.byKey(const Key('profile-background'));
          expect(background, findsOneWidget);
          backgroundColors[brightness] = tester
              .widget<ColoredBox>(background)
              .color;
          expect(find.byKey(const Key('profile-scroll')), findsOneWidget);
          expect(find.byKey(const Key('profile-history-grid')), findsOneWidget);
          expect(
            Theme.of(tester.element(profile)).brightness,
            brightness,
            reason: '${formFactor.$1} $brightness',
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '${formFactor.$1} $brightness feed',
          );

          await _openHistoryCard(
            tester,
            const Key('profile-history-card-experience-0'),
          );
          expect(
            find.byKey(const Key('profile-history-detail')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('profile-history-detail-scroll')),
            findsOneWidget,
          );
          expect(
            Theme.of(
              tester.element(find.byKey(const Key('profile-history-detail'))),
            ).brightness,
            brightness,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '${formFactor.$1} $brightness detail',
          );

          await tester.tap(find.byKey(const Key('mobile-back-close-profile')));
          await tester.pumpAndSettle();
          await _openHistoryCard(
            tester,
            const Key('profile-history-card-education-0'),
          );
          expect(
            find.byKey(const Key('profile-history-detail')),
            findsOneWidget,
          );
          expect(find.text(data.education.first.program), findsOneWidget);
          expect(
            tester.takeException(),
            isNull,
            reason: '${formFactor.$1} $brightness education detail',
          );
        }
        expect(
          backgroundColors[Brightness.light],
          isNot(backgroundColors[Brightness.dark]),
          reason: '${formFactor.$1} light and dark surfaces',
        );
      }
    });

    testWidgets('iPhone과 iPad의 피드와 상세는 터치와 마우스 드래그로 스크롤된다', (tester) async {
      for (final scenario in const <(String, Size, bool)>[
        ('iPhone', Size(320, 480), false),
        ('iPad', Size(834, 620), true),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProfileShell(
          tester,
          size: scenario.$2,
          tablet: scenario.$3,
          data: _injectedProfileData(),
        );
        await _openProfile(tester);
        await _expectTouchAndMouseScroll(
          tester,
          const Key('profile-scroll'),
          reason: '${scenario.$1} feed',
        );
        await _openHistoryCard(
          tester,
          const Key('profile-history-card-experience-0'),
        );
        await _expectTouchAndMouseScroll(
          tester,
          const Key('profile-history-detail-scroll'),
          reason: '${scenario.$1} detail',
        );
        expect(tester.takeException(), isNull, reason: scenario.$1);
      }
    });
  });
}

Future<void> _pumpProfileShell(
  WidgetTester tester, {
  required Size size,
  required bool tablet,
  PortfolioData data = portfolioData,
  ExternalLauncher? launcher,
  Brightness brightness = Brightness.light,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final themeController = PortfolioThemeController(
    initial: brightness == Brightness.dark
        ? PortfolioThemePreference.dark
        : PortfolioThemePreference.light,
  );
  addTearDown(themeController.dispose);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.light(),
      darkTheme: AppleTheme.dark(),
      themeMode: themeController.themeMode,
      scrollBehavior: const PortfolioScrollBehavior(),
      home: MediaQuery(
        data: MediaQueryData(size: size, textScaler: textScaler),
        child: AppleMobileShell(
          data: data,
          externalLauncher: launcher ?? _RecordingLauncher(),
          themeController: themeController,
          tablet: tablet,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

PortfolioData _injectedProfileData() {
  return PortfolioData(
    identity: const PortfolioIdentity(
      name: '프로필 사용자',
      englishName: 'Profile User',
      email: 'profile@example.com',
      githubUrl: 'https://github.com/profile-user/',
      headline: 'Injected profile headline',
      biography: 'Injected profile biography',
    ),
    experiences: const <PortfolioExperience>[
      PortfolioExperience(
        role: 'Lead Flutter Developer',
        organization: 'Profile Company Alpha',
        period: '2024 - Present',
        description: _longExperienceDescription,
      ),
      PortfolioExperience(
        role: 'Mobile Engineer',
        organization: 'Profile Company Beta',
        period: '2022 - 2024',
        description: 'Flutter와 Dart 기반 모바일 제품의 설계와 출시를 담당했습니다.',
      ),
      PortfolioExperience(
        role: 'Junior Java Developer',
        organization: 'Profile Company Gamma',
        period: '2020 - 2021',
        description: 'Java 기반 애플리케이션 개발과 운영 자동화를 경험했습니다.',
      ),
    ],
    education: const <PortfolioEducation>[
      PortfolioEducation(
        program: 'Advanced Mobile Application Development Program',
        institution: 'Profile Technology Academy',
        period: '2019 - 2020',
        link: PortfolioProjectLink(
          label: 'Education certificate',
          url: 'https://example.com/education/certificate',
        ),
      ),
      PortfolioEducation(
        program: 'Game Entertainment and Business Degree',
        institution: 'Profile University',
        period: '2009 - 2011',
      ),
    ],
    skillGroups: const <PortfolioSkillGroup>[
      PortfolioSkillGroup.constant(
        title: _sentinelSkillGroup,
        skills: <String>[_sentinelSkill, 'SECOND_SENTINEL_SKILL'],
      ),
    ],
    projects: const <PortfolioProject>[
      PortfolioProject.constant(
        title: _sentinelProjectTitle,
        description: _sentinelProjectDescription,
        period: '2026',
        technologies: <String>['SENTINEL_PROJECT_TECHNOLOGY'],
        links: <PortfolioProjectLink>[],
      ),
    ],
  );
}

final class _RecordingLauncher implements ExternalLauncher {
  final List<Uri> uris = <Uri>[];

  @override
  Future<bool> launch(Uri uri) async {
    uris.add(uri);
    return true;
  }
}

Finder _scrollableInside(Key key) {
  return find.descendant(
    of: find.byKey(key),
    matching: find.byType(Scrollable),
  );
}

Future<void> _openProfile(WidgetTester tester) async {
  final profileLauncher = find.byKey(const Key('home-app-profile'));
  expect(profileLauncher, findsOneWidget);
  await tester.tap(profileLauncher);
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('profile-app')), findsOneWidget);
}

Future<void> _openHistoryCard(WidgetTester tester, Key cardKey) async {
  final card = find.byKey(cardKey);
  await _ensureCardBuilt(tester, card);
  expect(card, findsOneWidget);
  await tester.ensureVisible(card);
  await tester.pumpAndSettle();
  await tester.tap(card);
  await tester.pumpAndSettle();
}

Future<void> _expectThreeColumnSquareGrid(
  WidgetTester tester,
  List<Finder> cards,
) async {
  expect(cards, hasLength(5));
  final rects = <Rect>[];
  final contentTops = <double>[];
  final position = tester
      .state<ScrollableState>(_scrollableInside(const Key('profile-scroll')))
      .position;
  for (final card in cards) {
    await _ensureCardBuilt(tester, card);
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    expect(card, findsOneWidget);
    final rect = tester.getRect(card);
    expect(rect.width, closeTo(rect.height, 0.5));
    rects.add(rect);
    contentTops.add(rect.top + position.pixels);
  }

  expect(contentTops[0], closeTo(contentTops[1], 0.5));
  expect(contentTops[1], closeTo(contentTops[2], 0.5));
  expect(rects[0].left, lessThan(rects[1].left));
  expect(rects[1].left, lessThan(rects[2].left));
  expect(contentTops[3], greaterThan(contentTops[2]));
  expect(contentTops[3], closeTo(contentTops[4], 0.5));
  expect(rects[3].left, lessThan(rects[4].left));
  expect(rects[3].left, closeTo(rects[0].left, 0.5));
  expect(rects[4].left, closeTo(rects[1].left, 0.5));
}

Future<void> _ensureCardBuilt(WidgetTester tester, Finder card) async {
  final scrollable = _scrollableInside(const Key('profile-scroll'));
  final position = tester.state<ScrollableState>(scrollable).position;
  while (card.evaluate().isEmpty &&
      position.pixels < position.maxScrollExtent) {
    await tester.drag(
      find.byKey(const Key('profile-scroll')),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _expectTouchAndMouseScroll(
  WidgetTester tester,
  Key scrollKey, {
  required String reason,
}) async {
  final target = find.byKey(scrollKey);
  expect(target, findsOneWidget, reason: reason);
  final scrollable = find.descendant(
    of: target,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          (widget.axisDirection == AxisDirection.down ||
              widget.axisDirection == AxisDirection.up),
      description: 'vertical Scrollable',
    ),
  );
  expect(scrollable, findsOneWidget, reason: reason);
  final position = tester.state<ScrollableState>(scrollable).position;
  expect(position.maxScrollExtent, greaterThan(0), reason: reason);

  await tester.drag(target, const Offset(0, -180));
  await tester.pumpAndSettle();
  expect(position.pixels, greaterThan(0), reason: '$reason touch');

  position.jumpTo(0);
  await tester.pump();
  final center = tester.getCenter(target);
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: center);
  await mouse.down(center);
  await mouse.moveBy(const Offset(0, -180));
  await mouse.up();
  await tester.pumpAndSettle();
  expect(position.pixels, greaterThan(0), reason: '$reason mouse');
  await mouse.removePointer();

  position.jumpTo(0);
  await tester.pump();
}

Finder _fakeSocialMetricTextInside(Finder scope) {
  return find.descendant(
    of: scope,
    matching: find.textContaining(_fakeSocialMetricPattern, findRichText: true),
  );
}

Finder _fakeSocialMetricSemanticsInside(Finder scope) {
  return find.descendant(
    of: scope,
    matching: find.bySemanticsLabel(_fakeSocialMetricPattern),
  );
}

void _expectReelTemplate(
  WidgetTester tester, {
  required PortfolioData data,
  required String expectedCaption,
}) {
  final detail = find.byKey(const Key('profile-history-detail'));
  final context = find.byKey(const Key('profile-reel-context'));
  final visual = find.byKey(const Key('profile-reel-visual'));
  final account = find.byKey(const Key('profile-reel-account-row'));
  final caption = find.byKey(const Key('profile-reel-caption'));

  expect(detail, findsOneWidget);
  expect(context, findsOneWidget);
  expect(
    find.descendant(of: context, matching: find.text('Reels')),
    findsOneWidget,
  );
  expect(visual, findsOneWidget);
  final visualRect = tester.getRect(visual);
  expect(visualRect.height, greaterThan(visualRect.width));
  expect(visualRect.width, greaterThan(tester.getSize(detail).width * 0.55));
  expect(
    find.descendant(
      of: visual,
      matching: find.byKey(const Key('profile-reel-artwork')),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(of: visual, matching: find.byType(Image)),
    findsNothing,
  );
  expect(
    find.descendant(of: visual, matching: find.byType(RawImage)),
    findsNothing,
  );
  expect(
    find.descendant(
      of: visual,
      matching: find.byWidgetPredicate(
        (widget) => switch (widget) {
          Container(:final decoration) =>
            decoration is BoxDecoration && decoration.image != null,
          DecoratedBox(:final decoration) =>
            decoration is BoxDecoration && decoration.image != null,
          _ => false,
        },
        description: 'widget with a DecorationImage',
      ),
    ),
    findsNothing,
  );
  expect(account, findsOneWidget);
  expect(
    find.descendant(of: account, matching: find.text(data.identity.name)),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: account,
      matching: find.byKey(const Key('profile-reel-avatar')),
    ),
    findsOneWidget,
  );
  expect(caption, findsOneWidget);
  final captionText = tester.widget<Text>(
    find.descendant(of: caption, matching: find.text(expectedCaption)),
  );
  expect(captionText.maxLines, isNull);
  expect(captionText.overflow, isNot(TextOverflow.ellipsis));
  expect(tester.getRect(context).top, lessThan(tester.getRect(visual).top));
  expect(tester.getRect(visual).top, lessThan(tester.getRect(account).top));
  expect(tester.getRect(account).top, lessThan(tester.getRect(caption).top));
  expect(find.byKey(const Key('profile-reel-like-count')), findsNothing);
  expect(find.byKey(const Key('profile-reel-follower-count')), findsNothing);
  expect(find.byKey(const Key('mobile-app-navigation-bar')), findsOneWidget);
  expect(_fakeSocialMetricTextInside(detail), findsNothing);
  expect(_fakeSocialMetricSemanticsInside(detail), findsNothing);
}

const _sentinelSkillGroup = 'SENTINEL_SKILL_GROUP';
const _sentinelSkill = 'SENTINEL_SKILL';
const _sentinelProjectTitle = 'SENTINEL_PROJECT_TITLE';
const _sentinelProjectDescription = 'SENTINEL_PROJECT_DESCRIPTION';
const _longExperienceDescription =
    '사용자 문제를 분석하고 Flutter 애플리케이션의 구조를 설계한 뒤 구현과 출시를 '
    '담당했습니다. 다양한 화면 크기와 접근성 글자 크기를 함께 검증하고, 제품 출시 이후에는 '
    '사용자 피드백과 운영 지표를 바탕으로 긴 호흡의 개선 작업을 반복했습니다. 이 설명은 작은 '
    'iPhone과 iPad의 상세 화면에서 실제 스크롤이 필요한 길이를 보장하기 위한 테스트 데이터입니다.';

final _fakeSocialMetricPattern = RegExp(
  r'(?:\d[\d,.]*\s*(?:[KkMm]|만)?\s*'
  r'(?:좋아요|팔로워|팔로잉|likes?|followers?|following))|'
  r'(?:(?:좋아요|팔로워|팔로잉|likes?|followers?|following)\s*'
  r'\d[\d,.]*\s*(?:[KkMm]|만)?)',
  caseSensitive: false,
);
