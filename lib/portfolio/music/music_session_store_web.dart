import 'dart:convert';

import 'package:web/web.dart' as web;

import 'music_session_store.dart';

MusicSessionStore createPlatformMusicSessionStore() =>
    const WebMusicSessionStore();

class WebMusicSessionStore implements MusicSessionStore {
  const WebMusicSessionStore();

  static const _storageKey = 'portfolio.music.session.v1';

  @override
  MusicSessionState? read() {
    try {
      final encoded = web.window.sessionStorage.getItem(_storageKey);
      if (encoded == null) return null;
      final value = jsonDecode(encoded);
      if (value is! Map<String, dynamic>) return null;
      final index = value['currentIndex'];
      final volume = value['volume'];
      final modeName = value['mode'];
      if (index is! int || volume is! num || modeName is! String) return null;
      final mode = MusicPlaybackMode.values
          .where((candidate) => candidate.name == modeName)
          .firstOrNull;
      if (mode == null) return null;
      return MusicSessionState(
        currentIndex: index,
        mode: mode,
        volume: volume.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void write(MusicSessionState state) {
    try {
      web.window.sessionStorage.setItem(
        _storageKey,
        jsonEncode(<String, Object>{
          'currentIndex': state.currentIndex,
          'mode': state.mode.name,
          'volume': state.volume,
        }),
      );
    } catch (_) {
      // Storage can be unavailable in private or restricted browsing contexts.
    }
  }
}
