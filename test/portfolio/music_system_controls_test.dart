import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart' as audio;
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/music/music_controller.dart';
import 'package:portfolio_hesu/portfolio/music/music_playback.dart';
import 'package:portfolio_hesu/portfolio/music/music_system_controls.dart';
import 'package:portfolio_hesu/portfolio/music/music_track.dart';

void main() {
  const track = MusicTrack(
    assetPath: 'assets/music/01-always.mp3',
    title: 'Always',
  );

  test(
    'a denied audio session updates both app and system playback state',
    () async {
      final player = _Player()..denyActivation = true;
      final controls = _TestControls();
      final playback = JustAudioMusicPlayback(
        player: player,
        systemControls: controls,
      );
      final controller = MusicController(
        tracks: [track],
        playbackFactory: () => playback,
      );
      await controller.play();
      await pumpEventQueue();
      expect(controller.isPlaying, isFalse);
      expect(controls.playbackState.value.playing, isFalse);
      controller.dispose();
      await pumpEventQueue();
    },
  );

  test(
    'asynchronous playback failure pauses the app and publishes an error',
    () async {
      final player = _Player();
      final controls = _TestControls();
      final playback = JustAudioMusicPlayback(
        player: player,
        systemControls: controls,
      );
      final controller = MusicController(
        tracks: [track],
        playbackFactory: () => playback,
      );
      await controller.play();
      player.playbackFinished.completeError(StateError('decoder failure'));
      await pumpEventQueue();
      expect(controller.isPlaying, isFalse);
      expect(controller.errorMessage, MusicController.playbackErrorMessage);
      expect(controls.playbackState.value.playing, isFalse);
      controller.dispose();
      await pumpEventQueue();
    },
  );

  test(
    'repeat uses native looping and loop boundaries keep Now Playing active',
    () async {
      final player = _Player();
      final controls = _TestControls();
      final playback = JustAudioMusicPlayback(
        player: player,
        systemControls: controls,
      );
      await playback.setRepeatOne(true);
      expect(player.loopMode, audio.LoopMode.one);
      await playback.play(track).timeout(const Duration(seconds: 1));
      // A native loop returns to zero without a completed/release/reload cycle.
      player.position = Duration.zero;
      player.events.add(
        audio.PlaybackEvent(processingState: audio.ProcessingState.ready),
      );
      await pumpEventQueue();
      expect(controls.playbackState.value.playing, isTrue);
      expect(controls.playbackState.value.updatePosition, Duration.zero);
      expect(player.paths, [track.assetPath]);
      await playback.setRepeatOne(false);
      expect(player.loopMode, audio.LoopMode.off);
      await playback.dispose();
    },
  );

  test(
    'player events publish metadata and pause/resume/seek state to iOS',
    () async {
      final player = _Player();
      final controls = _TestControls();
      final playback = JustAudioMusicPlayback(
        player: player,
        systemControls: controls,
      );
      await playback.play(track);
      player.durations.add(const Duration(minutes: 3));
      await pumpEventQueue();
      expect(controls.initializations, 1);
      expect(controls.mediaItem.value?.title, 'Always');
      expect(controls.mediaItem.value?.duration, const Duration(minutes: 3));
      expect(controls.playbackState.value.playing, isTrue);

      player.positions.add(const Duration(seconds: 12));
      await pumpEventQueue();
      // Frame updates stop in the background while native playback continues.
      player.position = const Duration(seconds: 40);
      await playback.pause();
      await pumpEventQueue();
      expect(controls.playbackState.value.playing, isFalse);
      expect(
        controls.playbackState.value.updatePosition,
        const Duration(seconds: 40),
      );

      await controls.seek(const Duration(seconds: 25));
      expect(player.seekPosition, const Duration(seconds: 25));
      expect(
        controls.playbackState.value.updatePosition,
        const Duration(seconds: 25),
      );
      await playback.resume();
      await pumpEventQueue();
      expect(controls.playbackState.value.playing, isTrue);
      await playback.play(track);
      expect(controls.initializations, 1);
      expect(player.startPositions, [Duration.zero, Duration.zero]);
      await playback.dispose();
      expect(controls.mediaItem.value, isNull);
      expect(
        controls.playbackState.value.processingState,
        AudioProcessingState.idle,
      );
    },
  );

  test(
    'failed player start cannot leave Now Playing marked as playing',
    () async {
      final player = _Player()..playError = StateError('unavailable');
      final controls = _TestControls();
      final playback = JustAudioMusicPlayback(
        player: player,
        systemControls: controls,
      );
      await expectLater(playback.play(track), throwsStateError);
      expect(controls.playbackState.value.playing, isFalse);
      expect(
        controls.playbackState.value.processingState,
        AudioProcessingState.error,
      );
      await playback.dispose();
    },
  );

  test('system metadata follows duration, position and actual playback', () {
    final controls = MusicSystemControls();
    controls.setTrack(track);
    controls.setDuration(const Duration(minutes: 3));
    controls.updatePlayback(
      playing: true,
      position: const Duration(seconds: 12),
    );

    expect(controls.mediaItem.value?.title, 'Always');
    expect(controls.mediaItem.value?.duration, const Duration(minutes: 3));
    expect(controls.playbackState.value.playing, isTrue);
    expect(
      controls.playbackState.value.updatePosition,
      const Duration(seconds: 12),
    );
    expect(controls.playbackState.value.controls, contains(MediaControl.pause));

    controls.updatePlayback(
      playing: false,
      position: const Duration(seconds: 15),
    );
    expect(controls.playbackState.value.playing, isFalse);
    expect(controls.playbackState.value.controls, contains(MediaControl.play));
  });

  test(
    'Control Center commands use the app controller and preserve repeat',
    () async {
      final playback = _SystemPlayback();
      final controller = MusicController(
        tracks: [track],
        playbackFactory: () => playback,
      );
      await controller.play();
      await playback.controls.pause();
      await pumpEventQueue();
      expect(controller.isPlaying, isFalse);
      expect(playback.pauseCalls, 1);

      await playback.controls.play();
      await pumpEventQueue();
      expect(controller.isPlaying, isTrue);
      expect(playback.resumeCalls, 1);

      await playback.controls.skipToNext();
      await pumpEventQueue();
      expect(controller.navigationRevision, 1);
      expect(playback.playCalls, 2);

      await playback.controls.skipToPrevious();
      await pumpEventQueue();
      expect(controller.navigationRevision, 2);
      expect(playback.playCalls, 3);

      playback.completions.add(null);
      await pumpEventQueue();
      expect(controller.isPlaying, isTrue);
      expect(playback.playCalls, 4);

      controller.dispose();
      await pumpEventQueue();
    },
  );
}

class _TestControls extends MusicSystemControls {
  int initializations = 0;
  @override
  Future<void> initialize() async {
    initializations++;
  }
}

class _Player implements audio.AudioPlayer {
  final states = StreamController<audio.PlayerState>.broadcast();
  final durations = StreamController<Duration?>.broadcast();
  final positions = StreamController<Duration>.broadcast();
  final events = StreamController<audio.PlaybackEvent>.broadcast();
  final processing = StreamController<audio.ProcessingState>.broadcast();
  final errors = StreamController<audio.PlayerException>.broadcast();
  @override
  bool playing = false;
  @override
  audio.ProcessingState processingState = audio.ProcessingState.ready;
  @override
  Duration position = Duration.zero;
  Object? playError;
  bool denyActivation = false;
  Duration? seekPosition;
  @override
  audio.LoopMode loopMode = audio.LoopMode.off;
  final startPositions = <Duration?>[];
  final paths = <String>[];
  final playbackFinished = Completer<void>();
  @override
  Stream<audio.PlayerState> get playerStateStream => states.stream;
  @override
  Stream<audio.PlaybackEvent> get playbackEventStream => events.stream;
  @override
  Stream<audio.ProcessingState> get processingStateStream => processing.stream;
  @override
  Stream<audio.PlayerException> get errorStream => errors.stream;
  @override
  Stream<Duration?> get durationStream => durations.stream;
  @override
  Stream<Duration> get positionStream => positions.stream;
  @override
  Future<Duration?> setAsset(
    String path, {
    String? package,
    bool preload = true,
    Duration? initialPosition,
    dynamic tag,
  }) async {
    if (playError case final error?) throw error;
    paths.add(path);
    startPositions.add(initialPosition);
    position = initialPosition ?? Duration.zero;
    return const Duration(minutes: 3);
  }

  @override
  Future<void> play() {
    playing = true;
    states.add(audio.PlayerState(playing, processingState));
    if (denyActivation) {
      scheduleMicrotask(() {
        playing = false;
        states.add(audio.PlayerState(playing, processingState));
      });
    }
    return playbackFinished.future;
  }

  @override
  Future<void> pause() async {
    playing = false;
    states.add(audio.PlayerState(playing, processingState));
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {
    seekPosition = position;
    this.position = position ?? Duration.zero;
    positions.add(this.position);
  }

  @override
  Future<void> setLoopMode(audio.LoopMode mode) async {
    loopMode = mode;
  }

  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> dispose() async {
    if (!playbackFinished.isCompleted) playbackFinished.complete();
    await states.close();
    await durations.close();
    await positions.close();
    await events.close();
    await processing.close();
    await errors.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SystemPlayback implements MusicPlayback, SystemMusicPlayback {
  @override
  Stream<Duration> get onPositionChanged => const Stream.empty();
  @override
  Stream<Duration> get onDurationChanged => const Stream.empty();
  @override
  Stream<Object> get onError => const Stream.empty();
  @override
  Stream<bool> get onPlayingChanged => const Stream.empty();
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> setRepeatOne(bool enabled) async {}
  final controls = MusicSystemControls();
  final completions = StreamController<void>.broadcast();
  int playCalls = 0;
  int pauseCalls = 0;
  int resumeCalls = 0;
  @override
  Stream<MusicRemoteCommand> get remoteCommands => controls.commands;
  @override
  Stream<void> get onComplete => completions.stream;
  @override
  Future<void> play(MusicTrack track) async {
    playCalls++;
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
  }

  @override
  Future<void> resume() async {
    resumeCalls++;
  }

  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> dispose() async {
    await completions.close();
    await controls.dispose();
  }
}
