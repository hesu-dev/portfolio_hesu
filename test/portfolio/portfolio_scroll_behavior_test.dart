import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/portfolio_app_content.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';
import 'package:portfolio_hesu/portfolio/music/music_track.dart';
import 'package:portfolio_hesu/portfolio/portfolio_app.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/theme/portfolio_theme_controller.dart';

import 'support/music_test_controller.dart';

void main() {
  group('Portfolio scroll behavior', () {
    testWidgets('전역 정책은 터치와 마우스 드래그를 모두 허용한다', (tester) async {
      await _pumpPortfolio(tester);

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(
        app.scrollBehavior?.dragDevices,
        containsAll(<PointerDeviceKind>{
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
        }),
      );
    });

    for (final layout in _adaptiveLayouts) {
      testWidgets('${layout.name}의 모든 공개 앱 본문은 터치와 마우스로 스크롤된다', (tester) async {
        for (final target in _publicAppScrollTargets) {
          await tester.pumpWidget(const SizedBox.shrink());
          await _pumpAppContent(tester, layout: layout, target: target);

          if (target.appId == PortfolioAppId.terminal) {
            await _fillTerminalTranscript(tester);
          }

          await _expectTouchAndMouseScroll(
            tester,
            find.byKey(target.scrollKey),
            reason: '${layout.name} ${target.appId.name}',
            mouseDragStartBelow:
                layout.mobile &&
                    !layout.tablet &&
                    target.appId == PortfolioAppId.skills
                ? find.byKey(const Key('skills-mobile-certification-strip'))
                : null,
          );
          if (target.appId == PortfolioAppId.projects) {
            final collectionScrollable = tester.state<ScrollableState>(
              find.descendant(
                of: find.byKey(const Key('projects-collection-scroll')),
                matching: find.byType(Scrollable),
              ),
            );
            collectionScrollable.position.jumpTo(0);
            await tester.pump();
            final firstProject = find.byKey(const Key('project-selector-2'));
            await tester.ensureVisible(firstProject);
            await tester.tap(firstProject);
            await tester.pumpAndSettle();
            await _expectTouchAndMouseScroll(
              tester,
              find.byKey(const Key('projects-detail-scroll')),
              reason: '${layout.name} projects detail',
            );
          }
          if (target.appId == PortfolioAppId.skills &&
              layout.mobile &&
              !layout.tablet) {
            final listScrollable = tester.state<ScrollableState>(
              find
                  .descendant(
                    of: find.byKey(const Key('skills-list')),
                    matching: find.byWidgetPredicate(
                      (widget) =>
                          widget is Scrollable &&
                          (widget.axisDirection == AxisDirection.down ||
                              widget.axisDirection == AxisDirection.up),
                    ),
                  )
                  .first,
            );
            listScrollable.position.jumpTo(0);
            await tester.pump();
            final development = find.byKey(
              const Key('skills-mobile-channel-Development'),
            );
            await tester.ensureVisible(development);
            await tester.tap(development);
            await tester.pumpAndSettle();
            await _expectTouchAndMouseScroll(
              tester,
              find.byKey(const Key('skills-mobile-message-list')),
              reason: '${layout.name} skills detail',
            );
          }
          expect(
            tester.takeException(),
            isNull,
            reason: '${layout.name} ${target.appId.name}',
          );
        }
      });
    }
  });
}

const List<_AdaptiveLayout> _adaptiveLayouts = <_AdaptiveLayout>[
  _AdaptiveLayout(
    name: 'iPhone',
    width: 390,
    compact: true,
    mobile: true,
    tablet: false,
  ),
  _AdaptiveLayout(
    name: 'iPad',
    width: 834,
    compact: false,
    mobile: true,
    tablet: true,
  ),
  _AdaptiveLayout(
    name: 'Desktop',
    width: 1100,
    compact: false,
    mobile: false,
    tablet: false,
  ),
];

const List<_AppScrollTarget> _publicAppScrollTargets = <_AppScrollTarget>[
  _AppScrollTarget(PortfolioAppId.about, Key('about-scroll')),
  _AppScrollTarget(
    PortfolioAppId.introduction,
    Key('introduction-scroll'),
    height: 180,
  ),
  _AppScrollTarget(
    PortfolioAppId.projects,
    Key('projects-collection-scroll'),
    mobileHeight: 360,
  ),
  _AppScrollTarget(PortfolioAppId.skills, Key('skills-list')),
  _AppScrollTarget(
    PortfolioAppId.settings,
    Key('settings-scroll'),
    height: 180,
  ),
  _AppScrollTarget(PortfolioAppId.terminal, Key('terminal-transcript')),
  _AppScrollTarget(PortfolioAppId.music, Key('music-scroll'), height: 180),
  _AppScrollTarget(PortfolioAppId.photos, Key('photos-scroll'), height: 180),
  _AppScrollTarget(PortfolioAppId.trash, Key('trash-scroll'), height: 180),
  _AppScrollTarget(PortfolioAppId.github, Key('github-app-scroll')),
  _AppScrollTarget(PortfolioAppId.mail, Key('mail-app-scroll')),
];

class _AdaptiveLayout {
  const _AdaptiveLayout({
    required this.name,
    required this.width,
    required this.compact,
    required this.mobile,
    required this.tablet,
  });

  final String name;
  final double width;
  final bool compact;
  final bool mobile;
  final bool tablet;
}

class _AppScrollTarget {
  const _AppScrollTarget(
    this.appId,
    this.scrollKey, {
    this.height = 260,
    this.mobileHeight,
  });

  final PortfolioAppId appId;
  final Key scrollKey;
  final double height;
  final double? mobileHeight;
}

Future<void> _pumpPortfolio(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 600);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    PortfolioApp(externalLauncher: CallbackExternalLauncher((_) async => true)),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpAppContent(
  WidgetTester tester, {
  required _AdaptiveLayout layout,
  required _AppScrollTarget target,
}) async {
  final themeController = PortfolioThemeController();
  addTearDown(themeController.dispose);
  tester.view.devicePixelRatio = 1;
  final targetHeight = layout.compact || layout.tablet
      ? target.mobileHeight ?? target.height
      : target.height;
  tester.view.physicalSize = Size(layout.width, targetHeight);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      scrollBehavior: const PortfolioScrollBehavior(),
      theme: AppleTheme.light(),
      home: PortfolioAppContent(
        appId: target.appId,
        data: portfolioData,
        launcher: CallbackExternalLauncher((_) async => true),
        themeController: themeController,
        musicController: createTestMusicController(
          tracks: target.appId == PortfolioAppId.music
              ? _scrollMusicTracks
              : const <MusicTrack>[],
        ),
        compact: layout.compact,
        mobile: layout.mobile,
        tablet: layout.tablet,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _scrollMusicTracks = <MusicTrack>[
  MusicTrack(assetPath: 'assets/music/01-first.mp3', title: 'First Song'),
  MusicTrack(assetPath: 'assets/music/02-second.mp3', title: 'Second Song'),
  MusicTrack(assetPath: 'assets/music/03-third.mp3', title: 'Third Song'),
];

Future<void> _fillTerminalTranscript(WidgetTester tester) async {
  for (var index = 0; index < 4; index++) {
    await tester.enterText(find.byKey(const Key('terminal-input')), 'help');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> _expectTouchAndMouseScroll(
  WidgetTester tester,
  Finder scrollTarget, {
  required String reason,
  Finder? mouseDragStartBelow,
}) async {
  expect(scrollTarget, findsOneWidget, reason: reason);
  final verticalScrollables = find.descendant(
    of: scrollTarget,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          (widget.axisDirection == AxisDirection.down ||
              widget.axisDirection == AxisDirection.up),
      description: 'vertical Scrollable',
    ),
  );
  final scrollableFinder = verticalScrollables.first;
  expect(scrollableFinder, findsOneWidget, reason: reason);
  final position = tester.state<ScrollableState>(scrollableFinder).position;
  expect(position.maxScrollExtent, greaterThan(0), reason: reason);

  position.jumpTo(0);
  await tester.drag(scrollTarget, const Offset(0, -100));
  await tester.pumpAndSettle();
  expect(position.pixels, greaterThan(0), reason: '$reason touch');

  position.jumpTo(0);
  await tester.pump();
  final targetRect = tester.getRect(scrollTarget);
  final dragStart = mouseDragStartBelow == null
      ? targetRect.centerLeft + const Offset(8, 0)
      : Offset(
          targetRect.center.dx,
          tester.getRect(mouseDragStartBelow).bottom + 8,
        );
  final mouseGesture = await tester.startGesture(
    dragStart,
    kind: PointerDeviceKind.mouse,
  );
  await mouseGesture.moveBy(const Offset(0, -100));
  await mouseGesture.up();
  await tester.pumpAndSettle();
  expect(position.pixels, greaterThan(0), reason: '$reason mouse');
}
