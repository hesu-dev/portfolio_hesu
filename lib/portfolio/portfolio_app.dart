import 'package:flutter/material.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/widgets/adaptive_portfolio_shell.dart';

class PortfolioApp extends StatelessWidget {
  const PortfolioApp({
    this.externalLauncher = const UrlLauncherExternalLauncher(),
    super.key,
  });

  final ExternalLauncher externalLauncher;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: portfolioData.appTitle,
      color: const Color(0xFF121316),
      debugShowCheckedModeBanner: false,
      theme: AppleTheme.light(),
      darkTheme: AppleTheme.dark(),
      themeMode: ThemeMode.system,
      home: AdaptivePortfolioShell(
        data: portfolioData,
        externalLauncher: externalLauncher,
      ),
    );
  }
}
