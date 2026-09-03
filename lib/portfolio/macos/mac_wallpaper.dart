import 'package:flutter/material.dart';

class MacWallpaper extends StatelessWidget {
  const MacWallpaper({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: const Key('mac-wallpaper'),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF102050),
              Color(0xFF2A1B67),
              Color(0xFF0D5780),
            ],
            stops: <double>[0, 0.48, 1],
          ),
        ),
        child: const CustomPaint(
          painter: _AuroraWallpaperPainter(),
          child: SizedBox.expand(),
        ),
      ),
    );
  }
}

class _AuroraWallpaperPainter extends CustomPainter {
  const _AuroraWallpaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final wash = Paint()
      ..shader =
          RadialGradient(
            colors: <Color>[
              const Color(0xFF65E5D4).withValues(alpha: 0.48),
              const Color(0xFF65E5D4).withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.75, size.height * 0.16),
              radius: size.longestSide * 0.58,
            ),
          );
    canvas.drawRect(Offset.zero & size, wash);

    _drawRibbon(
      canvas,
      size,
      start: Offset(-size.width * 0.12, size.height * 0.8),
      control1: Offset(size.width * 0.16, size.height * 0.14),
      control2: Offset(size.width * 0.5, size.height * 1.1),
      end: Offset(size.width * 1.1, size.height * 0.24),
      colors: <Color>[
        const Color(0xFF7B5CFA).withValues(alpha: 0.72),
        const Color(0xFF2DD4BF).withValues(alpha: 0.38),
      ],
      strokeWidth: size.shortestSide * 0.27,
    );
    _drawRibbon(
      canvas,
      size,
      start: Offset(-size.width * 0.08, size.height * 0.24),
      control1: Offset(size.width * 0.26, size.height * 0.58),
      control2: Offset(size.width * 0.7, -size.height * 0.08),
      end: Offset(size.width * 1.08, size.height * 0.62),
      colors: <Color>[
        const Color(0xFF64D8FF).withValues(alpha: 0.3),
        const Color(0xFFFF73B9).withValues(alpha: 0.32),
      ],
      strokeWidth: size.shortestSide * 0.2,
    );

    final vignette = Paint()
      ..shader = RadialGradient(
        radius: 0.95,
        colors: <Color>[
          Colors.transparent,
          const Color(0xFF070A22).withValues(alpha: 0.38),
        ],
        stops: const <double>[0.52, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  void _drawRibbon(
    Canvas canvas,
    Size size, {
    required Offset start,
    required Offset control1,
    required Offset control2,
    required Offset end,
    required List<Color> colors,
    required double strokeWidth,
  }) {
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        control1.dx,
        control1.dy,
        control2.dx,
        control2.dy,
        end.dx,
        end.dy,
      );
    final bounds = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 54)
      ..shader = LinearGradient(colors: colors).createShader(bounds);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AuroraWallpaperPainter oldDelegate) => false;
}
