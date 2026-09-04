import 'dart:ui' show PointerDeviceKind;

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

    testWidgets('주입한 프로필 정보와 Instagram형 섹션을 모두 표시한다', (tester) async {
      final data = _injectedProfileData();
      final launcher = _RecordingLauncher();
      await _pumpProfileShell(
        tester,
        size: const Size(390, 844),
        tablet: false,
        data: data,
        launcher: launcher,
      );

      final profileLauncher = find.byKey(const Key('home-app-profile'));
      expect(profileLauncher, findsOneWidget);
      await tester.tap(profileLauncher);
      await tester.pumpAndSettle();

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
      expect(find.bySemanticsLabel('프로젝트 2개'), findsOneWidget);
      expect(find.bySemanticsLabel('스킬 3개'), findsOneWidget);
      expect(find.bySemanticsLabel('경력 1개'), findsOneWidget);
      expect(find.byKey(const Key('profile-github-action')), findsOneWidget);
      expect(find.byKey(const Key('profile-mail-action')), findsOneWidget);
      expect(find.byKey(const Key('profile-highlights')), findsOneWidget);
      expect(find.byKey(const Key('profile-project-grid')), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('profile-project-1')),
        240,
        scrollable: _scrollableInside(const Key('profile-scroll')),
      );
      expect(find.text('첫 번째 프로젝트'), findsOneWidget);
      expect(find.text('두 번째 프로젝트'), findsOneWidget);

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
    });

    testWidgets('라이트와 다크의 iPhone·iPad 200% 글자에서도 넘치지 않는다', (tester) async {
      for (final formFactor in const <(Size, bool)>[
        (Size(320, 480), false),
        (Size(834, 1194), true),
      ]) {
        for (final brightness in Brightness.values) {
          await tester.pumpWidget(const SizedBox.shrink());
          await _pumpProfileShell(
            tester,
            size: formFactor.$1,
            tablet: formFactor.$2,
            brightness: brightness,
            textScaler: const TextScaler.linear(2),
          );

          final profileLauncher = find.byKey(const Key('home-app-profile'));
          expect(profileLauncher, findsOneWidget);
          await tester.tap(profileLauncher);
          await tester.pumpAndSettle();

          final profile = find.byKey(const Key('profile-app'));
          expect(profile, findsOneWidget);
          expect(
            Theme.of(tester.element(profile)).brightness,
            brightness,
            reason: '${formFactor.$1} $brightness',
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '${formFactor.$1} $brightness',
          );
        }
      }
    });

    testWidgets('프로필 본문은 터치와 마우스 드래그로 스크롤된다', (tester) async {
      await _pumpProfileShell(
        tester,
        size: const Size(320, 480),
        tablet: false,
      );
      final profileLauncher = find.byKey(const Key('home-app-profile'));
      expect(profileLauncher, findsOneWidget);
      await tester.tap(profileLauncher);
      await tester.pumpAndSettle();

      final profileScroll = find.byKey(const Key('profile-scroll'));
      expect(profileScroll, findsOneWidget);
      final scrollable = find.descendant(
        of: profileScroll,
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable).position;

      await tester.drag(profileScroll, const Offset(0, -180));
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(0));

      position.jumpTo(0);
      await tester.pump();
      final center = tester.getCenter(profileScroll);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: center);
      await mouse.down(center);
      await mouse.moveBy(const Offset(0, -180));
      await mouse.up();
      await tester.pumpAndSettle();

      expect(position.pixels, greaterThan(0));
      await mouse.removePointer();
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
        role: 'Developer',
        organization: 'Profile Company',
        period: '2024 - Present',
        description: 'Profile experience',
      ),
    ],
    education: const <PortfolioEducation>[],
    skillGroups: const <PortfolioSkillGroup>[
      PortfolioSkillGroup.constant(
        title: 'Development',
        skills: <String>['Flutter', 'Dart'],
      ),
      PortfolioSkillGroup.constant(
        title: 'Collaboration',
        skills: <String>['Slack'],
      ),
    ],
    projects: const <PortfolioProject>[
      PortfolioProject.constant(
        title: '첫 번째 프로젝트',
        description: '첫 번째 설명',
        period: '2026',
        technologies: <String>['Flutter'],
        links: <PortfolioProjectLink>[],
      ),
      PortfolioProject.constant(
        title: '두 번째 프로젝트',
        description: '두 번째 설명',
        period: '2025',
        technologies: <String>['Dart'],
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
