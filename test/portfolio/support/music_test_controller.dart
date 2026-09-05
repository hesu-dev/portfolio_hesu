import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/music/music_controller.dart';
import 'package:portfolio_hesu/portfolio/music/music_session_store.dart';
import 'package:portfolio_hesu/portfolio/music/music_track.dart';

MusicController createTestMusicController({
  Iterable<MusicTrack> tracks = const <MusicTrack>[],
}) {
  final controller = MusicController(
    tracks: tracks,
    sessionStore: _TestMusicSessionStore(),
  );
  addTearDown(controller.dispose);
  return controller;
}

class _TestMusicSessionStore implements MusicSessionStore {
  MusicSessionState? _state;

  @override
  MusicSessionState? read() => _state;

  @override
  void write(MusicSessionState state) => _state = state;
}
