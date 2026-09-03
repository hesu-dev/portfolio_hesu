import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/settings_app.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/theme/portfolio_theme_controller.dart';

void main() {
  group('설정 프로필과 화면 모드 메뉴', () {
    testWidgets('중복 소개 toolbar를 없애고 프로필을 화면 모드 위에 둔다', (tester) async {
      await _pumpSettings(tester, size: const Size(820, 620));

      expect(find.byType(AppleToolbar), findsNothing);
      expect(find.text('포트폴리오 화면의 표시 방식을 선택합니다'), findsNothing);

      final profile = find.byKey(const Key('settings-profile'));
      final displayMode = find.byKey(
        const Key('settings-display-mode-menu-item'),
      );
      expect(profile, findsOneWidget);
      expect(displayMode, findsOneWidget);
      expect(find.text('he-su min'), findsOneWidget);
      expect(find.text('Apple 계정'), findsOneWidget);
      expect(
        tester.getTopLeft(profile).dy,
        lessThan(tester.getTopLeft(displayMode).dy),
      );
      expect(
        find.descendant(
          of: displayMode,
          matching: find.byKey(const Key('settings-display-mode-svg')),
        ),
        findsOneWidget,
      );
    });

    testWidgets('iPhone 크기에서도 프로필 뒤에 화면 모드를 한 열로 표시한다', (tester) async {
      await _pumpSettings(
        tester,
        size: const Size(320, 480),
        compact: true,
        textScaler: const TextScaler.linear(2),
      );

      final profile = find.byKey(const Key('settings-profile'));
      final displayMode = find.byKey(const Key('settings-display-mode'));
      expect(profile, findsOneWidget);
      expect(displayMode, findsOneWidget);
      expect(
        tester.getTopLeft(profile).dy,
        lessThan(tester.getTopLeft(displayMode).dy),
      );
      expect(find.byKey(const Key('settings-scroll')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('새 화면 모드 SVG는 로컬 벡터 도형만 사용한다', () {
      final icon = File('assets/icons/settings-display-mode.svg');
      expect(icon.existsSync(), isTrue);

      final source = icon.readAsStringSync();
      expect(source, contains('<svg'));
      expect(source, contains('<linearGradient'));
      expect(source, contains('<circle'));
      expect(source, isNot(contains('<image')));
      expect(source, isNot(matches(RegExp(r'\s(?:xlink:)?href\s*='))));
      expect(source, isNot(matches(RegExp(r'url\(\s*https?://'))));
    });
  });
}

Future<void> _pumpSettings(
  WidgetTester tester, {
  required Size size,
  bool compact = false,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final controller = PortfolioThemeController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(size: size, textScaler: textScaler),
        child: SettingsApp(
          data: portfolioData,
          themeController: controller,
          compact: compact,
        ),
      ),
    ),
  );
  await tester.pump();
}
