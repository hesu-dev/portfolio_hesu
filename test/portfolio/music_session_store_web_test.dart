@TestOn('browser')
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/music/music_session_store.dart';
import 'package:web/web.dart' as web;

const _storageKey = 'portfolio.music.session.v1';

void main() {
  setUp(() => web.window.sessionStorage.removeItem(_storageKey));
  tearDown(() => web.window.sessionStorage.removeItem(_storageKey));

  test('web session stores selection, mode, and volume without playing', () {
    final store = createMusicSessionStore();
    const state = MusicSessionState(
      currentIndex: 2,
      mode: MusicPlaybackMode.repeatOne,
      volume: 0.35,
    );

    store.write(state);

    final encoded = web.window.sessionStorage.getItem(_storageKey);
    expect(encoded, isNotNull);
    final json = jsonDecode(encoded!) as Map<String, dynamic>;
    expect(json, <String, Object>{
      'currentIndex': 2,
      'mode': 'repeatOne',
      'volume': 0.35,
    });
    expect(json, isNot(containsPair('playing', anything)));
    expect(json, isNot(containsPair('isPlaying', anything)));
    expect(store.read(), state);
  });

  test('web session ignores malformed data', () {
    web.window.sessionStorage.setItem(_storageKey, '{not-json');

    expect(createMusicSessionStore().read(), isNull);
  });
}
