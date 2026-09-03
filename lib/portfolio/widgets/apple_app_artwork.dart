import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/portfolio_app_id.dart';

/// Scalable, code-native artwork shared by every portfolio app launcher.
///
/// Primary app marks are drawn with Flutter paths instead of bundled platform
/// artwork. Utility apps keep their established Material glyphs for visual
/// continuity with the existing desktop.
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
    PortfolioAppId.settings => true,
    PortfolioAppId.thisMac ||
    PortfolioAppId.github ||
    PortfolioAppId.trash => false,
  };

  static List<Color> colorsFor(PortfolioAppId appId) => switch (appId) {
    PortfolioAppId.about => const <Color>[Color(0xFF79DCFF), Color(0xFF2167E8)],
    PortfolioAppId.skills => const <Color>[
      Color(0xFF35364A),
      Color(0xFF171824),
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
      Color(0xFF8C8C91),
      Color(0xFF3B3C42),
    ],
    PortfolioAppId.trash => const <Color>[Color(0xFFF4F5F7), Color(0xFFA9ADB5)],
    PortfolioAppId.github => const <Color>[
      Color(0xFF42454D),
      Color(0xFF111216),
    ],
    PortfolioAppId.mail => const <Color>[Color(0xFF5ED4FF), Color(0xFF0868E8)],
  };

  static IconData utilityIconFor(PortfolioAppId appId) => switch (appId) {
    PortfolioAppId.thisMac => Icons.laptop_mac_rounded,
    PortfolioAppId.github => Icons.code_rounded,
    PortfolioAppId.trash => Icons.delete_rounded,
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

    return SizedBox.square(
      dimension: size,
      child: ExcludeSemantics(
        key: Key('apple-app-artwork-${appId.name}'),
        child: DecoratedBox(
          decoration: BoxDecoration(
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
            borderRadius: BorderRadius.circular(radius),
            child: bespoke
                ? CustomPaint(
                    painter: _AppleAppArtworkPainter(appId),
                    child: const SizedBox.expand(),
                  )
                : Center(
                    child: Icon(
                      utilityIconFor(appId),
                      color: appId == PortfolioAppId.trash
                          ? const Color(0xFF4D5058)
                          : Colors.white,
                      size: size * 0.5,
                    ),
                  ),
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
    _drawGlassHighlight(canvas, size);
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
      case PortfolioAppId.thisMac:
      case PortfolioAppId.trash:
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
    final center = size.center(Offset.zero);
    canvas.drawCircle(
      center,
      size.width * 0.12,
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );

    const colors = <Color>[
      Color(0xFF36C5B5),
      Color(0xFFF4C94C),
      Color(0xFFED5C73),
      Color(0xFFB779E8),
    ];
    const angles = <double>[-2.3, -0.72, 0.84, 2.42];

    for (var index = 0; index < colors.length; index++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angles[index]);
      final capsule = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.03,
          -size.height * 0.09,
          size.width * 0.34,
          size.height * 0.18,
        ),
        Radius.circular(size.width * 0.1),
      );
      canvas.drawRRect(
        capsule.shift(Offset(0, size.height * 0.025)),
        Paint()..color = Colors.black.withValues(alpha: 0.18),
      );
      canvas.drawRRect(capsule, Paint()..color = colors[index]);
      canvas.restore();
    }
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

    final paper = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.31,
        size.height * 0.31,
        size.width * 0.46,
        size.height * 0.35,
      ),
      Radius.circular(size.width * 0.045),
    );
    canvas.drawRRect(paper, Paint()..color = const Color(0xFFEFFBFF));
    final paperLine = Paint()
      ..color = const Color(0xFF8BCDF5)
      ..strokeWidth = size.width * 0.025
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 0.43),
      Offset(size.width * 0.69, size.height * 0.43),
      paperLine,
    );
    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 0.51),
      Offset(size.width * 0.62, size.height * 0.51),
      paperLine,
    );

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
    final panel = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.12,
        size.height * 0.17,
        size.width * 0.76,
        size.height * 0.66,
      ),
      Radius.circular(size.width * 0.1),
    );
    canvas.drawRRect(
      panel.shift(Offset(0, size.height * 0.035)),
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );
    canvas.drawRRect(panel, Paint()..color = const Color(0xFF0B0D11));

    final prompt = TextPainter(
      text: TextSpan(
        text: '>_',
        style: TextStyle(
          color: const Color(0xFFB8FFD4),
          fontFamily: 'monospace',
          fontSize: size.width * 0.32,
          fontWeight: FontWeight.w700,
          height: 1,
          letterSpacing: -size.width * 0.035,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    prompt.paint(canvas, Offset(size.width * 0.2, size.height * 0.37));
    prompt.dispose();
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
