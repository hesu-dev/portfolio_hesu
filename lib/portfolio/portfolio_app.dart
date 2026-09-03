import 'package:flutter/material.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/theme/portfolio_theme_controller.dart';
import 'package:portfolio_hesu/portfolio/widgets/adaptive_portfolio_shell.dart';

class PortfolioApp extends StatefulWidget {
  const PortfolioApp({
    this.data = portfolioData,
    this.externalLauncher = const UrlLauncherExternalLauncher(),
    this.themeController,
    super.key,
  });

  final PortfolioData data;
  final ExternalLauncher externalLauncher;
  final PortfolioThemeController? themeController;

  @override
  State<PortfolioApp> createState() => _PortfolioAppState();
}

class _PortfolioAppState extends State<PortfolioApp> {
  late PortfolioThemeController _themeController;
  late bool _ownsThemeController;

  @override
  void initState() {
    super.initState();
    _adoptThemeController(widget.themeController);
  }

  @override
  void didUpdateWidget(PortfolioApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.themeController, oldWidget.themeController)) {
      final previousController = _themeController;
      final ownedPreviousController = _ownsThemeController;
      _adoptThemeController(widget.themeController);
      if (ownedPreviousController) {
        previousController.dispose();
      }
    }
  }

  void _adoptThemeController(PortfolioThemeController? controller) {
    _ownsThemeController = controller == null;
    _themeController = controller ?? PortfolioThemeController();
  }

  @override
  void dispose() {
    if (_ownsThemeController) {
      _themeController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeController,
      child: AdaptivePortfolioShell(
        data: widget.data,
        externalLauncher: widget.externalLauncher,
        themeController: _themeController,
      ),
      builder: (context, child) => MaterialApp(
        title: widget.data.appTitle,
        color: const Color(0xFF121316),
        debugShowCheckedModeBanner: false,
        theme: AppleTheme.light(),
        darkTheme: AppleTheme.dark(),
        themeMode: _themeController.themeMode,
        themeAnimationDuration: Duration.zero,
        home: child,
      ),
    );
  }
}
