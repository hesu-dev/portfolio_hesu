import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/portfolio_app_content.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/mobile/apple_mobile_shell.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/theme/portfolio_theme_controller.dart';
import 'package:portfolio_hesu/portfolio/widgets/adaptive_portfolio_shell.dart';

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

    testWidgets('wide mobile devices stay on the iPad shell without a Dock', (
      tester,
    ) async {
      await _pumpShell(
        tester,
        size: const Size(1366, 1024),
        mobilePlatformOverride: true,
      );

      expect(find.byKey(const Key('ipad-shell')), findsOneWidget);
      expect(find.byKey(const Key('mac-shell')), findsNothing);
      expect(find.byKey(const Key('mobile-dock')), findsNothing);
      expect(find.byKey(const Key('mac-dock')), findsNothing);
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

        expect(find.text('Skills'), findsOneWidget);
        await tester.longPress(find.byKey(const Key('home-app-skills')));
        await tester.pump(const Duration(seconds: 1));
        expect(
          find.text('Skills'),
          findsNWidgets(2),
          reason: '${scenario.$2} 아이콘 이름이 툴팁으로 중복되면 안 됩니다.',
        );
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
  });

  group('iPhone home and navigation', () {
    testWidgets(
      'uses a four-column app grid and home chrome without an app Dock',
      (tester) async {
        await _pumpShell(tester, size: const Size(390, 844));

        expect(find.byKey(const Key('iphone-shell')), findsOneWidget);
        expect(find.byKey(const Key('apple-status-bar')), findsOneWidget);
        expect(find.byKey(const Key('mobile-home-grid')), findsOneWidget);
        expect(find.byKey(const Key('mobile-home-indicator')), findsOneWidget);
        expect(find.byKey(const Key('mobile-dock')), findsNothing);
        _expectAllHomeApps();

        expect(_distinctHomeColumns(tester), 4);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('opens one full-screen app and closes it back to home', (
      tester,
    ) async {
      await _pumpShell(tester, size: const Size(390, 844));

      await tester.tap(find.byKey(const Key('iphone-profile-card')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mobile-home')), findsNothing);
      expect(find.byKey(const Key('mobile-app-surface')), findsOneWidget);
      expect(find.byKey(const Key('about-app')), findsOneWidget);
      expect(find.bySemanticsLabel('Close About window'), findsOneWidget);

      await tester.tap(find.byKey(const Key('mobile-back-close-about')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mobile-home')), findsOneWidget);
      expect(find.byKey(const Key('mobile-app-surface')), findsNothing);
    });

    testWidgets('home icon supports keyboard activation and button semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpShell(tester, size: const Size(390, 844));

      expect(find.bySemanticsLabel('Open Skills'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('skills-app')), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('Space also activates the initially focused home icon', (
      tester,
    ) async {
      await _pumpShell(tester, size: const Size(390, 844));

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('skills-app')), findsOneWidget);
    });

    testWidgets('does not add duplicate Dock focus targets', (tester) async {
      await _pumpShell(tester, size: const Size(390, 844));

      expect(find.byKey(const Key('mobile-dock')), findsNothing);
      expect(find.byKey(const Key('mobile-dock-about')), findsNothing);
      expect(find.bySemanticsLabel('Open About'), findsNothing);
      expect(find.bySemanticsLabel('Open Skills'), findsOneWidget);
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

      expect(find.byKey(const Key('mobile-home-scroll')), findsOneWidget);
      await tester.drag(
        find.byKey(const Key('mobile-home-scroll')),
        const Offset(0, -240),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final about = find.byKey(const Key('iphone-profile-card'));
      await tester.ensureVisible(about);
      await tester.tap(about);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('about-scroll')), findsOneWidget);
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
        final submitSize = tester.getSize(
          find.byKey(const Key('terminal-submit')),
        );
        expect(submitSize.width, greaterThanOrEqualTo(44));
        expect(submitSize.height, greaterThanOrEqualTo(44));
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

    testWidgets('uses six columns and renders the injected profile widget', (
      tester,
    ) async {
      final data = _profileData(name: '테스트 사용자');
      await _pumpShell(tester, size: const Size(834, 1194), data: data);

      expect(find.byKey(const Key('ipad-shell')), findsOneWidget);
      expect(find.byKey(const Key('ipad-profile-widget')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('mobile-notes-profile-header')),
          matching: find.text('테스트 사용자'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('mobile-notes-profile-body')),
          matching: find.text('테스트 사용자'),
        ),
        findsNothing,
      );
      expect(find.text('자세히 보러가기'), findsOneWidget);
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

    testWidgets('uses a dark profile surface with readable dark-mode text', (
      tester,
    ) async {
      final data = _profileData(name: '어두운 사용자');
      await _pumpShell(
        tester,
        size: const Size(834, 1194),
        data: data,
        brightness: Brightness.dark,
      );

      expect(find.byKey(const Key('ipad-profile-card')), findsOneWidget);
      final card = tester.widget<Container>(
        find.byKey(const Key('ipad-profile-card')),
      );
      final decoration = card.decoration! as BoxDecoration;
      final gradient = decoration.gradient! as LinearGradient;
      expect(gradient.colors.first.computeLuminance(), lessThan(0.2));

      final name = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('mobile-notes-profile-header')),
          matching: find.text('어두운 사용자'),
        ),
      );
      expect(name.style?.color?.computeLuminance(), greaterThan(0.7));
      expect(find.byKey(const Key('ipad-profile-date')), findsNothing);
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
        expect(find.byKey(const Key('ipad-profile-widget')), findsOneWidget);
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
        final submitSize = tester.getSize(
          find.byKey(const Key('terminal-submit')),
        );
        expect(submitSize.width, greaterThanOrEqualTo(44));
        expect(submitSize.height, greaterThanOrEqualTo(44));
        expect(tester.takeException(), isNull, reason: '$size');
      }
    });

    testWidgets('keeps Trash content visible without a duplicate title row', (
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
        expect(find.text('Trash is Empty'), findsOneWidget);
        await tester.drag(trashScroll, const Offset(0, -80));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$size');
      }
    });

    testWidgets('짧은 iPad에서도 Dock 없이 모든 홈 앱을 스크롤할 수 있다', (tester) async {
      await _pumpShell(
        tester,
        size: const Size(600, 400),
        textScaler: const TextScaler.linear(2),
      );

      expect(find.byKey(const Key('mobile-dock')), findsNothing);

      for (final appName in _allAppNames) {
        await _scrollHomeIconIntoView(
          tester,
          find.byKey(Key('home-app-$appName')),
          reason: appName,
        );
      }
    });
  });
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
  'skills',
  'projects',
  'terminal',
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
        data: MediaQueryData(size: size, textScaler: textScaler),
        child: AdaptivePortfolioShell(
          data: data,
          externalLauncher: launcher ?? _RecordingLauncher(),
          themeController: themeController,
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
