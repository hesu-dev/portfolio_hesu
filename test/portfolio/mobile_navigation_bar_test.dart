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
import 'package:portfolio_hesu/portfolio/widgets/apple_mobile_navigation_header.dart';

import 'support/music_test_controller.dart';

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
          expect(find.byType(AppleMobileNavigationHeader), findsOneWidget);
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

    testWidgets(
      'iPhone title keeps its natural height and aligns with the leading control',
      (tester) async {
        await _pumpSurface(
          tester,
          size: const Size(390, 844),
          appId: PortfolioAppId.about,
        );

        final title = find.byKey(const Key('mobile-app-title'));
        final leading = find.byKey(const Key('mobile-back-close-about'));

        expect(tester.getSize(title).height, lessThan(30));
        expect(
          tester.getCenter(title).dy,
          closeTo(tester.getCenter(leading).dy, 1),
        );
        expect(tester.getCenter(title).dx, closeTo(390 / 2, 0.01));
      },
    );

    testWidgets(
      'regular mobile header keeps title blank areas and more inert',
      (tester) async {
        for (final size in const <Size>[Size(390, 844), Size(834, 1194)]) {
          await tester.pumpWidget(const SizedBox.shrink());
          await _pumpSurface(tester, size: size, appId: PortfolioAppId.about);

          final header = find.byKey(const Key('mobile-app-navigation-bar'));
          final title = find.byKey(const Key('mobile-app-title'));
          final more = find.byKey(const Key('mobile-app-more-about'));
          final headerRect = tester.getRect(header);

          expect(more, findsOneWidget, reason: '$size');
          await tester.tap(title);
          await tester.pumpAndSettle();
          await tester.tapAt(
            Offset(headerRect.left + 58, headerRect.center.dy),
          );
          await tester.pumpAndSettle();
          await tester.tapAt(
            Offset(headerRect.right - 58, headerRect.center.dy),
          );
          await tester.pumpAndSettle();
          await tester.tap(more);
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('mobile-app-surface')), findsOneWidget);
          expect(find.byKey(const Key('mobile-home')), findsNothing);
        }
      },
    );

    testWidgets(
      'every non-Projects iPad app uses the shared back close header',
      (tester) async {
        for (final appId in PortfolioAppId.values.where(
          (appId) => appId != PortfolioAppId.projects,
        )) {
          await tester.pumpWidget(const SizedBox.shrink());
          await _pumpSurface(tester, size: const Size(834, 1194), appId: appId);

          final close = find.byKey(Key('mobile-back-close-${appId.name}'));
          final navigationBar = find.byKey(
            const Key('mobile-app-navigation-bar'),
          );
          final title = find.byKey(const Key('mobile-app-title'));

          expect(find.byType(MacTrafficControls), findsNothing);
          expect(close, findsOneWidget);
          expect(tester.getSize(close), const Size(44, 44));
          expect(
            tester.getCenter(title).dx,
            closeTo(tester.getRect(navigationBar).center.dx, 0.01),
            reason: '${appId.name} title must center in its header area',
          );
          expect(
            find.byKey(Key('mobile-app-more-${appId.name}')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull, reason: appId.name);
        }
      },
    );

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
          expect(find.byType(AppleMobileNavigationHeader), findsOneWidget);
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

    testWidgets('Projects header keeps non-leading regions inert', (
      tester,
    ) async {
      for (final size in const <Size>[Size(390, 844), Size(834, 1194)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpSurface(tester, size: size, appId: PortfolioAppId.projects);

        final header = find.byKey(const Key('projects-finder-toolbar'));
        final title = find.byKey(const Key('projects-finder-current-location'));
        final more = find.byKey(const Key('projects-finder-more'));
        final headerRect = tester.getRect(header);

        await tester.tap(title);
        await tester.pumpAndSettle();
        await tester.tapAt(Offset(headerRect.left + 58, headerRect.center.dy));
        await tester.pumpAndSettle();
        await tester.tapAt(Offset(headerRect.right - 58, headerRect.center.dy));
        await tester.pumpAndSettle();
        await tester.tap(more);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('mobile-app-surface')), findsOneWidget);
        expect(find.byKey(const Key('mobile-home')), findsNothing);
      }
    });

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
            'Close 포트폴리오 window',
            reason: '$size root semantics',
          );
          expect(
            tester.getSemantics(circularControl).rect.size,
            const Size(44, 44),
            reason: '$size root semantics target',
          );
          expect(find.byTooltip('Close 포트폴리오 window'), findsOneWidget);

          await tester.tap(find.byKey(const Key('projects-career-folder-0')));
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('project-detail-title')), findsOneWidget);
          expect(
            tester.getSemantics(circularControl).getSemanticsData().label,
            'Back in 포트폴리오',
            reason: '$size detail semantics',
          );
          expect(find.byTooltip('Back in 포트폴리오'), findsOneWidget);

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
            'Close 포트폴리오 window',
            reason: '$size returned root semantics',
          );
          expect(find.byTooltip('Close 포트폴리오 window'), findsOneWidget);

          await tester.tap(circularControl);
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('mobile-home')), findsOneWidget);
          expect(find.byKey(const Key('mobile-app-surface')), findsNothing);
        }

        semantics.dispose();
      },
    );

    testWidgets('Projects Finder circular control closes every location root', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      for (final size in const <Size>[Size(390, 844), Size(834, 1194)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpSurface(tester, size: size, appId: PortfolioAppId.projects);

        await tester.tap(
          find.byKey(const Key('projects-finder-location-recent')),
        );
        await tester.pumpAndSettle();

        final circularControl = find.byKey(
          const Key('mobile-back-close-projects'),
        );
        expect(find.text('최근 항목'), findsWidgets);
        expect(
          tester.getSemantics(circularControl).getSemanticsData().label,
          startsWith('Close 포트폴리오 window'),
          reason: '$size location root semantics',
        );

        await tester.tap(circularControl);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('mobile-home')), findsOneWidget);
        expect(find.byKey(const Key('mobile-app-surface')), findsNothing);
      }

      semantics.dispose();
    });

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
      expect(find.bySemanticsLabel('Close 프로필 window'), findsOneWidget);
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
              matching: find.text('Terminal - Portfolio zsh'),
            ),
            findsOneWidget,
            reason: '$size',
          );
          expect(find.text('portfolio — zsh'), findsNothing, reason: '$size');
        }
      },
    );

    testWidgets('keeps the shared back close header overflow-free at 200%', (
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

        final title = find.byKey(const Key('mobile-app-title'));
        final titleWidget = tester.widget<Text>(title);
        expect(titleWidget.maxLines, 1);
        expect(titleWidget.overflow, TextOverflow.ellipsis);
        expect(titleWidget.textAlign, TextAlign.center);
        expect(tester.getCenter(title).dx, closeTo(size.width / 2, 0.01));
        expect(find.byType(MacTrafficControls), findsNothing);
        expect(
          find.byKey(const Key('mobile-back-close-terminal')),
          findsOneWidget,
        );
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
      musicController: createTestMusicController(),
      tablet: widget.tablet,
      onClose: () => setState(() => _open = false),
    );
  }
}

final class _FakeLauncher implements ExternalLauncher {
  @override
  Future<bool> launch(Uri uri) async => true;
}
