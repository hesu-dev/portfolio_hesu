import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/macos/mac_desktop.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/portfolio_theme_controller.dart';
import 'package:portfolio_hesu/portfolio/widgets/desktop_printer_shortcut.dart';

import 'support/music_test_controller.dart';

void main() {
  testWidgets('desktop exposes a printer without overlapping app launchers', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1024, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final theme = PortfolioThemeController();
    final music = createTestMusicController();
    addTearDown(theme.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MacDesktop(
          data: portfolioData,
          externalLauncher: CallbackExternalLauncher((_) async => true),
          themeController: theme,
          musicController: music,
        ),
      ),
    );
    await tester.pump();

    final printer = find.byKey(const Key('desktop-printer'));
    expect(printer, findsOneWidget);
    expect(find.text('프린터'), findsOneWidget);
    expect(
      tester
          .getRect(printer)
          .overlaps(tester.getRect(find.byKey(const Key('mac-desktop-icons')))),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('one click opens the viewer using the current portfolio data', (
    tester,
  ) async {
    final documents = <PortfolioData>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: DesktopPrinterShortcut(
            data: portfolioData,
            openDocument: (data) {
              documents.add(data);
              return true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('desktop-printer')));
    expect(documents, hasLength(1));
    expect(documents.single, same(portfolioData));
  });

  testWidgets('printer can be activated with Enter and Space', (tester) async {
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: DesktopPrinterShortcut(
            data: portfolioData,
            openDocument: (_) {
              opened++;
              return true;
            },
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(opened, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(opened, 2);
  });

  testWidgets('failed opening offers feedback and leaves the printer usable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: DesktopPrinterShortcut(
            data: portfolioData,
            openDocument: (_) => false,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('desktop-printer')));
    await tester.pumpAndSettle();
    expect(find.text('인쇄 화면을 열지 못했어요'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byKey(const Key('desktop-printer')), findsOneWidget);
  });
}
