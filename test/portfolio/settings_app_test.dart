import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/settings_app.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';
import 'package:portfolio_hesu/portfolio/portfolio_app.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/theme/portfolio_theme_controller.dart';

void main() {
  group('Settings 화면 모드', () {
    testWidgets('넓은 화면은 단일 사이드바와 두 개의 미리보기를 보여준다', (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = PortfolioThemeController();
      addTearDown(controller.dispose);

      await _pumpSettings(
        tester,
        controller: controller,
        size: const Size(820, 620),
      );

      expect(find.byKey(const Key('settings-app')), findsOneWidget);
      expect(find.byKey(const Key('settings-sidebar')), findsOneWidget);
      expect(find.byKey(const Key('settings-display-mode')), findsOneWidget);
      expect(find.text('화면 모드'), findsWidgets);
      expect(find.text('라이트'), findsOneWidget);
      expect(find.text('다크'), findsOneWidget);
      expect(_visibleText(tester), isNot(contains('자동')));
      expect(_visibleText(tester), isNot(contains('Auto')));
      expect(_visibleText(tester), isNot(contains('System')));

      for (final key in const <Key>[Key('theme-light'), Key('theme-dark')]) {
        expect(
          tester.getSize(find.byKey(key)).height,
          greaterThanOrEqualTo(44),
        );
        final data = tester.getSemantics(find.byKey(key)).getSemanticsData();
        expect(data.flagsCollection.isButton, isTrue);
      }
      expect(
        tester
            .getSemantics(find.byKey(const Key('theme-light')))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        ui.Tristate.isTrue,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets('Mac 화면 모드 선택 영역은 절반 폭으로 줄여 가운데 정렬한다', (tester) async {
      final controller = PortfolioThemeController();
      addTearDown(controller.dispose);

      await _pumpSettings(
        tester,
        controller: controller,
        size: const Size(820, 620),
      );

      final content = tester.getRect(
        find.byKey(const Key('settings-display-mode')),
      );
      final light = tester.getRect(find.byKey(const Key('theme-light')));
      final dark = tester.getRect(find.byKey(const Key('theme-dark')));
      final choicesWidth = dark.right - light.left;
      final choicesCenter = (light.left + dark.right) / 2;

      expect(choicesWidth, closeTo(content.width * 0.5, 1));
      expect(choicesCenter, closeTo(content.center.dx, 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('iPhone과 iPad는 사이드바 없이 프로필과 화면 모드를 보여준다', (tester) async {
      for (final scenario in const <({Size size, bool compact, bool tablet})>[
        (size: Size(390, 844), compact: true, tablet: false),
        (size: Size(834, 1194), compact: false, tablet: true),
      ]) {
        final controller = PortfolioThemeController();

        await _pumpSettings(
          tester,
          controller: controller,
          size: scenario.size,
          compact: scenario.compact,
          tablet: scenario.tablet,
        );

        expect(find.byKey(const Key('settings-sidebar')), findsNothing);
        final profile = find.byKey(const Key('settings-profile'));
        final displayMode = find.byKey(const Key('settings-display-mode'));
        expect(profile, findsOneWidget);
        expect(displayMode, findsOneWidget);
        expect(
          tester.getTopLeft(profile).dy,
          lessThan(tester.getTopLeft(displayMode).dy),
        );
        expect(tester.takeException(), isNull, reason: '${scenario.size}');

        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
      }
    });

    testWidgets('선택하면 앱 전체 테마와 선택 상태를 즉시 바꾼다', (tester) async {
      final controller = PortfolioThemeController();
      addTearDown(controller.dispose);
      await _pumpSettings(
        tester,
        controller: controller,
        size: const Size(820, 620),
      );

      expect(controller.preference, PortfolioThemePreference.light);
      expect(
        Theme.of(
          tester.element(find.byKey(const Key('settings-app'))),
        ).brightness,
        Brightness.light,
      );

      await tester.tap(find.byKey(const Key('theme-dark')));
      await tester.pumpAndSettle();

      expect(controller.preference, PortfolioThemePreference.dark);
      expect(
        Theme.of(
          tester.element(find.byKey(const Key('settings-app'))),
        ).brightness,
        Brightness.dark,
      );
      expect(find.byKey(const Key('theme-selected-dark')), findsOneWidget);

      await tester.tap(find.byKey(const Key('theme-light')));
      await tester.pumpAndSettle();

      expect(controller.preference, PortfolioThemePreference.light);
      expect(find.byKey(const Key('theme-selected-light')), findsOneWidget);
    });

    testWidgets('Enter와 Space 및 포커스 링으로 두 선택지를 조작한다', (tester) async {
      final controller = PortfolioThemeController();
      addTearDown(controller.dispose);
      await _pumpSettings(
        tester,
        controller: controller,
        size: const Size(820, 620),
      );

      final darkAction = tester.widget<FocusableActionDetector>(
        find.descendant(
          of: find.byKey(const Key('theme-dark')),
          matching: find.byType(FocusableActionDetector),
        ),
      );
      darkAction.focusNode!.requestFocus();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('theme-focus-dark')), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(controller.preference, PortfolioThemePreference.dark);

      final lightAction = tester.widget<FocusableActionDetector>(
        find.descendant(
          of: find.byKey(const Key('theme-light')),
          matching: find.byType(FocusableActionDetector),
        ),
      );
      lightAction.focusNode!.requestFocus();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('theme-focus-light')), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(controller.preference, PortfolioThemePreference.light);
    });

    testWidgets('선택·비선택 카드의 설명과 포커스 링은 두 테마에서 대비를 충족한다', (tester) async {
      for (final preference in PortfolioThemePreference.values) {
        final controller = PortfolioThemeController(initial: preference);
        addTearDown(controller.dispose);
        await _pumpSettings(
          tester,
          controller: controller,
          size: const Size(820, 620),
        );

        for (final choice in const <(String, String)>[
          ('light', '밝고 선명한 화면'),
          ('dark', '눈이 편안한 어두운 화면'),
        ]) {
          final choiceKey = Key('theme-${choice.$1}');
          final background = _choiceDecoration(tester, choiceKey).color!;
          final description = tester
              .widgetList<Text>(
                find.descendant(
                  of: find.byKey(choiceKey),
                  matching: find.byType(Text),
                ),
              )
              .singleWhere((text) => text.data == choice.$2)
              .style!
              .color!;

          expect(
            _contrastRatio(description, background),
            greaterThanOrEqualTo(4.5),
            reason: '${preference.name}/${choice.$1} 설명 텍스트와 카드 배경',
          );

          final action = tester.widget<FocusableActionDetector>(
            find.descendant(
              of: find.byKey(choiceKey),
              matching: find.byType(FocusableActionDetector),
            ),
          );
          action.focusNode!.requestFocus();
          await tester.pumpAndSettle();

          final focusedDecoration = _choiceDecoration(tester, choiceKey);
          final focusColor = focusedDecoration.border!.top.color;
          expect(
            _contrastRatio(focusColor, focusedDecoration.color!),
            greaterThanOrEqualTo(3),
            reason: '${preference.name}/${choice.$1} 포커스 링과 카드 배경',
          );
        }
      }
    });

    testWidgets('iPhone은 세로형, iPad는 4:3 화면 모드 미리보기를 사용한다', (tester) async {
      final phoneController = PortfolioThemeController();
      await _pumpSettings(
        tester,
        controller: phoneController,
        size: const Size(390, 844),
        compact: true,
      );

      final phonePreview = tester.getSize(
        find.byKey(const Key('theme-preview-light')),
      );
      expect(phonePreview.aspectRatio, closeTo(0.64, 0.01));
      expect(phonePreview.width, lessThanOrEqualTo(160));

      await tester.pumpWidget(const SizedBox.shrink());
      phoneController.dispose();

      final tabletController = PortfolioThemeController();
      await _pumpSettings(
        tester,
        controller: tabletController,
        size: const Size(834, 1194),
        tablet: true,
      );

      final tabletPreview = tester.getSize(
        find.byKey(const Key('theme-preview-light')),
      );
      expect(tabletPreview.aspectRatio, closeTo(4 / 3, 0.01));
      expect(tabletPreview.width, greaterThan(240));
      expect(tabletPreview.width, greaterThan(phonePreview.width));

      await tester.pumpWidget(const SizedBox.shrink());
      tabletController.dispose();
    });

    testWidgets('iPhone과 iPad는 화면 비율 미리보기를 두 열로 맞춘다', (tester) async {
      for (final scenario
          in const <
            ({
              Size size,
              bool compact,
              bool tablet,
              TextScaler textScaler,
              PortfolioThemePreference preference,
            })
          >[
            (
              size: Size(320, 480),
              compact: true,
              tablet: false,
              textScaler: TextScaler.linear(2),
              preference: PortfolioThemePreference.light,
            ),
            (
              size: Size(320, 480),
              compact: true,
              tablet: false,
              textScaler: TextScaler.linear(2),
              preference: PortfolioThemePreference.dark,
            ),
            (
              size: Size(834, 700),
              compact: false,
              tablet: true,
              textScaler: TextScaler.noScaling,
              preference: PortfolioThemePreference.light,
            ),
            (
              size: Size(834, 700),
              compact: false,
              tablet: true,
              textScaler: TextScaler.noScaling,
              preference: PortfolioThemePreference.dark,
            ),
          ]) {
        final controller = PortfolioThemeController(
          initial: scenario.preference,
        );

        await _pumpSettings(
          tester,
          controller: controller,
          size: scenario.size,
          compact: scenario.compact,
          tablet: scenario.tablet,
          textScaler: scenario.textScaler,
        );

        expect(
          find.byKey(const Key('settings-mobile-mode-panel')),
          findsOneWidget,
        );
        final light = tester.getRect(find.byKey(const Key('theme-light')));
        final dark = tester.getRect(find.byKey(const Key('theme-dark')));
        expect(light.left, lessThan(dark.left));
        expect((light.top - dark.top).abs(), lessThan(1));
        expect(light.right, lessThanOrEqualTo(dark.left));

        for (final mode in const <String>['light', 'dark']) {
          final preview = tester.getSize(
            find.byKey(Key('theme-preview-$mode')),
          );
          if (scenario.tablet) {
            expect(preview.aspectRatio, closeTo(4 / 3, 0.01));
            expect(preview.width, greaterThan(240));
          } else {
            expect(preview.aspectRatio, closeTo(0.64, 0.01));
            expect(preview.width, lessThanOrEqualTo(160));
          }
        }

        expect(
          find.byKey(Key('theme-selected-${scenario.preference.name}')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('settings-scroll')), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '${scenario.size}');

        await tester.drag(
          find.byKey(const Key('settings-scroll')),
          const Offset(0, -180),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '${scenario.size}');

        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
      }
    });
  });

  group('Settings 셸 연결', () {
    testWidgets('Mac, iPad, iPhone에서 실행되고 현재 화면을 유지한다', (tester) async {
      for (final scenario in <(Size, String, String)>[
        (const Size(1440, 900), 'desktop-app-settings', 'mac-window-settings'),
        (const Size(834, 1194), 'home-app-settings', 'mobile-app-surface'),
        (const Size(390, 844), 'home-app-settings', 'mobile-app-surface'),
      ]) {
        final controller = PortfolioThemeController();
        await _pumpPortfolio(tester, size: scenario.$1, controller: controller);

        final launcher = find.byKey(Key(scenario.$2));
        if (scenario.$1.width >= 1024) {
          await tester.tap(launcher);
          await tester.pump(const Duration(milliseconds: 50));
          await tester.tap(launcher);
        } else {
          await tester.ensureVisible(launcher);
          await tester.tap(launcher);
        }
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('settings-app')), findsOneWidget);
        expect(find.byKey(Key(scenario.$3)), findsOneWidget);
        if (scenario.$1.width >= 1024) {
          expect(find.byKey(const Key('settings-sidebar')), findsOneWidget);
          expect(
            find.byKey(const Key('settings-mobile-mode-panel')),
            findsNothing,
          );
        } else {
          expect(find.byKey(const Key('settings-sidebar')), findsNothing);
          expect(
            find.byKey(const Key('settings-mobile-mode-panel')),
            findsOneWidget,
          );
        }
        await tester.tap(find.byKey(const Key('theme-dark')));
        await tester.pumpAndSettle();

        expect(controller.preference, PortfolioThemePreference.dark);
        expect(
          tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
          ThemeMode.dark,
        );
        expect(find.byKey(const Key('settings-app')), findsOneWidget);
        expect(find.byKey(Key(scenario.$3)), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '${scenario.$1}');

        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
      }
    });

    testWidgets('Mac의 실행 중인 터미널 상태를 테마 변경 뒤에도 보존한다', (tester) async {
      final controller = PortfolioThemeController();
      addTearDown(controller.dispose);
      await _pumpPortfolio(
        tester,
        size: const Size(1440, 900),
        controller: controller,
      );

      await _openDesktopApp(tester, PortfolioAppId.terminal);
      await tester.enterText(find.byKey(const Key('terminal-input')), 'help');
      await tester.tap(find.byKey(const Key('terminal-submit')));
      await tester.pumpAndSettle();
      expect(find.text('hs0647@portfolio ~ % help'), findsOneWidget);

      await _openDesktopApp(tester, PortfolioAppId.settings);
      await tester.tap(find.byKey(const Key('theme-dark')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mac-window-terminal')), findsOneWidget);
      expect(find.byKey(const Key('mac-window-settings')), findsOneWidget);
      expect(find.text('hs0647@portfolio ~ % help'), findsOneWidget);
      expect(controller.preference, PortfolioThemePreference.dark);
    });

    testWidgets('Mac 설정 창은 화면 모드 카드에 맞는 초기 크기로 열린다', (tester) async {
      final controller = PortfolioThemeController();
      addTearDown(controller.dispose);
      await _pumpPortfolio(
        tester,
        size: const Size(1440, 900),
        controller: controller,
      );

      await _openDesktopApp(tester, PortfolioAppId.settings);

      final size = tester.getSize(find.byKey(const Key('mac-window-settings')));
      expect(size.width, inInclusiveRange(680, 820));
      expect(size.height, inInclusiveRange(480, 600));
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _pumpSettings(
  WidgetTester tester, {
  required PortfolioThemeController controller,
  required Size size,
  bool compact = false,
  bool tablet = false,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    AnimatedBuilder(
      animation: controller,
      builder: (context, _) => MaterialApp(
        theme: AppleTheme.light(),
        darkTheme: AppleTheme.dark(),
        themeMode: controller.themeMode,
        home: MediaQuery(
          data: MediaQueryData(size: size, textScaler: textScaler),
          child: SettingsApp(
            data: portfolioData,
            themeController: controller,
            compact: compact,
            tablet: tablet,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpPortfolio(
  WidgetTester tester, {
  required Size size,
  required PortfolioThemeController controller,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    PortfolioApp(
      themeController: controller,
      externalLauncher: CallbackExternalLauncher((_) async => true),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openDesktopApp(WidgetTester tester, PortfolioAppId appId) async {
  final icon = find.byKey(Key('desktop-app-${appId.name}'));
  await tester.tap(icon);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(icon);
  await tester.pumpAndSettle();
}

String _visibleText(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data ?? widget.textSpan?.toPlainText() ?? '')
      .join('\n');
}

BoxDecoration _choiceDecoration(WidgetTester tester, Key key) {
  final containers = tester.widgetList<AnimatedContainer>(
    find.descendant(
      of: find.byKey(key),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return containers.first.decoration! as BoxDecoration;
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
