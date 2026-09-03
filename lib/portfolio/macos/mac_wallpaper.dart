import 'package:flutter/material.dart';

/// An original, code-native desktop composition inspired by modern macOS.
///
/// No bitmap or platform artwork is loaded by this widget. Both variants are
/// painted from deterministic Flutter gradients and paths so they stay crisp
/// at every desktop size.
class MacWallpaper extends StatelessWidget {
  const MacWallpaper({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final variantKey = brightness == Brightness.dark
        ? const Key('mac-wallpaper-dark')
        : const Key('mac-wallpaper-light');

    return RepaintBoundary(
      key: const Key('mac-wallpaper'),
      child: CustomPaint(
        key: variantKey,
        painter: _MacWallpaperPainter(brightness),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _MacWallpaperPainter extends CustomPainter {
  const _MacWallpaperPainter(this.brightness);

  final Brightness brightness;

  bool get _dark => brightness == Brightness.dark;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final base = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _dark
            ? const <Color>[
                Color(0xFF090C20),
                Color(0xFF221441),
                Color(0xFF102D51),
              ]
            : const <Color>[
                Color(0xFFBCEAFF),
                Color(0xFFE9D8FF),
                Color(0xFFFFD5A6),
              ],
        stops: const <double>[0, 0.48, 1],
      ).createShader(bounds);
    canvas.drawRect(bounds, base);

    _drawGlow(
      canvas,
      size,
      center: Offset(size.width * 0.77, size.height * 0.13),
      radius: size.longestSide * 0.52,
      color: _dark ? const Color(0xFF26E3D2) : const Color(0xFF5BC5FF),
      opacity: _dark ? 0.28 : 0.48,
    );
    _drawGlow(
      canvas,
      size,
      center: Offset(size.width * 0.14, size.height * 0.8),
      radius: size.longestSide * 0.58,
      color: _dark ? const Color(0xFFFF3D9E) : const Color(0xFFFF647B),
      opacity: _dark ? 0.22 : 0.36,
    );

    _drawFlowingLayer(
      canvas,
      size,
      top: 0.18,
      depth: 0.34,
      colors: _dark
          ? const <Color>[Color(0xFF315FF4), Color(0xFF7644E7)]
          : const <Color>[Color(0xFF178FE8), Color(0xFF677AF4)],
      opacity: _dark ? 0.72 : 0.68,
      rise: true,
    );
    _drawFlowingLayer(
      canvas,
      size,
      top: 0.43,
      depth: 0.39,
      colors: _dark
          ? const <Color>[Color(0xFFA63FD2), Color(0xFFDF3C79)]
          : const <Color>[Color(0xFFF05978), Color(0xFFFF8B5B)],
      opacity: _dark ? 0.68 : 0.86,
      rise: false,
    );
    _drawFlowingLayer(
      canvas,
      size,
      top: 0.68,
      depth: 0.42,
      colors: _dark
          ? const <Color>[Color(0xFF3B1F74), Color(0xFF101D45)]
          : const <Color>[Color(0xFF6841AD), Color(0xFF243E72)],
      opacity: _dark ? 0.86 : 0.74,
      rise: true,
    );

    final sheen = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Colors.white.withValues(alpha: _dark ? 0.08 : 0.22),
          Colors.transparent,
          Colors.black.withValues(alpha: _dark ? 0.28 : 0.1),
        ],
        stops: const <double>[0, 0.5, 1],
      ).createShader(bounds);
    canvas.drawRect(bounds, sheen);
  }

  void _drawGlow(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required Color color,
    required double opacity,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          color.withValues(alpha: opacity),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _drawFlowingLayer(
    Canvas canvas,
    Size size, {
    required double top,
    required double depth,
    required List<Color> colors,
    required double opacity,
    required bool rise,
  }) {
    final y = size.height * top;
    final direction = rise ? -1.0 : 1.0;
    final path = Path()
      ..moveTo(-size.width * 0.08, y + size.height * depth * 0.25)
      ..cubicTo(
        size.width * 0.18,
        y + size.height * depth * direction,
        size.width * 0.42,
        y - size.height * depth * direction * 0.45,
        size.width * 0.66,
        y + size.height * depth * direction * 0.22,
      )
      ..cubicTo(
        size.width * 0.82,
        y + size.height * depth * direction * 0.72,
        size.width * 1.02,
        y - size.height * depth * direction * 0.15,
        size.width * 1.08,
        y + size.height * depth * 0.32,
      )
      ..lineTo(size.width * 1.08, size.height * 1.15)
      ..lineTo(-size.width * 0.08, size.height * 1.15)
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: colors
            .map((color) => color.withValues(alpha: opacity))
            .toList(growable: false),
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, paint);

    final highlightPath = Path()
      ..moveTo(-size.width * 0.06, y + size.height * depth * 0.2)
      ..cubicTo(
        size.width * 0.25,
        y + size.height * depth * direction * 0.9,
        size.width * 0.48,
        y - size.height * depth * direction * 0.35,
        size.width * 0.72,
        y + size.height * depth * direction * 0.3,
      );
    canvas.drawPath(
      highlightPath,
      Paint()
        ..color = Colors.white.withValues(alpha: _dark ? 0.07 : 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.018
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );
  }

  @override
  bool shouldRepaint(covariant _MacWallpaperPainter oldDelegate) {
    return brightness != oldDelegate.brightness;
  }
}
