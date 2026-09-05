import 'music_session_store.dart';

MusicSessionStore createPlatformMusicSessionStore() =>
    _MemoryMusicSessionStore();

class _MemoryMusicSessionStore implements MusicSessionStore {
  MusicSessionState? _state;

  @override
  MusicSessionState? read() => _state;

  @override
  void write(MusicSessionState state) => _state = state;
}
