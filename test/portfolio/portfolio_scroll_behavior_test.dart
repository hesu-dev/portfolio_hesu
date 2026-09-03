import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/portfolio_app_content.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';
import 'package:portfolio_hesu/portfolio/portfolio_app.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/theme/portfolio_theme_controller.dart';

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

    testWidgets('About 메모는 터치와 마우스 드래그로 스크롤된다', (tester) async {
      await _pumpPortfolio(tester);
      await tester.tap(find.byKey(const Key('home-app-about')));
      await tester.pumpAndSettle();

      final aboutScroll = find.byKey(const Key('about-scroll'));
      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: aboutScroll, matching: find.byType(Scrollable)),
      );
      expect(scrollable.position.maxScrollExtent, greaterThan(0));

      await tester.drag(aboutScroll, const Offset(0, -180));
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, greaterThan(0));

      scrollable.position.jumpTo(0);
      await tester.pump();

      final mouseGesture = await tester.startGesture(
        tester.getCenter(aboutScroll),
        kind: PointerDeviceKind.mouse,
      );
      await mouseGesture.moveBy(const Offset(0, -180));
      await mouseGesture.up();
      await tester.pumpAndSettle();

      expect(scrollable.position.pixels, greaterThan(0));
      expect(tester.takeException(), isNull);
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
          );
          if (target.appId == PortfolioAppId.projects) {
            final firstProject = find.byKey(const Key('project-selector-0'));
            await tester.ensureVisible(firstProject);
            await tester.tap(firstProject);
            await tester.pumpAndSettle();
            await _expectTouchAndMouseScroll(
              tester,
              find.byKey(const Key('projects-detail-scroll')),
              reason: '${layout.name} projects detail',
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
  _AdaptiveLayout(name: 'iPhone', width: 390, compact: true, tablet: false),
  _AdaptiveLayout(name: 'iPad', width: 834, compact: false, tablet: true),
  _AdaptiveLayout(name: 'Desktop', width: 1100, compact: false, tablet: false),
];

const List<_AppScrollTarget> _publicAppScrollTargets = <_AppScrollTarget>[
  _AppScrollTarget(PortfolioAppId.about, Key('about-scroll')),
  _AppScrollTarget(PortfolioAppId.projects, Key('projects-collection-scroll')),
  _AppScrollTarget(PortfolioAppId.skills, Key('skills-list')),
  _AppScrollTarget(
    PortfolioAppId.settings,
    Key('settings-scroll'),
    height: 180,
  ),
  _AppScrollTarget(PortfolioAppId.terminal, Key('terminal-transcript')),
  _AppScrollTarget(PortfolioAppId.trash, Key('trash-scroll'), height: 180),
  _AppScrollTarget(PortfolioAppId.github, Key('github-app-scroll')),
  _AppScrollTarget(PortfolioAppId.mail, Key('mail-app-scroll')),
];

class _AdaptiveLayout {
  const _AdaptiveLayout({
    required this.name,
    required this.width,
    required this.compact,
    required this.tablet,
  });

  final String name;
  final double width;
  final bool compact;
  final bool tablet;
}

class _AppScrollTarget {
  const _AppScrollTarget(this.appId, this.scrollKey, {this.height = 260});

  final PortfolioAppId appId;
  final Key scrollKey;
  final double height;
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
  tester.view.physicalSize = Size(layout.width, target.height);
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
        compact: layout.compact,
        tablet: layout.tablet,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _fillTerminalTranscript(WidgetTester tester) async {
  for (var index = 0; index < 4; index++) {
    await tester.enterText(find.byKey(const Key('terminal-input')), 'help');
    await tester.tap(find.byKey(const Key('terminal-submit')));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> _expectTouchAndMouseScroll(
  WidgetTester tester,
  Finder scrollTarget, {
  required String reason,
}) async {
  expect(scrollTarget, findsOneWidget, reason: reason);
  final scrollableFinder = find.descendant(
    of: scrollTarget,
    matching: find.byType(Scrollable),
  );
  expect(scrollableFinder, findsOneWidget, reason: reason);
  final position = tester.state<ScrollableState>(scrollableFinder).position;
  expect(position.maxScrollExtent, greaterThan(0), reason: reason);

  position.jumpTo(0);
  await tester.drag(scrollTarget, const Offset(0, -100));
  await tester.pumpAndSettle();
  expect(position.pixels, greaterThan(0), reason: '$reason touch');

  position.jumpTo(0);
  await tester.pump();
  final dragStart =
      tester.getRect(scrollTarget).centerLeft + const Offset(8, 0);
  final mouseGesture = await tester.startGesture(
    dragStart,
    kind: PointerDeviceKind.mouse,
  );
  await mouseGesture.moveBy(const Offset(0, -100));
  await mouseGesture.up();
  await tester.pumpAndSettle();
  expect(position.pixels, greaterThan(0), reason: '$reason mouse');
}
