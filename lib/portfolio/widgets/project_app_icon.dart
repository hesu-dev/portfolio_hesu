import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProjectAppIcon extends StatelessWidget {
  const ProjectAppIcon({
    required this.assetPath,
    this.size,
    this.alignment,
    super.key,
  });

  final String assetPath;
  final double? size;
  final AlignmentGeometry? alignment;

  static bool hasOwnBackground(String? assetPath) => switch (assetPath) {
    'assets/icons/projects/readinglog.jpg' ||
    'assets/icons/settings-display-mode.svg' ||
    'assets/icons/projects/blue-mentor.png' ||
    'assets/icons/projects/aiq.png' ||
    'assets/icons/projects/iris.svg' ||
    'assets/icons/projects/ai-bver.png' ||
    'assets/icons/projects/hiddentag.png' => true,
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    final iris = assetPath == 'assets/icons/projects/iris.svg';
    final wordmark = iris || assetPath == 'assets/icons/projects/aiq.png';
    final alignment =
        this.alignment ?? (iris ? Alignment.centerLeft : Alignment.center);
    final image = assetPath.endsWith('.svg')
        ? SvgPicture.asset(
            assetPath,
            width: size,
            height: size,
            fit: BoxFit.contain,
            alignment: alignment,
            excludeFromSemantics: true,
          )
        : Image.asset(
            assetPath,
            width: size,
            height: size,
            fit: wordmark ? BoxFit.contain : BoxFit.cover,
            excludeFromSemantics: true,
          );
    if (wordmark) {
      final iconSize = size ?? 74;
      return Container(
        key: Key('project-icon-${iris ? 'iris' : 'aiq'}-background'),
        width: size,
        height: size,
        padding: EdgeInsets.all(iconSize * 0.1),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(iconSize * 0.22),
        ),
        clipBehavior: Clip.antiAlias,
        child: image,
      );
    }
    // Backed artwork retains the rounded silhouette previously used by Finder,
    // without adding a separate backing tile or shrinking the image.
    if (hasOwnBackground(assetPath) && size != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size! * 0.22),
        child: image,
      );
    }
    return image;
  }
}
