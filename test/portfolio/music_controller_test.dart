import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/music/music_controller.dart';
import 'package:portfolio_hesu/portfolio/music/music_playback.dart';
import 'package:portfolio_hesu/portfolio/music/music_session_store.dart';
import 'package:portfolio_hesu/portfolio/music/music_track.dart';

void main() {
  const tracks = <MusicTrack>[
    MusicTrack(assetPath: 'assets/music/01-first.mp3', title: 'First'),
    MusicTrack(assetPath: 'assets/music/02-second.mp3', title: 'Second'),
  ];

  group('MusicController', () {
    test('starts paused and creates playback lazily', () {
      var factoryCalls = 0;
      final controller = MusicController(
        tracks: tracks,
        playbackFactory: () {
          factoryCalls += 1;
          return _FakePlayback();
        },
      );

      expect(controller.isPlaying, isFalse);
      expect(controller.currentIndex, 0);
      expect(factoryCalls, 0);

      controller.dispose();
    });

    test('restores selection, mode, and volume without autoplay', () {
      final store = _FakeSessionStore(
        const MusicSessionState(
          currentIndex: 1,
          mode: MusicPlaybackMode.repeatOne,
          volume: 0.35,
        ),
      );
      var factoryCalls = 0;
      final controller = MusicController(
        tracks: tracks,
        playbackFactory: () {
          factoryCalls += 1;
          return _FakePlayback();
        },
        sessionStore: store,
      );

      expect(controller.currentIndex, 1);
      expect(controller.mode, MusicPlaybackMode.repeatOne);
      expect(controller.volume, 0.35);
      expect(controller.isPlaying, isFalse);
      expect(factoryCalls, 0);

      controller.dispose();
    });

    test('ignores invalid restored values', () {
      final controller = MusicController(
        tracks: tracks,
        playbackFactory: _FakePlayback.new,
        sessionStore: _FakeSessionStore(
          const MusicSessionState(
            currentIndex: 99,
            mode: MusicPlaybackMode.queue,
            volume: 2,
          ),
        ),
      );

      expect(controller.currentIndex, 0);
      expect(controller.volume, 1);

      controller.dispose();
    });

    test('play starts the selected track after user action', () async {
      final playback = _FakePlayback();
      final controller = MusicController(
        tracks: tracks,
        playbackFactory: () => playback,
      );

      await controller.play();

      expect(controller.isPlaying, isTrue);
      expect(playback.playedTracks, <MusicTrack>[tracks.first]);

      controller.dispose();
      await playback.dispose();
    });

    test('play after pause resumes instead of restarting the track', () async {
      final playback = _FakePlayback();
      final controller = MusicController(
        tracks: tracks,
        playbackFactory: () => playback,
      );

      await controller.play();
      await controller.pause();
      await controller.play();

      expect(playback.playedTracks, <MusicTrack>[tracks.first]);
      expect(playback.resumeCalls, 1);
      expect(controller.isPlaying, isTrue);

      controller.dispose();
      await playback.dispose();
    });

    test('a pending play cannot overwrite a later pause intent', () async {
      final firstPlayGate = Completer<void>();
      final playback = _FakePlayback(firstPlayGate: firstPlayGate);
      final controller = MusicController(
        tracks: tracks,
        playbackFactory: () => playback,
      );

      final playFuture = controller.play();
      await pumpEventQueue();
      final pauseFuture = controller.pause();
      expect(controller.isPlaying, isFalse);

      firstPlayGate.complete();
      await Future.wait(<Future<void>>[playFuture, pauseFuture]);

      expect(controller.isPlaying, isFalse);
      expect(playback.pauseCalls, 1);

      controller.dispose();
      await playback.dispose();
    });

    test('skips a queued play that is stale before it starts', () async {
      final playback = _FakePlayback();
      final controller = MusicController(
        tracks: tracks,
        playbackFactory: () => playback,
      );

      final playFuture = controller.play();
      final pauseFuture = controller.pause();
      await Future.wait(<Future<void>>[playFuture, pauseFuture]);

      expect(playback.playedTracks, isEmpty);
      expect(controller.isPlaying, isFalse);

      controller.dispose();
      await playback.dispose();
    });

    test(
      'navigation during pending play finishes on the selected track',
      () async {
        final firstPlayGate = Completer<void>();
        final playback = _FakePlayback(firstPlayGate: firstPlayGate);
        final controller = MusicController(
          tracks: tracks,
          playbackFactory: () => playback,
        );

        final playFuture = controller.play();
        await pumpEventQueue();
        final nextFuture = controller.next();
        expect(controller.currentTrack, tracks[1]);

        firstPlayGate.complete();
        await Future.wait(<Future<void>>[playFuture, nextFuture]);

        expect(playback.playedTracks, <MusicTrack>[tracks[0], tracks[1]]);
        expect(controller.currentTrack, tracks[1]);
        expect(controller.isPlaying, isTrue);

        controller.dispose();
        await playback.dispose();
      },
    );

    test(
      'dispose waits for an active command before disposing playback',
      () async {
        final firstPlayGate = Completer<void>();
        final playback = _FakePlayback(firstPlayGate: firstPlayGate);
        final controller = MusicController(
          tracks: tracks,
          playbackFactory: () => playback,
        );

        final playFuture = controller.play();
        await pumpEventQueue();
        controller.dispose();
        expect(playback.disposeCalls, 0);

        firstPlayGate.complete();
        await playFuture;
        await pumpEventQueue();

        expect(playback.disposeCalls, 1);
        expect(playback.completedPlayAfterDispose, isFalse);
      },
    );

    test(
      'queue completion advances and wraps while remaining active',
      () async {
        final playback = _FakePlayback();
        final controller = MusicController(
          tracks: tracks,
          playbackFactory: () => playback,
        );
        await controller.play();

        playback.complete();
        await pumpEventQueue();
        playback.complete();
        await pumpEventQueue();

        expect(playback.playedTracks, <MusicTrack>[
          tracks[0],
          tracks[1],
          tracks[0],
        ]);
        expect(controller.currentIndex, 0);
        expect(controller.isPlaying, isTrue);
        expect(controller.navigationDirection, MusicNavigationDirection.next);
        expect(controller.navigationRevision, 2);

        controller.dispose();
        await playback.dispose();
      },
    );

    test('repeat-one completion restarts only the selected track', () async {
      final playback = _FakePlayback();
      final controller = MusicController(
        tracks: tracks,
        playbackFactory: () => playback,
      );
      controller.setMode(MusicPlaybackMode.repeatOne);
      await controller.play();

      playback.complete();
      await pumpEventQueue();

      expect(playback.playedTracks, <MusicTrack>[tracks[0], tracks[0]]);
      expect(controller.currentIndex, 0);
      expect(controller.navigationRevision, 0);

      controller.dispose();
      await playback.dispose();
    });

    test('previous and next wrap at both ends', () async {
      final controller = MusicController(
        tracks: tracks,
        playbackFactory: _FakePlayback.new,
      );

      await controller.previous();
      expect(controller.currentIndex, 1);
      expect(controller.navigationDirection, MusicNavigationDirection.previous);

      await controller.next();
      expect(controller.currentIndex, 0);
      expect(controller.navigationDirection, MusicNavigationDirection.next);

      controller.dispose();
    });

    test('navigation keeps playing but only selects while paused', () async {
      final playback = _FakePlayback();
      final controller = MusicController(
        tracks: tracks,
        playbackFactory: () => playback,
      );

      await controller.next();
      expect(playback.playedTracks, isEmpty);

      await controller.play();
      await controller.next();
      expect(playback.playedTracks, <MusicTrack>[tracks[1], tracks[0]]);
      expect(controller.isPlaying, isTrue);

      await controller.pause();
      await controller.next();
      expect(playback.playedTracks, <MusicTrack>[tracks[1], tracks[0]]);
      expect(controller.currentIndex, 1);
      expect(controller.isPlaying, isFalse);

      controller.dispose();
      await playback.dispose();
    });

    test('select changes the track and restarts only while playing', () async {
      final store = _FakeSessionStore();
      final playback = _FakePlayback();
      final controller = MusicController(
        tracks: tracks,
        playbackFactory: () => playback,
        sessionStore: store,
      );

      await controller.select(1);
      expect(controller.currentIndex, 1);
      expect(controller.navigationRevision, 1);
      expect(controller.navigationDirection, MusicNavigationDirection.next);
      expect(playback.playedTracks, isEmpty);

      await controller.play();
      await controller.select(0);
      expect(controller.currentIndex, 0);
      expect(controller.navigationRevision, 2);
      expect(controller.navigationDirection, MusicNavigationDirection.previous);
      expect(playback.playedTracks, <MusicTrack>[tracks[1], tracks[0]]);
      expect(store.state?.currentIndex, 0);

      controller.dispose();
      await playback.dispose();
    });

    test('navigation after an unawaited pause still pauses playback', () async {
      final playback = _FakePlayback();
      final controller = MusicController(
        tracks: tracks,
        playbackFactory: () => playback,
      );

      await controller.play();
      final pauseFuture = controller.pause();
      final navigationFuture = controller.next();
      await Future.wait(<Future<void>>[pauseFuture, navigationFuture]);

      expect(controller.currentIndex, 1);
      expect(controller.isPlaying, isFalse);
      expect(playback.pauseCalls, 1);
      expect(playback.playedTracks, <MusicTrack>[tracks[0]]);

      controller.dispose();
      await playback.dispose();
    });

    test('selection after an unawaited pause still pauses playback', () async {
      final playback = _FakePlayback();
      final controller = MusicController(
        tracks: tracks,
        playbackFactory: () => playback,
      );

      await controller.play();
      final pauseFuture = controller.pause();
      final selectionFuture = controller.select(1);
      await Future.wait(<Future<void>>[pauseFuture, selectionFuture]);

      expect(controller.currentIndex, 1);
      expect(controller.isPlaying, isFalse);
      expect(playback.pauseCalls, 1);
      expect(playback.playedTracks, <MusicTrack>[tracks[0]]);

      controller.dispose();
      await playback.dispose();
    });

    test('every navigation changes revision even with one track', () async {
      final controller = MusicController(
        tracks: tracks.take(1).toList(),
        playbackFactory: _FakePlayback.new,
      );

      await controller.next();
      expect(controller.navigationRevision, 1);
      expect(controller.navigationDirection, MusicNavigationDirection.next);
      await controller.next();
      expect(controller.navigationRevision, 2);
      await controller.previous();
      expect(controller.navigationRevision, 3);
      expect(controller.navigationDirection, MusicNavigationDirection.previous);

      controller.dispose();
    });

    test('persists selection, mode, and volume', () async {
      final store = _FakeSessionStore();
      final controller = MusicController(
        tracks: tracks,
        playbackFactory: _FakePlayback.new,
        sessionStore: store,
      );

      await controller.next();
      controller.setMode(MusicPlaybackMode.repeatOne);
      await controller.setVolume(0.4);

      expect(
        store.state,
        const MusicSessionState(
          currentIndex: 1,
          mode: MusicPlaybackMode.repeatOne,
          volume: 0.4,
        ),
      );

      controller.dispose();
    });

    test('the non-web default store retains state for its lifetime', () {
      final store = createMusicSessionStore();
      const state = MusicSessionState(
        currentIndex: 1,
        mode: MusicPlaybackMode.repeatOne,
        volume: 0.4,
      );

      store.write(state);

      expect(store.read(), state);
    });

    test('playback failure pauses and exposes a safe message', () async {
      final playback = _FakePlayback(playError: StateError('device details'));
      final controller = MusicController(
        tracks: tracks,
        playbackFactory: () => playback,
      );

      await controller.play();

      expect(controller.isPlaying, isFalse);
      expect(controller.errorMessage, '음악을 재생할 수 없습니다.');
      expect(controller.errorMessage, isNot(contains('device details')));

      controller.dispose();
      await playback.dispose();
    });

    test(
      'an unrelated volume update keeps the playback error visible',
      () async {
        final playback = _FakePlayback(playError: StateError('device details'));
        final controller = MusicController(
          tracks: tracks,
          playbackFactory: () => playback,
        );

        await controller.play();
        await controller.setVolume(0.5);

        expect(controller.errorMessage, MusicController.playbackErrorMessage);

        controller.dispose();
        await playback.dispose();
      },
    );
  });
}

class _FakePlayback implements MusicPlayback {
  _FakePlayback({this.playError, this.firstPlayGate});

  final Object? playError;
  final Completer<void>? firstPlayGate;
  final StreamController<void> _completeController =
      StreamController<void>.broadcast();
  final List<MusicTrack> playedTracks = <MusicTrack>[];
  double? lastVolume;
  var pauseCalls = 0;
  var resumeCalls = 0;
  var disposeCalls = 0;
  var disposed = false;
  var completedPlayAfterDispose = false;

  @override
  Stream<void> get onComplete => _completeController.stream;

  void complete() => _completeController.add(null);

  @override
  Future<void> pause() async {
    pauseCalls += 1;
  }

  @override
  Future<void> play(MusicTrack track) async {
    if (playError case final error?) {
      throw error;
    }
    playedTracks.add(track);
    if (playedTracks.length == 1) {
      await firstPlayGate?.future;
      completedPlayAfterDispose = disposed;
    }
  }

  @override
  Future<void> resume() async {
    resumeCalls += 1;
  }

  @override
  Future<void> setVolume(double volume) async {
    lastVolume = volume;
  }

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
    disposed = true;
    if (!_completeController.isClosed) {
      await _completeController.close();
    }
  }
}

class _FakeSessionStore implements MusicSessionStore {
  _FakeSessionStore([this.state]);

  MusicSessionState? state;

  @override
  MusicSessionState? read() => state;

  @override
  void write(MusicSessionState state) {
    this.state = state;
  }
}
