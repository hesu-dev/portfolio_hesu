import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/theme/portfolio_theme_controller.dart';

void main() {
  group('PortfolioThemePreference', () {
    test('exposes only light and dark choices', () {
      expect(PortfolioThemePreference.values, <PortfolioThemePreference>[
        PortfolioThemePreference.light,
        PortfolioThemePreference.dark,
      ]);
    });
  });

  group('PortfolioThemeController', () {
    test('defaults to the light preference and light theme mode', () {
      final controller = PortfolioThemeController();
      addTearDown(controller.dispose);

      expect(controller.preference, PortfolioThemePreference.light);
      expect(controller.themeMode, ThemeMode.light);
    });

    test('notifies once for a real preference change', () {
      final controller = PortfolioThemeController();
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications += 1);

      controller.select(PortfolioThemePreference.dark);

      expect(controller.preference, PortfolioThemePreference.dark);
      expect(controller.themeMode, ThemeMode.dark);
      expect(notifications, 1);
    });

    test('does not notify when selecting the current preference', () {
      final controller = PortfolioThemeController();
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications += 1);

      controller.select(PortfolioThemePreference.light);

      expect(notifications, 0);
    });

    test('can start with an explicit dark preference', () {
      final controller = PortfolioThemeController(
        initial: PortfolioThemePreference.dark,
      );
      addTearDown(controller.dispose);

      expect(controller.preference, PortfolioThemePreference.dark);
      expect(controller.themeMode, ThemeMode.dark);
    });
  });
}
