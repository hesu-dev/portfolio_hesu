import 'dart:async';

import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../models/portfolio_app_id.dart';
import '../services/external_launcher.dart';
import '../theme/portfolio_theme_controller.dart';
import 'apple_home_grid.dart';
import 'apple_mobile_dock.dart';
import 'apple_status_bar.dart';
import 'mobile_app_surface.dart';

typedef AppleNow = DateTime Function();

DateTime _systemNow() => DateTime.now();

class AppleMobileShell extends StatefulWidget {
  const AppleMobileShell({
    required this.data,
    required this.externalLauncher,
    required this.themeController,
    required this.tablet,
    this.now = _systemNow,
    this.clockTickInterval = const Duration(seconds: 30),
    super.key,
  });

  final PortfolioData data;
  final ExternalLauncher externalLauncher;
  final PortfolioThemeController themeController;
  final bool tablet;
  final AppleNow now;
  final Duration clockTickInterval;

  @override
  State<AppleMobileShell> createState() => _AppleMobileShellState();
}

class _AppleMobileShellState extends State<AppleMobileShell> {
  final List<PortfolioAppId> _appStack = <PortfolioAppId>[];
  Timer? _clockTimer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _restartClock();
  }

  @override
  void didUpdateWidget(covariant AppleMobileShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.now != widget.now ||
        oldWidget.clockTickInterval != widget.clockTickInterval) {
      _restartClock();
    }
  }

  void _restartClock() {
    _clockTimer?.cancel();
    _now = widget.now();
    _clockTimer = Timer.periodic(widget.clockTickInterval, (_) {
      if (!mounted) {
        return;
      }
      final next = widget.now();
      if (_showsSameTimeAndDate(_now, next)) {
        return;
      }
      setState(() => _now = next);
    });
  }

  bool _showsSameTimeAndDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day &&
        first.hour == second.hour &&
        first.minute == second.minute;
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _openApp(PortfolioAppId appId) {
    if (_appStack.length == 1 && _appStack.last == appId) {
      return;
    }
    setState(() {
      _appStack
        ..clear()
        ..add(appId);
    });
  }

  void _openAppWindow(PortfolioAppId appId) {
    setState(() => _appStack.add(appId));
  }

  void _closeApp() {
    if (_appStack.isEmpty) {
      return;
    }
    setState(() => _appStack.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    final activeApp = _appStack.isEmpty ? null : _appStack.last;

    return Material(
      type: MaterialType.transparency,
      child: SizedBox.expand(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: _AppleMobileWallpaper(
                tablet: widget.tablet,
                dark: Theme.of(context).brightness == Brightness.dark,
              ),
            ),
            SafeArea(
              child: Column(
                children: <Widget>[
                  AppleStatusBar(tablet: widget.tablet, now: _now),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      reverseDuration: const Duration(milliseconds: 190),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.985, end: 1).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: activeApp == null
                          ? _buildHome()
                          : SizedBox.expand(
                              key: const ValueKey<String>(
                                'mobile-window-stack',
                              ),
                              child: Stack(
                                children: <Widget>[
                                  for (
                                    var index = 0;
                                    index < _appStack.length;
                                    index++
                                  )
                                    Positioned.fill(
                                      child: Padding(
                                        padding: widget.tablet && index > 0
                                            ? EdgeInsets.only(
                                                left: index * 12,
                                                top: index * 10,
                                                right: index * 4,
                                                bottom: index * 4,
                                              )
                                            : EdgeInsets.zero,
                                        child: IgnorePointer(
                                          ignoring:
                                              index != _appStack.length - 1,
                                          child: ExcludeFocus(
                                            excluding:
                                                index != _appStack.length - 1,
                                            child: ExcludeSemantics(
                                              excluding:
                                                  index != _appStack.length - 1,
                                              child: MobileAppSurface(
                                                key: ValueKey<String>(
                                                  'mobile-window-$index-'
                                                  '${_appStack[index].name}',
                                                ),
                                                appId: _appStack[index],
                                                data: widget.data,
                                                launcher:
                                                    widget.externalLauncher,
                                                themeController:
                                                    widget.themeController,
                                                tablet: widget.tablet,
                                                onClose: _closeApp,
                                                onOpenApp: _openAppWindow,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
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

  Widget _buildHome() {
    return SizedBox.expand(
      key: const Key('mobile-home'),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: AppleHomeGrid(
              data: widget.data,
              tablet: widget.tablet,
              onOpen: _openApp,
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: widget.tablet ? 14 : 9,
            child: Center(
              child: AppleMobileDock(tablet: widget.tablet, onOpen: _openApp),
            ),
          ),
        ],
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
