import 'package:audioplayers/audioplayers.dart';

import 'music_track.dart';

typedef MusicPlaybackFactory = MusicPlayback Function();

abstract interface class MusicPlayback {
  Stream<void> get onComplete;

  Future<void> play(MusicTrack track);

  Future<void> resume();

  Future<void> pause();

  Future<void> setVolume(double volume);

  Future<void> dispose();
}

MusicPlayback createMusicPlayback() => AudioplayersMusicPlayback();

class AudioplayersMusicPlayback implements MusicPlayback {
  AudioplayersMusicPlayback({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Stream<void> get onComplete => _player.onPlayerComplete;

  @override
  Future<void> play(MusicTrack track) {
    const bundlePrefix = 'assets/';
    final sourcePath = track.assetPath.startsWith(bundlePrefix)
        ? track.assetPath.substring(bundlePrefix.length)
        : track.assetPath;
    return _player.play(AssetSource(sourcePath));
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() => _player.resume();

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> dispose() => _player.dispose();
}
