import 'package:flutter/foundation.dart';

@immutable
class MusicTrack {
  const MusicTrack({required this.assetPath, required this.title});

  final String assetPath;
  final String title;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MusicTrack &&
          other.assetPath == assetPath &&
          other.title == title;

  @override
  int get hashCode => Object.hash(assetPath, title);
}
