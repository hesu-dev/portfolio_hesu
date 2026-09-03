import 'package:flutter/material.dart';
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
      title: 'Min He-su Portfolio',
      debugShowCheckedModeBanner: false,
      theme: AppleTheme.light(),
      darkTheme: AppleTheme.dark(),
      themeMode: ThemeMode.system,
      home: AdaptivePortfolioShell(externalLauncher: externalLauncher),
    );
  }
}
