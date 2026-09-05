import 'package:flutter/services.dart';

import 'music_track.dart';

class MusicAssetLibrary {
  const MusicAssetLibrary();

  static const _assetPrefix = 'assets/music/';
  static const _supportedExtensions = <String>{
    'aac',
    'flac',
    'm4a',
    'mp3',
    'ogg',
    'wav',
  };

  Future<List<MusicTrack>> load({AssetBundle? bundle}) async {
    final manifest = await AssetManifest.loadFromAssetBundle(
      bundle ?? rootBundle,
    );
    return tracksFromManifest(manifest);
  }

  List<MusicTrack> tracksFromManifest(AssetManifest manifest) {
    final paths = manifest.listAssets().where(_isSupported).toList()
      ..sort((left, right) {
        final leftName = _filename(left);
        final rightName = _filename(right);
        final foldedComparison = leftName.toLowerCase().compareTo(
          rightName.toLowerCase(),
        );
        if (foldedComparison != 0) return foldedComparison;
        final filenameComparison = leftName.compareTo(rightName);
        return filenameComparison != 0
            ? filenameComparison
            : left.compareTo(right);
      });
    return List<MusicTrack>.unmodifiable(
      paths.map(
        (path) => MusicTrack(assetPath: path, title: _titleFromPath(path)),
      ),
    );
  }

  bool _isSupported(String path) {
    if (!path.startsWith(_assetPrefix)) return false;
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return false;
    return _supportedExtensions.contains(path.substring(dot + 1).toLowerCase());
  }

  String _titleFromPath(String path) {
    final filename = _filename(path);
    final dot = filename.lastIndexOf('.');
    final stem = dot < 0 ? filename : filename.substring(0, dot);
    var title = stem;
    title = title.replaceFirst(RegExp(r'^\d+\s*[._-]?\s*'), '');
    title = title.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    if (title.isEmpty) return stem;
    return title
        .split(RegExp(r'\s+'))
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  String _filename(String path) => path.substring(path.lastIndexOf('/') + 1);
}
