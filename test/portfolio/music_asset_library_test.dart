import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/music/music_asset_library.dart';

void main() {
  group('MusicAssetLibrary', () {
    test('filters supported music assets under the prefix and sorts them', () {
      const library = MusicAssetLibrary();
      final manifest = _FakeAssetManifest(<String>[
        'assets/music/z-last.ogg',
        'assets/images/ignored.mp3',
        'assets/music/readme.txt',
        'assets/music/A-first.MP3',
        'assets/music/middle.m4a',
        'assets/music/nested/second.wav',
      ]);

      final tracks = library.tracksFromManifest(manifest);

      expect(tracks.map((track) => track.assetPath), <String>[
        'assets/music/A-first.MP3',
        'assets/music/middle.m4a',
        'assets/music/nested/second.wav',
        'assets/music/z-last.ogg',
      ]);
    });

    test('derives a readable title from the asset filename', () {
      const library = MusicAssetLibrary();
      final manifest = _FakeAssetManifest(<String>[
        'assets/music/01. night_drive-final.mp3',
      ]);

      final track = library.tracksFromManifest(manifest).single;

      expect(track.title, 'Night Drive Final');
    });

    test('sorts by filename with a deterministic case tie-breaker', () {
      const library = MusicAssetLibrary();
      final manifest = _FakeAssetManifest(<String>[
        'assets/music/a/02-beta.mp3',
        'assets/music/z/01-alpha.mp3',
        'assets/music/b/same.mp3',
        'assets/music/a/SAME.MP3',
      ]);

      final tracks = library.tracksFromManifest(manifest);

      expect(tracks.map((track) => track.assetPath), <String>[
        'assets/music/z/01-alpha.mp3',
        'assets/music/a/02-beta.mp3',
        'assets/music/a/SAME.MP3',
        'assets/music/b/same.mp3',
      ]);
    });

    test('keeps a numeric-only filename readable without its extension', () {
      const library = MusicAssetLibrary();
      final manifest = _FakeAssetManifest(<String>['assets/music/01.mp3']);

      expect(library.tracksFromManifest(manifest).single.title, '01');
    });
  });
}

class _FakeAssetManifest implements AssetManifest {
  _FakeAssetManifest(this.assets);

  final List<String> assets;

  @override
  List<AssetMetadata>? getAssetVariants(String key) => null;

  @override
  List<String> listAssets() => assets;
}
