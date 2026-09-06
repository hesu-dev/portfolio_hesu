import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/portfolio_app_content.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/theme/portfolio_theme_controller.dart';
import 'package:portfolio_hesu/portfolio/widgets/apple_app_icon.dart';

import 'support/music_test_controller.dart';

void main() {
  group('AppleAppIcon', () {
    testWidgets('maps every portfolio app to a stable label and key', (
      tester,
    ) async {
      final tapped = <PortfolioAppId>[];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppleTheme.light(),
          home: Material(
            child: Wrap(
              children: <Widget>[
                for (final appId in PortfolioAppId.values)
                  AppleAppIcon(appId: appId, onTap: () => tapped.add(appId)),
              ],
            ),
          ),
        ),
      );

      const expectedLabels = <String, String>{
        'profile': '프로필',
        'about': '프로필',
        'introduction': '자기소개',
        'skills': '스킬',
        'projects': '포트폴리오',
        'terminal': '터미널',
        'music': '배경음',
        'photos': '사진',
        'settings': '설정',
        'thisMac': '프로젝트',
        'trash': '휴지통',
        'github': 'git',
        'mail': '이메일',
      };

      for (final entry in expectedLabels.entries) {
        final appId = PortfolioAppId.values.singleWhere(
          (candidate) => candidate.name == entry.key,
        );
        final icon = find.byKey(Key('apple-app-icon-${appId.name}'));
        expect(icon, findsOneWidget);
        expect(
          find.descendant(of: icon, matching: find.text(entry.value)),
          findsOneWidget,
        );
      }

      await tester.tap(find.byKey(const Key('apple-app-icon-about')));
      await tester.pump();
      expect(tapped, <PortfolioAppId>[PortfolioAppId.about]);
      expect(
        AppleAppIcon.windowTitleFor(PortfolioAppId.terminal),
        AppleAppIcon.terminalWindowTitle,
      );
    });

    testWidgets('exposes selection, running, compact, and semantics states', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppleTheme.light(),
          home: Material(
            child: AppleAppIcon(
              appId: PortfolioAppId.projects,
              compact: true,
              selected: true,
              running: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Open 포트폴리오'), findsOneWidget);
      expect(
        find.byKey(const Key('apple-app-icon-selection-projects')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('apple-app-icon-running-projects')),
        findsOneWidget,
      );
      expect(
        tester
            .getSize(find.byKey(const Key('apple-app-icon-tile-projects')))
            .width,
        lessThan(56),
      );
      semantics.dispose();
    });

    testWidgets('shows focus and activates with Enter and Space', (
      tester,
    ) async {
      var activations = 0;
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppleTheme.light(),
          home: Material(
            child: Center(
              child: AppleAppIcon(
                appId: PortfolioAppId.about,
                onTap: () => activations++,
              ),
            ),
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        find.byKey(const Key('apple-app-icon-focus-about')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Open 프로필'), findsOneWidget);
      final node = tester.getSemantics(
        find.byKey(const Key('apple-app-icon-about')),
      );
      final semanticsData = node.getSemanticsData();
      expect(semanticsData.flagsCollection.isFocused, ui.Tristate.isTrue);
      expect(semanticsData.hasAction(SemanticsAction.tap), isTrue);
      expect(semanticsData.hasAction(SemanticsAction.focus), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(activations, 2);
      semantics.dispose();
    });
  });

  group('AppleTheme', () {
    test('light filled buttons meet AA contrast with white labels', () {
      final style = AppleTheme.light().filledButtonTheme.style!;
      final background = style.backgroundColor!.resolve(<WidgetState>{})!;
      final foreground = style.foregroundColor!.resolve(<WidgetState>{})!;

      expect(foreground, Colors.white);
      expect(_contrastRatio(background, foreground), greaterThanOrEqualTo(4.5));
    });

    test('light outlined button labels meet AA contrast on white', () {
      final theme = AppleTheme.light();
      final foreground = theme.outlinedButtonTheme.style!.foregroundColor!
          .resolve(<WidgetState>{})!;

      expect(
        _contrastRatio(theme.colorScheme.surface, foreground),
        greaterThanOrEqualTo(4.5),
      );
    });

    testWidgets('toolbar grows without overflow at 200 percent text scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppleTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: const Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 360,
                child: AppleToolbar(
                  title: 'Portfolio application',
                  subtitle: 'Adaptive shared content',
                  leading: Icon(Icons.folder_rounded),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(AppleToolbar)).height, greaterThan(62));
    });

    testWidgets('blue pills resolve AA colors in light and dark themes', (
      tester,
    ) async {
      for (final brightness in Brightness.values) {
        final theme = brightness == Brightness.dark
            ? AppleTheme.dark()
            : AppleTheme.light();
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Material(
              child: Center(
                child: ApplePill(key: Key('contrast-pill'), label: 'Flutter'),
              ),
            ),
          ),
        );

        final pill = find.byKey(const Key('contrast-pill'));
        final decoration =
            tester
                    .widget<DecoratedBox>(
                      find.descendant(
                        of: pill,
                        matching: find.byType(DecoratedBox),
                      ),
                    )
                    .decoration
                as BoxDecoration;
        final background = decoration.color!;
        final foreground = tester
            .widget<Text>(
              find.descendant(of: pill, matching: find.text('Flutter')),
            )
            .style!
            .color!;

        expect(background.a, 1);
        expect(
          _contrastRatio(foreground, background),
          greaterThanOrEqualTo(4.5),
          reason: '$brightness',
        );
      }
    });
  });

  group('PortfolioAppContent', () {
    testWidgets('routes and renders every app without reference identity', (
      tester,
    ) async {
      final launcher = _FakeExternalLauncher();
      const expectedRootKeys = <String, String>{
        'profile': 'profile-app',
        'about': 'about-app',
        'introduction': 'introduction-app',
        'skills': 'skills-app',
        'projects': 'projects-app',
        'terminal': 'terminal-app',
        'music': 'music-app',
        'photos': 'photos-app',
        'settings': 'settings-app',
        'thisMac': 'this-mac-app',
        'trash': 'trash-app',
        'github': 'github-app',
        'mail': 'mail-app',
      };

      for (final entry in expectedRootKeys.entries) {
        final appId = PortfolioAppId.values.singleWhere(
          (candidate) => candidate.name == entry.key,
        );
        await _pumpApp(
          tester,
          appId: appId,
          launcher: launcher,
          size: const Size(900, 650),
        );

        expect(find.byKey(Key(entry.value)), findsOneWidget);
        expect(_visibleText(tester), isNot(contains('천주아')));
        expect(_visibleText(tester).toLowerCase(), isNot(contains('juah')));
        expect(tester.takeException(), isNull, reason: entry.key);
      }
    });

    testWidgets('Photos gallery is scrollable in light and dark modes', (
      tester,
    ) async {
      final photos = PortfolioAppId.values.singleWhere(
        (appId) => appId.name == 'photos',
      );

      for (final brightness in Brightness.values) {
        await _pumpApp(
          tester,
          appId: photos,
          launcher: _FakeExternalLauncher(),
          size: const Size(390, 180),
          compact: true,
          brightness: brightness,
        );

        final scroll = find.byKey(const Key('photos-scroll'));
        expect(find.byKey(const Key('photos-app')), findsOneWidget);
        expect(scroll, findsOneWidget);
        final scrollable = tester.state<ScrollableState>(
          find.descendant(of: scroll, matching: find.byType(Scrollable)),
        );
        expect(scrollable.position.maxScrollExtent, greaterThan(0));
        await tester.drag(scroll, const Offset(0, -80));
        await tester.pumpAndSettle();
        expect(scrollable.position.pixels, greaterThan(0));
        expect(tester.takeException(), isNull, reason: '$brightness');
      }
    });

    testWidgets(
      'Introduction is a separate scrollable document without invented copy',
      (tester) async {
        await _pumpApp(
          tester,
          appId: PortfolioAppId.introduction,
          launcher: _FakeExternalLauncher(),
          size: const Size(390, 220),
          compact: true,
        );

        final scroll = find.byKey(const Key('introduction-scroll'));
        expect(find.byKey(const Key('introduction-app')), findsOneWidget);
        final document = find.byKey(const Key('introduction-document'));
        expect(document, findsOneWidget);
        expect(scroll, findsOneWidget);
        expect(
          tester
              .widgetList<Text>(
                find.descendant(of: document, matching: find.byType(Text)),
              )
              .map((text) => text.data)
              .whereType<String>(),
          orderedEquals(<String>['자기소개', '자기소개서 내용을 추가할 예정입니다.']),
        );
        expect(find.byKey(const Key('profile-app')), findsNothing);
        expect(find.byKey(const Key('about-app')), findsNothing);

        final scrollable = tester.state<ScrollableState>(
          find.descendant(of: scroll, matching: find.byType(Scrollable)),
        );
        expect(scrollable.position.maxScrollExtent, greaterThan(0));
        await tester.drag(scroll, const Offset(0, -80));
        await tester.pumpAndSettle();
        expect(scrollable.position.pixels, greaterThan(0));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Introduction stays readable and scrollable at 200 percent in both themes',
      (tester) async {
        for (final brightness in Brightness.values) {
          final semantics = tester.ensureSemantics();
          await _pumpApp(
            tester,
            appId: PortfolioAppId.introduction,
            launcher: _FakeExternalLauncher(),
            size: const Size(320, 260),
            compact: true,
            brightness: brightness,
            textScaler: const TextScaler.linear(2),
          );

          final surface = find.byKey(const Key('introduction-app'));
          final document = find.byKey(const Key('introduction-document'));
          final message = find.descendant(
            of: document,
            matching: find.text('자기소개서 내용을 추가할 예정입니다.'),
          );
          expect(
            tester.widget<AppleAppSurface>(surface).color,
            AppleTheme.panel(tester.element(surface)),
          );
          expect(
            (tester.widget<Container>(document).decoration! as BoxDecoration)
                .color,
            AppleTheme.surface(tester.element(document)),
          );
          expect(
            tester.widget<Text>(message).style?.color,
            AppleTheme.secondaryLabel(tester.element(message)),
          );
          expect(find.bySemanticsLabel('자기소개'), findsWidgets);
          expect(find.bySemanticsLabel('자기소개서 내용을 추가할 예정입니다.'), findsOneWidget);

          final scroll = find.byKey(const Key('introduction-scroll'));
          final scrollable = tester.state<ScrollableState>(
            find.descendant(of: scroll, matching: find.byType(Scrollable)),
          );
          expect(scrollable.position.maxScrollExtent, greaterThan(0));
          await tester.drag(scroll, const Offset(0, -80));
          await tester.pumpAndSettle();
          expect(scrollable.position.pixels, greaterThan(0));
          expect(tester.takeException(), isNull, reason: '$brightness');
          semantics.dispose();
        }
      },
    );

    testWidgets(
      'app bodies omit the duplicate icon and title toolbar on every form factor',
      (tester) async {
        for (final scenario
            in const <({Size size, bool compact, bool mobile, bool tablet})>[
              (
                size: Size(360, 640),
                compact: true,
                mobile: true,
                tablet: false,
              ),
              (
                size: Size(834, 900),
                compact: false,
                mobile: true,
                tablet: true,
              ),
              (
                size: Size(1024, 700),
                compact: false,
                mobile: false,
                tablet: false,
              ),
            ]) {
          for (final appId in const <PortfolioAppId>[
            PortfolioAppId.introduction,
            PortfolioAppId.skills,
            PortfolioAppId.music,
            PortfolioAppId.photos,
            PortfolioAppId.trash,
            PortfolioAppId.github,
            PortfolioAppId.mail,
          ]) {
            await _pumpApp(
              tester,
              appId: appId,
              launcher: _FakeExternalLauncher(),
              size: scenario.size,
              compact: scenario.compact,
              mobile: scenario.mobile,
              tablet: scenario.tablet,
            );

            expect(
              find.byType(AppleToolbar),
              findsNothing,
              reason: '${appId.name} $scenario',
            );
            expect(tester.takeException(), isNull, reason: '$appId $scenario');
          }
        }
      },
    );

    testWidgets('about shows canonical identity, 경력, and 교육 without contact', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        appId: PortfolioAppId.about,
        launcher: _FakeExternalLauncher(),
        size: const Size(360, 600),
        compact: true,
      );

      expect(find.text('민희수'), findsOneWidget);
      expect(find.text('Min He-su'), findsOneWidget);
      expect(find.text(portfolioData.identity.headline), findsOneWidget);
      expect(find.text(portfolioData.identity.email), findsNothing);
      expect(find.text(portfolioData.identity.githubUrl), findsNothing);
      expect(find.text('Contact'), findsNothing);
      expect(find.text('Let’s build something thoughtful'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('경력'),
        220,
        scrollable: _scrollableInside(const Key('about-scroll')),
      );
      expect(find.text('경력'), findsOneWidget);
      expect(find.text('Career'), findsNothing);
      expect(find.text(portfolioData.experiences.first.role), findsNothing);
      expect(
        find.text(portfolioData.experiences.first.organization),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.text('교육'),
        220,
        scrollable: _scrollableInside(const Key('about-scroll')),
      );
      expect(find.text('교육'), findsOneWidget);
      expect(find.text('Education'), findsNothing);
      expect(
        find.text(portfolioData.education.first.institution),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('about omits avatar monograms for every injected identity', (
      tester,
    ) async {
      final englishIdentity = _dataWithIdentity(
        name: '에이다 러브레이스',
        englishName: 'Ada Lovelace',
        email: 'ada@example.com',
      );
      await _pumpApp(
        tester,
        appId: PortfolioAppId.about,
        launcher: _FakeExternalLauncher(),
        data: englishIdentity,
        size: const Size(360, 600),
        compact: true,
      );

      expect(find.text('AL'), findsNothing);
      expect(find.text('MH'), findsNothing);

      final localFallback = _dataWithIdentity(
        name: '김 민수',
        englishName: '   ',
        email: 'invalid email',
      );
      await _pumpApp(
        tester,
        appId: PortfolioAppId.about,
        launcher: _FakeExternalLauncher(),
        data: localFallback,
        size: const Size(360, 600),
        compact: true,
      );

      expect(find.text('김민'), findsNothing);
      expect(find.text('MH'), findsNothing);
    });

    testWidgets('about education action reports external launch failure', (
      tester,
    ) async {
      final launcher = _FakeExternalLauncher(succeeds: false);
      await _pumpApp(
        tester,
        appId: PortfolioAppId.about,
        launcher: launcher,
        size: const Size(360, 600),
        compact: true,
      );

      final action = find.byKey(const Key('about-education-link-0'));
      expect(action, findsOneWidget);
      await tester.drag(
        find.byKey(const Key('about-scroll')),
        const Offset(0, -1100),
      );
      await tester.pumpAndSettle();
      await tester.tap(action);
      await tester.pumpAndSettle();

      final educationLink = portfolioData.education.first.link!;
      expect(launcher.launched, <Uri>[educationLink.uri]);
      expect(find.byKey(const Key('about-link-feedback')), findsOneWidget);
      expect(find.textContaining('열 수 없습니다'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('compact skills opens one of three group channels as detail', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        appId: PortfolioAppId.skills,
        launcher: _FakeExternalLauncher(),
        size: const Size(360, 600),
        compact: true,
        mobile: true,
      );

      expect(
        find.byKey(const Key('skills-mobile-channel-list')),
        findsOneWidget,
      );
      expect(find.text('정보처리기사'), findsOneWidget);
      expect(find.text('# Development'), findsOneWidget);
      expect(find.text('# Collaboration'), findsOneWidget);
      expect(find.text('# Design & UI/UX'), findsOneWidget);
      expect(find.text('# Flutter'), findsNothing);
      expect(find.text('# Notion'), findsNothing);

      await tester.tap(
        find.byKey(const Key('skills-mobile-channel-Development')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('skills-mobile-channel-detail')),
        findsOneWidget,
      );
      expect(find.text('# Development'), findsOneWidget);
      expect(find.text('1명의 멤버'), findsOneWidget);
      expect(find.text('1개의 탭'), findsOneWidget);
      expect(find.byKey(const Key('skill-item-Flutter')), findsOneWidget);
      expect(find.byKey(const Key('skill-item-Notion')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'skills master-detail categories expose accessible 44px controls',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await _pumpApp(
          tester,
          appId: PortfolioAppId.skills,
          launcher: _FakeExternalLauncher(),
          size: const Size(900, 650),
        );

        final development = find.byKey(
          const Key('skills-category-Development'),
        );
        expect(tester.getSize(development).height, greaterThanOrEqualTo(44));
        final developmentSemantics = tester.getSemantics(development);
        final developmentData = developmentSemantics.getSemanticsData();
        expect(developmentData.label, 'Select skill category Development');
        expect(developmentData.flagsCollection.isButton, isTrue);
        expect(developmentData.flagsCollection.isSelected, ui.Tristate.isTrue);
        expect(developmentData.hasAction(SemanticsAction.tap), isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final focusedDevelopmentData = tester
            .getSemantics(development)
            .getSemanticsData();
        expect(
          focusedDevelopmentData.flagsCollection.isFocused,
          ui.Tristate.isTrue,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(find.text('Notion'), findsOneWidget);
        expect(find.text('Flutter'), findsNothing);
        semantics.dispose();
      },
    );

    testWidgets(
      'project categories expose all six folders before their detail depth',
      (tester) async {
        await _pumpApp(
          tester,
          appId: PortfolioAppId.projects,
          launcher: _FakeExternalLauncher(),
          size: const Size(900, 650),
        );

        for (final index in const <int>[2, 3, 4, 5]) {
          expect(find.byKey(Key('project-selector-$index')), findsOneWidget);
        }
        expect(find.byKey(const Key('project-selector-0')), findsNothing);
        expect(find.byKey(const Key('project-selector-1')), findsNothing);

        await tester.tap(
          find.byKey(const Key('projects-finder-location-personal-projects')),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('project-selector-0')), findsOneWidget);
        expect(find.byKey(const Key('project-selector-1')), findsOneWidget);

        await tester.tap(find.byKey(const Key('project-selector-0')));
        await tester.pumpAndSettle();

        final readingLog = portfolioData.projects[0];
        expect(find.byKey(const Key('projects-finder-grid')), findsNothing);
        expect(
          _textAtKey(tester, const Key('project-detail-title')),
          readingLog.title,
        );
        expect(find.text(readingLog.period), findsOneWidget);
        expect(find.text(readingLog.description), findsOneWidget);
        for (final technology in readingLog.technologies) {
          expect(find.text('#$technology'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'project folders support keyboard detail navigation and selected return state',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await _pumpApp(
          tester,
          appId: PortfolioAppId.projects,
          launcher: _FakeExternalLauncher(),
          size: const Size(900, 650),
        );

        final firstProject = portfolioData.projects[2];
        final firstSelector = find.byKey(const Key('project-selector-2'));
        expect(tester.getSize(firstSelector).height, greaterThanOrEqualTo(44));
        final firstData = tester.getSemantics(firstSelector).getSemanticsData();
        expect(firstData.label, 'Open project ${firstProject.title}');
        expect(firstData.flagsCollection.isButton, isTrue);
        expect(firstData.flagsCollection.isSelected, ui.Tristate.isFalse);
        expect(firstData.hasAction(SemanticsAction.tap), isTrue);

        for (var index = 0; index < 12; index++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          if (tester
                  .getSemantics(firstSelector)
                  .getSemanticsData()
                  .flagsCollection
                  .isFocused ==
              ui.Tristate.isTrue) {
            break;
          }
        }
        expect(
          tester
              .getSemantics(firstSelector)
              .getSemanticsData()
              .flagsCollection
              .isFocused,
          ui.Tristate.isTrue,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(
          _textAtKey(tester, const Key('project-detail-title')),
          firstProject.title,
        );
        expect(firstSelector, findsNothing);

        await tester.tap(find.byKey(const Key('projects-finder-back')));
        await tester.pumpAndSettle();

        final returnedFirstSelector = find.byKey(
          const Key('project-selector-2'),
        );
        final returnedFirstData = tester
            .getSemantics(returnedFirstSelector)
            .getSemanticsData();
        expect(returnedFirstData.label, 'Open project ${firstProject.title}');
        expect(
          returnedFirstData.flagsCollection.isSelected,
          ui.Tristate.isTrue,
        );
        expect(find.byKey(const Key('project-detail-title')), findsNothing);
        semantics.dispose();
      },
    );

    testWidgets(
      'selected selectors render a contrast-safe keyboard focus outline',
      (tester) async {
        for (final brightness in Brightness.values) {
          for (final scenario in <(PortfolioAppId, String)>[
            (PortfolioAppId.skills, 'skills-category-Development'),
            (PortfolioAppId.projects, 'projects-career-folder-0'),
          ]) {
            await tester.pumpWidget(const SizedBox.shrink());
            await _pumpApp(
              tester,
              appId: scenario.$1,
              launcher: _FakeExternalLauncher(),
              size: const Size(900, 650),
              brightness: brightness,
            );

            final selector = find.byKey(Key(scenario.$2));
            final initialSize = tester.getSize(selector);
            final background = scenario.$1 == PortfolioAppId.projects
                ? find.descendant(
                    of: selector,
                    matching: find.byKey(
                      const Key('apple-finder-folder-artwork-background'),
                    ),
                  )
                : find.descendant(
                    of: selector,
                    matching: find.byType(AnimatedContainer),
                  );
            final selectedDecoration =
                tester.widget<AnimatedContainer>(background).decoration
                    as BoxDecoration;
            final resolvedBackground = Color.alphaBlend(
              selectedDecoration.color!,
              AppleTheme.panel(tester.element(selector)),
            );
            final focusOutline = find.descendant(
              of: selector,
              matching: find.byKey(const Key('apple-selection-focus')),
            );

            expect(focusOutline, findsNothing);

            for (var index = 0; index < 12; index++) {
              await tester.sendKeyEvent(LogicalKeyboardKey.tab);
              await tester.pump();
              if (focusOutline.evaluate().isNotEmpty) {
                break;
              }
            }

            expect(focusOutline, findsOneWidget, reason: '$scenario');
            final focusDecoration =
                tester.widget<DecoratedBox>(focusOutline).decoration
                    as BoxDecoration;
            final focusBorder = focusDecoration.border! as Border;
            expect(focusBorder.top.width, greaterThanOrEqualTo(2));
            expect(
              _contrastRatio(focusBorder.top.color, resolvedBackground),
              greaterThanOrEqualTo(4.5),
              reason: '$brightness ${scenario.$1.name}',
            );
            expect(tester.getSize(selector), initialSize);

            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pump();

            expect(focusOutline, findsNothing, reason: '$scenario');
            expect(tester.getSize(selector), initialSize);
          }
        }
      },
    );

    testWidgets(
      'selected project highlights only artwork and leaves label unchanged',
      (tester) async {
        for (final brightness in Brightness.values) {
          await tester.pumpWidget(const SizedBox.shrink());
          await _pumpApp(
            tester,
            appId: PortfolioAppId.projects,
            launcher: _FakeExternalLauncher(),
            size: const Size(900, 650),
            brightness: brightness,
          );

          final selector = find.byKey(const Key('projects-career-folder-0'));
          final tile = find.descendant(
            of: selector,
            matching: find.byKey(const Key('apple-finder-folder-container')),
          );
          final artworkBackground = find.descendant(
            of: selector,
            matching: find.byKey(
              const Key('apple-finder-folder-artwork-background'),
            ),
          );
          final labelBackground = find.descendant(
            of: selector,
            matching: find.byKey(
              const Key('apple-finder-folder-label-background'),
            ),
          );
          final label = find.descendant(
            of: selector,
            matching: find.text(portfolioData.projects[2].title),
          );
          final initialTileDecoration =
              tester.widget<AnimatedContainer>(tile).decoration
                  as BoxDecoration;
          final initialArtworkDecoration =
              tester.widget<AnimatedContainer>(artworkBackground).decoration
                  as BoxDecoration;
          final initialLabelDecoration =
              tester.widget<DecoratedBox>(labelBackground).decoration
                  as BoxDecoration;
          final initialLabelStyle = tester.widget<Text>(label).style;

          expect(initialTileDecoration.color, Colors.transparent);
          expect(initialArtworkDecoration.color, Colors.transparent);
          expect(initialLabelDecoration.color, Colors.transparent);

          await tester.tap(selector);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('projects-finder-back')));
          await tester.pumpAndSettle();

          final returnedSelector = find.byKey(
            const Key('projects-career-folder-0'),
          );
          final returnedTileDecoration =
              tester
                      .widget<AnimatedContainer>(
                        find.descendant(
                          of: returnedSelector,
                          matching: find.byKey(
                            const Key('apple-finder-folder-container'),
                          ),
                        ),
                      )
                      .decoration
                  as BoxDecoration;
          final selectedArtworkDecoration =
              tester
                      .widget<AnimatedContainer>(
                        find.descendant(
                          of: returnedSelector,
                          matching: find.byKey(
                            const Key('apple-finder-folder-artwork-background'),
                          ),
                        ),
                      )
                      .decoration
                  as BoxDecoration;
          final returnedLabelBackground =
              tester
                      .widget<DecoratedBox>(
                        find.descendant(
                          of: returnedSelector,
                          matching: find.byKey(
                            const Key('apple-finder-folder-label-background'),
                          ),
                        ),
                      )
                      .decoration
                  as BoxDecoration;
          final returnedLabelStyle = tester
              .widget<Text>(
                find.descendant(
                  of: returnedSelector,
                  matching: find.text(portfolioData.projects[2].title),
                ),
              )
              .style;

          expect(returnedTileDecoration, initialTileDecoration);
          expect(selectedArtworkDecoration.color, isNot(Colors.transparent));
          expect(selectedArtworkDecoration.color!.a, 1);
          expect(
            (selectedArtworkDecoration.color!.r -
                    selectedArtworkDecoration.color!.g)
                .abs(),
            lessThanOrEqualTo(0.001),
          );
          expect(
            (selectedArtworkDecoration.color!.g -
                    selectedArtworkDecoration.color!.b)
                .abs(),
            lessThanOrEqualTo(0.001),
          );
          expect(returnedLabelBackground, initialLabelDecoration);
          expect(returnedLabelBackground.color, Colors.transparent);
          expect(returnedLabelStyle, initialLabelStyle);
        }
      },
    );

    testWidgets('failed project launch shows local feedback without throwing', (
      tester,
    ) async {
      final launcher = _FakeExternalLauncher(succeeds: false);
      await _pumpApp(
        tester,
        appId: PortfolioAppId.projects,
        launcher: launcher,
        size: const Size(360, 600),
        compact: true,
      );
      await _openProjectsLocation(tester, 'personal-projects');

      await tester.tap(find.byKey(const Key('project-selector-0')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('project-link-0-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('project-link-0-0')));
      await tester.pumpAndSettle();

      expect(launcher.launched, <Uri>[portfolioData.projects[0].links[0].uri]);
      expect(find.byKey(const Key('project-launch-feedback')), findsOneWidget);
      expect(find.textContaining('열 수 없습니다'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'pending project link clears stale feedback and blocks duplicate requests',
      (tester) async {
        final launcher = _ControlledExternalLauncher();
        await _pumpApp(
          tester,
          appId: PortfolioAppId.projects,
          launcher: launcher,
          size: const Size(900, 650),
        );
        await _openProjectsLocation(tester, 'personal-projects');

        await tester.tap(find.byKey(const Key('project-selector-0')));
        await tester.pumpAndSettle();
        final link = find.byKey(const Key('project-link-0-0'));
        await tester.ensureVisible(link);
        await tester.tap(link);
        await tester.pump();

        expect(launcher.requests, hasLength(1));
        expect(tester.widget<OutlinedButton>(link).onPressed, isNull);
        await tester.tap(link);
        await tester.pump();
        expect(launcher.requests, hasLength(1));

        launcher.complete(0, false);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('project-launch-feedback')),
          findsOneWidget,
        );
        expect(tester.widget<OutlinedButton>(link).onPressed, isNotNull);

        await tester.tap(link);
        await tester.pump();
        expect(launcher.requests, hasLength(2));
        expect(find.byKey(const Key('project-launch-feedback')), findsNothing);

        launcher.complete(1, true);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'older same-URI completion cannot unlock a newer pending request',
      (tester) async {
        final launcher = _ControlledExternalLauncher();
        await _pumpApp(
          tester,
          appId: PortfolioAppId.projects,
          launcher: launcher,
          size: const Size(900, 650),
        );
        await _openProjectsLocation(tester, 'personal-projects');

        await tester.tap(find.byKey(const Key('project-selector-0')));
        await tester.pumpAndSettle();
        final link = find.byKey(const Key('project-link-0-0'));
        await tester.ensureVisible(link);
        await tester.tap(link);
        await tester.pump();

        await tester.tap(find.byKey(const Key('projects-finder-back')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('project-selector-0')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(link);
        await tester.tap(link);
        await tester.pump();
        expect(launcher.requests, hasLength(2));
        expect(tester.widget<OutlinedButton>(link).onPressed, isNull);

        launcher.complete(0, false);
        await tester.pumpAndSettle();
        expect(tester.widget<OutlinedButton>(link).onPressed, isNull);
        await tester.tap(link);
        await tester.pump();
        expect(launcher.requests, hasLength(2));

        launcher.complete(1, true);
        await tester.pumpAndSettle();
        expect(tester.widget<OutlinedButton>(link).onPressed, isNotNull);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'project launch feedback keeps only the latest request result',
      (tester) async {
        final launcher = _ControlledExternalLauncher();
        await _pumpApp(
          tester,
          appId: PortfolioAppId.projects,
          launcher: launcher,
          size: const Size(900, 650),
        );
        await _openProjectsLocation(tester, 'personal-projects');

        await tester.tap(find.byKey(const Key('project-selector-0')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('project-link-0-0')));
        await tester.tap(find.byKey(const Key('project-link-0-0')));
        await tester.pump();
        await tester.ensureVisible(find.byKey(const Key('project-link-0-1')));
        await tester.tap(find.byKey(const Key('project-link-0-1')));
        await tester.pump();

        expect(launcher.requests, hasLength(2));
        launcher.complete(1, true);
        await tester.pumpAndSettle();
        expect(find.text('App Store 링크를 열었습니다.'), findsOneWidget);

        launcher.complete(0, false);
        await tester.pumpAndSettle();
        expect(find.text('App Store 링크를 열었습니다.'), findsOneWidget);
        expect(find.textContaining('Google Play 링크를 열 수 없습니다'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('changing projects invalidates a pending launch result', (
      tester,
    ) async {
      final launcher = _ControlledExternalLauncher();
      await _pumpApp(
        tester,
        appId: PortfolioAppId.projects,
        launcher: launcher,
        size: const Size(900, 650),
      );
      await _openProjectsLocation(tester, 'personal-projects');

      await tester.tap(find.byKey(const Key('project-selector-0')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('project-link-0-0')));
      await tester.tap(find.byKey(const Key('project-link-0-0')));
      await tester.pump();
      expect(launcher.requests, hasLength(1));

      await tester.tap(find.byKey(const Key('projects-finder-back')));
      await tester.pumpAndSettle();
      await _openProjectsLocation(tester, 'career');
      await tester.tap(find.byKey(const Key('project-selector-2')));
      await tester.pumpAndSettle();
      launcher.complete(0, false);
      await tester.pumpAndSettle();

      expect(
        _textAtKey(tester, const Key('project-detail-title')),
        portfolioData.projects[2].title,
      );
      expect(find.byKey(const Key('project-launch-feedback')), findsNothing);
      expect(find.textContaining('열 수 없습니다'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('terminal executes whoami, unknown commands, and clear', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        appId: PortfolioAppId.terminal,
        launcher: _FakeExternalLauncher(),
        size: const Size(360, 600),
        compact: true,
      );

      expect(find.text(r'portfolio: ~$ help'), findsOneWidget);
      expect(find.text('flutter run'), findsOneWidget);
      expect(find.text('포트폴리오 개발 서버 실행'), findsOneWidget);
      await _finishTerminalReveal(tester, lineCount: 9);

      await tester.enterText(find.byKey(const Key('terminal-input')), 'whoami');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      expect(find.textContaining('Min He-su'), findsOneWidget);
      expect(find.textContaining(portfolioData.identity.email), findsOneWidget);
      await _finishTerminalReveal(tester, lineCount: 5);

      await tester.enterText(find.byKey(const Key('terminal-input')), 'oops');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      expect(find.textContaining('command not found'), findsOneWidget);
      await _finishTerminalReveal(tester, lineCount: 2);

      for (var index = 0; index < 3; index++) {
        await tester.enterText(find.byKey(const Key('terminal-input')), 'help');
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await tester.pump();
        await _finishTerminalReveal(tester, lineCount: 9);
      }
      final transcript = tester.widget<ListView>(
        find.byKey(const Key('terminal-transcript')),
      );
      expect(transcript.controller!.offset, greaterThan(0));

      await tester.enterText(find.byKey(const Key('terminal-input')), 'clear');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();
      expect(find.textContaining('Min He-su'), findsNothing);
      expect(find.textContaining('command not found'), findsNothing);
      expect(find.text(r'portfolio: ~$ help'), findsNothing);
      expect(find.byKey(const Key('terminal-output')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('terminal-output')),
          matching: find.byType(Text),
        ),
        findsNothing,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('terminal-input')))
            .controller!
            .text,
        isEmpty,
      );
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      expect(
        tester
            .widget<ListView>(find.byKey(const Key('terminal-transcript')))
            .controller!
            .offset,
        0,
      );

      await tester.enterText(find.byKey(const Key('terminal-input')), 'whoami');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      expect(find.textContaining('Min He-su'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'terminal places its focused command line only after help finishes',
      (tester) async {
        await _pumpApp(
          tester,
          appId: PortfolioAppId.terminal,
          launcher: _FakeExternalLauncher(),
          size: const Size(900, 650),
        );

        final inputArea = find.byKey(const Key('terminal-input-area'));
        final transcript = find.byKey(const Key('terminal-transcript'));
        final inputReveal = find.byKey(const Key('terminal-input-reveal'));
        expect(inputArea, findsNothing);
        expect(tester.getSize(inputReveal).height, 0);
        expect(transcript, findsOneWidget);
        await _finishTerminalReveal(tester, lineCount: 9);

        expect(inputArea, findsOneWidget);
        expect(tester.getSize(inputReveal).height, greaterThan(0));
        expect(
          tester.getTopLeft(transcript).dy,
          lessThan(tester.getTopLeft(inputArea).dy),
        );
        final lastHelpDescription = find.text('명령어 안내');
        expect(lastHelpDescription, findsOneWidget);
        expect(
          tester.getTopLeft(inputArea).dy -
              tester.getBottomLeft(lastHelpDescription).dy,
          inInclusiveRange(0, 12),
        );
        expect(find.text('portfolio — zsh'), findsNothing);
        expect(find.text(r'portfolio: ~$'), findsOneWidget);
        expect(find.text(r'portfolio: ~$ help'), findsOneWidget);
        expect(find.byKey(const Key('terminal-submit')), findsNothing);
        final input = tester.widget<TextField>(
          find.byKey(const Key('terminal-input')),
        );
        expect(input.decoration?.hintText, isNull);
        expect(input.autofocus, isTrue);
        expect(input.cursorOpacityAnimates, isTrue);
        expect(input.enableInteractiveSelection, isFalse);
        expect(input.decoration?.filled, isFalse);
        expect(input.decoration?.hoverColor, Colors.transparent);
        expect(input.decoration?.border, InputBorder.none);
        expect(input.decoration?.enabledBorder, InputBorder.none);
        expect(input.decoration?.focusedBorder, InputBorder.none);
        final inputSurface = tester.widget<Container>(
          find.byKey(const Key('terminal-input-surface')),
        );
        final decoration = inputSurface.decoration! as BoxDecoration;
        expect(decoration.border, isNull);
        expect(
          (tester.getCenter(find.text(r'portfolio: ~$')).dy -
                  tester.getCenter(find.byKey(const Key('terminal-input'))).dy)
              .abs(),
          lessThan(1),
        );

        await tester.enterText(
          find.byKey(const Key('terminal-input')),
          'flutter run',
        );
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await tester.pump();

        expect(find.textContaining('Easter egg'), findsOneWidget);
        expect(find.textContaining('이미 실행 중'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('terminal restores input focus after transcript interaction', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        appId: PortfolioAppId.terminal,
        launcher: _FakeExternalLauncher(),
        size: const Size(900, 650),
      );
      await _finishTerminalReveal(tester, lineCount: 9);

      final input = find.byKey(const Key('terminal-input'));
      final transcript = find.byKey(const Key('terminal-transcript'));

      FocusNode inputFocus() => tester
          .widget<EditableText>(
            find.descendant(of: input, matching: find.byType(EditableText)),
          )
          .focusNode;

      expect(inputFocus().hasFocus, isTrue);

      final mouse = await tester.startGesture(
        tester.getCenter(transcript),
        kind: ui.PointerDeviceKind.mouse,
      );
      await tester.pump();
      expect(inputFocus().hasFocus, isTrue);
      await mouse.up();
      await tester.pump();

      await tester.enterText(input, 'whoami');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      expect(input, findsNothing);
      await _finishTerminalReveal(tester, lineCount: 5);
      expect(inputFocus().hasFocus, isTrue);

      inputFocus().unfocus();
      await tester.pump();
      expect(inputFocus().hasFocus, isFalse);

      await tester.tap(transcript);
      await tester.pump();
      expect(inputFocus().hasFocus, isTrue);
    });

    testWidgets('terminal exposes one named and editable accessibility field', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpApp(
        tester,
        appId: PortfolioAppId.terminal,
        launcher: _FakeExternalLauncher(),
        size: const Size(900, 650),
      );
      await _finishTerminalReveal(tester, lineCount: 9);

      final textFields = find.semantics.byPredicate(
        (node) => node.getSemanticsData().flagsCollection.isTextField,
      );
      expect(textFields, findsOne);
      final inputSemantics = textFields.evaluate().single.getSemanticsData();
      expect(inputSemantics.label, '터미널 명령 입력');
      expect(inputSemantics.flagsCollection.isEnabled, ui.Tristate.isTrue);
      expect(inputSemantics.hasAction(SemanticsAction.setText), isTrue);
      semantics.dispose();
    });

    testWidgets('terminal keeps the fixed Korean prompt for injected data', (
      tester,
    ) async {
      final data = _dataWithIdentity(
        name: '에이다 러브레이스',
        englishName: 'Ada Lovelace',
        email: 'ada.dev@example.com',
      );
      const prompt = r'portfolio: ~$';
      await _pumpApp(
        tester,
        appId: PortfolioAppId.terminal,
        launcher: _FakeExternalLauncher(),
        data: data,
        size: const Size(360, 600),
        compact: true,
      );
      await _finishTerminalReveal(tester, lineCount: 9);

      expect(find.text(prompt), findsOneWidget);
      expect(find.text('$prompt help'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('terminal-input')), 'whoami');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      expect(find.text('$prompt whoami'), findsOneWidget);
      expect(find.textContaining('Ada Lovelace'), findsOneWidget);
      await _finishTerminalReveal(tester, lineCount: 5);

      await tester.enterText(find.byKey(const Key('terminal-input')), 'clear');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      expect(find.text('$prompt help'), findsNothing);
      expect(find.text('$prompt whoami'), findsNothing);
      expect(find.text(prompt), findsOneWidget);
    });

    testWidgets('terminal prompt never leaks an invalid injected email', (
      tester,
    ) async {
      final data = _dataWithIdentity(
        name: '그레이스 호퍼',
        englishName: 'Grace Hopper',
        email: 'invalid email',
      );
      await _pumpApp(
        tester,
        appId: PortfolioAppId.terminal,
        launcher: _FakeExternalLauncher(),
        data: data,
        size: const Size(360, 600),
        compact: true,
      );
      await _finishTerminalReveal(tester, lineCount: 9);

      expect(find.text(r'portfolio: ~$'), findsOneWidget);
      expect(find.textContaining('invalid email'), findsNothing);
    });

    testWidgets('system actions use the injected launcher and report failure', (
      tester,
    ) async {
      final launcher = _FakeExternalLauncher(succeeds: false);
      await _pumpApp(
        tester,
        appId: PortfolioAppId.github,
        launcher: launcher,
        size: const Size(360, 600),
        compact: true,
      );

      expect(find.text('Min He-su'), findsOneWidget);
      await tester.tap(find.byKey(const Key('github-external-action')));
      await tester.pumpAndSettle();

      expect(launcher.launched, <Uri>[Uri.parse(portfolioData.githubUrl)]);
      expect(find.byKey(const Key('github-launch-feedback')), findsOneWidget);
      expect(find.textContaining('열 수 없습니다'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('GitHub lists three repositories with their actual links', (
      tester,
    ) async {
      final launcher = _FakeExternalLauncher();
      const repositories = <String, String>{
        'portfolio_hesu': 'https://github.com/hesu-dev/portfolio_hesu',
        'chrome_extension': 'https://github.com/hesu-dev/chrome_extension',
        'code_study': 'https://github.com/hesu-dev/code_study',
      };
      await _pumpApp(
        tester,
        appId: PortfolioAppId.github,
        launcher: launcher,
        size: const Size(390, 700),
        compact: true,
      );

      expect(find.byKey(const Key('github-external-action')), findsOneWidget);
      expect(launcher.launched, isEmpty);
      for (final repository in repositories.entries) {
        final card = find.byKey(Key('github-repository-${repository.key}'));
        expect(card, findsOneWidget);
        expect(find.text(repository.key), findsOneWidget);
        await tester.ensureVisible(card);
        await tester.tap(card);
        await tester.pumpAndSettle();
      }

      expect(
        launcher.launched,
        repositories.values.map(Uri.parse).toList(growable: false),
      );
      expect(find.byKey(const Key('github-launch-feedback')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('GitHub hides the repository section when no repos exist', (
      tester,
    ) async {
      final launcher = _FakeExternalLauncher();
      await _pumpApp(
        tester,
        appId: PortfolioAppId.github,
        launcher: launcher,
        data: _dataWithRepositories(const <PortfolioRepository>[]),
        size: const Size(390, 700),
        compact: true,
      );

      expect(find.text('Repositories'), findsNothing);
      expect(
        find.byKey(const Key('github-repositories-section')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('GitHub reports malformed repository links as launch failure', (
      tester,
    ) async {
      final launcher = _FakeExternalLauncher();
      const malformedRepository = PortfolioRepository(
        name: 'broken_repository',
        description: 'Malformed URL fixture',
        language: 'Dart',
        url: 'https://github.com:abc/broken_repository',
      );
      await _pumpApp(
        tester,
        appId: PortfolioAppId.github,
        launcher: launcher,
        data: _dataWithRepositories(const <PortfolioRepository>[
          malformedRepository,
        ]),
        size: const Size(390, 700),
        compact: true,
      );

      final card = find.byKey(const Key('github-repository-broken_repository'));
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pumpAndSettle();

      expect(launcher.launched, isEmpty);
      expect(find.byKey(const Key('github-launch-feedback')), findsOneWidget);
      expect(find.text('GitHub 링크를 열 수 없습니다.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Mail composes subject and body into a mailto launch', (
      tester,
    ) async {
      final launcher = _FakeExternalLauncher();
      await _pumpApp(
        tester,
        appId: PortfolioAppId.mail,
        launcher: launcher,
        size: const Size(390, 700),
        compact: true,
      );

      expect(find.text(portfolioData.email), findsAtLeastNWidgets(1));
      expect(launcher.launched, isEmpty);
      final subjectInput = find.byKey(const Key('mail-subject-input'));
      final bodyInput = find.byKey(const Key('mail-body-input'));
      expect(subjectInput, findsOneWidget);
      expect(bodyInput, findsOneWidget);
      await tester.enterText(subjectInput, '포트폴리오 문의 & 미팅');
      await tester.enterText(bodyInput, '안녕하세요?\nFlutter 프로젝트를 제안드립니다.');
      await tester.ensureVisible(find.byKey(const Key('mail-external-action')));
      await tester.tap(find.byKey(const Key('mail-external-action')));
      await tester.pumpAndSettle();

      expect(launcher.launched, hasLength(1));
      final mail = launcher.launched.single;
      expect(mail.scheme, 'mailto');
      expect(Uri.decodeComponent(mail.path), portfolioData.email);
      expect(mail.queryParameters, <String, String>{
        'subject': '포트폴리오 문의 & 미팅',
        'body': '안녕하세요?\nFlutter 프로젝트를 제안드립니다.',
      });
      expect(mail.toString(), contains('%20'));
      expect(mail.toString(), contains('%26'));
      expect(mail.toString(), contains('%0A'));
      expect(mail.toString(), isNot(contains('+')));
      expect(find.byKey(const Key('mail-launch-feedback')), findsOneWidget);
      expect(find.text('Mail 앱을 열었습니다.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Mail keeps the empty compose action compatible', (
      tester,
    ) async {
      final launcher = _FakeExternalLauncher();
      await _pumpApp(
        tester,
        appId: PortfolioAppId.mail,
        launcher: launcher,
        size: const Size(390, 700),
        compact: true,
      );

      await tester.ensureVisible(find.byKey(const Key('mail-external-action')));
      await tester.tap(find.byKey(const Key('mail-external-action')));
      await tester.pumpAndSettle();

      expect(launcher.launched, <Uri>[Uri.parse(portfolioData.mailUrl)]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('system launch feedback keeps only the latest request result', (
      tester,
    ) async {
      final launcher = _ControlledExternalLauncher();
      await _pumpApp(
        tester,
        appId: PortfolioAppId.github,
        launcher: launcher,
        size: const Size(360, 600),
        compact: true,
      );

      await tester.tap(find.byKey(const Key('github-external-action')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('github-external-action')));
      await tester.pump();
      expect(launcher.requests, hasLength(2));

      launcher.complete(1, true);
      await tester.pumpAndSettle();
      expect(find.text('GitHub 앱을 열었습니다.'), findsOneWidget);

      launcher.complete(0, false);
      await tester.pumpAndSettle();
      expect(find.text('GitHub 앱을 열었습니다.'), findsOneWidget);
      expect(find.textContaining('GitHub 링크를 열 수 없습니다'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'changing a system target invalidates a pending launch result',
      (tester) async {
        final launcher = _ControlledExternalLauncher();
        await _pumpApp(
          tester,
          appId: PortfolioAppId.github,
          launcher: launcher,
          size: const Size(360, 600),
        );

        await tester.tap(find.byKey(const Key('github-external-action')));
        await tester.pump();
        expect(launcher.requests, <Uri>[Uri.parse(portfolioData.githubUrl)]);

        final updatedData = _dataWithGithubUrl(
          'https://github.com/hesu-updated/',
        );
        await _pumpApp(
          tester,
          appId: PortfolioAppId.github,
          launcher: launcher,
          data: updatedData,
          size: const Size(360, 600),
        );
        launcher.complete(0, false);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('github-launch-feedback')), findsNothing);
        expect(find.textContaining('열 수 없습니다'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('all apps avoid RenderFlex overflow in compact and wide bounds', (
      tester,
    ) async {
      final launcher = _FakeExternalLauncher();

      for (final scenario
          in const <({Size size, bool compact, bool mobile, bool tablet})>[
            (size: Size(360, 600), compact: true, mobile: true, tablet: false),
            (
              size: Size(900, 650),
              compact: false,
              mobile: false,
              tablet: false,
            ),
          ]) {
        for (final appId in PortfolioAppId.values) {
          await _pumpApp(
            tester,
            appId: appId,
            launcher: launcher,
            size: scenario.size,
            compact: scenario.compact,
            mobile: scenario.mobile,
            tablet: scenario.tablet,
          );
          await tester.pumpAndSettle();

          final exception = tester.takeException();
          expect(
            exception,
            isNull,
            reason:
                '${appId.name} at ${scenario.size.width}x${scenario.size.height}: $exception',
          );
        }
      }
    });
  });
}

class _FakeExternalLauncher implements ExternalLauncher {
  _FakeExternalLauncher({this.succeeds = true});

  final bool succeeds;
  final List<Uri> launched = <Uri>[];

  @override
  Future<bool> launch(Uri uri) async {
    launched.add(uri);
    return succeeds;
  }
}

class _ControlledExternalLauncher implements ExternalLauncher {
  final List<Uri> requests = <Uri>[];
  final List<Completer<bool>> _completers = <Completer<bool>>[];

  @override
  Future<bool> launch(Uri uri) {
    requests.add(uri);
    final completer = Completer<bool>();
    _completers.add(completer);
    return completer.future;
  }

  void complete(int index, bool result) {
    _completers[index].complete(result);
  }
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required PortfolioAppId appId,
  required ExternalLauncher launcher,
  required Size size,
  PortfolioData data = portfolioData,
  bool compact = false,
  bool mobile = false,
  bool tablet = false,
  Brightness brightness = Brightness.light,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  final themeController = PortfolioThemeController(
    initial: brightness == Brightness.dark
        ? PortfolioThemePreference.dark
        : PortfolioThemePreference.light,
  );
  addTearDown(themeController.dispose);
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
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: SizedBox.expand(
        child: PortfolioAppContent(
          key: ValueKey<PortfolioAppId>(appId),
          appId: appId,
          data: data,
          launcher: launcher,
          themeController: themeController,
          musicController: createTestMusicController(),
          compact: compact,
          mobile: mobile,
          tablet: tablet,
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _finishTerminalReveal(
  WidgetTester tester, {
  required int lineCount,
}) async {
  await tester.pump(Duration(milliseconds: 500 + (lineCount - 1) * 800));
  await tester.pump(const Duration(microseconds: 1));
  await tester.pump();
}

Future<void> _openProjectsLocation(
  WidgetTester tester,
  String locationId,
) async {
  final location = find.byKey(Key('projects-finder-location-$locationId'));
  await tester.ensureVisible(location);
  await tester.tap(location);
  await tester.pumpAndSettle();
}

String _visibleText(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data ?? widget.textSpan?.toPlainText() ?? '')
      .join('\n');
}

String _textAtKey(WidgetTester tester, Key key) {
  final text = tester.widget<Text>(find.byKey(key));
  return text.data ?? text.textSpan?.toPlainText() ?? '';
}

Finder _scrollableInside(Key key) {
  return find.descendant(
    of: find.byKey(key),
    matching: find.byType(Scrollable),
  );
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

PortfolioData _dataWithGithubUrl(String githubUrl) {
  final identity = portfolioData.identity;
  return PortfolioData(
    identity: PortfolioIdentity(
      name: identity.name,
      englishName: identity.englishName,
      email: identity.email,
      githubUrl: githubUrl,
      headline: identity.headline,
      biography: identity.biography,
    ),
    experiences: portfolioData.experiences,
    education: portfolioData.education,
    skillGroups: portfolioData.skillGroups,
    projects: portfolioData.projects,
  );
}

PortfolioData _dataWithRepositories(
  Iterable<PortfolioRepository> repositories,
) {
  return PortfolioData(
    identity: portfolioData.identity,
    experiences: portfolioData.experiences,
    education: portfolioData.education,
    skillGroups: portfolioData.skillGroups,
    projects: portfolioData.projects,
    repositories: repositories,
  );
}

PortfolioData _dataWithIdentity({
  required String name,
  required String englishName,
  required String email,
}) {
  final identity = portfolioData.identity;
  return PortfolioData(
    identity: PortfolioIdentity(
      name: name,
      englishName: englishName,
      email: email,
      githubUrl: identity.githubUrl,
      headline: identity.headline,
      biography: identity.biography,
    ),
    experiences: portfolioData.experiences,
    education: portfolioData.education,
    skillGroups: portfolioData.skillGroups,
    projects: portfolioData.projects,
  );
}
