import 'package:flutter/widgets.dart';

import '../data/portfolio_data.dart';
import '../models/portfolio_app_id.dart';
import '../music/music_controller.dart';
import '../services/external_launcher.dart';
import '../theme/portfolio_theme_controller.dart';
import '../widgets/apple_finder_scaffold.dart';
import 'about_app.dart';
import 'introduction_app.dart';
import 'music_app.dart';
import 'photos_app.dart';
import 'profile_app.dart';
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
    required this.musicController,
    this.compact = false,
    this.tablet = false,
    this.musicShortcutsEnabled = true,
    this.finderWindowChrome,
    this.onOpenApp,
    this.onClose,
    this.trashEmpty = false,
    this.onTrashEmptied,
    super.key,
  });

  final PortfolioAppId appId;
  final PortfolioData data;
  final ExternalLauncher launcher;
  final PortfolioThemeController themeController;
  final MusicController musicController;
  final bool compact;
  final bool tablet;
  final bool musicShortcutsEnabled;
  final AppleFinderWindowChrome? finderWindowChrome;
  final ValueChanged<PortfolioAppId>? onOpenApp;
  final VoidCallback? onClose;
  final bool trashEmpty;
  final VoidCallback? onTrashEmptied;

  @override
  Widget build(BuildContext context) {
    return switch (appId) {
      PortfolioAppId.profile => ProfileApp(
        data: data,
        launcher: launcher,
        compact: compact,
        tablet: tablet,
        onClose: onClose,
      ),
      PortfolioAppId.about => AboutApp(
        data: data,
        launcher: launcher,
        compact: compact,
        tablet: tablet,
      ),
      PortfolioAppId.introduction => IntroductionApp(
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
        finderWindowChrome: finderWindowChrome,
        onOpenApp: onOpenApp,
      ),
      PortfolioAppId.terminal => TerminalApp(
        data: data,
        compact: compact,
        tablet: tablet,
      ),
      PortfolioAppId.music => MusicApp(
        controller: musicController,
        compact: compact,
        tablet: tablet,
        shortcutsEnabled: musicShortcutsEnabled,
      ),
      PortfolioAppId.photos => PhotosApp(compact: compact, tablet: tablet),
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
        finderWindowChrome: finderWindowChrome,
      ),
      PortfolioAppId.trash => TrashApp(
        data: data,
        compact: compact,
        tablet: tablet,
        trashEmpty: trashEmpty,
        onTrashEmptied: onTrashEmptied,
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
