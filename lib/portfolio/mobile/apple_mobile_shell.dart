import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/portfolio_data.dart';
import '../models/portfolio_app_id.dart';
import '../music/music_controller.dart';
import '../services/external_launcher.dart';
import '../theme/portfolio_theme_controller.dart';
import '../theme/apple_theme.dart';
import '../widgets/portfolio_guide_button.dart';
import 'apple_home_grid.dart';
import 'apple_mobile_dock.dart';
import 'apple_mobile_dock_geometry.dart';
import 'apple_mobile_search.dart';
// import 'apple_status_bar.dart';
import 'mobile_app_surface.dart';

typedef AppleNow = DateTime Function();

DateTime _systemNow() => DateTime.now();

class AppleMobileShell extends StatefulWidget {
  const AppleMobileShell({
    required this.data,
    required this.externalLauncher,
    required this.themeController,
    required this.musicController,
    required this.tablet,
    this.trashEmpty = false,
    this.onTrashEmptied,
    this.now = _systemNow,
    this.clockTickInterval = const Duration(seconds: 30),
    super.key,
  });

  final PortfolioData data;
  final ExternalLauncher externalLauncher;
  final PortfolioThemeController themeController;
  final MusicController musicController;
  final bool tablet;
  final bool trashEmpty;
  final VoidCallback? onTrashEmptied;
  final AppleNow now;
  final Duration clockTickInterval;

  @override
  State<AppleMobileShell> createState() => _AppleMobileShellState();
}

class _AppleMobileShellState extends State<AppleMobileShell>
    with WidgetsBindingObserver {
  final List<PortfolioAppId> _appStack = <PortfolioAppId>[];
  Timer? _clockTimer;
  late DateTime _now;
  bool _searchOpen = false;
  double _homeDragDistance = 0;

  Future<void> _showSearch() async {
    if (_searchOpen || _appStack.isNotEmpty) return;
    _searchOpen = true;
    final app = await showGeneralDialog<PortfolioAppId>(
      context: context,
      barrierColor: Colors.transparent,
      barrierLabel: '검색 닫기',
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (context, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
      pageBuilder: (context, _, _) => AppleMobileSearch(
        tablet: widget.tablet,
        trashEmpty: widget.trashEmpty,
        onOpenApp: (app) => Navigator.of(context).pop(app),
        onClose: () => Navigator.of(context).pop(),
      ),
    );
    _searchOpen = false;
    if (mounted && app != null) _openApp(app);
  }

  bool get _usesNativeHomeIndicator =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _restartClock();
    if (_usesNativeHomeIndicator) {
      WidgetsBinding.instance.addObserver(this);
      _enableNativeHomeIndicatorAutoHide();
    }
  }

  void _enableNativeHomeIndicatorAutoHide() {
    // iOS owns the indicator's position and fade; keep the status bar visible.
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: const [SystemUiOverlay.top],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_usesNativeHomeIndicator && state == AppLifecycleState.resumed) {
      _enableNativeHomeIndicatorAutoHide();
    }
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
    WidgetsBinding.instance.removeObserver(this);
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
              bottom: activeApp == null,
              child: Column(
                children: <Widget>[
                  // 실제 기기 상태바와 중복되어 임시로 숨김. 복원 시 import도 해제.
                  // AppleStatusBar(tablet: widget.tablet, now: _now),
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
                                                bottom: 0,
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
                                                musicController:
                                                    widget.musicController,
                                                tablet: widget.tablet,
                                                trashEmpty: widget.trashEmpty,
                                                onTrashEmptied:
                                                    widget.onTrashEmptied,
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
                  if (activeApp == null)
                    if (_usesNativeHomeIndicator)
                      const SizedBox(
                        height: AppleMobileDockGeometry.homeIndicatorExtent,
                      )
                    else
                      const _AppleHomeIndicator(),
                ],
              ),
            ),
            if (activeApp != null && !_usesNativeHomeIndicator)
              Positioned.fill(
                child: IgnorePointer(
                  child: SafeArea(
                    top: false,
                    left: false,
                    right: false,
                    child: const Align(
                      alignment: Alignment.bottomCenter,
                      child: _AppleHomeIndicator(),
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              key: const ValueKey('floating-portfolio-guide'),
              child: PortfolioGuideButton(
                onOpenApp: _openApp,
                initialRight: 16,
                initialBottom:
                    AppleMobileDockGeometry.homeIndicatorExtent +
                    AppleMobileDockGeometry.homeBottomOffset(
                      tablet: widget.tablet,
                    ) +
                    AppleMobileDockGeometry.height(tablet: widget.tablet) +
                    12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHome() {
    final dockBottom = AppleMobileDockGeometry.homeBottomOffset(
      tablet: widget.tablet,
    );
    final dockHeight = AppleMobileDockGeometry.height(tablet: widget.tablet);
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent && event.scrollDelta.dy > 0) {
          unawaited(_showSearch());
        }
      },
      child: GestureDetector(
        key: const Key('mobile-home'),
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) => _homeDragDistance = 0,
        onVerticalDragUpdate: (details) {
          _homeDragDistance += details.delta.dy;
          if (_homeDragDistance >= 48) unawaited(_showSearch());
        },
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              bottom: dockBottom + dockHeight + 68,
              child: AppleHomeGrid(
                data: widget.data,
                tablet: widget.tablet,
                trashEmpty: widget.trashEmpty,
                onOpen: _openApp,
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: dockBottom + dockHeight + 12,
              height: 44,
              child: Center(
                child: TextButton.icon(
                  key: const Key('mobile-home-search'),
                  onPressed: () => unawaited(_showSearch()),
                  style: TextButton.styleFrom(
                    foregroundColor: AppleTheme.primaryLabel(context),
                    backgroundColor: AppleTheme.surface(
                      context,
                    ).withValues(alpha: 0.5),
                    minimumSize: const Size(90, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(CupertinoIcons.search, size: 16),
                  label: const Text('검색'),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: dockBottom,
              child: Center(
                child: AppleMobileDock(
                  data: widget.data,
                  tablet: widget.tablet,
                  onOpen: _openApp,
                ),
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
