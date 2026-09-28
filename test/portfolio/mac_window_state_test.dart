import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/macos/mac_window_state.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';

void main() {
  test(
    'only the Safari project window starts at 1.6 times the usual width',
    () {
      const viewport = Size(1600, 1000);
      for (final appId in PortfolioAppId.values) {
        final window = MacWindowState.initial(
          appId: appId,
          cascadeIndex: 0,
          viewport: viewport,
        );
        final expectedSize = switch (appId) {
          PortfolioAppId.safari => const Size(1376, 620),
          PortfolioAppId.settings => const Size(820, 600),
          _ => const Size(860, 620),
        };
        expect(window.size, expectedSize, reason: appId.name);
      }
    },
  );

  test('the wider project window clamps to a smaller desktop work area', () {
    const viewport = Size(1024, 700);
    final window = MacWindowState.initial(
      appId: PortfolioAppId.safari,
      cascadeIndex: 3,
      viewport: viewport,
    );
    final finder = MacWindowState.initial(
      appId: PortfolioAppId.projects,
      cascadeIndex: 3,
      viewport: viewport,
    );
    final workArea = MacDesktopMetrics.workArea(viewport);
    final frame = window.frameFor(viewport);
    expect(frame.left, workArea.left);
    expect(frame.right, workArea.right);
    expect(window.size.width, 1008);
    expect(window.size.height, finder.size.height);
    expect(frame.top, greaterThanOrEqualTo(workArea.top));
    expect(frame.bottom, lessThanOrEqualTo(workArea.bottom));
  });

  test('maximizing and restoring preserves the wider project window frame', () {
    const viewport = Size(1600, 1000);
    final window = MacWindowState.initial(
      appId: PortfolioAppId.safari,
      cascadeIndex: 0,
      viewport: viewport,
    );
    final maximized = window.toggleMaximized(viewport);
    expect(maximized.maximized, isTrue);
    expect(maximized.frameFor(viewport), MacDesktopMetrics.workArea(viewport));
    final restored = maximized.toggleMaximized(viewport);
    expect(restored.maximized, isFalse);
    expect(restored.frameFor(viewport), window.frameFor(viewport));
    expect(restored.size.width, 1376);
    expect(restored.restoreSize, isNull);
    expect(restored.restorePosition, isNull);
  });
}
