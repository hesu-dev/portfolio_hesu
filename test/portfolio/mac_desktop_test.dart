import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/portfolio_app_content.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/macos/mac_desktop.dart';
import 'package:portfolio_hesu/portfolio/macos/mac_dock.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';
import 'package:portfolio_hesu/portfolio/portfolio_app.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/theme/portfolio_theme_controller.dart';
import 'package:portfolio_hesu/portfolio/widgets/adaptive_portfolio_shell.dart';
import 'package:portfolio_hesu/portfolio/widgets/apple_app_artwork.dart';

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
      final selection = tester.widget<AnimatedContainer>(
        find.byKey(const Key('desktop-app-selection-about')),
      );
      expect(
        (selection.decoration! as BoxDecoration).color,
        Colors.white.withValues(alpha: 0.2),
      );
      expect(
        find.byKey(const Key('desktop-app-artwork-selection-about')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('desktop-app-label-selection-about')),
        findsNothing,
      );
      expect(find.byKey(const Key('mac-window-about')), findsNothing);

      await _doubleClick(tester, about);

      expect(find.byKey(const Key('mac-window-about')), findsOneWidget);
      expect(find.byKey(const Key('mac-window-active-about')), findsOneWidget);
    });

    testWidgets('Projects 선택은 artwork를 바꾸지 않고 아이콘 주변과 이름만 중립 회색으로 표시한다', (
      tester,
    ) async {
      final previousHighlightStrategy = FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () =>
            FocusManager.instance.highlightStrategy = previousHighlightStrategy,
      );

      for (final scenario in const <({Brightness brightness, Size size})>[
        (brightness: Brightness.light, size: Size(1280, 720)),
        (brightness: Brightness.dark, size: Size(1440, 900)),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpThemedDesktop(
          tester,
          brightness: scenario.brightness,
          size: scenario.size,
        );

        const appId = PortfolioAppId.projects;
        final launcher = find.byKey(const Key('desktop-app-projects'));
        final beforeArtwork = _desktopArtworkSignature(tester, appId);

        await tester.tap(launcher);
        await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 20));

        expect(_desktopArtworkSignature(tester, appId), beforeArtwork);
        expect(
          find.byKey(const Key('desktop-app-selection-projects')),
          findsOneWidget,
        );

        for (final key in const <Key>[
          Key('desktop-app-artwork-selection-projects'),
          Key('desktop-app-label-selection-projects'),
          Key('desktop-app-focus-projects'),
        ]) {
          expect(find.byKey(key), findsOneWidget, reason: '$key $scenario');
        }

        final artworkSelection = _desktopSelectionDecoration(
          tester,
          const Key('desktop-app-artwork-selection-projects'),
        );
        final labelSelection = _desktopSelectionDecoration(
          tester,
          const Key('desktop-app-label-selection-projects'),
        );
        for (final decoration in <BoxDecoration>[
          artworkSelection,
          labelSelection,
        ]) {
          expect(decoration.color, isNotNull);
          expect(decoration.color, isNot(Colors.transparent));
          expect(_isNeutralGray(decoration.color!), isTrue);
          expect(decoration.color, isNot(AppleTheme.blue));
          expect(decoration.border, isNull);
        }

        final focusDecoration = _desktopSelectionDecoration(
          tester,
          const Key('desktop-app-focus-projects'),
        );
        expect(focusDecoration.border, isNotNull);
        expect(
          _isNeutralGray((focusDecoration.border! as Border).top.color),
          isTrue,
        );

        final semantics = tester.getSemantics(launcher).getSemanticsData();
        expect(semantics.flagsCollection.isSelected, ui.Tristate.isTrue);
        expect(semantics.flagsCollection.isButton, isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('mac-window-projects')), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$scenario');
      }
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
      expect(find.byKey(const Key('dock-app-about')), findsNothing);
      expect(find.byKey(const Key('dock-running-about')), findsNothing);
    });

    testWidgets('traffic lights expose larger pointer and semantics targets', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpPortfolio(tester);
      await _openDesktopApp(tester, PortfolioAppId.about);

      expect(
        find.byKey(const Key('mac-traffic-controls-about')),
        findsOneWidget,
      );

      const colors = <String, Color>{
        'close': Color(0xFFFF5F57),
        'minimize': Color(0xFFFEBC2E),
        'maximize': Color(0xFF28C840),
      };

      for (final control in const <String>['close', 'minimize', 'maximize']) {
        final target = find.byKey(Key('window-$control-about'));
        final visual = find.byKey(Key('window-$control-about-visual'));
        final targetSize = tester.getSize(target);
        final semanticsSize = tester.getSemantics(target).rect.size;
        final circle = tester.widget<Container>(visual);
        final decoration = circle.decoration! as BoxDecoration;

        expect(targetSize.width, inInclusiveRange(32, 44));
        expect(targetSize.height, inInclusiveRange(32, 44));
        expect(semanticsSize.width, inInclusiveRange(32, 44));
        expect(semanticsSize.height, inInclusiveRange(32, 44));
        expect(tester.getSize(visual).width, inInclusiveRange(13, 14));
        expect(tester.getSize(visual).height, inInclusiveRange(13, 14));
        expect(decoration.color, colors[control]);
        expect(circle.child, isNull, reason: '$control must not show a mark');
        expect(
          find.descendant(of: visual, matching: find.byType(Icon)),
          findsNothing,
        );
        expect(
          find.byTooltip(
            '${control == 'close'
                ? 'Close'
                : control == 'minimize'
                ? 'Minimize'
                : 'Maximize'} About window',
          ),
          findsOneWidget,
        );
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

    testWidgets('traffic lights retain keyboard focus and callbacks', (
      tester,
    ) async {
      await _pumpPortfolio(tester);
      await _openDesktopApp(tester, PortfolioAppId.about);

      await _focusWindowControl(tester, 'minimize', PortfolioAppId.about);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mac-window-about')), findsNothing);

      await tester.tap(find.byKey(const Key('dock-app-about')));
      await tester.pumpAndSettle();
      await _focusWindowControl(tester, 'maximize', PortfolioAppId.about);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Restore About window'), findsOneWidget);

      await _focusWindowControl(tester, 'close', PortfolioAppId.about);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mac-window-about')), findsNothing);
    });

    testWidgets(
      'window title bar keeps the app title without duplicate artwork',
      (tester) async {
        await _pumpPortfolio(tester);
        await _openDesktopApp(tester, PortfolioAppId.trash);

        final titleBar = find.byKey(const Key('mac-window-titlebar-trash'));
        expect(titleBar, findsOneWidget);
        expect(
          find.descendant(of: titleBar, matching: find.byType(AppleAppArtwork)),
          findsNothing,
        );
        expect(
          find.descendant(of: titleBar, matching: find.text('Trash')),
          findsOneWidget,
        );
      },
    );

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

    testWidgets('프로젝트 시스템 메뉴는 영문 Projects 창과 Dock 항목 하나만 연다', (tester) async {
      await _pumpPortfolio(tester);

      await tester.tap(find.byKey(const Key('mac-system-menu-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('system-menu-this-mac')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mac-window-projects')), findsOneWidget);
      expect(find.byKey(const Key('dock-app-projects')), findsOneWidget);
      expect(find.byKey(const Key('dock-running-projects')), findsOneWidget);
      expect(find.byKey(const Key('mac-window-thisMac')), findsNothing);
      expect(find.byKey(const Key('dock-app-thisMac')), findsNothing);
    });

    testWidgets('shows desktop chrome and only Trash in Dock initially', (
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

      expect(find.byKey(const Key('dock-app-trash')), findsOneWidget);
      for (final appId in _launchableDockApps) {
        expect(find.byKey(Key('dock-app-${appId.name}')), findsNothing);
        expect(find.byKey(Key('desktop-app-${appId.name}')), findsOneWidget);
      }
    });

    testWidgets('uses a borderless theme-derived translucent Dock surface', (
      tester,
    ) async {
      await _pumpDock(tester, brightness: Brightness.light);
      final dock = find.byKey(const Key('mac-dock'));
      final lightDecoration =
          tester.widget<Container>(dock).decoration! as BoxDecoration;
      final lightColor = lightDecoration.color!;

      expect(lightDecoration.border, isNull);
      expect(lightColor.a, closeTo(0.48, 0.02));
      expect(lightDecoration.boxShadow, isNotEmpty);
      expect(
        find.descendant(of: dock, matching: find.byType(BackdropFilter)),
        findsOneWidget,
      );

      await _pumpDock(tester, brightness: Brightness.dark);
      final darkDecoration =
          tester.widget<Container>(dock).decoration! as BoxDecoration;
      final darkColor = darkDecoration.color!;

      expect(darkDecoration.border, isNull);
      expect(darkColor.a, closeTo(0.48, 0.02));
      expect(darkColor, isNot(lightColor));
    });

    testWidgets(
      'keeps active and inactive running indicators at 3:1 contrast',
      (tester) async {
        for (final brightness in Brightness.values) {
          await _pumpDock(
            tester,
            brightness: brightness,
            runningApps: const <PortfolioAppId>{
              PortfolioAppId.about,
              PortfolioAppId.skills,
            },
            activeApp: PortfolioAppId.about,
          );

          final dock = find.byKey(const Key('mac-dock'));
          final dockDecoration =
              tester.widget<Container>(dock).decoration! as BoxDecoration;
          final theme = Theme.of(tester.element(dock));
          final renderedSurface = Color.alphaBlend(
            dockDecoration.color!,
            theme.canvasColor,
          );
          final ratios = <String, double>{};

          for (final entry in const <String, PortfolioAppId>{
            'active': PortfolioAppId.about,
            'inactive': PortfolioAppId.skills,
          }.entries) {
            final indicator = find.descendant(
              of: find.byKey(Key('dock-running-${entry.value.name}')),
              matching: find.byType(Container),
            );
            final indicatorDecoration =
                tester.widget<Container>(indicator).decoration!
                    as BoxDecoration;
            final renderedIndicator = Color.alphaBlend(
              indicatorDecoration.color!,
              renderedSurface,
            );
            ratios[entry.key] = _contrastRatio(
              renderedIndicator,
              renderedSurface,
            );
          }

          expect(
            ratios.values,
            everyElement(greaterThanOrEqualTo(3)),
            reason: '${brightness.name} rendered ratios: $ratios',
          );
        }
      },
    );

    testWidgets('shows every launchable app only while open or minimized', (
      tester,
    ) async {
      await _pumpPortfolio(tester, size: const Size(1024, 700));

      for (final appId in _launchableDockApps) {
        expect(find.byKey(Key('dock-app-${appId.name}')), findsNothing);

        await _openDesktopApp(tester, appId);
        expect(find.byKey(Key('dock-app-${appId.name}')), findsOneWidget);
        expect(find.byKey(Key('dock-running-${appId.name}')), findsOneWidget);

        await tester.tap(find.byKey(Key('window-minimize-${appId.name}')));
        await tester.pumpAndSettle();
        expect(find.byKey(Key('mac-window-${appId.name}')), findsNothing);
        expect(find.byKey(Key('dock-app-${appId.name}')), findsOneWidget);

        await tester.tap(find.byKey(Key('dock-app-${appId.name}')));
        await tester.pumpAndSettle();
        expect(find.byKey(Key('mac-window-${appId.name}')), findsOneWidget);
        expect(
          find.byKey(Key('mac-window-active-${appId.name}')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(Key('window-close-${appId.name}')));
        await tester.pumpAndSettle();
        expect(find.byKey(Key('dock-app-${appId.name}')), findsNothing);
        expect(find.byKey(Key('desktop-app-${appId.name}')), findsOneWidget);
      }
    });

    testWidgets('keeps running apps in a stable canonical Dock order', (
      tester,
    ) async {
      const runningApps = <PortfolioAppId>{
        PortfolioAppId.github,
        PortfolioAppId.settings,
        PortfolioAppId.terminal,
        PortfolioAppId.about,
      };
      await _pumpDock(
        tester,
        brightness: Brightness.light,
        runningApps: runningApps,
        activeApp: PortfolioAppId.github,
      );

      final centers = <double>[
        for (final appId in _launchableDockApps)
          if (runningApps.contains(appId))
            tester.getCenter(find.byKey(Key('dock-app-${appId.name}'))).dx,
      ];
      expect(centers, orderedEquals(centers.toList()..sort()));
      for (final appId in _launchableDockApps) {
        expect(
          find.byKey(Key('dock-app-${appId.name}')),
          runningApps.contains(appId) ? findsOneWidget : findsNothing,
        );
      }
      expect(find.byKey(const Key('dock-app-trash')), findsOneWidget);
    });

    testWidgets('Terminal content omits duplicate traffic-light circles', (
      tester,
    ) async {
      await _pumpPortfolio(tester);
      await _openDesktopApp(tester, PortfolioAppId.terminal);

      const trafficLightColors = <Color>[
        Color(0xFFFF5F57),
        Color(0xFFFFBD2E),
        Color(0xFF28C840),
      ];
      final fakeTrafficLights = find.descendant(
        of: find.byKey(const Key('terminal-app')),
        matching: find.byWidgetPredicate((widget) {
          if (widget is! Container || widget.decoration is! BoxDecoration) {
            return false;
          }
          final decoration = widget.decoration! as BoxDecoration;
          return decoration.shape == BoxShape.circle &&
              trafficLightColors.contains(decoration.color);
        }, description: 'Terminal traffic-light circle'),
      );

      expect(fakeTrafficLights, findsNothing);
      expect(
        find.byKey(const Key('mac-traffic-controls-terminal')),
        findsOneWidget,
      );
    });

    testWidgets('keeps minimized dynamic apps and restores them from Dock', (
      tester,
    ) async {
      await _pumpPortfolio(tester);
      await _openDesktopApp(tester, PortfolioAppId.settings);

      await tester.tap(find.byKey(const Key('window-minimize-settings')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dock-app-settings')), findsOneWidget);
      expect(find.byKey(const Key('dock-running-settings')), findsOneWidget);
      expect(find.byKey(const Key('mac-window-settings')), findsNothing);

      await _focusDockApp(tester, PortfolioAppId.settings);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mac-window-settings')), findsOneWidget);
      expect(
        find.byKey(const Key('mac-window-active-settings')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('mac-window-settings'), skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('keeps the complete Dock overflow-free at 1024 and 200%', (
      tester,
    ) async {
      await _pumpDock(
        tester,
        brightness: Brightness.light,
        runningApps: _launchableDockApps.toSet(),
        size: const Size(1024, 700),
        textScaler: const TextScaler.linear(2),
      );

      final dockRect = tester.getRect(find.byKey(const Key('mac-dock')));
      expect(dockRect.left, greaterThanOrEqualTo(0));
      expect(dockRect.right, lessThanOrEqualTo(1024));
      expect(tester.takeException(), isNull);
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
  PortfolioAppId.settings: '설정',
  PortfolioAppId.github: 'GitHub',
  PortfolioAppId.mail: 'Mail',
  PortfolioAppId.trash: 'Trash',
};

const List<PortfolioAppId> _launchableDockApps = portfolioDockAppIds;

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
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: size, textScaler: textScaler),
      child: PortfolioApp(externalLauncher: launcher ?? _FakeLauncher()),
    ),
  );
  await tester.pump();
}

Future<void> _pumpThemedDesktop(
  WidgetTester tester, {
  required Brightness brightness,
  required Size size,
}) async {
  final themeController = PortfolioThemeController(
    initial: brightness == Brightness.light
        ? PortfolioThemePreference.light
        : PortfolioThemePreference.dark,
  );
  addTearDown(themeController.dispose);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      theme: brightness == Brightness.light
          ? AppleTheme.light()
          : AppleTheme.dark(),
      home: MacDesktop(
        data: portfolioData,
        externalLauncher: _FakeLauncher(),
        themeController: themeController,
      ),
    ),
  );
  await tester.pump();
}

Map<String, Object?> _desktopArtworkSignature(
  WidgetTester tester,
  PortfolioAppId appId,
) {
  final frameContainer = find.byKey(
    Key('desktop-app-artwork-frame-${appId.name}'),
  );
  final frame = tester.widget<AppleAppArtworkFrame>(
    find.ancestor(
      of: frameContainer,
      matching: find.byType(AppleAppArtworkFrame),
    ),
  );
  final artwork = tester.widget<AppleAppArtwork>(
    find.descendant(of: frameContainer, matching: find.byType(AppleAppArtwork)),
  );
  return <String, Object?>{
    'frameAppId': frame.appId,
    'frameSize': frame.size,
    'artworkAppId': artwork.appId,
    'artworkSize': artwork.size,
  };
}

BoxDecoration _desktopSelectionDecoration(WidgetTester tester, Key key) {
  final widget = tester.widget<AnimatedContainer>(find.byKey(key));
  return widget.decoration! as BoxDecoration;
}

bool _isNeutralGray(Color color) {
  const tolerance = 0.001;
  return (color.r - color.g).abs() <= tolerance &&
      (color.g - color.b).abs() <= tolerance;
}

Future<void> _pumpDock(
  WidgetTester tester, {
  required Brightness brightness,
  Set<PortfolioAppId> runningApps = const <PortfolioAppId>{},
  PortfolioAppId? activeApp,
  Size size = const Size(800, 600),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      theme: brightness == Brightness.light
          ? AppleTheme.light()
          : AppleTheme.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: Material(
        child: Center(
          child: MacDock(
            runningApps: runningApps,
            activeApp: activeApp,
            onAppPressed: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
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

Future<void> _focusWindowControl(
  WidgetTester tester,
  String control,
  PortfolioAppId appId,
) async {
  final focusable = tester.widget<FocusableActionDetector>(
    find.descendant(
      of: find.byKey(Key('window-$control-${appId.name}')),
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
