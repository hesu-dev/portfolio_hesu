import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/portfolio_app_content.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';
import 'package:portfolio_hesu/portfolio/portfolio_app.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/theme/portfolio_theme_controller.dart';
import 'package:portfolio_hesu/portfolio/widgets/adaptive_portfolio_shell.dart';

void main() {
  group('macOS adaptive shell', () {
    testWidgets('fills representative 1024 and 1440 desktop viewports', (
      tester,
    ) async {
      for (final size in const <Size>[Size(1024, 700), Size(1440, 900)]) {
        await _pumpPortfolio(tester, size: size);

        expect(find.byKey(const Key('mac-shell')), findsOneWidget);
        expect(
          tester.getSize(find.byKey(const Key('mac-shell'))),
          size,
          reason: '$size',
        );
        expect(find.byKey(const Key('ipad-shell')), findsNothing);
        expect(find.byKey(const Key('iphone-shell')), findsNothing);
        expect(tester.takeException(), isNull, reason: '$size');
      }
    });

    testWidgets('keeps the iPad and iPhone shells below 1024', (tester) async {
      await _pumpPortfolio(tester, size: const Size(834, 700));
      expect(find.byKey(const Key('ipad-shell')), findsOneWidget);
      expect(find.byKey(const Key('mac-shell')), findsNothing);

      await _pumpPortfolio(tester, size: const Size(390, 700));
      expect(find.byKey(const Key('iphone-shell')), findsOneWidget);
      expect(find.byKey(const Key('mac-shell')), findsNothing);
    });

    testWidgets('uses the shared Apple light and dark themes', (tester) async {
      await tester.pumpWidget(PortfolioApp(externalLauncher: _FakeLauncher()));

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(
        app.theme?.scaffoldBackgroundColor,
        AppleTheme.light().scaffoldBackgroundColor,
      );
      expect(
        app.darkTheme?.scaffoldBackgroundColor,
        AppleTheme.dark().scaffoldBackgroundColor,
      );
    });
  });

  group('macOS desktop icons', () {
    testWidgets('shows the complete desktop catalog and discoverability hint', (
      tester,
    ) async {
      await _pumpPortfolio(tester);

      for (final entry in _labels.entries) {
        expect(
          find.byKey(Key('desktop-app-${entry.key.name}')),
          findsOneWidget,
        );
        expect(find.text(entry.value), findsAtLeastNWidgets(1));
      }
      expect(
        find.byKey(const Key('desktop-discoverability-hint')),
        findsOneWidget,
      );
      expect(find.textContaining('Double-click'), findsOneWidget);
    });

    testWidgets('single click selects and double click opens an app', (
      tester,
    ) async {
      await _pumpPortfolio(tester);
      final about = find.byKey(const Key('desktop-app-about'));

      await tester.tap(about);
      await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 20));

      expect(
        find.byKey(const Key('desktop-app-selection-about')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('mac-window-about')), findsNothing);

      await _doubleClick(tester, about);

      expect(find.byKey(const Key('mac-window-about')), findsOneWidget);
      expect(find.byKey(const Key('mac-window-active-about')), findsOneWidget);
    });

    testWidgets('Enter and Space open the focused desktop icon', (
      tester,
    ) async {
      await _pumpPortfolio(tester);
      final skills = find.byKey(const Key('desktop-app-skills'));

      await tester.tap(skills);
      await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 20));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mac-window-skills')), findsOneWidget);

      await tester.tap(find.byKey(const Key('desktop-app-terminal')));
      await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 20));
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mac-window-terminal')), findsOneWidget);
    });

    testWidgets('injects portfolio data and launcher into opened content', (
      tester,
    ) async {
      final launcher = _FakeLauncher();
      await _pumpPortfolio(tester, launcher: launcher);

      await _doubleClick(tester, find.byKey(const Key('desktop-app-github')));

      final content = tester.widget<PortfolioAppContent>(
        find.byType(PortfolioAppContent),
      );
      expect(content.appId, PortfolioAppId.github);
      expect(content.launcher, same(launcher));
    });
  });

  group('macOS window manager', () {
    testWidgets('keeps one instance and focuses an already-open app', (
      tester,
    ) async {
      await _pumpPortfolio(tester);
      await _openDesktopApp(tester, PortfolioAppId.about);
      await _openDesktopApp(tester, PortfolioAppId.projects);

      expect(find.byKey(const Key('mac-window-about')), findsOneWidget);
      expect(find.byKey(const Key('mac-window-projects')), findsOneWidget);
      expect(
        find.byKey(const Key('mac-window-active-projects')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('dock-app-about')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mac-window-about')), findsOneWidget);
      expect(find.byKey(const Key('mac-window-active-about')), findsOneWidget);
      expect(find.byKey(const Key('mac-window-active-projects')), findsNothing);
    });

    testWidgets('traffic lights close, minimize, restore, and maximize', (
      tester,
    ) async {
      await _pumpPortfolio(tester, size: const Size(1024, 700));
      await _openDesktopApp(tester, PortfolioAppId.about);
      final window = find.byKey(const Key('mac-window-about'));
      final originalRect = tester.getRect(window);

      expect(find.bySemanticsLabel('Close About window'), findsOneWidget);
      expect(find.bySemanticsLabel('Minimize About window'), findsOneWidget);
      expect(find.bySemanticsLabel('Maximize About window'), findsOneWidget);

      await tester.tap(find.byKey(const Key('window-minimize-about')));
      await tester.pumpAndSettle();
      expect(window, findsNothing);
      expect(find.byKey(const Key('dock-running-about')), findsOneWidget);

      await tester.tap(find.byKey(const Key('dock-app-about')));
      await tester.pumpAndSettle();
      expect(window, findsOneWidget);

      await tester.tap(find.byKey(const Key('window-maximize-about')));
      await tester.pumpAndSettle();
      final maximizedRect = tester.getRect(window);
      expect(maximizedRect.width, greaterThan(originalRect.width));
      expect(maximizedRect.top, greaterThanOrEqualTo(30));

      await tester.tap(find.byKey(const Key('window-maximize-about')));
      await tester.pumpAndSettle();
      final restoredRect = tester.getRect(window);
      expect(restoredRect.size, originalRect.size);

      await tester.tap(find.byKey(const Key('window-close-about')));
      await tester.pumpAndSettle();
      expect(window, findsNothing);
      expect(find.byKey(const Key('dock-running-about')), findsNothing);
    });

    testWidgets('traffic lights expose larger pointer and semantics targets', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpPortfolio(tester);
      await _openDesktopApp(tester, PortfolioAppId.about);

      for (final control in const <String>['close', 'minimize', 'maximize']) {
        final target = find.byKey(Key('window-$control-about'));
        final visual = find.byKey(Key('window-$control-about-visual'));
        final targetSize = tester.getSize(target);
        final semanticsSize = tester.getSemantics(target).rect.size;

        expect(targetSize.width, inInclusiveRange(28, 44));
        expect(targetSize.height, inInclusiveRange(28, 44));
        expect(semanticsSize.width, inInclusiveRange(28, 44));
        expect(semanticsSize.height, inInclusiveRange(28, 44));
        expect(tester.getSize(visual), const Size.square(14));
      }

      final minimizeTarget = tester.getRect(
        find.byKey(const Key('window-minimize-about')),
      );
      await tester.tapAt(minimizeTarget.centerLeft + const Offset(1, 0));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mac-window-about')), findsNothing);
      expect(find.byKey(const Key('dock-running-about')), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('title-bar drag clamps windows into the visible work area', (
      tester,
    ) async {
      await _pumpPortfolio(tester, size: const Size(1024, 700));
      await _openDesktopApp(tester, PortfolioAppId.terminal);

      await tester.drag(
        find.byKey(const Key('mac-window-titlebar-terminal')),
        const Offset(-4000, -4000),
      );
      await tester.pumpAndSettle();
      var rect = tester.getRect(find.byKey(const Key('mac-window-terminal')));
      expect(rect.left, greaterThanOrEqualTo(8));
      expect(rect.top, greaterThanOrEqualTo(38));

      await tester.drag(
        find.byKey(const Key('mac-window-titlebar-terminal')),
        const Offset(5000, 5000),
      );
      await tester.pumpAndSettle();
      rect = tester.getRect(find.byKey(const Key('mac-window-terminal')));
      expect(rect.right, lessThanOrEqualTo(1016));
      expect(rect.bottom, lessThanOrEqualTo(594));
    });

    testWidgets(
      'reordering windows preserves app state and the inactive drag gesture',
      (tester) async {
        await _pumpPortfolio(tester);
        await _openDesktopApp(tester, PortfolioAppId.terminal);
        await tester.enterText(
          find.byKey(const Key('terminal-input')),
          'skills',
        );
        await tester.tap(find.byKey(const Key('terminal-submit')));
        await tester.pumpAndSettle();

        await tester.drag(
          find.byKey(const Key('mac-window-titlebar-terminal')),
          const Offset(-220, 0),
        );
        await tester.pumpAndSettle();
        await _openDesktopApp(tester, PortfolioAppId.projects);
        await tester.tap(find.byKey(const Key('project-selector-1')));
        await tester.pumpAndSettle();

        expect(find.text('hs0647@portfolio ~ % skills'), findsOneWidget);
        expect(
          tester
              .widget<Text>(find.byKey(const Key('project-detail-title')))
              .data,
          'ReadingLog',
        );

        final terminal = find.byKey(const Key('mac-window-terminal'));
        final beforeDrag = tester.getRect(terminal);
        final gesture = await tester.startGesture(
          beforeDrag.topLeft + const Offset(18, 12),
        );
        await gesture.moveBy(const Offset(24, 8));
        await tester.pump();
        await gesture.moveBy(const Offset(76, 24));
        await gesture.up();
        await tester.pumpAndSettle();

        final afterDrag = tester.getRect(terminal);
        expect(afterDrag.left, greaterThan(beforeDrag.left + 60));
        expect(
          find.byKey(const Key('mac-window-active-terminal')),
          findsOneWidget,
        );
        expect(find.text('hs0647@portfolio ~ % skills'), findsOneWidget);
        expect(
          tester
              .widget<Text>(find.byKey(const Key('project-detail-title')))
              .data,
          'ReadingLog',
        );
      },
    );

    testWidgets(
      'minimized windows preserve state without focus or interaction',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await _pumpPortfolio(tester);
        await _openDesktopApp(tester, PortfolioAppId.terminal);
        await tester.enterText(
          find.byKey(const Key('terminal-input')),
          'skills',
        );
        await tester.tap(find.byKey(const Key('terminal-submit')));
        await tester.pumpAndSettle();

        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .focusNode
              .hasFocus,
          isTrue,
        );
        final hiddenControlLocation = tester.getCenter(
          find.byKey(const Key('window-close-terminal')),
        );

        await tester.tap(find.byKey(const Key('window-minimize-terminal')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('mac-window-terminal')), findsNothing);
        expect(
          find.byKey(const Key('mac-window-terminal'), skipOffstage: false),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('Close Terminal window'), findsNothing);
        expect(
          tester
              .widget<EditableText>(
                find.byType(EditableText, skipOffstage: false),
              )
              .focusNode
              .hasFocus,
          isFalse,
        );

        await tester.tapAt(hiddenControlLocation);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('dock-running-terminal')), findsOneWidget);

        await tester.tap(find.byKey(const Key('dock-app-terminal')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('mac-window-terminal')), findsOneWidget);
        expect(find.text('hs0647@portfolio ~ % skills'), findsOneWidget);
        semantics.dispose();
      },
    );
  });

  group('macOS menu bar and Dock', () {
    testWidgets('system menu derives identity from injected portfolio data', (
      tester,
    ) async {
      await _pumpAdaptivePortfolio(tester, data: _customPortfolioData);

      await tester.tap(find.byKey(const Key('mac-system-menu-button')));
      await tester.pumpAndSettle();

      expect(find.text('Custom Developer · Flutter portfolio'), findsOneWidget);
      expect(find.text('Min He-su · Flutter portfolio'), findsNothing);
    });

    testWidgets('opens an accessible system menu with keyboard activation', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpPortfolio(tester);
      final systemMenu = find.byKey(const Key('mac-system-menu-button'));

      expect(find.bySemanticsLabel('Open system menu'), findsOneWidget);
      await tester.tap(systemMenu);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mac-system-menu-panel')), findsOneWidget);
      expect(find.text('About This Portfolio'), findsOneWidget);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'mac-system-menu');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mac-system-menu-panel')), findsNothing);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'mac-system-menu');

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mac-system-menu-panel')), findsOneWidget);

      await tester.tap(find.byKey(const Key('system-menu-about')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mac-system-menu-panel')), findsNothing);
      expect(find.byKey(const Key('mac-window-about')), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('shows desktop menu labels, status controls, and Dock apps', (
      tester,
    ) async {
      await _pumpPortfolio(tester);

      for (final label in const <String>[
        'Finder',
        'File',
        'Edit',
        'View',
        'Window',
        'Help',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byKey(const Key('mac-wifi-status')), findsOneWidget);
      expect(find.byKey(const Key('mac-battery-status')), findsOneWidget);
      expect(
        find.byKey(const Key('mac-control-center-button')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('mac-clock-button')), findsOneWidget);

      for (final appId in PortfolioAppId.values) {
        expect(find.byKey(Key('dock-app-${appId.name}')), findsOneWidget);
      }
    });

    testWidgets('toggles exclusive system panels and dismisses them', (
      tester,
    ) async {
      await _pumpPortfolio(tester);

      await tester.tap(find.byKey(const Key('mac-control-center-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mac-control-center-panel')), findsOneWidget);

      await tester.tap(find.byKey(const Key('mac-clock-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mac-control-center-panel')), findsNothing);
      expect(find.byKey(const Key('mac-notifications-panel')), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mac-notifications-panel')), findsNothing);

      await tester.tap(find.byKey(const Key('mac-control-center-button')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(200, 300));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mac-control-center-panel')), findsNothing);
    });

    testWidgets('Dock restores minimized apps with Enter and Space', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpPortfolio(tester);
      await _openDesktopApp(tester, PortfolioAppId.skills);
      await tester.tap(find.byKey(const Key('window-minimize-skills')));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Open or restore Skills'), findsOneWidget);
      await _focusDockApp(tester, PortfolioAppId.skills);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mac-window-skills')), findsOneWidget);
      expect(find.byKey(const Key('mac-window-active-skills')), findsOneWidget);

      await tester.tap(find.byKey(const Key('window-minimize-skills')));
      await tester.pumpAndSettle();
      await _focusDockApp(tester, PortfolioAppId.skills);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mac-window-skills')), findsOneWidget);
      expect(find.byKey(const Key('mac-window-active-skills')), findsOneWidget);
      semantics.dispose();
    });
  });

  testWidgets(
    'avoids overflow and forbidden reference identity at desktop sizes',
    (tester) async {
      for (final size in const <Size>[Size(1024, 700), Size(1440, 900)]) {
        await _pumpPortfolio(tester, size: size);
        await _openDesktopApp(tester, PortfolioAppId.projects);

        final visibleText = tester
            .widgetList<Text>(find.byType(Text))
            .map((widget) => widget.data ?? '')
            .join('\n')
            .toLowerCase();
        expect(visibleText, isNot(contains('천주아')));
        expect(visibleText, isNot(contains('juah')));
        expect(visibleText, isNot(contains('portfolio-juah')));
        expect(tester.takeException(), isNull, reason: '$size');
      }
    },
  );
}

const Map<PortfolioAppId, String> _labels = <PortfolioAppId, String>{
  PortfolioAppId.about: 'About',
  PortfolioAppId.skills: 'Skills',
  PortfolioAppId.projects: 'Projects',
  PortfolioAppId.terminal: 'Terminal',
  PortfolioAppId.settings: 'Settings',
  PortfolioAppId.thisMac: 'This Mac',
  PortfolioAppId.github: 'GitHub',
  PortfolioAppId.mail: 'Mail',
  PortfolioAppId.trash: 'Trash',
};

const PortfolioData _customPortfolioData = PortfolioData.constant(
  identity: PortfolioIdentity(
    name: '커스텀 개발자',
    englishName: 'Custom Developer',
    email: 'custom@example.com',
    githubUrl: 'https://example.com/custom',
    headline: 'Custom Headline',
    biography: 'Custom Biography',
  ),
  experiences: <PortfolioExperience>[],
  education: <PortfolioEducation>[],
  skillGroups: <PortfolioSkillGroup>[],
  projects: <PortfolioProject>[],
);

Future<void> _pumpPortfolio(
  WidgetTester tester, {
  Size size = const Size(1440, 900),
  ExternalLauncher? launcher,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    PortfolioApp(externalLauncher: launcher ?? _FakeLauncher()),
  );
  await tester.pump();
}

Future<void> _pumpAdaptivePortfolio(
  WidgetTester tester, {
  required PortfolioData data,
  Size size = const Size(1440, 900),
}) async {
  final themeController = PortfolioThemeController();
  addTearDown(themeController.dispose);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.light(),
      home: AdaptivePortfolioShell(
        externalLauncher: _FakeLauncher(),
        data: data,
        themeController: themeController,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _doubleClick(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _openDesktopApp(WidgetTester tester, PortfolioAppId appId) async {
  await _doubleClick(tester, find.byKey(Key('desktop-app-${appId.name}')));
  expect(find.byKey(Key('mac-window-${appId.name}')), findsOneWidget);
}

Future<void> _focusDockApp(WidgetTester tester, PortfolioAppId appId) async {
  final focusable = tester.widget<FocusableActionDetector>(
    find.descendant(
      of: find.byKey(Key('dock-app-${appId.name}')),
      matching: find.byType(FocusableActionDetector),
    ),
  );
  focusable.focusNode!.requestFocus();
  await tester.pump();
  expect(focusable.focusNode!.hasFocus, isTrue);
}

class _FakeLauncher implements ExternalLauncher {
  final List<Uri> launched = <Uri>[];

  @override
  Future<bool> launch(Uri uri) async {
    launched.add(uri);
    return true;
  }
}
