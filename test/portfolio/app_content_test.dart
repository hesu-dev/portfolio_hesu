import 'package:flutter/material.dart';
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

Future<void> _pumpApp(
  WidgetTester tester, {
  required PortfolioAppId appId,
  required ExternalLauncher launcher,
  required Size size,
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
          data: portfolioData,
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
