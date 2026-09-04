import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/mobile/apple_mobile_shell.dart';
import 'package:portfolio_hesu/portfolio/portfolio_app.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/theme/portfolio_theme_controller.dart';

void main() {
  for (final scenario in const <({Size size, bool tablet, String name})>[
    (size: Size(390, 844), tablet: false, name: 'iPhone'),
    (size: Size(834, 1112), tablet: true, name: 'iPad'),
  ]) {
    testWidgets('${scenario.name} 터미널 진입 시 입력에 포커스한다', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = scenario.size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final themeController = PortfolioThemeController();
      addTearDown(themeController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppleTheme.light(),
          home: AppleMobileShell(
            data: portfolioData,
            externalLauncher: CallbackExternalLauncher((_) async => true),
            themeController: themeController,
            tablet: scenario.tablet,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('home-app-terminal')));
      await tester.pumpAndSettle();

      _expectTerminalInputHasPrimaryFocus(tester);
    });
  }

  testWidgets('macOS 터미널 진입 시 입력에 포커스한다', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      PortfolioApp(
        externalLauncher: CallbackExternalLauncher((_) async => true),
      ),
    );
    await tester.pump();

    final terminalIcon = find.byKey(const Key('desktop-app-terminal'));
    await tester.tap(terminalIcon);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(terminalIcon);
    await tester.pumpAndSettle();

    _expectTerminalInputHasPrimaryFocus(tester);
  });
}

void _expectTerminalInputHasPrimaryFocus(WidgetTester tester) {
  final editable = tester.widget<EditableText>(
    find.descendant(
      of: find.byKey(const Key('terminal-input')),
      matching: find.byType(EditableText),
    ),
  );
  expect(FocusManager.instance.primaryFocus, same(editable.focusNode));
}
