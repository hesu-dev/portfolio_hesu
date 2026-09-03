import 'package:flutter/material.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';

class AdaptivePortfolioShell extends StatelessWidget {
  const AdaptivePortfolioShell({
    required this.externalLauncher,
    this.data = portfolioData,
    super.key,
  });

  static const double iPadBreakpoint = 600;
  static const double macBreakpoint = 1024;

  final ExternalLauncher externalLauncher;
  final PortfolioData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width >= macBreakpoint) {
          return _PortfolioShellPlaceholder(
            key: const Key('mac-shell'),
            deviceName: 'Mac',
            data: data,
            backgroundColor: const Color(0xFFE8EEF8),
          );
        }
        if (width >= iPadBreakpoint) {
          return _PortfolioShellPlaceholder(
            key: const Key('ipad-shell'),
            deviceName: 'iPad',
            data: data,
            backgroundColor: const Color(0xFFEAF2FF),
          );
        }
        return _PortfolioShellPlaceholder(
          key: const Key('iphone-shell'),
          deviceName: 'iPhone',
          data: data,
          backgroundColor: const Color(0xFFF2F5FA),
        );
      },
    );
  }
}

class _PortfolioShellPlaceholder extends StatelessWidget {
  const _PortfolioShellPlaceholder({
    required this.deviceName,
    required this.data,
    required this.backgroundColor,
    super.key,
  });

  final String deviceName;
  final PortfolioData data;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$deviceName portfolio shell',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(data.name),
              const SizedBox(height: 4),
              const Text('Placeholder'),
            ],
          ),
        ),
      ),
    );
  }
}
