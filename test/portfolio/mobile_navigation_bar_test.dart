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
      'every iPhone and iPad app uses shared traffic lights and a left title',
      (tester) async {
        for (final size in const <Size>[Size(390, 844), Size(834, 1194)]) {
          for (final appId in PortfolioAppId.values) {
            await tester.pumpWidget(const SizedBox.shrink());
            await _pumpSurface(tester, size: size, appId: appId);

            final navigationBar = find.byKey(
              const Key('mobile-app-navigation-bar'),
            );
            final title = find.byKey(const Key('mobile-app-title'));
            final trafficControls = find.descendant(
              of: navigationBar,
              matching: find.byType(MacTrafficControls),
            );

            expect(navigationBar, findsOneWidget);
            expect(find.byKey(const Key('mobile-home-back')), findsNothing);
            expect(trafficControls, findsOneWidget);
            expect(
              tester.widget<MacTrafficControls>(trafficControls).appId,
              appId,
            );
            expect(find.byKey(const Key('mobile-close')), findsNothing);
            expect(
              find.descendant(
                of: navigationBar,
                matching: find.byIcon(Icons.keyboard_arrow_down_rounded),
              ),
              findsNothing,
            );
            expect(
              find.descendant(
                of: navigationBar,
                matching: find.byType(AppleAppArtwork),
              ),
              findsNothing,
              reason: 'The trailing app artwork was removed from mobile bars.',
            );
            final titleWidget = tester.widget<Text>(title);
            expect(titleWidget.textAlign, TextAlign.left);
            expect(
              tester.getRect(title).left,
              greaterThanOrEqualTo(tester.getRect(trafficControls).right),
            );
            expect(
              tester.takeException(),
              isNull,
              reason: '$size ${appId.name}',
            );
          }
        }
      },
    );

    testWidgets('red traffic light closes the surface and returns home', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpSurface(
        tester,
        size: const Size(390, 844),
        appId: PortfolioAppId.about,
      );

      final closeButton = find.byKey(const Key('window-close-about'));
      expect(find.bySemanticsLabel('Close About window'), findsOneWidget);
      expect(tester.getSize(closeButton).width, MacTrafficControls.targetSize);
      expect(tester.getSize(closeButton).height, MacTrafficControls.targetSize);
      final semanticsData = tester.getSemantics(closeButton).getSemanticsData();
      expect(semanticsData.flagsCollection.isButton, isTrue);
      expect(semanticsData.hasAction(ui.SemanticsAction.tap), isTrue);

      await tester.tap(closeButton);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mobile-home')), findsOneWidget);
      expect(find.byKey(const Key('mobile-app-surface')), findsNothing);
      semantics.dispose();
    });

    testWidgets('keeps left titles and traffic lights overflow-free at 200%', (
      tester,
    ) async {
      for (final size in const <Size>[Size(320, 480), Size(600, 400)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpSurface(
          tester,
          size: size,
          appId: PortfolioAppId.terminal,
          textScaler: const TextScaler.linear(2),
        );

        final navigationBar = find.byKey(
          const Key('mobile-app-navigation-bar'),
        );
        final title = find.byKey(const Key('mobile-app-title'));
        final titleWidget = tester.widget<Text>(title);
        expect(titleWidget.maxLines, 1);
        expect(titleWidget.overflow, TextOverflow.ellipsis);
        expect(titleWidget.textAlign, TextAlign.left);
        expect(find.byType(MacTrafficControls), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$size');
      }
    });
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
