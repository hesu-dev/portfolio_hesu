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
import 'package:portfolio_hesu/portfolio/widgets/apple_app_artwork.dart';
import 'package:portfolio_hesu/portfolio/widgets/apple_app_icon.dart';

void main() {
  group('Apple app artwork', () {
    testWidgets(
      'renders bespoke code-native artwork for primary apps and Trash',
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

    testWidgets(
      'renders Projects as a large folder silhouette on a transparent canvas',
      (tester) async {
        await _pumpArtwork(tester, PortfolioAppId.projects);

        final artwork = find.byKey(const Key('apple-app-artwork-projects'));
        expect(
          find.descendant(of: artwork, matching: find.byType(DecoratedBox)),
          findsNothing,
        );
        expect(
          find.descendant(of: artwork, matching: find.byType(ClipRRect)),
          findsNothing,
        );

        final expandedSilhouette = tester.widget<Transform>(
          find.byKey(const Key('apple-app-artwork-projects-silhouette')),
        );
        expect(
          expandedSilhouette.transform.getMaxScaleOnAxis(),
          greaterThanOrEqualTo(1.16),
        );
      },
    );

    testWidgets('uses a white rounded-square tile for Skills', (tester) async {
      await _pumpArtwork(tester, PortfolioAppId.skills);

      final decoration = _artworkDecoration(tester, PortfolioAppId.skills);
      final gradient = decoration.gradient! as LinearGradient;
      expect(
        gradient.colors.every((color) => color.computeLuminance() > 0.85),
        isTrue,
      );
      expect(decoration.border, isNotNull);
    });

    testWidgets(
      'draws Trash as a transparent code-native bin with colorful contents',
      (tester) async {
        await _pumpArtwork(tester, PortfolioAppId.trash);

        final artwork = find.byKey(const Key('apple-app-artwork-trash'));
        expect(
          find.descendant(of: artwork, matching: find.byType(DecoratedBox)),
          findsNothing,
        );
        expect(
          find.descendant(of: artwork, matching: find.byType(ClipRRect)),
          findsNothing,
        );
        expect(
          find.descendant(of: artwork, matching: find.byType(CustomPaint)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: artwork, matching: find.byType(Icon)),
          findsNothing,
        );

        final palette = AppleAppArtwork.colorsFor(PortfolioAppId.trash);
        expect(palette.length, greaterThanOrEqualTo(4));
        expect(
          palette.map((color) => color.toARGB32()).toSet().length,
          greaterThanOrEqualTo(4),
          reason: 'Trash contents should retain four distinct colors.',
        );
      },
    );

    testWidgets('extends the Terminal screen to the icon edges', (
      tester,
    ) async {
      await _pumpArtwork(tester, PortfolioAppId.terminal);

      final artwork = find.byKey(const Key('apple-app-artwork-terminal'));
      final screen = find.byKey(const Key('apple-app-artwork-terminal-screen'));
      expect(screen, findsOneWidget);
      expect(tester.getSize(screen), tester.getSize(artwork));
      expect(tester.widget<ColoredBox>(screen).color, const Color(0xFF0B0D11));
    });

    testWidgets('keeps the Projects desktop launcher wrapper transparent', (
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

      final frame = find.byKey(const Key('desktop-app-artwork-frame-projects'));
      expect(frame, findsOneWidget);
      final decoration =
          tester.widget<Container>(frame).decoration! as BoxDecoration;
      expect(decoration.color, isNull);
      expect(decoration.gradient, isNull);
      expect(decoration.border, isNull);
      expect(decoration.boxShadow, isEmpty);
    });

    testWidgets('does not add a square shadow behind Projects app artwork', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppleTheme.light(),
          home: Material(
            child: Center(
              child: AppleAppIcon(
                appId: PortfolioAppId.projects,
                showLabel: false,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      final tile = find.byKey(const Key('apple-app-icon-tile-projects'));
      final sharedFrame = find.descendant(
        of: tile,
        matching: find.byType(AppleAppArtworkFrame),
      );
      expect(sharedFrame, findsOneWidget);
      final frameContainer = find.descendant(
        of: sharedFrame,
        matching: find.byType(Container),
      );
      final decoration =
          tester.widget<Container>(frameContainer.first).decoration!
              as BoxDecoration;
      expect(decoration.boxShadow, isEmpty);
    });

    testWidgets('keeps About and Mail on their existing framed tiles', (
      tester,
    ) async {
      for (final appId in const <PortfolioAppId>[
        PortfolioAppId.about,
        PortfolioAppId.mail,
      ]) {
        await _pumpArtwork(tester, appId);
        final decoration = _artworkDecoration(tester, appId);
        expect(decoration.gradient, isNotNull, reason: appId.name);
        expect(decoration.border, isNotNull, reason: appId.name);
      }
    });

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

      expect(find.byKey(const Key('apple-app-artwork-about')), findsOneWidget);

      final desktopAbout = find.byKey(const Key('desktop-app-about'));
      await tester.tap(desktopAbout);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(desktopAbout);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mac-window-about')), findsOneWidget);
      expect(
        find.byKey(const Key('apple-app-artwork-about')),
        findsNWidgets(3),
      );
    });

    testWidgets(
      'keeps app artwork on iPhone home and removes it from app chrome',
      (tester) async {
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
        expect(
          find.byKey(const Key('mac-traffic-controls-about')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('mobile-home-back')), findsNothing);
        expect(find.byKey(const Key('apple-app-artwork-about')), findsNothing);
      },
    );
  });
}

const List<PortfolioAppId> _bespokeApps = <PortfolioAppId>[
  PortfolioAppId.about,
  PortfolioAppId.skills,
  PortfolioAppId.projects,
  PortfolioAppId.terminal,
  PortfolioAppId.mail,
  PortfolioAppId.settings,
  PortfolioAppId.trash,
];

const List<PortfolioAppId> _utilityApps = <PortfolioAppId>[
  PortfolioAppId.thisMac,
  PortfolioAppId.github,
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

Future<void> _pumpArtwork(WidgetTester tester, PortfolioAppId appId) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.light(),
      home: Center(
        child: RepaintBoundary(
          key: Key('artwork-capture-${appId.name}'),
          child: AppleAppArtwork(appId: appId, size: 72),
        ),
      ),
    ),
  );
}

BoxDecoration _artworkDecoration(WidgetTester tester, PortfolioAppId appId) {
  final artwork = find.byKey(Key('apple-app-artwork-${appId.name}'));
  final decoratedBox = find.descendant(
    of: artwork,
    matching: find.byType(DecoratedBox),
  );
  return tester.widget<DecoratedBox>(decoratedBox.first).decoration
      as BoxDecoration;
}
