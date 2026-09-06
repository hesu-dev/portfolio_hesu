import 'package:flutter/widgets.dart';

/// A pixel-art study scene with deterministic stat-up timing.
class EducationPixelStudy extends StatefulWidget {
  const EducationPixelStudy({super.key});

  static const studySpriteAsset = 'assets/sprites/education_student_study.png';
  static const studySheetSize = Size(1536, 1024);
  static const studyFrameBottomPadding = 8.0;

  /// Per-pose crops measured from the visible alpha bounds, with about eight
  /// transparent source pixels of padding instead of the original full cells.
  static const studySourceFrames = <Rect>[
    Rect.fromLTRB(56, 107, 336, 448),
    Rect.fromLTRB(449, 108, 720, 447),
    Rect.fromLTRB(810, 113, 1062, 448),
    Rect.fromLTRB(1178, 113, 1430, 448),
    Rect.fromLTRB(68, 525, 331, 866),
    Rect.fromLTRB(408, 526, 704, 866),
    Rect.fromLTRB(810, 530, 1062, 866),
    Rect.fromLTRB(1169, 534, 1447, 866),
  ];
  static const statLabels = <String>['FLUTTER', 'DART', 'UX', 'SOLVE'];

  static const _statWindows = <(double, double)>[
    (0.12, 0.24),
    (0.30, 0.42),
    (0.48, 0.60),
    (0.66, 0.78),
  ];

  /// Returns the highlighted stat for a finite, normalized cycle [progress].
  ///
  /// Stat windows are half-open. Their start is active, their end and every
  /// gap return `-1`, as do values outside the inclusive `0...1` cycle.
  static int activeStatIndexFor(double progress) {
    if (!progress.isFinite || progress < 0 || progress > 1) {
      return -1;
    }
    for (var index = 0; index < _statWindows.length; index++) {
      final (start, end) = _statWindows[index];
      if (progress >= start && progress < end) {
        return index;
      }
    }
    return -1;
  }

  /// Maps a measured source crop onto one shared painter-space [baseline].
  ///
  /// Each crop keeps the same transparent bottom padding. Positioning its
  /// visible bottom edge on [baseline] removes the source sheet's row offset.
  static Rect destinationRectForFrame(
    int frameIndex, {
    required Offset baseline,
    required double scale,
  }) {
    final source = studySourceFrames[frameIndex];
    final width = source.width * scale;
    final height = source.height * scale;
    return Rect.fromLTWH(
      baseline.dx - (width / 2),
      baseline.dy - ((source.height - studyFrameBottomPadding) * scale),
      width,
      height,
    );
  }

  @override
  State<EducationPixelStudy> createState() => _EducationPixelStudyState();
}

class _EducationPixelStudyState extends State<EducationPixelStudy> {
  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
