import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/macos/mac_desktop.dart';
import 'package:portfolio_hesu/portfolio/mobile/apple_mobile_shell.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/theme/portfolio_theme_controller.dart';
import 'package:portfolio_hesu/portfolio/widgets/apple_app_icon.dart';

void main() {
  group('Apple app artwork', () {
    testWidgets(
      'renders bespoke code-native artwork for the six primary apps',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppleTheme.light(),
            home: Material(
              child: Wrap(
                children: <Widget>[
                  for (final appId in _bespokeApps)
                    AppleAppIcon(appId: appId, showLabel: false, onTap: () {}),
                ],
              ),
            ),
          ),
        );

        for (final appId in _bespokeApps) {
          final artwork = find.byKey(Key('apple-app-artwork-${appId.name}'));
          expect(artwork, findsOneWidget, reason: appId.name);
          expect(
            find.descendant(of: artwork, matching: find.byType(CustomPaint)),
            findsOneWidget,
            reason: '${appId.name} should be painted from Flutter paths',
          );
          expect(
            find.descendant(of: artwork, matching: find.byType(Icon)),
            findsNothing,
            reason: '${appId.name} must not render a generic Material icon',
          );
          expect(
            find.descendant(of: artwork, matching: find.byType(Image)),
            findsNothing,
            reason: '${appId.name} must not render copied bitmap artwork',
          );
        }
      },
    );

    testWidgets('keeps stable artwork wrappers for the existing utility apps', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppleTheme.light(),
          home: Material(
            child: Row(
              children: <Widget>[
                for (final appId in _utilityApps)
                  AppleAppIcon(appId: appId, showLabel: false, onTap: () {}),
              ],
            ),
          ),
        ),
      );

      for (final appId in _utilityApps) {
        final artwork = find.byKey(Key('apple-app-artwork-${appId.name}'));
        expect(artwork, findsOneWidget, reason: appId.name);
        expect(
          find.descendant(of: artwork, matching: find.byType(Icon)),
          findsOneWidget,
          reason: '${appId.name} should preserve its existing icon mapping',
        );
      }
    });

    testWidgets('scales the artwork with its desktop and mobile tile', (
      tester,
    ) async {
      for (final size in const <double>[48, 72]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppleTheme.light(),
            home: Material(
              child: Center(
                child: AppleAppIcon(
                  appId: PortfolioAppId.projects,
                  size: size,
                  showLabel: false,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );

        expect(
          tester.getSize(find.byKey(const Key('apple-app-artwork-projects'))),
          Size.square(size),
          reason: 'artwork should fill a $size logical-pixel tile',
        );
      }
    });

    testWidgets('leaves one labelled button semantic and keyboard behavior', (
      tester,
    ) async {
      var activations = 0;
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppleTheme.light(),
          home: Material(
            child: Center(
              child: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                child: AppleAppIcon(
                  appId: PortfolioAppId.about,
                  compact: true,
                  onTap: () => activations++,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Open About'), findsOneWidget);
      final semanticsNode = tester.getSemantics(
        find.byKey(const Key('apple-app-icon-about')),
      );
      final semanticsData = semanticsNode.getSemanticsData();
      expect(semanticsData.label, 'Open About');
      expect(semanticsData.flagsCollection.isButton, isTrue);
      expect(semanticsData.hasAction(SemanticsAction.tap), isTrue);

      final hitTarget = tester.getSize(
        find.byKey(const Key('apple-app-icon-about')),
      );
      expect(hitTarget.width, greaterThanOrEqualTo(44));
      expect(hitTarget.height, greaterThanOrEqualTo(44));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(activations, 2);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets('reuses primary artwork across desktop, Dock, and title bar', (
      tester,
    ) async {
      final themeController = PortfolioThemeController();
      addTearDown(themeController.dispose);
      await _setViewport(tester, const Size(1440, 900));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppleTheme.light(),
          home: MacDesktop(
            data: portfolioData,
            externalLauncher: _FakeLauncher(),
            themeController: themeController,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('apple-app-artwork-about')),
        findsNWidgets(2),
      );

      await tester.tap(find.byKey(const Key('dock-app-about')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mac-window-about')), findsOneWidget);
      expect(
        find.byKey(const Key('apple-app-artwork-about')),
        findsNWidgets(3),
      );
    });

    testWidgets('reuses primary artwork on iPhone home and app chrome', (
      tester,
    ) async {
      final themeController = PortfolioThemeController();
      addTearDown(themeController.dispose);
      await _setViewport(tester, const Size(390, 844));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppleTheme.light(),
          home: AppleMobileShell(
            data: portfolioData,
            externalLauncher: _FakeLauncher(),
            themeController: themeController,
            tablet: false,
            now: _fixedNow,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('apple-app-artwork-about')),
        findsNWidgets(2),
      );

      await tester.tap(find.byKey(const Key('home-app-about')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mobile-app-surface')), findsOneWidget);
      expect(find.byKey(const Key('apple-app-artwork-about')), findsOneWidget);
    });
  });
}

const List<PortfolioAppId> _bespokeApps = <PortfolioAppId>[
  PortfolioAppId.about,
  PortfolioAppId.skills,
  PortfolioAppId.projects,
  PortfolioAppId.terminal,
  PortfolioAppId.mail,
  PortfolioAppId.settings,
];

const List<PortfolioAppId> _utilityApps = <PortfolioAppId>[
  PortfolioAppId.thisMac,
  PortfolioAppId.github,
  PortfolioAppId.trash,
];

DateTime _fixedNow() => DateTime(2026, 9, 3, 10, 9);

Future<void> _setViewport(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

final class _FakeLauncher implements ExternalLauncher {
  @override
  Future<bool> launch(Uri uri) async => true;
}
