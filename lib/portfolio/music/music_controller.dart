import 'dart:async';

import 'package:flutter/foundation.dart';

import 'music_playback.dart';
import 'music_session_store.dart';
import 'music_system_controls.dart';
import 'music_track.dart';

enum MusicNavigationDirection { previous, next }

class MusicController extends ChangeNotifier {
  MusicController({
    required Iterable<MusicTrack> tracks,
    MusicPlaybackFactory playbackFactory = createMusicPlayback,
    MusicSessionStore? sessionStore,
  }) : _tracks = List<MusicTrack>.unmodifiable(tracks),
       _playbackFactory = playbackFactory,
       _sessionStore = sessionStore ?? createMusicSessionStore() {
    _restore();
  }

  static const playbackErrorMessage = '음악을 재생할 수 없습니다.';

  List<MusicTrack> _tracks;
  final MusicPlaybackFactory _playbackFactory;
  final MusicSessionStore _sessionStore;

  MusicPlayback? _playback;
  StreamSubscription<void>? _completionSubscription;
  StreamSubscription<MusicRemoteCommand>? _remoteSubscription;
  final _timelineSubscriptions = <StreamSubscription<dynamic>>[];
  Future<void> _commandQueue = Future<void>.value();
  MusicTrack? _loadedTrack;
  MusicTrack? _timelineTrack;
  int? _pendingRestoredIndex;
  int _commandGeneration = 0;
  int _currentIndex = 0;
  MusicPlaybackMode _mode = MusicPlaybackMode.queue;
  double _volume = 1;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _errorMessage;
  int _navigationRevision = 0;
  MusicNavigationDirection? _navigationDirection;
  bool _disposed = false;

  List<MusicTrack> get tracks => _tracks;
  int get currentIndex => _currentIndex;
  MusicTrack? get currentTrack => tracks.isEmpty ? null : tracks[_currentIndex];
  MusicPlaybackMode get mode => _mode;
  double get volume => _volume;
  bool get isPlaying => _isPlaying;
  Duration get duration =>
      _timelineTrack == currentTrack ? _duration : Duration.zero;
  Duration get position => _timelineTrack != currentTrack
      ? Duration.zero
      : _duration > Duration.zero && _position > _duration
      ? _duration
      : _position;
  bool get canSeek => _duration > Duration.zero && _loadedTrack == currentTrack;
  String? get errorMessage => _errorMessage;
  int get navigationRevision => _navigationRevision;
  MusicNavigationDirection? get navigationDirection => _navigationDirection;

  Future<void> play() async {
    final track = currentTrack;
    if (track == null) {
      _setPlaybackError();
      return;
    }

    _isPlaying = true;
    _errorMessage = null;
    final generation = ++_commandGeneration;
    _notify();
    await _enqueueStart(track, generation: generation, restart: false);
  }

  Future<void> pause() async {
    _isPlaying = false;
    final generation = ++_commandGeneration;
    _notify();
    await _enqueue(generation, () async {
      await _playback?.pause();
    });
  }

  Future<void> togglePlayback() => isPlaying ? pause() : play();

  Future<void> next() => _navigate(MusicNavigationDirection.next);

  Future<void> previous() => _navigate(MusicNavigationDirection.previous);

  /// Replaces the bootstrap asset list without creating or starting playback.
  void replaceTracks(Iterable<MusicTrack> tracks) {
    if (_disposed) return;

    final previousPath = currentTrack?.assetPath;
    final nextTracks = List<MusicTrack>.unmodifiable(tracks);
    var nextIndex = 0;
    if (previousPath != null) {
      final matchingIndex = nextTracks.indexWhere(
        (track) => track.assetPath == previousPath,
      );
      if (matchingIndex >= 0) nextIndex = matchingIndex;
    } else if (_pendingRestoredIndex case final restoredIndex?
        when restoredIndex >= 0 && restoredIndex < nextTracks.length) {
      nextIndex = restoredIndex;
    }

    _tracks = nextTracks;
    _currentIndex = nextTracks.isEmpty ? 0 : nextIndex;
    _pendingRestoredIndex = null;
    if (_loadedTrack != null && !nextTracks.contains(_loadedTrack)) {
      _loadedTrack = null;
    }
    _persist();
    _notify();
  }

  Future<void> select(int index) async {
    if (index < 0 || index >= tracks.length || index == _currentIndex) return;

    _navigationDirection = index > _currentIndex
        ? MusicNavigationDirection.next
        : MusicNavigationDirection.previous;
    _navigationRevision += 1;
    _currentIndex = index;
    _persist();
    final generation = ++_commandGeneration;
    final track = currentTrack;
    _notify();

    if (_isPlaying && track != null) {
      await _enqueueStart(track, generation: generation, restart: true);
    } else {
      await _enqueue(generation, () async {
        await _playback?.pause();
      });
    }
  }

  void setMode(MusicPlaybackMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _persist();
    _notify();
    unawaited(
      _enqueue(_commandGeneration, () async {
        await _playback?.setRepeatOne(_mode == MusicPlaybackMode.repeatOne);
      }),
    );
  }

  Future<void> seek(Duration position) async {
    if (!canSeek) return;
    final target = Duration(
      microseconds: position.inMicroseconds.clamp(0, _duration.inMicroseconds),
    );
    _position = target;
    _notify();
    await _enqueue(_commandGeneration, () async {
      await _playback?.seek(target);
    });
  }

  Future<void> setVolume(double volume) async {
    final nextVolume = volume.clamp(0.0, 1.0).toDouble();
    _volume = nextVolume;
    _persist();
    _notify();
    final generation = _commandGeneration;
    await _enqueue(generation, () async {
      await _playback?.setVolume(nextVolume);
    });
  }

  Future<void> _navigate(MusicNavigationDirection direction) async {
    _navigationDirection = direction;
    _navigationRevision += 1;
    if (tracks.isNotEmpty) {
      final delta = direction == MusicNavigationDirection.next ? 1 : -1;
      _currentIndex = (_currentIndex + delta) % tracks.length;
      _persist();
    }
    final generation = ++_commandGeneration;
    final track = currentTrack;
    _notify();

    if (_isPlaying && track != null) {
      await _enqueueStart(track, generation: generation, restart: true);
    } else {
      await _enqueue(generation, () async {
        await _playback?.pause();
      });
    }
  }

  Future<void> _enqueueStart(
    MusicTrack track, {
    required int generation,
    required bool restart,
  }) {
    return _enqueue(generation, () async {
      _timelineTrack = track;
      final playback = _ensurePlayback();
      await playback.setVolume(_volume);
      await playback.setRepeatOne(_mode == MusicPlaybackMode.repeatOne);
      if (!_isCurrentCommand(generation)) return;
      if (!restart && _loadedTrack == track) {
        await playback.resume();
      } else {
        _position = Duration.zero;
        if (_loadedTrack != track) _duration = Duration.zero;
        await playback.play(track);
        _loadedTrack = track;
        _notify();
      }
    });
  }

  Future<void> _enqueue(int generation, Future<void> Function() operation) {
    _commandQueue = _commandQueue.then((_) async {
      if (!_isCurrentCommand(generation)) return;
      try {
        await operation();
      } catch (_) {
        if (_isCurrentCommand(generation)) {
          _setPlaybackError();
        }
      }
    });
    return _commandQueue;
  }

  bool _isCurrentCommand(int generation) =>
      !_disposed && generation == _commandGeneration;

  MusicPlayback _ensurePlayback() {
    final existing = _playback;
    if (existing != null) return existing;
    final playback = _playbackFactory();
    _playback = playback;
    _completionSubscription = playback.onComplete.listen((_) {
      unawaited(_handleCompletion());
    });
    _timelineSubscriptions.addAll([
      playback.onPlayingChanged.listen((playing) {
        if (_disposed) return;
        _isPlaying = playing;
        _notify();
      }),
      playback.onPositionChanged.listen((position) {
        _position = position < Duration.zero ? Duration.zero : position;
        _notify();
      }),
      playback.onDurationChanged.listen((duration) {
        _duration = duration < Duration.zero ? Duration.zero : duration;
        _notify();
      }),
      playback.onError.listen((_) {
        if (_disposed) return;
        _commandGeneration++;
        _setPlaybackError();
      }),
    ]);
    if (playback is SystemMusicPlayback) {
      _remoteSubscription = (playback as SystemMusicPlayback).remoteCommands
          .listen((command) {
            if (_disposed) return;
            unawaited(switch (command) {
              MusicRemoteCommand.play => play(),
              MusicRemoteCommand.pause => pause(),
              MusicRemoteCommand.next => next(),
              MusicRemoteCommand.previous => previous(),
            });
          });
    }
    return playback;
  }

  Future<void> _handleCompletion() async {
    if (!_isPlaying || _disposed) return;
    if (_mode == MusicPlaybackMode.repeatOne) {
      final track = currentTrack;
      if (track == null) return;
      final generation = ++_commandGeneration;
      await _enqueueStart(track, generation: generation, restart: true);
    } else {
      await _navigate(MusicNavigationDirection.next);
    }
  }

  void _restore() {
    try {
      final state = _sessionStore.read();
      if (state == null) return;
      if (tracks.isEmpty && state.currentIndex >= 0) {
        _pendingRestoredIndex = state.currentIndex;
      } else if (state.currentIndex >= 0 &&
          state.currentIndex < tracks.length) {
        _currentIndex = state.currentIndex;
      }
      _mode = state.mode;
      if (state.volume.isFinite && state.volume >= 0 && state.volume <= 1) {
        _volume = state.volume;
      }
    } catch (_) {
      // A denied storage read should not prevent the portfolio from loading.
    }
  }

  void _persist() {
    try {
      _sessionStore.write(
        MusicSessionState(
          currentIndex: _currentIndex,
          mode: _mode,
          volume: _volume,
        ),
      );
    } catch (_) {
      // Session persistence is best effort.
    }
  }

  void _setPlaybackError() {
    _isPlaying = false;
    _loadedTrack = null;
    _errorMessage = playbackErrorMessage;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _commandGeneration += 1;
    unawaited(_remoteSubscription?.cancel());
    for (final subscription in _timelineSubscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(
      _disposeResources(
        subscription: _completionSubscription,
        playback: _playback,
        pendingCommands: _commandQueue,
      ),
    );
    super.dispose();
  }

  Future<void> _disposeResources({
    required StreamSubscription<void>? subscription,
    required MusicPlayback? playback,
    required Future<void> pendingCommands,
  }) async {
    Future<void>? cancellation;
    try {
      cancellation = subscription?.cancel();
    } catch (_) {
      // The controller is already disposed, so teardown is best effort.
    }
    try {
      await pendingCommands;
    } catch (_) {
      // Queued playback errors are already converted into controller state.
    }
    try {
      await playback?.dispose();
    } catch (_) {
      // A platform teardown failure must not escape ChangeNotifier.dispose().
    }
    try {
      await cancellation;
    } catch (_) {
      // Subscription teardown is best effort after the player is released.
    }
  }
}
