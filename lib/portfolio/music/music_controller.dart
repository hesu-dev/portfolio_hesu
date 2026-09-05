import 'dart:async';

import 'package:flutter/foundation.dart';

import 'music_playback.dart';
import 'music_session_store.dart';
import 'music_track.dart';

enum MusicNavigationDirection { previous, next }

class MusicController extends ChangeNotifier {
  MusicController({
    required Iterable<MusicTrack> tracks,
    MusicPlaybackFactory playbackFactory = createMusicPlayback,
    MusicSessionStore? sessionStore,
  }) : tracks = List<MusicTrack>.unmodifiable(tracks),
       _playbackFactory = playbackFactory,
       _sessionStore = sessionStore ?? createMusicSessionStore() {
    _restore();
  }

  static const playbackErrorMessage = '음악을 재생할 수 없습니다.';

  final List<MusicTrack> tracks;
  final MusicPlaybackFactory _playbackFactory;
  final MusicSessionStore _sessionStore;

  MusicPlayback? _playback;
  StreamSubscription<void>? _completionSubscription;
  Future<void> _commandQueue = Future<void>.value();
  MusicTrack? _loadedTrack;
  int _commandGeneration = 0;
  int _currentIndex = 0;
  MusicPlaybackMode _mode = MusicPlaybackMode.queue;
  double _volume = 1;
  bool _isPlaying = false;
  String? _errorMessage;
  int _navigationRevision = 0;
  MusicNavigationDirection? _navigationDirection;
  bool _disposed = false;

  int get currentIndex => _currentIndex;
  MusicTrack? get currentTrack => tracks.isEmpty ? null : tracks[_currentIndex];
  MusicPlaybackMode get mode => _mode;
  double get volume => _volume;
  bool get isPlaying => _isPlaying;
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

  void setMode(MusicPlaybackMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _persist();
    _notify();
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
    }
  }

  Future<void> _enqueueStart(
    MusicTrack track, {
    required int generation,
    required bool restart,
  }) {
    return _enqueue(generation, () async {
      final playback = _ensurePlayback();
      await playback.setVolume(_volume);
      if (!_isCurrentCommand(generation)) return;
      if (!restart && _loadedTrack == track) {
        await playback.resume();
      } else {
        await playback.play(track);
        _loadedTrack = track;
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
      if (state.currentIndex >= 0 && state.currentIndex < tracks.length) {
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
    try {
      await subscription?.cancel();
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
  }
}
