import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/portfolio_app_content.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
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
  });

  group('iPhone home and navigation', () {
    testWidgets(
      'uses a four-column app grid, translucent dock, and home chrome',
      (tester) async {
        await _pumpShell(tester, size: const Size(390, 844));

        expect(find.byKey(const Key('iphone-shell')), findsOneWidget);
        expect(find.byKey(const Key('apple-status-bar')), findsOneWidget);
        expect(find.byKey(const Key('mobile-home-grid')), findsOneWidget);
        expect(find.byKey(const Key('mobile-home-indicator')), findsOneWidget);
        expect(find.byKey(const Key('mobile-dock')), findsOneWidget);
        _expectAllHomeApps();
        for (final id in _phoneDockApps) {
          expect(find.byKey(Key('mobile-dock-${id.name}')), findsOneWidget);
        }

        expect(_distinctHomeColumns(tester), 4);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('opens one full-screen app and closes it back to home', (
      tester,
    ) async {
      await _pumpShell(tester, size: const Size(390, 844));

      await tester.tap(find.byKey(const Key('home-app-about')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mobile-home')), findsNothing);
      expect(find.byKey(const Key('mobile-app-surface')), findsOneWidget);
      expect(find.byKey(const Key('about-app')), findsOneWidget);
      expect(find.bySemanticsLabel('Close About'), findsOneWidget);

      await tester.tap(find.byKey(const Key('mobile-close')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mobile-home')), findsOneWidget);
      expect(find.byKey(const Key('mobile-app-surface')), findsNothing);
    });

    testWidgets('home icon supports keyboard activation and button semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpShell(tester, size: const Size(390, 844));

      expect(find.bySemanticsLabel('Open About'), findsAtLeastNWidgets(1));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('about-app')), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('Space also activates the initially focused home icon', (
      tester,
    ) async {
      await _pumpShell(tester, size: const Size(390, 844));

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('about-app')), findsOneWidget);
    });

    testWidgets('Dock icon supports focus traversal and keyboard activation', (
      tester,
    ) async {
      await _pumpShell(tester, size: const Size(390, 844));

      for (var index = 0; index < _allApps.length; index++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('about-app')), findsOneWidget);
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

      await tester.tap(find.byKey(const Key('mobile-dock-about')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('about-scroll')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps compact Skills and Projects controls usable at 200%', (
      tester,
    ) async {
      for (final scenario in <(PortfolioAppId, String)>[
        (PortfolioAppId.skills, 'skills-category-Development'),
        (PortfolioAppId.projects, 'project-selector-0'),
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
  });

  group('iPad home and app surface', () {
    testWidgets('uses six columns and renders the injected profile widget', (
      tester,
    ) async {
      final data = _profileData(name: '테스트 사용자');
      await _pumpShell(tester, size: const Size(834, 1194), data: data);

      expect(find.byKey(const Key('ipad-shell')), findsOneWidget);
      expect(find.byKey(const Key('ipad-profile-widget')), findsOneWidget);
      expect(find.text('테스트 사용자'), findsOneWidget);
      expect(find.text(portfolioData.name), findsNothing);
      _expectAllHomeApps();
      expect(_distinctHomeColumns(tester), 6);
      expect(tester.takeException(), isNull);
    });

    testWidgets('derives the profile monogram from injected identity data', (
      tester,
    ) async {
      final data = _profileData(name: '테스트 사용자', englishName: 'Apple Tester');
      await _pumpShell(tester, size: const Size(834, 1194), data: data);

      expect(find.text('AT'), findsOneWidget);
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

      final name = tester.widget<Text>(find.text('어두운 사용자'));
      expect(name.style?.color?.computeLuminance(), greaterThan(0.7));

      final date = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('ipad-profile-card')),
          matching: find.byWidgetPredicate(
            (widget) => widget is Text && (widget.data?.contains(',') ?? false),
          ),
        ),
      );
      expect(
        _contrastRatio(date.style!.color!, gradient.colors.first),
        greaterThanOrEqualTo(4.5),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'opens a rounded tablet app surface with project master-detail',
      (tester) async {
        await _pumpShell(tester, size: const Size(834, 1194));

        await tester.tap(find.byKey(const Key('home-app-projects')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('mobile-app-surface')), findsOneWidget);
        expect(find.byKey(const Key('projects-app')), findsOneWidget);
        expect(find.byKey(const Key('projects-detail-scroll')), findsOneWidget);
        expect(
          tester.getCenter(find.byKey(const Key('project-selector-0'))).dx,
          lessThan(
            tester.getCenter(find.byKey(const Key('project-detail-title'))).dx,
          ),
        );

        await tester.tap(find.byKey(const Key('project-selector-1')));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<Text>(find.byKey(const Key('project-detail-title')))
              .data,
          'ReadingLog',
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
  });
}

const List<PortfolioAppId> _allApps = PortfolioAppId.values;

const List<PortfolioAppId> _phoneDockApps = <PortfolioAppId>[
  PortfolioAppId.about,
  PortfolioAppId.projects,
  PortfolioAppId.github,
  PortfolioAppId.mail,
];

void _expectAllHomeApps() {
  for (final appId in _allApps) {
    expect(find.byKey(Key('home-app-${appId.name}')), findsOneWidget);
  }
}

int _distinctHomeColumns(WidgetTester tester) {
  final xCoordinates = <int>{
    for (final appId in _allApps)
      tester.getCenter(find.byKey(Key('home-app-${appId.name}'))).dx.round(),
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
}) async {
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

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
