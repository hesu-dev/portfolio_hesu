import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProjectAppIcon extends StatelessWidget {
  const ProjectAppIcon({required this.assetPath, this.size, super.key});

  final String assetPath;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final iris = assetPath == 'assets/icons/projects/iris.svg';
    final wordmark = iris || assetPath == 'assets/icons/projects/aiq.png';
    final alignment = iris ? Alignment.centerLeft : Alignment.center;
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
    return wordmark ? ColoredBox(color: Colors.white, child: image) : image;
  }
}
