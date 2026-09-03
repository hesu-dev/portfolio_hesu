import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/apple_theme.dart';

/// A lightweight gallery entry point kept intentionally content-neutral until
/// the portfolio photo experience is planned.
class PhotosApp extends StatelessWidget {
  const PhotosApp({this.compact = false, this.tablet = false, super.key});

  final bool compact;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    return AppleAppSurface(
      key: const Key('photos-app'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            key: const Key('photos-scroll'),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: math.max(360, constraints.maxHeight + 120),
              ),
              child: const AppleEmptyState(
                icon: Icons.photo_library_outlined,
                title: '사진',
                message: '갤러리 콘텐츠는 추후 추가할 예정입니다.',
              ),
            ),
          );
        },
      ),
    );
  }
}
