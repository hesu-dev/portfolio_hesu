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
import 'package:portfolio_hesu/portfolio/widgets/apple_app_icon.dart';

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

      const expectedLabels = <PortfolioAppId, String>{
        PortfolioAppId.about: 'About',
        PortfolioAppId.skills: 'Skills',
        PortfolioAppId.projects: 'Projects',
        PortfolioAppId.terminal: 'Terminal',
        PortfolioAppId.thisMac: 'This Mac',
        PortfolioAppId.trash: 'Trash',
        PortfolioAppId.github: 'GitHub',
        PortfolioAppId.mail: 'Mail',
      };

      for (final entry in expectedLabels.entries) {
        expect(
          find.byKey(Key('apple-app-icon-${entry.key.name}')),
          findsOneWidget,
        );
        expect(find.text(entry.value), findsOneWidget);
      }

      await tester.tap(find.byKey(const Key('apple-app-icon-about')));
      await tester.pump();
      expect(tapped, <PortfolioAppId>[PortfolioAppId.about]);
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

      expect(find.bySemanticsLabel('Open Projects'), findsOneWidget);
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
      expect(find.bySemanticsLabel('Open About'), findsOneWidget);
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
  });

  group('PortfolioAppContent', () {
    testWidgets('routes and renders every app without reference identity', (
      tester,
    ) async {
      final launcher = _FakeExternalLauncher();
      const expectedRootKeys = <PortfolioAppId, String>{
        PortfolioAppId.about: 'about-app',
        PortfolioAppId.skills: 'skills-app',
        PortfolioAppId.projects: 'projects-app',
        PortfolioAppId.terminal: 'terminal-app',
        PortfolioAppId.thisMac: 'this-mac-app',
        PortfolioAppId.trash: 'trash-app',
        PortfolioAppId.github: 'github-app',
        PortfolioAppId.mail: 'mail-app',
      };

      for (final entry in expectedRootKeys.entries) {
        await _pumpApp(
          tester,
          appId: entry.key,
          launcher: launcher,
          size: const Size(900, 650),
        );

        expect(find.byKey(Key(entry.value)), findsOneWidget);
        expect(_visibleText(tester), isNot(contains('천주아')));
        expect(_visibleText(tester).toLowerCase(), isNot(contains('juah')));
        expect(tester.takeException(), isNull, reason: entry.key.name);
      }
    });

    testWidgets(
      'about shows canonical identity, career, education, and contact',
      (tester) async {
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
        expect(find.text(portfolioData.identity.email), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('Career'),
          220,
          scrollable: _scrollableInside(const Key('about-scroll')),
        );
        expect(find.text('Career'), findsOneWidget);
        expect(
          find.text(portfolioData.experiences.first.role),
          findsAtLeastNWidgets(1),
        );

        await tester.scrollUntilVisible(
          find.text('Education'),
          220,
          scrollable: _scrollableInside(const Key('about-scroll')),
        );
        expect(
          find.text(portfolioData.education.first.institution),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('about derives its avatar monogram from injected identity', (
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

      expect(find.text('AL'), findsOneWidget);
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

      expect(find.text('김민'), findsOneWidget);
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

    testWidgets('skills category selection updates actual visible skills', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        appId: PortfolioAppId.skills,
        launcher: _FakeExternalLauncher(),
        size: const Size(360, 600),
        compact: true,
      );

      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Notion'), findsNothing);

      await tester.tap(find.byKey(const Key('skills-category-Collaboration')));
      await tester.pumpAndSettle();

      expect(find.text('Notion'), findsOneWidget);
      expect(find.text('Slack'), findsOneWidget);
      expect(find.text('Flutter'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'project selector updates detail and exposes all six projects',
      (tester) async {
        await _pumpApp(
          tester,
          appId: PortfolioAppId.projects,
          launcher: _FakeExternalLauncher(),
          size: const Size(900, 650),
        );

        for (var index = 0; index < portfolioData.projects.length; index++) {
          expect(find.byKey(Key('project-selector-$index')), findsOneWidget);
        }
        expect(
          _textAtKey(tester, const Key('project-detail-title')),
          portfolioData.projects.first.title,
        );

        await tester.tap(find.byKey(const Key('project-selector-1')));
        await tester.pumpAndSettle();

        final readingLog = portfolioData.projects[1];
        expect(
          _textAtKey(tester, const Key('project-detail-title')),
          readingLog.title,
        );
        expect(find.text(readingLog.period), findsOneWidget);
        expect(find.text(readingLog.description), findsOneWidget);
        for (final technology in readingLog.technologies) {
          expect(find.text(technology), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
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

      await tester.tap(find.byKey(const Key('project-selector-1')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('project-link-1-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('project-link-1-0')));
      await tester.pumpAndSettle();

      expect(launcher.launched, <Uri>[portfolioData.projects[1].links[0].uri]);
      expect(find.byKey(const Key('project-launch-feedback')), findsOneWidget);
      expect(find.textContaining('열 수 없습니다'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

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

        await tester.tap(find.byKey(const Key('project-selector-1')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('project-link-1-0')));
        await tester.tap(find.byKey(const Key('project-link-1-0')));
        await tester.pump();
        await tester.ensureVisible(find.byKey(const Key('project-link-1-1')));
        await tester.tap(find.byKey(const Key('project-link-1-1')));
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

      await tester.tap(find.byKey(const Key('project-selector-1')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('project-link-1-0')));
      await tester.tap(find.byKey(const Key('project-link-1-0')));
      await tester.pump();
      expect(launcher.requests, hasLength(1));

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

      await tester.enterText(find.byKey(const Key('terminal-input')), 'whoami');
      await tester.tap(find.byKey(const Key('terminal-submit')));
      await tester.pump();
      expect(find.textContaining('Min He-su'), findsOneWidget);
      expect(find.textContaining(portfolioData.identity.email), findsOneWidget);

      await tester.enterText(find.byKey(const Key('terminal-input')), 'oops');
      await tester.tap(find.byKey(const Key('terminal-submit')));
      await tester.pump();
      expect(find.textContaining('command not found'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('terminal-input')), 'clear');
      await tester.tap(find.byKey(const Key('terminal-submit')));
      await tester.pump();
      expect(find.textContaining('Min He-su'), findsNothing);
      expect(find.textContaining('command not found'), findsNothing);
      expect(tester.takeException(), isNull);
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

    testWidgets(
      'all apps avoid RenderFlex overflow in compact and wide bounds',
      (tester) async {
        final launcher = _FakeExternalLauncher();

        for (final size in const <Size>[Size(360, 600), Size(900, 650)]) {
          for (final appId in PortfolioAppId.values) {
            await _pumpApp(
              tester,
              appId: appId,
              launcher: launcher,
              size: size,
              compact: size.width < 600,
              tablet: size.width >= 600 && size.width < 1024,
            );
            await tester.pumpAndSettle();

            final exception = tester.takeException();
            expect(
              exception,
              isNull,
              reason:
                  '${appId.name} at ${size.width}x${size.height}: $exception',
            );
          }
        }
      },
    );
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
  bool tablet = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.light(),
      darkTheme: AppleTheme.dark(),
      home: SizedBox.expand(
        child: PortfolioAppContent(
          key: ValueKey<PortfolioAppId>(appId),
          appId: appId,
          data: data,
          launcher: launcher,
          compact: compact,
          tablet: tablet,
        ),
      ),
    ),
  );
  await tester.pump();
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
