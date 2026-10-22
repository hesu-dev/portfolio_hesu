import 'dart:async';

import 'package:audio_service/audio_service.dart' show AudioProcessingState;
import 'package:audioplayers/audioplayers.dart' as legacy;
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as audio;

import 'music_system_controls.dart';
import 'music_track.dart';

typedef MusicPlaybackFactory = MusicPlayback Function();

abstract interface class MusicPlayback {
  Stream<void> get onComplete;
  Stream<Duration> get onPositionChanged;
  Stream<Duration> get onDurationChanged;
  Stream<Object> get onError;
  Stream<bool> get onPlayingChanged;
  Future<void> play(MusicTrack track);
  Future<void> resume();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setRepeatOne(bool enabled);
  Future<void> setVolume(double volume);
  Future<void> dispose();
}

MusicPlayback createMusicPlayback() =>
    !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux)
    ? AudioplayersMusicPlayback()
    : JustAudioMusicPlayback(
        systemControls: !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
            ? MusicSystemControls()
            : null,
      );

class JustAudioMusicPlayback implements MusicPlayback, SystemMusicPlayback {
  JustAudioMusicPlayback({
    audio.AudioPlayer? player,
    MusicSystemControls? systemControls,
  }) : _player =
           player ??
           audio.AudioPlayer(handleInterruptions: systemControls == null),
       _systemControls = systemControls {
    systemControls?.seekTo = seek;
    _subscriptions.addAll([
      _player.playerStateStream.listen((state) {
        _publishState();
        if (_forwardPlayingState) _playingChanges.add(state.playing);
      }),
      // Includes native loop boundaries and position discontinuities. iOS
      // extrapolates elapsed time between events, including in the background.
      _player.playbackEventStream.listen((_) => _publishState()),
      _player.durationStream.listen((duration) {
        if (duration != null) systemControls?.setDuration(duration);
      }),
      _player.errorStream.listen(_reportError),
    ]);
  }

  final audio.AudioPlayer _player;
  final MusicSystemControls? _systemControls;
  final _subscriptions = <StreamSubscription<dynamic>>[];
  final _errors = StreamController<Object>.broadcast();
  final _playingChanges = StreamController<bool>.broadcast();
  Future<void>? _systemReady;
  bool _hasTrack = false;
  bool _forwardPlayingState = false;

  @override
  Stream<MusicRemoteCommand> get remoteCommands =>
      _systemControls?.commands ?? const Stream.empty();
  @override
  Stream<void> get onComplete => _player.processingStateStream
      .where((state) => state == audio.ProcessingState.completed)
      .map<void>((_) {});
  @override
  Stream<Duration> get onPositionChanged => _player.positionStream;
  @override
  Stream<Duration> get onDurationChanged =>
      _player.durationStream.map((duration) => duration ?? Duration.zero);
  @override
  Stream<Object> get onError => _errors.stream;
  @override
  Stream<bool> get onPlayingChanged => _playingChanges.stream;

  void _publishState() {
    if (!_hasTrack) return;
    _systemControls?.updatePlayback(
      playing:
          _player.playing &&
          _player.processingState != audio.ProcessingState.completed,
      position: _player.position,
      processingState: switch (_player.processingState) {
        audio.ProcessingState.idle => AudioProcessingState.idle,
        audio.ProcessingState.loading => AudioProcessingState.loading,
        audio.ProcessingState.buffering => AudioProcessingState.buffering,
        audio.ProcessingState.ready => AudioProcessingState.ready,
        audio.ProcessingState.completed => AudioProcessingState.completed,
      },
    );
  }

  void _reportError(Object error) {
    _systemControls?.reportError();
    if (!_errors.isClosed) _errors.add(error);
  }

  @override
  Future<void> play(MusicTrack track) async {
    try {
      // Loading emits an initial paused state. Keep it separate from a later
      // session activation denial or interruption after an actual play request.
      _forwardPlayingState = false;
      final controls = _systemControls;
      if (controls != null) {
        await (_systemReady ??= controls.initialize());
        controls.setTrack(track);
      }
      _hasTrack = true;
      await _player.setAsset(track.assetPath, initialPosition: Duration.zero);
      await resume();
    } catch (_) {
      _systemControls?.reportError();
      rethrow;
    }
  }

  @override
  Future<void> resume() async {
    // This future lasts until pause/end. Waiting here would block the
    // controller's pause, seek and navigation command queue.
    _forwardPlayingState = true;
    unawaited(_player.play().catchError(_reportError));
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _publishState();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _publishState();
  }

  @override
  Future<void> setRepeatOne(bool enabled) =>
      _player.setLoopMode(enabled ? audio.LoopMode.one : audio.LoopMode.off);
  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _player.dispose();
    await _systemControls?.dispose();
    await _errors.close();
    await _playingChanges.close();
  }
}

/// Preserve the existing Windows/Linux backend; just_audio has no bundled
/// implementation for those runners. Their completion loop stays app-owned.
class AudioplayersMusicPlayback implements MusicPlayback {
  AudioplayersMusicPlayback({legacy.AudioPlayer? player})
    : _player = player ?? legacy.AudioPlayer();
  final legacy.AudioPlayer _player;
  @override
  Stream<void> get onComplete => _player.onPlayerComplete;
  @override
  Stream<Duration> get onPositionChanged => _player.onPositionChanged;
  @override
  Stream<Duration> get onDurationChanged => _player.onDurationChanged;
  @override
  Stream<bool> get onPlayingChanged => _player.onPlayerStateChanged
      .where((state) => state != legacy.PlayerState.completed)
      .map((state) => state == legacy.PlayerState.playing);
  @override
  Stream<Object> get onError => const Stream.empty();
  @override
  Future<void> play(MusicTrack track) => _player.play(
    legacy.AssetSource(track.assetPath.replaceFirst(RegExp(r'^assets/'), '')),
    position: Duration.zero,
  );
  @override
  Future<void> resume() => _player.resume();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> seek(Duration position) => _player.seek(position);
  @override
  Future<void> setRepeatOne(bool enabled) async {}
  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);
  @override
  Future<void> dispose() => _player.dispose();
}
