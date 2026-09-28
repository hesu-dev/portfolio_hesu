import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProjectAppIcon extends StatelessWidget {
  const ProjectAppIcon({required this.assetPath, this.size, super.key});

  final String assetPath;
  final double? size;

  @override
  Widget build(BuildContext context) => assetPath.endsWith('.svg')
      ? SvgPicture.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        )
      : Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
        );
}
