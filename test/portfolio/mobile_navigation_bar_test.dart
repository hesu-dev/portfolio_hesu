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
      'every iPhone and iPad app uses one iOS-style Home back button',
      (tester) async {
        for (final size in const <Size>[Size(390, 844), Size(834, 1194)]) {
          for (final appId in PortfolioAppId.values) {
            await tester.pumpWidget(const SizedBox.shrink());
            await _pumpSurface(tester, size: size, appId: appId);

            final navigationBar = find.byKey(
              const Key('mobile-app-navigation-bar'),
            );
            final homeButton = find.byKey(const Key('mobile-home-back'));
            final title = find.byKey(const Key('mobile-app-title'));

            expect(navigationBar, findsOneWidget);
            expect(homeButton, findsOneWidget);
            expect(
              find.descendant(of: navigationBar, matching: find.text('홈')),
              findsOneWidget,
            );
            expect(
              find.descendant(
                of: navigationBar,
                matching: find.byIcon(Icons.chevron_left_rounded),
              ),
              findsOneWidget,
            );
            expect(find.byType(MacTrafficControls), findsNothing);
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
            expect(
              tester.getCenter(title).dx,
              closeTo(tester.getCenter(navigationBar).dx, 0.5),
              reason: '$size ${appId.name}',
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

    testWidgets('Home back button exposes a 44px target and returns home', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpSurface(
        tester,
        size: const Size(390, 844),
        appId: PortfolioAppId.about,
      );

      final homeButton = find.byKey(const Key('mobile-home-back'));
      expect(find.bySemanticsLabel('홈으로 돌아가기'), findsOneWidget);
      expect(tester.getSize(homeButton).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(homeButton).height, greaterThanOrEqualTo(44));
      final semanticsData = tester.getSemantics(homeButton).getSemanticsData();
      expect(semanticsData.flagsCollection.isButton, isTrue);
      expect(semanticsData.hasAction(ui.SemanticsAction.tap), isTrue);

      await tester.tap(homeButton);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mobile-home')), findsOneWidget);
      expect(find.byKey(const Key('mobile-app-surface')), findsNothing);
      semantics.dispose();
    });

    testWidgets(
      'keeps centered titles overflow-free at 200% on phone and iPad',
      (tester) async {
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
          expect(
            tester.getCenter(title).dx,
            closeTo(tester.getCenter(navigationBar).dx, 0.5),
          );
          expect(
            tester.getSize(find.byKey(const Key('mobile-home-back'))).height,
            greaterThanOrEqualTo(44),
          );
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
