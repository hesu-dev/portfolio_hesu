import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/macos/mac_desktop.dart';
import 'package:portfolio_hesu/portfolio/macos/mac_dock.dart';
import 'package:portfolio_hesu/portfolio/mobile/apple_home_grid.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/theme/portfolio_theme_controller.dart';
import 'package:portfolio_hesu/portfolio/widgets/apple_app_artwork.dart';

import 'support/music_test_controller.dart';

void main() {
  group('Apple 아이콘 프레임 일관성', () {
    for (final surface in _IconSurface.values) {
      testWidgets('${surface.label}의 모든 앱이 공용 normalized frame을 사용한다', (
        tester,
      ) async {
        await _pumpSurface(tester, surface);

        for (final appId in _appsFor(surface)) {
          final launcher = find.byKey(_launcherKey(surface, appId));
          expect(launcher, findsOneWidget, reason: appId.name);

          final frame = find.descendant(
            of: launcher,
            matching: find.byType(AppleAppArtworkFrame),
          );
          expect(
            frame,
            findsOneWidget,
            reason: '${surface.label} ${appId.name}',
          );

          final frameWidget = tester.widget<AppleAppArtworkFrame>(frame);
          expect(frameWidget.appId, appId);
          final artwork = find.descendant(
            of: frame,
            matching: find.byType(AppleAppArtwork),
          );
          expect(artwork, findsOneWidget);
          expect(
            tester.widget<AppleAppArtwork>(artwork).size,
            frameWidget.size,
            reason: '${surface.label} ${appId.name} normalized fill',
          );
        }
      });
    }

    for (final surface in const <_IconSurface>[
      _IconSurface.desktop,
      _IconSurface.dock,
    ]) {
      testWidgets('${surface.label}의 투명 실루엣에는 사각 frame 효과나 clip이 없다', (
        tester,
      ) async {
        await _pumpSurface(tester, surface);

        final transparentApps = surface == _IconSurface.desktop
            ? const <PortfolioAppId>[
                PortfolioAppId.projects,
                PortfolioAppId.github,
              ]
            : const <PortfolioAppId>[
                PortfolioAppId.projects,
                PortfolioAppId.github,
                PortfolioAppId.trash,
              ];
        for (final appId in transparentApps) {
          final launcher = find.byKey(_launcherKey(surface, appId));
          final frame = find.descendant(
            of: launcher,
            matching: find.byType(AppleAppArtworkFrame),
          );
          expect(frame, findsOneWidget, reason: appId.name);
          expect(
            find.descendant(of: frame, matching: find.byType(ClipRRect)),
            findsNothing,
            reason: '${surface.label} ${appId.name} transparent silhouette',
          );

          for (final decoration in _boxDecorations(tester, frame)) {
            expect(
              decoration.gradient,
              isNull,
              reason: '${surface.label} ${appId.name} gradient',
            );
            expect(
              decoration.border,
              isNull,
              reason: '${surface.label} ${appId.name} border',
            );
            expect(
              decoration.boxShadow ?? const <BoxShadow>[],
              isEmpty,
              reason: '${surface.label} ${appId.name} shadow',
            );
          }
        }
      });
    }

    for (final surface in const <_IconSurface>[
      _IconSurface.iPad,
      _IconSurface.iPhone,
    ]) {
      testWidgets('${surface.label}의 투명 아트워크는 공통 반투명 타일을 쓴다', (tester) async {
        await _pumpSurface(tester, surface);

        for (final appId in const <PortfolioAppId>[
          PortfolioAppId.introduction,
          PortfolioAppId.projects,
          PortfolioAppId.github,
          PortfolioAppId.trash,
        ]) {
          final launcher = find.byKey(_launcherKey(surface, appId));
          final frame = find.descendant(
            of: launcher,
            matching: find.byType(AppleAppArtworkFrame),
          );
          final container = tester.widget<Container>(
            find.descendant(of: frame, matching: find.byType(Container)).first,
          );
          final decoration = container.decoration! as BoxDecoration;
          expect(
            decoration.color,
            Colors.white.withValues(alpha: 0.5),
            reason: appId.name,
          );
          expect(decoration.borderRadius, isNotNull, reason: appId.name);
          expect(decoration.boxShadow, isEmpty, reason: appId.name);
          expect(
            find.descendant(of: frame, matching: find.byType(ClipRRect)),
            findsOneWidget,
            reason:
                '${surface.label} ${appId.name} uses only the shared tile clip',
          );
        }
      });
    }

    testWidgets('Dock Trash는 49px 전체 painter를 비클리핑으로 노출한다', (tester) async {
      await _pumpSurface(tester, _IconSurface.dock);

      final desktopFrame = find.byKey(
        const Key('dock-app-artwork-frame-trash'),
      );
      final desktopLauncher = find.byKey(const Key('dock-app-trash'));
      expect(desktopFrame, findsOneWidget);
      final sharedFrame = find.descendant(
        of: desktopLauncher,
        matching: find.byType(AppleAppArtworkFrame),
      );
      expect(sharedFrame, findsOneWidget);

      final paint = find.descendant(
        of: sharedFrame,
        matching: find.byType(CustomPaint),
      );
      expect(paint, findsOneWidget);
      expect(tester.getSize(paint), const Size.square(49));
      expect(
        find.descendant(of: sharedFrame, matching: find.byType(ClipRRect)),
        findsNothing,
      );
      for (final stack in tester.widgetList<Stack>(
        find.descendant(of: sharedFrame, matching: find.byType(Stack)),
      )) {
        expect(stack.clipBehavior, Clip.none);
      }
    });

    testWidgets('720px 높이에서도 Trash는 그리드가 아닌 Dock 오른쪽에 보인다', (tester) async {
      await _pumpSurface(
        tester,
        _IconSurface.desktop,
        overrideSize: const Size(1280, 720),
      );

      final grid = find.byKey(const Key('mac-desktop-icons'));
      final trash = find.byKey(const Key('desktop-app-trash'));
      final dockTrash = find.byKey(const Key('dock-app-trash'));
      final artwork = find.byKey(const Key('dock-app-artwork-frame-trash'));

      expect(grid, findsOneWidget);
      expect(trash, findsNothing);
      expect(dockTrash, findsOneWidget);
      expect(artwork, findsOneWidget);
      expect(tester.getRect(dockTrash).bottom, lessThanOrEqualTo(720));
    });
  });
}

List<PortfolioAppId> _appsFor(_IconSurface surface) => switch (surface) {
  _IconSurface.desktop => portfolioMacDesktopLauncherAppIds,
  _IconSurface.iPad || _IconSurface.iPhone => AppleHomeGrid.apps,
  _IconSurface.dock => MacDock.launchableApps,
};

enum _IconSurface {
  desktop('Desktop'),
  iPad('iPad home'),
  iPhone('iPhone home'),
  dock('Mac Dock');

  const _IconSurface(this.label);

  final String label;
}

Key _launcherKey(_IconSurface surface, PortfolioAppId appId) =>
    switch (surface) {
      _IconSurface.desktop => Key('desktop-app-${appId.name}'),
      _IconSurface.iPad || _IconSurface.iPhone => Key('home-app-${appId.name}'),
      _IconSurface.dock => Key('dock-app-${appId.name}'),
    };

Future<void> _pumpSurface(
  WidgetTester tester,
  _IconSurface surface, {
  Size? overrideSize,
}) async {
  final size =
      overrideSize ??
      switch (surface) {
        _IconSurface.desktop => const Size(1440, 900),
        _IconSurface.iPad => const Size(834, 1194),
        _IconSurface.iPhone => const Size(390, 844),
        _IconSurface.dock => const Size(900, 140),
      };
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final themeController = PortfolioThemeController();
  addTearDown(themeController.dispose);
  final child = switch (surface) {
    _IconSurface.desktop => MacDesktop(
      data: portfolioData,
      externalLauncher: const _FakeLauncher(),
      themeController: themeController,
      musicController: createTestMusicController(),
    ),
    _IconSurface.iPad => AppleHomeGrid(
      data: portfolioData,
      tablet: true,
      onOpen: (_) {},
    ),
    _IconSurface.iPhone => AppleHomeGrid(
      data: portfolioData,
      tablet: false,
      onOpen: (_) {},
    ),
    _IconSurface.dock => Center(
      child: MacDock(
        runningApps: portfolioLauncherAppIds.toSet(),
        activeApp: PortfolioAppId.about,
        onAppPressed: (_) {},
      ),
    ),
  };

  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.light(),
      home: Material(child: child),
    ),
  );
  await tester.pump();
}

Iterable<BoxDecoration> _boxDecorations(
  WidgetTester tester,
  Finder frame,
) sync* {
  for (final widget in tester.widgetList<DecoratedBox>(
    find.descendant(of: frame, matching: find.byType(DecoratedBox)),
  )) {
    if (widget.decoration case final BoxDecoration decoration) {
      yield decoration;
    }
  }
  for (final widget in tester.widgetList<AnimatedContainer>(
    find.descendant(of: frame, matching: find.byType(AnimatedContainer)),
  )) {
    if (widget.decoration case final BoxDecoration decoration) {
      yield decoration;
    }
  }
  for (final widget in tester.widgetList<Container>(
    find.descendant(of: frame, matching: find.byType(Container)),
  )) {
    if (widget.decoration case final BoxDecoration decoration) {
      yield decoration;
    }
  }
}

final class _FakeLauncher implements ExternalLauncher {
  const _FakeLauncher();

  @override
  Future<bool> launch(Uri uri) async => true;
}
