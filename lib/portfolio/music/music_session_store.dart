import 'package:flutter/foundation.dart';

import 'music_session_store_stub.dart'
    if (dart.library.js_interop) 'music_session_store_web.dart'
    as platform;

enum MusicPlaybackMode { queue, repeatOne }

@immutable
class MusicSessionState {
  const MusicSessionState({
    required this.currentIndex,
    required this.mode,
    required this.volume,
  });

  final int currentIndex;
  final MusicPlaybackMode mode;
  final double volume;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MusicSessionState &&
          other.currentIndex == currentIndex &&
          other.mode == mode &&
          other.volume == volume;

  @override
  int get hashCode => Object.hash(currentIndex, mode, volume);
}

abstract interface class MusicSessionStore {
  MusicSessionState? read();

  void write(MusicSessionState state);
}

MusicSessionStore createMusicSessionStore() =>
    platform.createPlatformMusicSessionStore();
