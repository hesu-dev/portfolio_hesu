import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/macos/mac_desktop.dart';
import 'package:portfolio_hesu/portfolio/mobile/apple_mobile_shell.dart';
import 'package:portfolio_hesu/portfolio/music/music_controller.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/portfolio_theme_controller.dart';

class AdaptivePortfolioShell extends StatefulWidget {
  const AdaptivePortfolioShell({
    required this.externalLauncher,
    required this.themeController,
    required this.musicController,
    this.data = portfolioData,
    this.mobilePlatformOverride,
    super.key,
  });

  static const double iPadBreakpoint = 600;
  static const double macBreakpoint = 1024;

  final ExternalLauncher externalLauncher;
  final PortfolioThemeController themeController;
  final MusicController musicController;
  final PortfolioData data;
  final bool? mobilePlatformOverride;

  @override
  State<AdaptivePortfolioShell> createState() => _AdaptivePortfolioShellState();
}

class _AdaptivePortfolioShellState extends State<AdaptivePortfolioShell> {
  bool _trashEmpty = false;

  bool get _mobilePlatform {
    final override = widget.mobilePlatformOverride;
    if (override != null) {
      return override;
    }
    if (!kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width >= AdaptivePortfolioShell.macBreakpoint && !_mobilePlatform) {
          return MacDesktop(
            data: widget.data,
            externalLauncher: widget.externalLauncher,
            themeController: widget.themeController,
            musicController: widget.musicController,
            trashEmpty: _trashEmpty,
            onTrashEmptied: _emptyTrash,
          );
        }
        if (width >= AdaptivePortfolioShell.iPadBreakpoint) {
          return TooltipVisibility(
            key: const Key('mobile-tooltip-visibility'),
            visible: false,
            child: AppleMobileShell(
              key: const Key('ipad-shell'),
              data: widget.data,
              externalLauncher: widget.externalLauncher,
              themeController: widget.themeController,
              musicController: widget.musicController,
              tablet: true,
              trashEmpty: _trashEmpty,
              onTrashEmptied: _emptyTrash,
            ),
          );
        }
        return TooltipVisibility(
          key: const Key('mobile-tooltip-visibility'),
          visible: false,
          child: AppleMobileShell(
            key: const Key('iphone-shell'),
            data: widget.data,
            externalLauncher: widget.externalLauncher,
            themeController: widget.themeController,
            musicController: widget.musicController,
            tablet: false,
            trashEmpty: _trashEmpty,
            onTrashEmptied: _emptyTrash,
          ),
        );
      },
    );
  }

  void _emptyTrash() {
    if (_trashEmpty) {
      return;
    }
    setState(() => _trashEmpty = true);
  }
}
