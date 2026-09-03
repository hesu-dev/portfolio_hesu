import 'package:flutter/material.dart';

enum PortfolioThemePreference { light, dark }

class PortfolioThemeController extends ChangeNotifier {
  PortfolioThemeController({
    PortfolioThemePreference initial = PortfolioThemePreference.light,
  }) : _preference = initial;

  PortfolioThemePreference _preference;

  PortfolioThemePreference get preference => _preference;

  ThemeMode get themeMode => _preference == PortfolioThemePreference.light
      ? ThemeMode.light
      : ThemeMode.dark;

  void select(PortfolioThemePreference value) {
    if (_preference == value) {
      return;
    }
    _preference = value;
    notifyListeners();
  }
}
