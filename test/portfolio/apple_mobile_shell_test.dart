import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:portfolio_hesu/portfolio/apps/portfolio_app_content.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/mobile/apple_mobile_shell.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/theme/portfolio_theme_controller.dart';
import 'package:portfolio_hesu/portfolio/widgets/apple_app_artwork.dart';
import 'package:portfolio_hesu/portfolio/widgets/adaptive_portfolio_shell.dart';

import 'support/music_test_controller.dart';

void main() {
  group('adaptive Apple mobile shells', () {
    testWidgets('selects exact iPhone, iPad, and Mac breakpoint boundaries', (
      tester,
    ) async {
      await _expectOnlyShell(tester, width: 599, expected: 'iphone-shell');
      await _expectOnlyShell(tester, width: 600, expected: 'ipad-shell');
      await _expectOnlyShell(tester, width: 1023, expected: 'ipad-shell');
      await _expectOnlyShell(tester, width: 1024, expected: 'mac-shell');
    });

    testWidgets('never renders a Mac window below the desktop breakpoint', (
      tester,
    ) async {
      for (final size in const <Size>[Size(390, 844), Size(834, 1194)]) {
        await _pumpShell(tester, size: size);

        expect(find.byKey(const Key('mobile-home')), findsOneWidget);
        expect(find.byKey(const Key('mac-shell')), findsNothing);
        expect(
          find.byKey(const Key('mac-window-about'), skipOffstage: false),
          findsNothing,
        );
      }
    });

    testWidgets('wide mobile devices stay on the iPad shell with a Dock', (
      tester,
    ) async {
      await _pumpShell(
        tester,
        size: const Size(1366, 1024),
        mobilePlatformOverride: true,
      );

      expect(find.byKey(const Key('ipad-shell')), findsOneWidget);
      expect(find.byKey(const Key('mac-shell')), findsNothing);
      expect(find.byKey(const Key('mobile-dock')), findsOneWidget);
      expect(find.byKey(const Key('mobile-dock-profile')), findsOneWidget);
      expect(find.byKey(const Key('mobile-dock-projects')), findsOneWidget);
      expect(find.byKey(const Key('mobile-dock-about')), findsNothing);
      expect(find.byKey(const Key('mobile-dock-trash')), findsNothing);
      expect(find.byKey(const Key('mac-dock')), findsNothing);
    });

    testWidgets(
      'iPhone and iPad give Projects, GitHub, and Trash white rounded tiles',
      (tester) async {
        for (final size in const <Size>[Size(390, 844), Size(834, 1194)]) {
          for (final brightness in Brightness.values) {
            await tester.pumpWidget(const SizedBox.shrink());
            await _pumpShell(tester, size: size, brightness: brightness);

            for (final appId in const <PortfolioAppId>[
              PortfolioAppId.projects,
              PortfolioAppId.github,
              PortfolioAppId.trash,
            ]) {
              final reason = '$size ${brightness.name} ${appId.name}';
              final decoration = _launcherFrameDecoration(
                tester,
                find.byKey(Key('home-app-${appId.name}')),
              );
              expect(decoration.color, Colors.white, reason: reason);
              expect(decoration.borderRadius, isNotNull, reason: reason);
              expect(decoration.boxShadow, isEmpty, reason: reason);
            }

            final githubSvg = tester.widget<SvgPicture>(
              find.descendant(
                of: find.byKey(const Key('home-app-github')),
                matching: find.byKey(const Key('apple-app-artwork-github-svg')),
              ),
            );
            expect(
              (githubSvg.bytesLoader as SvgAssetLoader).theme?.currentColor,
              Colors.black,
              reason: '$size ${brightness.name} GitHub foreground',
            );

            final dockProjectsDecoration = _launcherFrameDecoration(
              tester,
              find.byKey(const Key('mobile-dock-projects')),
            );
            expect(
              dockProjectsDecoration.color,
              Colors.white,
              reason: '$size ${brightness.name}',
            );
            expect(dockProjectsDecoration.borderRadius, isNotNull);
            expect(dockProjectsDecoration.boxShadow, isEmpty);
          }
        }
      },
    );

    testWidgets('dark mobile GitHub stays black on its white tile', (
      tester,
    ) async {
      await _pumpShell(
        tester,
        size: const Size(390, 844),
        brightness: Brightness.dark,
      );

      final githubSvg = tester.widget<SvgPicture>(
        find.descendant(
          of: find.byKey(const Key('home-app-github')),
          matching: find.byKey(const Key('apple-app-artwork-github-svg')),
        ),
      );
      expect(
        (githubSvg.bytesLoader as SvgAssetLoader).theme?.currentColor,
        Colors.black,
      );
    });

    testWidgets('iPhone과 iPad는 모든 툴팁 효과를 숨기고 Mac은 유지한다', (tester) async {
      for (final scenario in const <(Size, String)>[
        (Size(390, 844), 'iphone-shell'),
        (Size(834, 1194), 'ipad-shell'),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpShell(tester, size: scenario.$1);

        final visibility = find.byKey(const Key('mobile-tooltip-visibility'));
        expect(visibility, findsOneWidget, reason: scenario.$2);
        expect(tester.widget<TooltipVisibility>(visibility).visible, isFalse);
        expect(
          TooltipVisibility.of(tester.element(find.byKey(Key(scenario.$2)))),
          isFalse,
        );

        expect(find.text('프로필'), findsOneWidget);
        final icon = find.byKey(const Key('home-app-profile'));
        final touch = await tester.startGesture(tester.getCenter(icon));
        await tester.pump(const Duration(seconds: 1));
        expect(find.byKey(const Key('mobile-home')), findsOneWidget);
        expect(find.byKey(const Key('mobile-app-surface')), findsNothing);
        expect(
          find.text('프로필'),
          findsOneWidget,
          reason: '${scenario.$2} 길게 누르기에 툴팁이 나타나면 안 됩니다.',
        );
        await touch.cancel();
        await tester.pump();

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        await mouse.moveTo(tester.getCenter(icon));
        await tester.pump(const Duration(seconds: 1));
        expect(
          find.text('프로필'),
          findsOneWidget,
          reason: '${scenario.$2} hover에 툴팁이 나타나면 안 됩니다.',
        );
        await mouse.removePointer();
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpShell(tester, size: const Size(1024, 700));
      expect(find.byKey(const Key('mobile-tooltip-visibility')), findsNothing);
      expect(
        TooltipVisibility.of(
          tester.element(find.byKey(const Key('mac-shell'))),
        ),
        isTrue,
      );
    });

    testWidgets('열린 앱은 투명 홈 인디케이터 뒤와 하단 안전 영역까지 이어진다', (tester) async {
      for (final scenario in const <(Size, List<double>)>[
        (Size(390, 844), <double>[0, 34]),
        (Size(834, 1194), <double>[0, 20]),
      ]) {
        for (final bottomInset in scenario.$2) {
          for (final brightness in Brightness.values) {
            await tester.pumpWidget(const SizedBox.shrink());
            await _pumpShell(
              tester,
              size: scenario.$1,
              brightness: brightness,
              viewPadding: EdgeInsets.only(bottom: bottomInset),
            );
            final homeIndicatorRect = tester.getRect(
              find.byKey(const Key('mobile-home-indicator')),
            );

            await tester.tap(find.byKey(const Key('home-app-settings')));
            await tester.pumpAndSettle();

            final surfaceRect = tester.getRect(
              find.byKey(const Key('mobile-app-surface')),
            );
            final indicatorRect = tester.getRect(
              find.byKey(const Key('mobile-home-indicator')),
            );

            final reason = '${scenario.$1} bottom=$bottomInset $brightness';
            expect(
              surfaceRect.top,
              lessThan(indicatorRect.top),
              reason: reason,
            );
            expect(
              surfaceRect.bottom,
              greaterThanOrEqualTo(indicatorRect.bottom),
              reason: reason,
            );
            expect(
              indicatorRect.bottom,
              lessThanOrEqualTo(scenario.$1.height - bottomInset),
              reason: reason,
            );
            expect(
              indicatorRect.center.dy,
              closeTo(homeIndicatorRect.center.dy, 0.1),
              reason: '$reason 앱 전환 중 인디케이터 위치',
            );
          }
        }
      }
    });
  });

  group('iPhone home and navigation', () {
    testWidgets(
      'uses a four-column app grid with Profile and Projects in the Dock',
      (tester) async {
        await _pumpShell(tester, size: const Size(390, 844));

        expect(find.byKey(const Key('iphone-shell')), findsOneWidget);
        expect(find.byKey(const Key('apple-status-bar')), findsOneWidget);
        expect(find.byKey(const Key('mobile-home-grid')), findsOneWidget);
        expect(find.byKey(const Key('mobile-home-indicator')), findsOneWidget);
        expect(find.byKey(const Key('mobile-dock')), findsOneWidget);
        expect(find.byKey(const Key('mobile-dock-profile')), findsOneWidget);
        expect(find.byKey(const Key('mobile-dock-projects')), findsOneWidget);
        expect(find.byKey(const Key('mobile-dock-about')), findsNothing);
        expect(find.byKey(const Key('mobile-dock-trash')), findsNothing);
        _expectAllHomeApps();

        expect(_distinctHomeColumns(tester), 4);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('opens one full-screen app and closes it back to home', (
      tester,
    ) async {
      await _pumpShell(tester, size: const Size(390, 844));

      final profile = find.byKey(const Key('home-app-profile'));
      expect(profile, findsOneWidget);
      await tester.tap(profile);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mobile-home')), findsNothing);
      expect(find.byKey(const Key('mobile-app-surface')), findsOneWidget);
      expect(find.byKey(const Key('profile-app')), findsOneWidget);
      expect(find.byKey(const Key('about-app')), findsNothing);
      expect(find.bySemanticsLabel('Close 프로필 window'), findsOneWidget);

      await tester.tap(find.byKey(const Key('mobile-back-close-profile')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mobile-home')), findsOneWidget);
      expect(find.byKey(const Key('mobile-app-surface')), findsNothing);
    });

    testWidgets('home icon supports keyboard activation and button semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpShell(tester, size: const Size(390, 844));

      expect(find.bySemanticsLabel('Open 프로필'), findsNWidgets(2));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile-app')), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('Space also activates the initially focused home icon', (
      tester,
    ) async {
      await _pumpShell(tester, size: const Size(390, 844));

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile-app')), findsOneWidget);
    });

    testWidgets('opens both pinned mobile Dock shortcuts on iPhone and iPad', (
      tester,
    ) async {
      for (final scenario in const <(Size, PortfolioAppId, String)>[
        (Size(390, 844), PortfolioAppId.profile, 'profile-app'),
        (Size(390, 844), PortfolioAppId.projects, 'projects-app'),
        (Size(834, 1194), PortfolioAppId.profile, 'profile-app'),
        (Size(834, 1194), PortfolioAppId.projects, 'projects-app'),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpShell(tester, size: scenario.$1);

        expect(find.byKey(const Key('mobile-dock')), findsOneWidget);
        expect(find.byKey(const Key('mobile-dock-profile')), findsOneWidget);
        expect(find.byKey(const Key('mobile-dock-projects')), findsOneWidget);
        expect(find.byKey(const Key('mobile-dock-about')), findsNothing);
        expect(find.bySemanticsLabel('Open 프로필'), findsNWidgets(2));
        expect(find.bySemanticsLabel('Open 자기소개'), findsOneWidget);

        await tester.tap(find.byKey(Key('mobile-dock-${scenario.$2.name}')));
        await tester.pumpAndSettle();

        expect(find.byKey(Key(scenario.$3)), findsOneWidget);
        expect(find.byKey(const Key('mobile-dock')), findsNothing);
      }
    });

    testWidgets(
      'Projects bottom navigation matches the home Dock height and position',
      (tester) async {
        for (final scenario in const <({Size size, double bottomInset})>[
          (size: Size(390, 844), bottomInset: 0),
          (size: Size(390, 844), bottomInset: 34),
          (size: Size(834, 1194), bottomInset: 0),
          (size: Size(834, 1194), bottomInset: 20),
        ]) {
          await tester.pumpWidget(const SizedBox.shrink());
          await _pumpShell(
            tester,
            size: scenario.size,
            viewPadding: EdgeInsets.only(bottom: scenario.bottomInset),
          );

          final homeDockRect = tester.getRect(
            find.byKey(const Key('mobile-dock')),
          );

          await tester.tap(find.byKey(const Key('mobile-dock-projects')));
          await tester.pumpAndSettle();

          final projectsDockRect = tester.getRect(
            find.byKey(const Key('projects-finder-mobile-dock')),
          );
          final reason = '${scenario.size} bottom=${scenario.bottomInset}';
          expect(
            projectsDockRect.height,
            closeTo(homeDockRect.height, 0.1),
            reason: '$reason height',
          );
          expect(
            projectsDockRect.bottom,
            closeTo(homeDockRect.bottom, 0.1),
            reason: '$reason vertical position',
          );
        }
      },
    );

    testWidgets('opens the separate Introduction app on iPhone and iPad', (
      tester,
    ) async {
      for (final size in const <Size>[Size(390, 844), Size(834, 1194)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpShell(tester, size: size);

        expect(find.byKey(const Key('mobile-dock-introduction')), findsNothing);
        await tester.tap(find.byKey(const Key('home-app-introduction')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('introduction-app')), findsOneWidget);
        expect(find.bySemanticsLabel('Close 자기소개 window'), findsOneWidget);
        expect(find.byKey(const Key('profile-app')), findsNothing);
      }
    });

    testWidgets('opens GitHub externally only after its explicit action', (
      tester,
    ) async {
      final launcher = _RecordingLauncher();
      await _pumpShell(tester, size: const Size(390, 844), launcher: launcher);

      await tester.tap(find.byKey(const Key('home-app-github')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('github-app')), findsOneWidget);
      expect(launcher.uris, isEmpty);

      await tester.tap(find.byKey(const Key('github-external-action')));
      await tester.pumpAndSettle();

      expect(launcher.uris, <Uri>[Uri.parse(portfolioData.githubUrl)]);
    });

    testWidgets(
      'injects phone form-factor data and launcher into app content',
      (tester) async {
        final data = _profileData(name: '전화 사용자');
        final launcher = _RecordingLauncher();
        await _pumpShell(
          tester,
          size: const Size(390, 844),
          data: data,
          launcher: launcher,
        );

        await tester.tap(find.byKey(const Key('home-app-skills')));
        await tester.pumpAndSettle();

        expect(find.byType(PortfolioAppContent), findsOneWidget);
        final content = tester.widget<PortfolioAppContent>(
          find.byType(PortfolioAppContent),
        );
        expect(content.appId, PortfolioAppId.skills);
        expect(content.data, same(data));
        expect(content.launcher, same(launcher));
        expect(content.compact, isTrue);
        expect(content.tablet, isFalse);
      },
    );

    testWidgets('remains scrollable without overflow on a small 200% screen', (
      tester,
    ) async {
      await _pumpShell(
        tester,
        size: const Size(320, 480),
        textScaler: const TextScaler.linear(2),
      );

      final dock = find.byKey(const Key('mobile-dock'));
      expect(dock, findsOneWidget);
      for (final appName in _allAppNames) {
        final icon = find.byKey(Key('home-app-$appName'));
        await _scrollHomeIconIntoView(tester, icon, reason: appName);
        expect(
          tester.getRect(icon).overlaps(tester.getRect(dock)),
          isFalse,
          reason: '$appName 아이콘을 Dock이 가리면 안 됩니다.',
        );
      }
      expect(tester.takeException(), isNull);

      final profile = find.byKey(const Key('home-app-profile'));
      await tester.ensureVisible(profile);
      await tester.tap(profile);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile-scroll')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps compact Skills and Projects controls usable at 200%', (
      tester,
    ) async {
      for (final scenario in <(PortfolioAppId, String)>[
        (PortfolioAppId.skills, 'skills-mobile-summary-Development'),
        (PortfolioAppId.projects, 'project-selector-2'),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpShell(
          tester,
          size: const Size(320, 480),
          textScaler: const TextScaler.linear(2),
        );

        final appIcon = find.byKey(Key('home-app-${scenario.$1.name}'));
        await tester.ensureVisible(appIcon);
        await tester.tap(appIcon);
        await tester.pumpAndSettle();

        final control = find.byKey(Key(scenario.$2));
        expect(control, findsOneWidget);
        expect(tester.getSize(control).height, greaterThanOrEqualTo(44));
        expect(tester.takeException(), isNull, reason: scenario.$1.name);
      }
    });

    testWidgets('opens Terminal without overflow at 200 percent text scale', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      for (final size in const <Size>[Size(390, 844), Size(320, 480)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpShell(
          tester,
          size: size,
          textScaler: const TextScaler.linear(2),
        );

        final terminalIcon = find.byKey(const Key('home-app-terminal'));
        await tester.ensureVisible(terminalIcon);
        await tester.tap(terminalIcon);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('terminal-app')), findsOneWidget);
        expect(find.bySemanticsLabel('Close Terminal window'), findsOneWidget);
        final closeSize = tester.getSize(
          find.byKey(const Key('mobile-back-close-terminal')),
        );
        expect(closeSize, const Size(44, 44));
        expect(find.text(r'portfolio: ~$'), findsOneWidget);
        expect(find.byKey(const Key('terminal-submit')), findsNothing);
        final input = tester.widget<TextField>(
          find.byKey(const Key('terminal-input')),
        );
        expect(input.decoration?.hintText, isNull);
        expect(input.autofocus, isTrue);
        expect(tester.takeException(), isNull, reason: '$size');
      }
      semantics.dispose();
    });
  });

  group('iPad home and app surface', () {
    testWidgets('refreshes status time without rendering a profile date', (
      tester,
    ) async {
      final clock = _MutableClock(DateTime(2026, 9, 3, 23, 59));
      const size = Size(834, 1194);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final themeController = PortfolioThemeController();
      addTearDown(themeController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppleTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(size: size),
            child: AppleMobileShell(
              data: portfolioData,
              externalLauncher: _RecordingLauncher(),
              themeController: themeController,
              musicController: createTestMusicController(),
              tablet: true,
              now: clock.call,
              clockTickInterval: const Duration(seconds: 1),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('apple-status-time')), findsOneWidget);
      expect(find.text('23:59'), findsOneWidget);
      expect(find.text('Thursday, September 3'), findsNothing);

      clock.current = DateTime(2026, 9, 4);
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('0:00'), findsOneWidget);
      expect(find.text('Friday, September 4'), findsNothing);
      expect(find.text('23:59'), findsNothing);
      expect(find.text('Thursday, September 3'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      clock.current = DateTime(2026, 9, 5);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses six columns with an injected profile app first', (
      tester,
    ) async {
      final data = _profileData(name: '테스트 사용자');
      await _pumpShell(tester, size: const Size(834, 1194), data: data);

      expect(find.byKey(const Key('ipad-shell')), findsOneWidget);
      expect(find.byKey(const Key('ipad-profile-widget')), findsNothing);
      expect(
        find.byKey(const Key('mobile-notes-profile-header')),
        findsNothing,
      );
      expect(find.byKey(const Key('mobile-notes-profile-body')), findsNothing);
      expect(find.byKey(const Key('home-app-profile')), findsOneWidget);
      expect(find.text('테스트 사용자'), findsNothing);
      expect(find.text('프로필 보러가기'), findsNothing);
      expect(find.text('Injected headline'), findsNothing);
      expect(find.text(portfolioData.name), findsNothing);
      _expectAllHomeApps();
      expect(_distinctHomeColumns(tester), 6);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not render a profile monogram tile', (tester) async {
      final data = _profileData(name: '테스트 사용자', englishName: 'Apple Tester');
      await _pumpShell(tester, size: const Size(834, 1194), data: data);

      expect(find.text('AT'), findsNothing);
      expect(find.text('MH'), findsNothing);
    });

    testWidgets('keeps the profile launcher visible on the dark iPad home', (
      tester,
    ) async {
      final data = _profileData(name: '어두운 사용자');
      await _pumpShell(
        tester,
        size: const Size(834, 1194),
        data: data,
        brightness: Brightness.dark,
      );

      expect(find.byKey(const Key('home-app-profile')), findsOneWidget);
      expect(find.byKey(const Key('ipad-profile-card')), findsNothing);
      expect(find.byKey(const Key('ipad-profile-widget')), findsNothing);
      expect(find.text('어두운 사용자'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'opens the rounded tablet career list before its detail depth',
      (tester) async {
        await _pumpShell(tester, size: const Size(834, 1194));

        await tester.tap(find.byKey(const Key('home-app-projects')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('mobile-app-surface')), findsOneWidget);
        expect(find.byKey(const Key('projects-app')), findsOneWidget);
        expect(
          find.byKey(const Key('projects-collection-scroll')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('projects-detail-scroll')), findsNothing);
        expect(find.byKey(const Key('project-detail-title')), findsNothing);
        for (final index in const <int>[2, 3, 4, 5]) {
          expect(find.byKey(Key('project-selector-$index')), findsOneWidget);
        }

        await tester.tap(find.byKey(const Key('project-selector-3')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('projects-collection-scroll')),
          findsNothing,
        );
        expect(find.byKey(const Key('projects-detail-scroll')), findsOneWidget);
        expect(
          tester
              .widget<Text>(find.byKey(const Key('project-detail-title')))
              .data,
          'IRIS',
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'injects tablet form-factor data and launcher into app content',
      (tester) async {
        final data = _profileData(name: '태블릿 사용자');
        final launcher = _RecordingLauncher();
        await _pumpShell(
          tester,
          size: const Size(834, 1194),
          data: data,
          launcher: launcher,
        );

        await tester.tap(find.byKey(const Key('home-app-terminal')));
        await tester.pumpAndSettle();

        expect(find.byType(PortfolioAppContent), findsOneWidget);
        final content = tester.widget<PortfolioAppContent>(
          find.byType(PortfolioAppContent),
        );
        expect(content.appId, PortfolioAppId.terminal);
        expect(content.data, same(data));
        expect(content.launcher, same(launcher));
        expect(content.compact, isFalse);
        expect(content.tablet, isTrue);
      },
    );

    testWidgets('keeps portrait and landscape iPad layouts overflow-free', (
      tester,
    ) async {
      for (final size in const <Size>[Size(834, 1194), Size(1023, 700)]) {
        await _pumpShell(
          tester,
          size: size,
          textScaler: const TextScaler.linear(2),
        );

        expect(find.byKey(const Key('ipad-shell')), findsOneWidget);
        expect(find.byKey(const Key('home-app-profile')), findsOneWidget);
        expect(find.byKey(const Key('ipad-profile-widget')), findsNothing);
        expect(tester.takeException(), isNull, reason: '$size');
      }
    });

    testWidgets('opens Terminal in short iPad layouts at 200 percent', (
      tester,
    ) async {
      for (final size in const <Size>[Size(600, 400), Size(1023, 600)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpShell(
          tester,
          size: size,
          textScaler: const TextScaler.linear(2),
        );

        final terminalIcon = find.byKey(const Key('home-app-terminal'));
        await tester.ensureVisible(terminalIcon);
        await tester.tap(terminalIcon);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('terminal-app')), findsOneWidget);
        expect(find.text(r'portfolio: ~$'), findsOneWidget);
        expect(find.byKey(const Key('terminal-submit')), findsNothing);
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('terminal-input')))
              .decoration
              ?.hintText,
          isNull,
        );
        expect(tester.takeException(), isNull, reason: '$size');
      }
    });

    testWidgets('keeps Trash items visible without a duplicate title row', (
      tester,
    ) async {
      for (final size in const <Size>[Size(600, 400), Size(1023, 600)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpShell(
          tester,
          size: size,
          textScaler: const TextScaler.linear(2),
        );

        final trashIcon = find.byKey(const Key('home-app-trash'));
        await _scrollHomeIconIntoView(tester, trashIcon, reason: '$size');
        await tester.tap(trashIcon);
        await tester.pumpAndSettle();

        final trashScroll = find.byKey(const Key('trash-scroll'));
        expect(trashScroll, findsOneWidget);
        expect(find.byType(AppleToolbar), findsNothing);
        expect(find.byKey(const Key('trash-item-0')), findsOneWidget);
        expect(find.byKey(const Key('trash-empty-button')), findsOneWidget);
        expect(find.text('Trash is Empty'), findsNothing);
        await tester.drag(trashScroll, const Offset(0, -80));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$size');
      }
    });

    testWidgets('짧은 iPad에서도 Dock 위로 모든 홈 앱을 스크롤할 수 있다', (tester) async {
      await _pumpShell(
        tester,
        size: const Size(600, 400),
        textScaler: const TextScaler.linear(2),
      );

      final dock = find.byKey(const Key('mobile-dock'));
      expect(dock, findsOneWidget);
      expect(find.byKey(const Key('mobile-dock-profile')), findsOneWidget);
      expect(find.byKey(const Key('mobile-dock-projects')), findsOneWidget);

      for (final appName in _allAppNames) {
        final icon = find.byKey(Key('home-app-$appName'));
        await _scrollHomeIconIntoView(tester, icon, reason: appName);
        expect(
          tester.getRect(icon).overlaps(tester.getRect(dock)),
          isFalse,
          reason: '$appName 아이콘을 Dock이 가리면 안 됩니다.',
        );
      }
    });
  });
}

BoxDecoration _launcherFrameDecoration(WidgetTester tester, Finder launcher) {
  final frame = find.descendant(
    of: launcher,
    matching: find.byType(AppleAppArtworkFrame),
  );
  expect(frame, findsOneWidget);
  final frameContainer = find.descendant(
    of: frame,
    matching: find.byType(Container),
  );
  return tester.widget<Container>(frameContainer.first).decoration!
      as BoxDecoration;
}

Future<void> _scrollHomeIconIntoView(
  WidgetTester tester,
  Finder icon, {
  required String reason,
}) async {
  final homeScroll = find.byKey(const Key('mobile-home-scroll'));

  for (var attempt = 0; attempt < 16; attempt += 1) {
    if (icon.evaluate().isNotEmpty) {
      final scrollRect = tester.getRect(homeScroll);
      final iconRect = tester.getRect(icon);
      if (iconRect.top >= scrollRect.top + 4 &&
          iconRect.bottom <= scrollRect.bottom - 4) {
        break;
      }
    }
    await tester.drag(homeScroll, const Offset(0, -100));
    await tester.pumpAndSettle();
  }

  expect(icon, findsOneWidget, reason: reason);
  expect(
    tester.getRect(homeScroll).overlaps(tester.getRect(icon)),
    isTrue,
    reason: reason,
  );
}

const List<String> _allAppNames = <String>[
  'profile',
  'introduction',
  'skills',
  'projects',
  'terminal',
  'music',
  'photos',
  'github',
  'mail',
  'settings',
  'trash',
];

void _expectAllHomeApps() {
  for (final appName in _allAppNames) {
    expect(find.byKey(Key('home-app-$appName')), findsOneWidget);
  }
  expect(find.byKey(const Key('home-app-about')), findsNothing);
}

int _distinctHomeColumns(WidgetTester tester) {
  final xCoordinates = <int>{
    for (final appName in _allAppNames)
      tester.getCenter(find.byKey(Key('home-app-$appName'))).dx.round(),
  };
  return xCoordinates.length;
}

Future<void> _expectOnlyShell(
  WidgetTester tester, {
  required double width,
  required String expected,
}) async {
  await _pumpShell(tester, size: Size(width, 900));

  for (final key in const <String>['iphone-shell', 'ipad-shell', 'mac-shell']) {
    expect(
      find.byKey(Key(key)),
      key == expected ? findsOneWidget : findsNothing,
      reason: 'width $width should select only $expected',
    );
  }
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required Size size,
  PortfolioData data = portfolioData,
  ExternalLauncher? launcher,
  TextScaler textScaler = TextScaler.noScaling,
  Brightness brightness = Brightness.light,
  bool? mobilePlatformOverride,
  EdgeInsets viewPadding = EdgeInsets.zero,
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
      theme: brightness == Brightness.dark
          ? AppleTheme.dark()
          : AppleTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: textScaler,
          padding: viewPadding,
          viewPadding: viewPadding,
        ),
        child: AdaptivePortfolioShell(
          data: data,
          externalLauncher: launcher ?? _RecordingLauncher(),
          themeController: themeController,
          musicController: createTestMusicController(),
          mobilePlatformOverride: mobilePlatformOverride,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

PortfolioData _profileData({
  required String name,
  String englishName = 'Injected Person',
}) {
  return PortfolioData(
    identity: PortfolioIdentity(
      name: name,
      englishName: englishName,
      email: 'injected@example.com',
      githubUrl: 'https://example.com/injected',
      headline: 'Injected headline',
      biography: 'Injected biography',
    ),
    experiences: const <PortfolioExperience>[],
    education: const <PortfolioEducation>[],
    skillGroups: const <PortfolioSkillGroup>[],
    projects: const <PortfolioProject>[],
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

final class _MutableClock {
  _MutableClock(this.current);

  DateTime current;

  DateTime call() => current;
}
