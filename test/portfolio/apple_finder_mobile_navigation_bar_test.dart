import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/mobile/apple_mobile_dock_geometry.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/widgets/apple_finder_scaffold.dart';

void main() {
  group('AppleFinderMobileNavigationBar', () {
    testWidgets('uses a translucent pill Dock and a Dock-height fade', (
      tester,
    ) async {
      for (final scenario in const <({Size size, bool tablet})>[
        (size: Size(390, 844), tablet: false),
        (size: Size(834, 1194), tablet: true),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpNavigation(
          tester,
          size: scenario.size,
          tablet: scenario.tablet,
        );

        final dock = find.byKey(const Key('test-finder-mobile-dock'));
        final dockDecoration =
            tester.widget<Container>(dock).decoration! as BoxDecoration;
        final dockRadius = dockDecoration.borderRadius! as BorderRadius;
        final fade = find.byKey(
          const Key('test-finder-mobile-dock-backdrop-gradient'),
        );
        final fadeDecoration =
            tester.widget<DecoratedBox>(fade).decoration as BoxDecoration;
        final gradient = fadeDecoration.gradient! as LinearGradient;
        final indicator = find.byKey(
          const Key('test-finder-mobile-dock-selection-indicator'),
        );
        final indicatorDecoration =
            tester.widget<DecoratedBox>(indicator).decoration as BoxDecoration;
        final indicatorRadius =
            indicatorDecoration.borderRadius! as BorderRadius;

        expect(dockRadius.topLeft, const Radius.circular(999));
        expect(indicatorRadius.topLeft, const Radius.circular(999));
        expect(
          dockDecoration.color,
          AppleTheme.surface(tester.element(dock)).withValues(alpha: 0.42),
        );
        expect(gradient.begin, Alignment.topCenter);
        expect(gradient.end, Alignment.bottomCenter);
        expect(gradient.colors.first, Colors.white.withValues(alpha: 0));
        expect(gradient.colors.last, Colors.white.withValues(alpha: 0.4));
        expect(
          tester.getSize(fade).height,
          closeTo(
            AppleMobileDockGeometry.height(tablet: scenario.tablet),
            0.01,
          ),
        );
      }
    });

    testWidgets('slides and pulses on every move before settling', (
      tester,
    ) async {
      for (final scenario in const <({Size size, bool tablet})>[
        (size: Size(390, 844), tablet: false),
        (size: Size(834, 1194), tablet: true),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpNavigation(
          tester,
          size: scenario.size,
          tablet: scenario.tablet,
        );

        final indicator = find.byKey(
          const Key('test-finder-mobile-dock-selection-indicator'),
        );
        final scale = find.byKey(
          const Key('test-finder-mobile-dock-selection-scale'),
        );
        for (final targetId in const <String>['personal', 'recent']) {
          final initialCenter = tester.getCenter(indicator);
          final targetCenter = tester.getCenter(
            find.byKey(Key('test-finder-location-$targetId')),
          );

          await tester.tap(find.byKey(Key('test-finder-location-$targetId')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 144));

          final movingCenter = tester.getCenter(indicator);
          final movingScale = tester
              .widget<Transform>(scale)
              .transform
              .storage[0];
          expect(
            movingCenter.dx,
            inExclusiveRange(
              initialCenter.dx < targetCenter.dx
                  ? initialCenter.dx
                  : targetCenter.dx,
              initialCenter.dx < targetCenter.dx
                  ? targetCenter.dx
                  : initialCenter.dx,
            ),
          );
          expect(movingScale, closeTo(1.08, 0.001));

          await tester.pumpAndSettle();

          expect(
            tester.getCenter(indicator).dx,
            closeTo(targetCenter.dx, 0.01),
          );
          expect(
            tester.widget<Transform>(scale).transform.storage[0],
            closeTo(1, 0.001),
          );
        }
      }
    });
  });
}

Future<void> _pumpNavigation(
  WidgetTester tester, {
  required Size size,
  required bool tablet,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.light(),
      home: _NavigationHarness(tablet: tablet),
    ),
  );
  await tester.pumpAndSettle();
}

class _NavigationHarness extends StatefulWidget {
  const _NavigationHarness({required this.tablet});

  final bool tablet;

  @override
  State<_NavigationHarness> createState() => _NavigationHarnessState();
}

class _NavigationHarnessState extends State<_NavigationHarness> {
  String selectedId = 'career';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          const Expanded(child: SizedBox.expand()),
          AppleFinderMobileNavigationBar(
            keyPrefix: 'test-finder',
            destinations: const <AppleFinderMobileDestination>[
              AppleFinderMobileDestination(
                id: 'recent',
                label: '최근 항목',
                icon: Icons.access_time_filled_rounded,
              ),
              AppleFinderMobileDestination(
                id: 'career',
                label: '회사',
                icon: Icons.business_center_rounded,
              ),
              AppleFinderMobileDestination(
                id: 'personal',
                label: '개인',
                icon: Icons.folder_special_rounded,
              ),
            ],
            selectedId: selectedId,
            onSelected: (value) => setState(() => selectedId = value),
            tablet: widget.tablet,
          ),
        ],
      ),
    );
  }
}
