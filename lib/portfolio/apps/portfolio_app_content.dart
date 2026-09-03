import 'package:flutter/widgets.dart';

import '../data/portfolio_data.dart';
import '../models/portfolio_app_id.dart';
import '../services/external_launcher.dart';
import '../theme/portfolio_theme_controller.dart';
import 'about_app.dart';
import 'projects_app.dart';
import 'settings_app.dart';
import 'skills_app.dart';
import 'system_apps.dart';
import 'terminal_app.dart';

/// Routes an app identifier to a shell-independent portfolio surface.
class PortfolioAppContent extends StatelessWidget {
  const PortfolioAppContent({
    required this.appId,
    required this.data,
    required this.launcher,
    required this.themeController,
    this.compact = false,
    this.tablet = false,
    super.key,
  });

  final PortfolioAppId appId;
  final PortfolioData data;
  final ExternalLauncher launcher;
  final PortfolioThemeController themeController;
  final bool compact;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    return switch (appId) {
      PortfolioAppId.about => AboutApp(
        data: data,
        launcher: launcher,
        compact: compact,
        tablet: tablet,
      ),
      PortfolioAppId.skills => SkillsApp(
        data: data,
        compact: compact,
        tablet: tablet,
      ),
      PortfolioAppId.projects => ProjectsApp(
        data: data,
        launcher: launcher,
        compact: compact,
        tablet: tablet,
      ),
      PortfolioAppId.terminal => TerminalApp(
        data: data,
        compact: compact,
        tablet: tablet,
      ),
      PortfolioAppId.settings => SettingsApp(
        data: data,
        themeController: themeController,
        compact: compact,
        tablet: tablet,
      ),
      PortfolioAppId.thisMac => ThisMacApp(
        data: data,
        compact: compact,
        tablet: tablet,
      ),
      PortfolioAppId.trash => TrashApp(
        data: data,
        compact: compact,
        tablet: tablet,
      ),
      PortfolioAppId.github => GitHubApp(
        data: data,
        launcher: launcher,
        compact: compact,
        tablet: tablet,
      ),
      PortfolioAppId.mail => MailApp(
        data: data,
        launcher: launcher,
        compact: compact,
        tablet: tablet,
      ),
    };
  }
}
