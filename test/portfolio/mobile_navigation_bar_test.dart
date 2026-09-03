import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/macos/mac_traffic_controls.dart';
import 'package:portfolio_hesu/portfolio/mobile/mobile_app_surface.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/theme/portfolio_theme_controller.dart';
import 'package:portfolio_hesu/portfolio/widgets/apple_app_artwork.dart';

void main() {
  group('mobile app navigation bar', () {
    testWidgets(
      'every non-Projects iPhone app uses one circular back close button',
      (tester) async {
        for (final appId in PortfolioAppId.values.where(
          (appId) => appId != PortfolioAppId.projects,
        )) {
          await tester.pumpWidget(const SizedBox.shrink());
          await _pumpSurface(tester, size: const Size(390, 844), appId: appId);

          final navigationBar = find.byKey(
            const Key('mobile-app-navigation-bar'),
          );
          final title = find.byKey(const Key('mobile-app-title'));
          final close = find.byKey(Key('mobile-back-close-${appId.name}'));

          expect(navigationBar, findsOneWidget);
          expect(find.byType(MacTrafficControls), findsNothing);
          expect(close, findsOneWidget);
          expect(tester.getSize(close), const Size(44, 44));
          expect(
            find.descendant(
              of: close,
              matching: find.byIcon(Icons.arrow_back_ios_new_rounded),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: navigationBar,
              matching: find.byType(AppleAppArtwork),
            ),
            findsNothing,
          );
          expect(tester.widget<Text>(title).textAlign, TextAlign.center);
          expect(
            tester.getCenter(title).dx,
            closeTo(390 / 2, 0.01),
            reason: '${appId.name} title must use the full bar center',
          );
          expect(
            tester.getRect(title).left,
            greaterThanOrEqualTo(tester.getRect(close).right),
          );
          expect(tester.takeException(), isNull, reason: appId.name);
        }
      },
    );

    testWidgets('every non-Projects iPad app keeps the shared traffic lights', (
      tester,
    ) async {
      for (final appId in PortfolioAppId.values.where(
        (appId) => appId != PortfolioAppId.projects,
      )) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpSurface(tester, size: const Size(834, 1194), appId: appId);

        final navigationBar = find.byKey(
          const Key('mobile-app-navigation-bar'),
        );
        final trafficControls = find.descendant(
          of: navigationBar,
          matching: find.byType(MacTrafficControls),
        );
        expect(trafficControls, findsOneWidget);
        expect(tester.widget<MacTrafficControls>(trafficControls).appId, appId);
        expect(
          tester
              .widget<MacTrafficControls>(trafficControls)
              .secondaryControlsInteractive,
          isFalse,
        );
        expect(
          find.byKey(Key('mobile-back-close-${appId.name}')),
          findsNothing,
        );
        expect(tester.takeException(), isNull, reason: appId.name);
      }
    });

    testWidgets(
      'Projects uses one mobile Finder header without traffic lights',
      (tester) async {
        for (final size in const <Size>[Size(390, 844), Size(834, 1194)]) {
          await tester.pumpWidget(const SizedBox.shrink());
          await _pumpSurface(
            tester,
            size: size,
            appId: PortfolioAppId.projects,
          );

          final finderToolbar = find.byKey(
            const Key('projects-finder-toolbar'),
          );
          final currentLocation = find.descendant(
            of: finderToolbar,
            matching: find.byKey(const Key('projects-finder-current-location')),
          );

          expect(
            find.byKey(const Key('mobile-app-navigation-bar')),
            findsNothing,
          );
          expect(find.byKey(const Key('mobile-app-title')), findsNothing);
          expect(finderToolbar, findsOneWidget);
          expect(find.byType(MacTrafficControls), findsNothing);
          expect(
            find.byKey(const Key('mobile-back-close-projects')),
            findsOneWidget,
          );
          expect(find.byKey(const Key('projects-finder-more')), findsOneWidget);
          expect(
            find.byKey(const Key('projects-finder-forward')),
            findsNothing,
          );
          expect(
            find.byKey(const Key('projects-finder-view-options')),
            findsNothing,
          );
          expect(currentLocation, findsOneWidget);
          expect(
            tester.getCenter(currentLocation).dx,
            closeTo(size.width / 2, 1),
          );
          expect(tester.takeException(), isNull, reason: '$size');
        }
      },
    );

    testWidgets('Projects Finder back button closes the surface', (
      tester,
    ) async {
      for (final size in const <Size>[Size(390, 844), Size(834, 1194)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpSurface(tester, size: size, appId: PortfolioAppId.projects);

        final closeButton = find.byKey(const Key('mobile-back-close-projects'));
        expect(closeButton, findsOneWidget);
        expect(tester.getSize(closeButton), const Size(44, 44));
        await tester.tap(closeButton);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('mobile-home')), findsOneWidget);
        expect(find.byKey(const Key('mobile-app-surface')), findsNothing);
      }
    });

    testWidgets(
      'Projects Finder circular control navigates detail then closes at root',
      (tester) async {
        final semantics = tester.ensureSemantics();

        for (final size in const <Size>[Size(390, 844), Size(834, 1194)]) {
          await tester.pumpWidget(const SizedBox.shrink());
          await _pumpSurface(
            tester,
            size: size,
            appId: PortfolioAppId.projects,
          );

          final circularControl = find.byKey(
            const Key('mobile-back-close-projects'),
          );
          expect(
            tester.getSemantics(circularControl).getSemanticsData().label,
            startsWith('Close Projects window'),
            reason: '$size root semantics',
          );
          expect(find.byTooltip('Close Projects window'), findsOneWidget);

          await tester.tap(find.byKey(const Key('projects-career-folder-0')));
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('project-detail-title')), findsOneWidget);
          expect(
            tester.getSemantics(circularControl).getSemanticsData().label,
            startsWith('Back in Projects'),
            reason: '$size detail semantics',
          );
          expect(find.byTooltip('Back in Projects'), findsOneWidget);

          await tester.tap(circularControl);
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('project-detail-title')), findsNothing);
          expect(
            find.byKey(const Key('projects-connection-directory')),
            findsOneWidget,
          );
          expect(find.byKey(const Key('mobile-app-surface')), findsOneWidget);
          expect(
            tester.getSemantics(circularControl).getSemanticsData().label,
            startsWith('Close Projects window'),
            reason: '$size returned root semantics',
          );
          expect(find.byTooltip('Close Projects window'), findsOneWidget);

          await tester.tap(circularControl);
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('mobile-home')), findsOneWidget);
          expect(find.byKey(const Key('mobile-app-surface')), findsNothing);
        }

        semantics.dispose();
      },
    );

    testWidgets('iPhone back button closes the surface and returns home', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpSurface(
        tester,
        size: const Size(390, 844),
        appId: PortfolioAppId.about,
      );

      final closeButton = find.byKey(const Key('mobile-back-close-about'));
      expect(find.bySemanticsLabel('Close About window'), findsOneWidget);
      expect(tester.getSize(closeButton), const Size(44, 44));
      final semanticsData = tester.getSemantics(closeButton).getSemanticsData();
      expect(semanticsData.flagsCollection.isButton, isTrue);
      expect(semanticsData.hasAction(ui.SemanticsAction.tap), isTrue);

      await tester.tap(closeButton);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mobile-home')), findsOneWidget);
      expect(find.byKey(const Key('mobile-app-surface')), findsNothing);
      semantics.dispose();
    });

    testWidgets(
      'iPhone and iPad show the single portfolio zsh terminal title',
      (tester) async {
        for (final size in const <Size>[Size(390, 844), Size(834, 1194)]) {
          await tester.pumpWidget(const SizedBox.shrink());
          await _pumpSurface(
            tester,
            size: size,
            appId: PortfolioAppId.terminal,
          );

          final navigationBar = find.byKey(
            const Key('mobile-app-navigation-bar'),
          );
          expect(
            find.descendant(
              of: navigationBar,
              matching: find.text('터미널 - 포트폴리오 zsh'),
            ),
            findsOneWidget,
            reason: '$size',
          );
          expect(find.text('portfolio — zsh'), findsNothing, reason: '$size');
        }
      },
    );

    testWidgets(
      'iPad traffic lights show static red X and yellow minus glyphs',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await _pumpSurface(
          tester,
          size: const Size(834, 1194),
          appId: PortfolioAppId.about,
        );

        for (final control in const <String>['minimize', 'maximize']) {
          final target = find.byKey(Key('window-$control-about'));
          expect(target, findsOneWidget);
          expect(tester.getSize(target), const Size(24, 32));

          final semanticsData = tester.getSemantics(target).getSemanticsData();
          expect(semanticsData.flagsCollection.isButton, isFalse);
          expect(semanticsData.hasAction(ui.SemanticsAction.tap), isFalse);
        }
        expect(find.bySemanticsLabel('Minimize About window'), findsNothing);
        expect(find.bySemanticsLabel('Restore About window'), findsNothing);
        expect(find.bySemanticsLabel('Maximize About window'), findsNothing);

        final closeGlyph = find.byKey(const Key('window-close-about-glyph'));
        final minimizeGlyph = find.byKey(
          const Key('window-minimize-about-glyph'),
        );
        expect(tester.widget<Icon>(closeGlyph).icon, Icons.close_rounded);
        expect(tester.widget<Icon>(minimizeGlyph).icon, Icons.remove_rounded);
        expect(
          find.byKey(const Key('window-maximize-about-glyph')),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('mac-traffic-controls-about')),
            matching: find.byType(InkResponse),
          ),
          findsNothing,
        );

        await tester.tap(find.byKey(const Key('window-minimize-about')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('mobile-app-surface')), findsOneWidget);

        await tester.tap(find.byKey(const Key('window-maximize-about')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('mobile-app-surface')), findsOneWidget);
        semantics.dispose();
      },
    );

    testWidgets(
      'keeps device-specific leading controls overflow-free at 200%',
      (tester) async {
        for (final size in const <Size>[Size(320, 480), Size(600, 400)]) {
          await tester.pumpWidget(const SizedBox.shrink());
          await _pumpSurface(
            tester,
            size: size,
            appId: PortfolioAppId.terminal,
            textScaler: const TextScaler.linear(2),
          );

          final title = find.byKey(const Key('mobile-app-title'));
          final titleWidget = tester.widget<Text>(title);
          expect(titleWidget.maxLines, 1);
          expect(titleWidget.overflow, TextOverflow.ellipsis);
          expect(
            titleWidget.textAlign,
            size.width < 600 ? TextAlign.center : TextAlign.left,
          );
          if (size.width < 600) {
            expect(tester.getCenter(title).dx, closeTo(size.width / 2, 0.01));
          }
          if (size.width < 600) {
            expect(find.byType(MacTrafficControls), findsNothing);
            expect(
              find.byKey(const Key('mobile-back-close-terminal')),
              findsOneWidget,
            );
          } else {
            expect(find.byType(MacTrafficControls), findsOneWidget);
            expect(
              find.byKey(const Key('mobile-back-close-terminal')),
              findsNothing,
            );
          }
          expect(tester.takeException(), isNull, reason: '$size');
        }
      },
    );
  });
}

Future<void> _pumpSurface(
  WidgetTester tester, {
  required Size size,
  required PortfolioAppId appId,
  TextScaler textScaler = TextScaler.noScaling,
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
      home: MediaQuery(
        data: MediaQueryData(size: size, textScaler: textScaler),
        child: _SurfaceHarness(
          appId: appId,
          data: portfolioData,
          launcher: _FakeLauncher(),
          themeController: themeController,
          tablet: size.width >= 600,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _SurfaceHarness extends StatefulWidget {
  const _SurfaceHarness({
    required this.appId,
    required this.data,
    required this.launcher,
    required this.themeController,
    required this.tablet,
  });

  final PortfolioAppId appId;
  final PortfolioData data;
  final ExternalLauncher launcher;
  final PortfolioThemeController themeController;
  final bool tablet;

  @override
  State<_SurfaceHarness> createState() => _SurfaceHarnessState();
}

class _SurfaceHarnessState extends State<_SurfaceHarness> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    if (!_open) {
      return const SizedBox.expand(key: Key('mobile-home'));
    }

    return MobileAppSurface(
      appId: widget.appId,
      data: widget.data,
      launcher: widget.launcher,
      themeController: widget.themeController,
      tablet: widget.tablet,
      onClose: () => setState(() => _open = false),
    );
  }
}

final class _FakeLauncher implements ExternalLauncher {
  @override
  Future<bool> launch(Uri uri) async => true;
}
