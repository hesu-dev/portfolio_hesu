import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/music/music_controller.dart';
import 'package:portfolio_hesu/portfolio/music/music_playback.dart';
import 'package:portfolio_hesu/portfolio/music/music_session_store.dart';
import 'package:portfolio_hesu/portfolio/music/music_track.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';
import 'package:portfolio_hesu/portfolio/portfolio_app.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';

void main() {
  const tracks = <MusicTrack>[
    MusicTrack(assetPath: 'assets/music/01-first.mp3', title: 'First Song'),
    MusicTrack(assetPath: 'assets/music/02-second.mp3', title: 'Second Song'),
  ];

  testWidgets('global music state survives window close and shell resize', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1440, 900));
    final playback = _FakePlayback();
    final controller = MusicController(
      tracks: tracks,
      playbackFactory: () => playback,
      sessionStore: _FakeSessionStore(),
    );
    addTearDown(controller.dispose);
    var loaderCalls = 0;

    await tester.pumpWidget(
      PortfolioApp(
        externalLauncher: const _FakeLauncher(),
        musicController: controller,
        musicTracksLoader: () async {
          loaderCalls += 1;
          return const <MusicTrack>[];
        },
      ),
    );
    await tester.pump();

    await _openDesktopMusic(tester);
    await tester.tap(find.byKey(const Key('music-next')));
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 1);
    expect(controller.isPlaying, isFalse);
    expect(find.text('Second Song'), findsWidgets);

    await tester.tap(find.byKey(const Key('window-close-music')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('music-app')), findsNothing);
    expect(controller.currentIndex, 1);
    expect(controller.isPlaying, isFalse);

    await _openDesktopMusic(tester);
    expect(find.text('Second Song'), findsWidgets);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    await tester.tap(find.byKey(const Key('music-play-pause')));
    await tester.pumpAndSettle();
    expect(controller.isPlaying, isTrue);
    expect(playback.playedTracks, <MusicTrack>[tracks[1]]);

    await tester.tap(find.byKey(const Key('window-close-music')));
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 1);
    expect(controller.isPlaying, isTrue);

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-app-music')), findsOneWidget);
    await tester.tap(find.byKey(const Key('home-app-music')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('music-app')), findsOneWidget);
    expect(find.text('Second Song'), findsWidgets);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    expect(controller.currentIndex, 1);
    expect(controller.isPlaying, isTrue);
    expect(loaderCalls, 0);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(playback.disposeCalls, 0);
  });

  testWidgets('owned controller loads assets lazily and is disposed by root', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1440, 900));
    final playback = _FakePlayback();
    var factoryCalls = 0;
    var loaderCalls = 0;

    await tester.pumpWidget(
      PortfolioApp(
        externalLauncher: const _FakeLauncher(),
        musicTracksLoader: () async {
          loaderCalls += 1;
          return tracks;
        },
        musicPlaybackFactory: () {
          factoryCalls += 1;
          return playback;
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(loaderCalls, 1);
    expect(factoryCalls, 0);

    await _openDesktopMusic(tester);
    expect(find.text('First Song'), findsWidgets);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(factoryCalls, 0);

    await tester.tap(find.byKey(const Key('music-play-pause')));
    await tester.pumpAndSettle();
    expect(factoryCalls, 1);
    expect(playback.playedTracks, <MusicTrack>[tracks.first]);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    expect(playback.disposeCalls, 1);
  });

  testWidgets('desktop window hands keyboard focus to music shortcuts', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1440, 900));
    final playback = _FakePlayback();
    final controller = MusicController(
      tracks: tracks,
      playbackFactory: () => playback,
      sessionStore: _FakeSessionStore(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      PortfolioApp(
        externalLauncher: const _FakeLauncher(),
        musicController: controller,
      ),
    );
    await tester.pumpAndSettle();
    await _openDesktopMusic(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(controller.isPlaying, isTrue);
    expect(playback.playedTracks, <MusicTrack>[tracks[1]]);
  });

  testWidgets('desktop music restores shortcut focus after Dock restore', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1440, 900));
    final controller = MusicController(
      tracks: tracks,
      playbackFactory: _FakePlayback.new,
      sessionStore: _FakeSessionStore(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      PortfolioApp(
        externalLauncher: const _FakeLauncher(),
        musicController: controller,
      ),
    );
    await tester.pumpAndSettle();
    await _openDesktopMusic(tester);

    await tester.tap(find.byKey(const Key('window-minimize-music')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('music-app')), findsNothing);

    await tester.tap(find.byKey(const Key('dock-app-music')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('music-app')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    expect(controller.currentIndex, 1);
  });

  testWidgets('inactive desktop music does not capture shortcuts', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1440, 900));
    final controller = MusicController(
      tracks: tracks,
      playbackFactory: _FakePlayback.new,
      sessionStore: _FakeSessionStore(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      PortfolioApp(
        externalLauncher: const _FakeLauncher(),
        musicController: controller,
      ),
    );
    await tester.pumpAndSettle();
    await _openDesktopApp(tester, PortfolioAppId.about);
    await _openDesktopMusic(tester);

    final aboutRect = tester.getRect(find.byKey(const Key('mac-window-about')));
    await tester.tapAt(Offset(aboutRect.center.dx, aboutRect.top + 10));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mac-window-active-about')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(controller.isPlaying, isFalse);
  });
}

Future<void> _setViewport(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<void> _openDesktopMusic(WidgetTester tester) async {
  await _openDesktopApp(tester, PortfolioAppId.music);
  expect(find.byKey(const Key('music-app')), findsOneWidget);
}

Future<void> _openDesktopApp(WidgetTester tester, PortfolioAppId appId) async {
  final icon = find.byKey(Key('desktop-app-${appId.name}'));
  expect(icon, findsOneWidget);
  await tester.tap(icon);
  await tester.pump(const Duration(milliseconds: 80));
  await tester.tap(icon);
  await tester.pumpAndSettle();
  expect(find.byKey(Key('mac-window-${appId.name}')), findsOneWidget);
}

class _FakePlayback implements MusicPlayback {
  final List<MusicTrack> playedTracks = <MusicTrack>[];
  final StreamController<void> _completionController =
      StreamController<void>.broadcast();
  var disposeCalls = 0;

  @override
  Stream<void> get onComplete => _completionController.stream;

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
    await _completionController.close();
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> play(MusicTrack track) async {
    playedTracks.add(track);
  }

  @override
  Future<void> resume() async {}

  @override
  Future<void> setVolume(double volume) async {}
}

class _FakeSessionStore implements MusicSessionStore {
  MusicSessionState? _state;

  @override
  MusicSessionState? read() => _state;

  @override
  void write(MusicSessionState state) => _state = state;
}

final class _FakeLauncher implements ExternalLauncher {
  const _FakeLauncher();

  @override
  Future<bool> launch(Uri uri) async => true;
}
