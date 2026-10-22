import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';

import 'music_track.dart';

enum MusicRemoteCommand { play, pause, next, previous }

abstract interface class SystemMusicPlayback {
  Stream<MusicRemoteCommand> get remoteCommands;
}

/// Publishes the existing player's state to iOS Now Playing. Playback commands
/// return to MusicController so the app and system controls share one queue.
class MusicSystemControls extends BaseAudioHandler {
  final _commands = StreamController<MusicRemoteCommand>.broadcast();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  Future<void> Function(Duration)? seekTo;

  Stream<MusicRemoteCommand> get commands => _commands.stream;

  Future<void> initialize() async {
    await AudioService.init(builder: () => this);
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    _subscriptions.add(
      session.interruptionEventStream.listen((event) {
        if (event.begin && playbackState.value.playing) {
          unawaited(pause());
        }
        // Resume remains an explicit user action, including after a call:
        // never override a pause made while the interruption was active.
      }),
    );
    _subscriptions.add(
      session.becomingNoisyEventStream.listen((_) {
        if (playbackState.value.playing) unawaited(pause());
      }),
    );
  }

  void setTrack(MusicTrack track) {
    mediaItem.add(
      MediaItem(
        id: track.assetPath,
        title: track.title,
        album: '희수 포폴',
      ),
    );
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.loading,
        updatePosition: Duration.zero,
      ),
    );
  }

  void setDuration(Duration duration) {
    final item = mediaItem.value;
    if (item != null) mediaItem.add(item.copyWith(duration: duration));
  }

  void updatePlayback({
    required bool playing,
    required Duration position,
    AudioProcessingState processingState = AudioProcessingState.ready,
  }) {
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        processingState: processingState,
        playing: playing,
        updatePosition: position,
        speed: 1,
      ),
    );
  }

  void reportError() {
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        playing: false,
        errorCode: 1,
        errorMessage: '음악을 재생할 수 없습니다.',
      ),
    );
  }

  void _send(MusicRemoteCommand command) {
    if (!_commands.isClosed) _commands.add(command);
  }

  @override
  Future<void> play() async => _send(MusicRemoteCommand.play);
  @override
  Future<void> pause() async => _send(MusicRemoteCommand.pause);
  @override
  Future<void> skipToNext() async => _send(MusicRemoteCommand.next);
  @override
  Future<void> skipToPrevious() async => _send(MusicRemoteCommand.previous);
  @override
  Future<void> stop() => pause();
  @override
  Future<void> seek(Duration position) async => seekTo?.call(position);

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    playbackState.add(
      PlaybackState(processingState: AudioProcessingState.idle),
    );
    mediaItem.add(null);
    seekTo = null;
    await _commands.close();
  }
}
