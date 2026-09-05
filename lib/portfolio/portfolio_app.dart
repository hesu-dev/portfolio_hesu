import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/music/music_asset_library.dart';
import 'package:portfolio_hesu/portfolio/music/music_controller.dart';
import 'package:portfolio_hesu/portfolio/music/music_playback.dart';
import 'package:portfolio_hesu/portfolio/music/music_track.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/theme/portfolio_theme_controller.dart';
import 'package:portfolio_hesu/portfolio/widgets/adaptive_portfolio_shell.dart';

class PortfolioScrollBehavior extends MaterialScrollBehavior {
  const PortfolioScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => <PointerDeviceKind>{
    ...super.dragDevices,
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

typedef MusicTracksLoader = Future<List<MusicTrack>> Function();

class PortfolioApp extends StatefulWidget {
  const PortfolioApp({
    this.data = portfolioData,
    this.externalLauncher = const UrlLauncherExternalLauncher(),
    this.themeController,
    this.musicController,
    this.musicTracksLoader,
    this.musicPlaybackFactory = createMusicPlayback,
    super.key,
  });

  final PortfolioData data;
  final ExternalLauncher externalLauncher;
  final PortfolioThemeController? themeController;
  final MusicController? musicController;
  final MusicTracksLoader? musicTracksLoader;
  final MusicPlaybackFactory musicPlaybackFactory;

  @override
  State<PortfolioApp> createState() => _PortfolioAppState();
}

class _PortfolioAppState extends State<PortfolioApp> {
  late PortfolioThemeController _themeController;
  late bool _ownsThemeController;
  late MusicController _musicController;
  late bool _ownsMusicController;
  int _musicLoadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _adoptThemeController(widget.themeController);
    _adoptMusicController(widget.musicController);
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
    if (!identical(widget.musicController, oldWidget.musicController) ||
        widget.musicTracksLoader != oldWidget.musicTracksLoader ||
        widget.musicPlaybackFactory != oldWidget.musicPlaybackFactory) {
      final previousController = _musicController;
      final ownedPreviousController = _ownsMusicController;
      _adoptMusicController(widget.musicController);
      if (ownedPreviousController) {
        previousController.dispose();
      }
    }
  }

  void _adoptThemeController(PortfolioThemeController? controller) {
    _ownsThemeController = controller == null;
    _themeController = controller ?? PortfolioThemeController();
  }

  void _adoptMusicController(MusicController? controller) {
    _musicLoadGeneration += 1;
    _ownsMusicController = controller == null;
    _musicController =
        controller ??
        MusicController(
          tracks: const <MusicTrack>[],
          playbackFactory: widget.musicPlaybackFactory,
        );
    if (_ownsMusicController) {
      unawaited(
        _loadMusicTracks(
          controller: _musicController,
          generation: _musicLoadGeneration,
          loader: widget.musicTracksLoader,
        ),
      );
    }
  }

  Future<void> _loadMusicTracks({
    required MusicController controller,
    required int generation,
    required MusicTracksLoader? loader,
  }) async {
    try {
      final tracks = await (loader?.call() ?? const MusicAssetLibrary().load());
      if (!mounted ||
          generation != _musicLoadGeneration ||
          !identical(controller, _musicController) ||
          !_ownsMusicController) {
        return;
      }
      controller.replaceTracks(tracks);
    } catch (_) {
      // A missing or unreadable manifest leaves the Music app in its empty state.
    }
  }

  @override
  void dispose() {
    if (_ownsThemeController) {
      _themeController.dispose();
    }
    _musicLoadGeneration += 1;
    if (_ownsMusicController) {
      _musicController.dispose();
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
        musicController: _musicController,
      ),
      builder: (context, child) => MaterialApp(
        title: widget.data.appTitle,
        color: const Color(0xFFF4F4F7),
        debugShowCheckedModeBanner: false,
        theme: AppleTheme.light(),
        darkTheme: AppleTheme.dark(),
        themeMode: _themeController.themeMode,
        themeAnimationDuration: Duration.zero,
        scrollBehavior: const PortfolioScrollBehavior(),
        home: child,
      ),
    );
  }
}
