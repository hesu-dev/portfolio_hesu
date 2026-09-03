import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/portfolio_app_id.dart';

/// Scalable, code-native artwork shared by every portfolio app launcher.
///
/// Primary app marks and Trash are drawn with Flutter paths instead of bundled
/// platform artwork. The remaining utility apps keep their established
/// Material glyphs for visual continuity with the existing desktop.
class AppleAppArtwork extends StatelessWidget {
  const AppleAppArtwork({required this.appId, required this.size, super.key})
    : assert(size > 0);

  final PortfolioAppId appId;
  final double size;

  static bool usesBespokeArtwork(PortfolioAppId appId) => switch (appId) {
    PortfolioAppId.about ||
    PortfolioAppId.skills ||
    PortfolioAppId.projects ||
    PortfolioAppId.terminal ||
    PortfolioAppId.mail ||
    PortfolioAppId.settings ||
    PortfolioAppId.trash => true,
    PortfolioAppId.thisMac || PortfolioAppId.github => false,
  };

  static bool usesTransparentFrame(PortfolioAppId appId) => switch (appId) {
    PortfolioAppId.projects || PortfolioAppId.trash => true,
    _ => false,
  };

  static List<Color> colorsFor(PortfolioAppId appId) => switch (appId) {
    PortfolioAppId.about => const <Color>[Color(0xFF79DCFF), Color(0xFF2167E8)],
    PortfolioAppId.skills => const <Color>[
      Color(0xFFFFFFFF),
      Color(0xFFF7F7F8),
    ],
    PortfolioAppId.projects => const <Color>[
      Color(0xFF7DE2FF),
      Color(0xFF0878ED),
    ],
    PortfolioAppId.terminal => const <Color>[
      Color(0xFF42454D),
      Color(0xFF111216),
    ],
    PortfolioAppId.settings => const <Color>[
      Color(0xFFD5DAE2),
      Color(0xFF6D7480),
    ],
    PortfolioAppId.thisMac => const <Color>[
      Color(0xFF69D5FF),
      Color(0xFF1675F8),
    ],
    PortfolioAppId.trash => const <Color>[
      Color(0xFFE01E5A),
      Color(0xFFECB22E),
      Color(0xFF2EB67D),
      Color(0xFF36C5F0),
      Color(0xFF7559D9),
    ],
    PortfolioAppId.github => const <Color>[
      Color(0xFF42454D),
      Color(0xFF111216),
    ],
    PortfolioAppId.mail => const <Color>[Color(0xFF5ED4FF), Color(0xFF0868E8)],
  };

  static IconData utilityIconFor(PortfolioAppId appId) => switch (appId) {
    PortfolioAppId.thisMac => Icons.folder_copy_rounded,
    PortfolioAppId.github => Icons.code_rounded,
    _ => throw ArgumentError.value(
      appId,
      'appId',
      'Primary app artwork does not use a Material icon.',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.28;
    final bespoke = usesBespokeArtwork(appId);
    final transparentFrame = usesTransparentFrame(appId);

    final Widget artwork = switch (appId) {
      PortfolioAppId.projects => Transform.scale(
        key: const Key('apple-app-artwork-projects-silhouette'),
        scale: 1.18,
        child: CustomPaint(
          painter: _AppleAppArtworkPainter(appId),
          child: const SizedBox.expand(),
        ),
      ),
      PortfolioAppId.terminal => CustomPaint(
        foregroundPainter: _AppleAppArtworkPainter(appId),
        child: const ColoredBox(
          key: Key('apple-app-artwork-terminal-screen'),
          color: Color(0xFF0B0D11),
        ),
      ),
      _ when bespoke => CustomPaint(
        painter: _AppleAppArtworkPainter(appId),
        child: const SizedBox.expand(),
      ),
      _ => Center(
        child: Icon(
          utilityIconFor(appId),
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    };

    return SizedBox.square(
      dimension: size,
      child: ExcludeSemantics(
        key: Key('apple-app-artwork-${appId.name}'),
        child: DecoratedBox(
          decoration: transparentFrame
              ? const BoxDecoration()
              : BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colorsFor(appId),
                  ),
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.44),
                    width: math.max(0.5, size * 0.014),
                  ),
                ),
          child: ClipRRect(
            borderRadius: transparentFrame
                ? BorderRadius.zero
                : BorderRadius.circular(radius),
            child: artwork,
          ),
        ),
      ),
    );
  }
}

class _AppleAppArtworkPainter extends CustomPainter {
  const _AppleAppArtworkPainter(this.appId);

  final PortfolioAppId appId;

  @override
  void paint(Canvas canvas, Size size) {
    if (!AppleAppArtwork.usesTransparentFrame(appId) &&
        appId != PortfolioAppId.terminal) {
      _drawGlassHighlight(canvas, size);
    }
    switch (appId) {
      case PortfolioAppId.about:
        _drawAbout(canvas, size);
      case PortfolioAppId.skills:
        _drawSkills(canvas, size);
      case PortfolioAppId.projects:
        _drawProjects(canvas, size);
      case PortfolioAppId.terminal:
        _drawTerminal(canvas, size);
      case PortfolioAppId.mail:
        _drawMail(canvas, size);
      case PortfolioAppId.settings:
        _drawSettings(canvas, size);
      case PortfolioAppId.trash:
        _drawTrash(canvas, size);
      case PortfolioAppId.thisMac:
      case PortfolioAppId.github:
        throw StateError('Utility artwork is rendered by its existing glyph.');
    }
  }

  void _drawGlassHighlight(Canvas canvas, Size size) {
    final highlight = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0x38FFFFFF), Color(0x00FFFFFF)],
        stops: <double>[0, 0.62],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, highlight);
  }

  void _drawAbout(Canvas canvas, Size size) {
    final leftHalf = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.54, 0)
      ..cubicTo(
        size.width * 0.47,
        size.height * 0.28,
        size.width * 0.55,
        size.height * 0.7,
        size.width * 0.45,
        size.height,
      )
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(leftHalf, Paint()..color = const Color(0x8A97EDFF));

    final line = Paint()
      ..color = const Color(0xFF07396E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawLine(
      Offset(size.width * 0.34, size.height * 0.37),
      Offset(size.width * 0.34, size.height * 0.43),
      line,
    );
    canvas.drawLine(
      Offset(size.width * 0.68, size.height * 0.37),
      Offset(size.width * 0.68, size.height * 0.43),
      line,
    );

    final nose = Path()
      ..moveTo(size.width * 0.52, size.height * 0.24)
      ..lineTo(size.width * 0.47, size.height * 0.56)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.61,
        size.width * 0.55,
        size.height * 0.59,
      );
    canvas.drawPath(nose, line);

    final smile = Path()
      ..moveTo(size.width * 0.25, size.height * 0.67)
      ..cubicTo(
        size.width * 0.37,
        size.height * 0.84,
        size.width * 0.62,
        size.height * 0.86,
        size.width * 0.76,
        size.height * 0.65,
      );
    canvas.drawPath(smile, line);
  }

  void _drawSkills(Canvas canvas, Size size) {
    final unit = size.width;
    final radius = Radius.circular(unit * 0.065);
    void capsule(Rect rect, Color color) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, radius),
        Paint()..color = color,
      );
    }

    const red = Color(0xFFE01E5A);
    const green = Color(0xFF2EB67D);
    const yellow = Color(0xFFECB22E);
    const blue = Color(0xFF36C5F0);

    capsule(
      Rect.fromLTWH(unit * 0.16, unit * 0.3, unit * 0.35, unit * 0.13),
      red,
    );
    canvas.drawCircle(
      Offset(unit * 0.37, unit * 0.21),
      unit * 0.065,
      Paint()..color = red,
    );
    capsule(
      Rect.fromLTWH(unit * 0.57, unit * 0.16, unit * 0.13, unit * 0.35),
      green,
    );
    canvas.drawCircle(
      Offset(unit * 0.79, unit * 0.37),
      unit * 0.065,
      Paint()..color = green,
    );
    capsule(
      Rect.fromLTWH(unit * 0.49, unit * 0.57, unit * 0.35, unit * 0.13),
      yellow,
    );
    canvas.drawCircle(
      Offset(unit * 0.63, unit * 0.79),
      unit * 0.065,
      Paint()..color = yellow,
    );
    capsule(
      Rect.fromLTWH(unit * 0.3, unit * 0.49, unit * 0.13, unit * 0.35),
      blue,
    );
    canvas.drawCircle(
      Offset(unit * 0.21, unit * 0.63),
      unit * 0.065,
      Paint()..color = blue,
    );
  }

  void _drawProjects(Canvas canvas, Size size) {
    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.18);
    final rearFolder = Path()
      ..moveTo(size.width * 0.17, size.height * 0.35)
      ..quadraticBezierTo(
        size.width * 0.17,
        size.height * 0.27,
        size.width * 0.25,
        size.height * 0.27,
      )
      ..lineTo(size.width * 0.42, size.height * 0.27)
      ..lineTo(size.width * 0.49, size.height * 0.34)
      ..lineTo(size.width * 0.78, size.height * 0.34)
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.34,
        size.width * 0.84,
        size.height * 0.42,
      )
      ..lineTo(size.width * 0.8, size.height * 0.69)
      ..lineTo(size.width * 0.17, size.height * 0.69)
      ..close();
    canvas.save();
    canvas.translate(0, size.height * 0.045);
    canvas.drawPath(rearFolder, shadow);
    canvas.restore();
    canvas.drawPath(rearFolder, Paint()..color = const Color(0xFF0B5DBB));

    final frontFolder = Path()
      ..moveTo(size.width * 0.12, size.height * 0.43)
      ..quadraticBezierTo(
        size.width * 0.13,
        size.height * 0.38,
        size.width * 0.19,
        size.height * 0.38,
      )
      ..lineTo(size.width * 0.87, size.height * 0.38)
      ..lineTo(size.width * 0.79, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.8,
        size.width * 0.71,
        size.height * 0.8,
      )
      ..lineTo(size.width * 0.2, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.14,
        size.height * 0.8,
        size.width * 0.13,
        size.height * 0.74,
      )
      ..close();
    final folderPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFF69D8FF), Color(0xFF1594ED)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(frontFolder, folderPaint);
  }

  void _drawTerminal(Canvas canvas, Size size) {
    final prompt = TextPainter(
      text: TextSpan(
        text: '>_',
        style: TextStyle(
          color: const Color(0xFFB8FFD4),
          fontFamily: 'monospace',
          fontSize: size.width * 0.36,
          fontWeight: FontWeight.w700,
          height: 1,
          letterSpacing: -size.width * 0.035,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    prompt.paint(canvas, Offset(size.width * 0.17, size.height * 0.34));
    prompt.dispose();
  }

  void _drawTrash(Canvas canvas, Size size) {
    final unit = size.width;
    final contents = AppleAppArtwork.colorsFor(PortfolioAppId.trash);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(unit * 0.5, size.height * 0.9),
        width: unit * 0.52,
        height: size.height * 0.12,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.045),
    );

    final contentShapes = <Path>[
      Path()
        ..moveTo(unit * 0.25, size.height * 0.43)
        ..lineTo(unit * 0.3, size.height * 0.14)
        ..lineTo(unit * 0.48, size.height * 0.22)
        ..lineTo(unit * 0.45, size.height * 0.48)
        ..close(),
      Path()
        ..moveTo(unit * 0.36, size.height * 0.43)
        ..lineTo(unit * 0.44, size.height * 0.1)
        ..lineTo(unit * 0.61, size.height * 0.18)
        ..lineTo(unit * 0.57, size.height * 0.47)
        ..close(),
      Path()
        ..moveTo(unit * 0.48, size.height * 0.45)
        ..lineTo(unit * 0.59, size.height * 0.16)
        ..lineTo(unit * 0.75, size.height * 0.27)
        ..lineTo(unit * 0.68, size.height * 0.5)
        ..close(),
      Path()
        ..moveTo(unit * 0.18, size.height * 0.36)
        ..lineTo(unit * 0.3, size.height * 0.23)
        ..lineTo(unit * 0.43, size.height * 0.4)
        ..lineTo(unit * 0.31, size.height * 0.52)
        ..close(),
      Path()
        ..moveTo(unit * 0.57, size.height * 0.39)
        ..lineTo(unit * 0.72, size.height * 0.18)
        ..lineTo(unit * 0.84, size.height * 0.35)
        ..lineTo(unit * 0.7, size.height * 0.52)
        ..close(),
    ];
    for (var index = 0; index < contentShapes.length; index++) {
      canvas.drawPath(
        contentShapes[index],
        Paint()..color = contents[index % contents.length],
      );
    }

    final bin = Path()
      ..moveTo(unit * 0.2, size.height * 0.34)
      ..quadraticBezierTo(
        unit * 0.21,
        size.height * 0.29,
        unit * 0.27,
        size.height * 0.3,
      )
      ..lineTo(unit * 0.73, size.height * 0.3)
      ..quadraticBezierTo(
        unit * 0.79,
        size.height * 0.29,
        unit * 0.8,
        size.height * 0.34,
      )
      ..lineTo(unit * 0.72, size.height * 0.86)
      ..quadraticBezierTo(
        unit * 0.71,
        size.height * 0.91,
        unit * 0.65,
        size.height * 0.92,
      )
      ..lineTo(unit * 0.35, size.height * 0.92)
      ..quadraticBezierTo(
        unit * 0.29,
        size.height * 0.91,
        unit * 0.28,
        size.height * 0.86,
      )
      ..close();
    canvas.drawPath(
      bin,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.92),
            const Color(0xFFB7C1CD).withValues(alpha: 0.76),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      bin,
      Paint()
        ..color = const Color(0xFF8E99A6).withValues(alpha: 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.9, unit * 0.018),
    );

    final rib = Paint()
      ..color = Colors.white.withValues(alpha: 0.62)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.7, unit * 0.012)
      ..strokeCap = StrokeCap.round;
    for (final x in <double>[0.35, 0.43, 0.51, 0.59, 0.67]) {
      canvas.drawLine(
        Offset(unit * x, size.height * 0.39),
        Offset(unit * (0.5 + (x - 0.5) * 0.75), size.height * 0.84),
        rib,
      );
    }

    final rim = RRect.fromRectAndRadius(
      Rect.fromLTWH(unit * 0.17, size.height * 0.29, unit * 0.66, unit * 0.13),
      Radius.circular(unit * 0.065),
    );
    canvas.drawRRect(
      rim,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFF9FCFF), Color(0xFFB8C1CB)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRRect(
      rim,
      Paint()
        ..color = const Color(0xFF87919D).withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, unit * 0.014),
    );
  }

  void _drawMail(Canvas canvas, Size size) {
    final envelopeRect = Rect.fromLTWH(
      size.width * 0.14,
      size.height * 0.24,
      size.width * 0.72,
      size.height * 0.53,
    );
    final envelope = RRect.fromRectAndRadius(
      envelopeRect,
      Radius.circular(size.width * 0.075),
    );
    canvas.drawRRect(
      envelope.shift(Offset(0, size.height * 0.045)),
      Paint()..color = Colors.black.withValues(alpha: 0.2),
    );
    canvas.drawRRect(envelope, Paint()..color = const Color(0xFFF8FCFF));

    final foldPaint = Paint()
      ..color = const Color(0xFF1D73D2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.035
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final topFold = Path()
      ..moveTo(envelopeRect.left + size.width * 0.04, envelopeRect.top)
      ..lineTo(size.width * 0.5, size.height * 0.55)
      ..lineTo(envelopeRect.right - size.width * 0.04, envelopeRect.top);
    canvas.drawPath(topFold, foldPaint);

    final bottomFold = Path()
      ..moveTo(envelopeRect.left + size.width * 0.035, envelopeRect.bottom)
      ..lineTo(size.width * 0.39, size.height * 0.54)
      ..moveTo(envelopeRect.right - size.width * 0.035, envelopeRect.bottom)
      ..lineTo(size.width * 0.61, size.height * 0.54);
    canvas.drawPath(bottomFold, foldPaint);
  }

  void _drawSettings(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const teeth = 10;
    final gear = Path();
    for (var index = 0; index < teeth * 4; index++) {
      final phase = index % 4;
      final radius = switch (phase) {
        0 || 1 => size.width * 0.37,
        _ => size.width * 0.29,
      };
      final angle = -math.pi / 2 + index * math.pi * 2 / (teeth * 4);
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      if (index == 0) {
        gear.moveTo(point.dx, point.dy);
      } else {
        gear.lineTo(point.dx, point.dy);
      }
    }
    gear.close();

    final hubHole = Path()
      ..addOval(Rect.fromCircle(center: center, radius: size.width * 0.115));
    final cutGear = Path.combine(PathOperation.difference, gear, hubHole);

    canvas.save();
    canvas.translate(0, size.height * 0.045);
    canvas.drawPath(
      cutGear,
      Paint()..color = Colors.black.withValues(alpha: 0.24),
    );
    canvas.restore();

    final gearPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xFFFFFFFF), Color(0xFFCED3DA)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(cutGear, gearPaint);
    canvas.drawCircle(
      center,
      size.width * 0.11,
      Paint()..color = const Color(0xFF69717D),
    );
    canvas.drawCircle(
      center.translate(-size.width * 0.025, -size.height * 0.03),
      size.width * 0.045,
      Paint()..color = Colors.white.withValues(alpha: 0.42),
    );
  }

  @override
  bool shouldRepaint(covariant _AppleAppArtworkPainter oldDelegate) {
    return oldDelegate.appId != appId;
  }
}
