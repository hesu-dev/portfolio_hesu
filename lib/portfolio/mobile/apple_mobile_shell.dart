import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../services/external_launcher.dart';
import 'apple_home_grid.dart';
import 'apple_mobile_dock.dart';
import 'apple_status_bar.dart';

class AppleMobileShell extends StatelessWidget {
  const AppleMobileShell({
    required this.data,
    required this.externalLauncher,
    required this.tablet,
    super.key,
  });

  final PortfolioData data;
  final ExternalLauncher externalLauncher;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SizedBox.expand(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: _AppleMobileWallpaper(
                tablet: tablet,
                dark: Theme.of(context).brightness == Brightness.dark,
              ),
            ),
            SafeArea(
              child: Column(
                children: <Widget>[
                  AppleStatusBar(tablet: tablet),
                  Expanded(
                    child: KeyedSubtree(
                      key: const Key('mobile-home'),
                      child: Stack(
                        children: <Widget>[
                          Positioned.fill(
                            child: AppleHomeGrid(
                              data: data,
                              tablet: tablet,
                              onOpen: (_) {},
                            ),
                          ),
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: tablet ? 14 : 9,
                            child: Center(
                              child: AppleMobileDock(
                                tablet: tablet,
                                onOpen: (_) {},
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const _AppleHomeIndicator(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppleHomeIndicator extends StatelessWidget {
  const _AppleHomeIndicator();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('mobile-home-indicator'),
      label: 'Home indicator',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 5, 0, 7),
        child: Container(
          width: 118,
          height: 5,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.82)
                : Colors.black.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _AppleMobileWallpaper extends StatelessWidget {
  const _AppleMobileWallpaper({required this.tablet, required this.dark});

  final bool tablet;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: const Key('mobile-wallpaper'),
      child: CustomPaint(
        painter: _AbstractWallpaperPainter(tablet: tablet, dark: dark),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _AbstractWallpaperPainter extends CustomPainter {
  const _AbstractWallpaperPainter({required this.tablet, required this.dark});

  final bool tablet;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dark
            ? const <Color>[
                Color(0xFF10192B),
                Color(0xFF18253A),
                Color(0xFF10141F),
              ]
            : const <Color>[
                Color(0xFFE9F7FF),
                Color(0xFFE9E9FF),
                Color(0xFFFFEFF8),
              ],
        stops: const <double>[0, 0.54, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);

    _drawGlow(
      canvas,
      center: Offset(size.width * 0.15, size.height * 0.18),
      radius: size.shortestSide * (tablet ? 0.48 : 0.62),
      color: const Color(0xFF5CCBFF),
    );
    _drawGlow(
      canvas,
      center: Offset(size.width * 0.9, size.height * 0.42),
      radius: size.shortestSide * (tablet ? 0.56 : 0.7),
      color: const Color(0xFF7C6CFF),
    );
    _drawGlow(
      canvas,
      center: Offset(size.width * 0.38, size.height * 0.92),
      radius: size.shortestSide * (tablet ? 0.55 : 0.78),
      color: const Color(0xFFFF78B4),
    );
  }

  void _drawGlow(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          color.withValues(alpha: dark ? 0.34 : 0.3),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _AbstractWallpaperPainter oldDelegate) {
    return tablet != oldDelegate.tablet || dark != oldDelegate.dark;
  }
}
