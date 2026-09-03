import 'package:flutter/material.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/macos/mac_desktop.dart';
import 'package:portfolio_hesu/portfolio/mobile/apple_mobile_shell.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/portfolio_theme_controller.dart';

class AdaptivePortfolioShell extends StatelessWidget {
  const AdaptivePortfolioShell({
    required this.externalLauncher,
    required this.themeController,
    this.data = portfolioData,
    super.key,
  });

  static const double iPadBreakpoint = 600;
  static const double macBreakpoint = 1024;

  final ExternalLauncher externalLauncher;
  final PortfolioThemeController themeController;
  final PortfolioData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width >= macBreakpoint) {
          return MacDesktop(data: data, externalLauncher: externalLauncher);
        }
        if (width >= iPadBreakpoint) {
          return AppleMobileShell(
            key: const Key('ipad-shell'),
            data: data,
            externalLauncher: externalLauncher,
            tablet: true,
          );
        }
        return AppleMobileShell(
          key: const Key('iphone-shell'),
          data: data,
          externalLauncher: externalLauncher,
          tablet: false,
        );
      },
    );
  }
}
