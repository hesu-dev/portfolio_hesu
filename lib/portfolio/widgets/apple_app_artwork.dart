import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/portfolio_app_id.dart';
import '../theme/apple_theme.dart';

enum AppleAppArtworkSurface { desktop, mobile }

/// The normalized launcher frame shared by macOS, iPadOS, and iOS surfaces.
///
/// App artwork owns its silhouette while this frame supplies only the backing
/// appropriate to its launcher surface. Mobile transparent artwork receives a
/// shared translucent rounded tile; desktop silhouettes remain unbacked.
class AppleAppArtworkFrame extends StatelessWidget {
  static const double mobileTileOpacity = 0.5;

  const AppleAppArtworkFrame({
    required this.appId,
    required this.size,
    this.frameKey,
    this.foregroundColor,
    this.surface = AppleAppArtworkSurface.desktop,
    this.trashEmpty = false,
    super.key,
  }) : assert(size > 0);

  final PortfolioAppId appId;
  final double size;
  final Key? frameKey;
  final Color? foregroundColor;
  final AppleAppArtworkSurface surface;
  final bool trashEmpty;

  @override
  Widget build(BuildContext context) {
    final transparent = AppleAppArtwork.usesTransparentFrame(appId);
    final mobileTranslucentTile =
        surface == AppleAppArtworkSurface.mobile &&
        AppleAppArtwork.usesMobileTranslucentTile(appId);
    final rounded = !transparent || mobileTranslucentTile;
    final effectiveForegroundColor =
        foregroundColor ??
        (mobileTranslucentTile && appId == PortfolioAppId.github
            ? Colors.black
            : null);
    return Container(
      key: frameKey,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: mobileTranslucentTile
            ? Colors.white.withValues(alpha: mobileTileOpacity)
            : null,
        borderRadius: rounded ? BorderRadius.circular(size * 0.28) : null,
        boxShadow: const <BoxShadow>[],
      ),
      child: mobileTranslucentTile
          ? ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.28),
              child: Padding(
                padding: EdgeInsets.all(size * 0.07),
                child: AppleAppArtwork(
                  appId: appId,
                  size: size,
                  foregroundColor: effectiveForegroundColor,
                  trashEmpty: trashEmpty,
                  includeBackground: false,
                ),
              ),
            )
          : Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: <Widget>[
                AppleAppArtwork(
                  appId: appId,
                  size: size,
                  foregroundColor: effectiveForegroundColor,
                  trashEmpty: trashEmpty,
                ),
              ],
            ),
    );
  }
}

/// Normalized artwork shared by every portfolio app launcher.
///
/// Supplied brand artwork is rendered from bundled assets, while the remaining
/// primary app marks and Trash use scalable Flutter paths. Utility apps keep
/// their established Material glyphs for visual continuity with the desktop.
class AppleAppArtwork extends StatelessWidget {
  const AppleAppArtwork({
    required this.appId,
    required this.size,
    this.foregroundColor,
    this.trashEmpty = false,
    this.includeBackground = true,
    super.key,
  }) : assert(size > 0);

  final PortfolioAppId appId;
  final double size;
  final Color? foregroundColor;
  final bool trashEmpty;
  final bool includeBackground;

  static bool usesBespokeArtwork(PortfolioAppId appId) => switch (appId) {
    PortfolioAppId.profile ||
    PortfolioAppId.about ||
    PortfolioAppId.skills ||
    PortfolioAppId.projects ||
    PortfolioAppId.terminal ||
    PortfolioAppId.music ||
    PortfolioAppId.photos ||
    PortfolioAppId.mail ||
    PortfolioAppId.settings ||
    PortfolioAppId.trash => true,
    PortfolioAppId.introduction ||
    PortfolioAppId.thisMac ||
    PortfolioAppId.github => false,
  };

  static String? assetPathFor(PortfolioAppId appId) => switch (appId) {
    PortfolioAppId.introduction => 'assets/icons/microsoft-word.png',
    PortfolioAppId.github => 'assets/icons/github.svg',
    _ => null,
  };

  static bool usesTransparentFrame(PortfolioAppId appId) => switch (appId) {
    PortfolioAppId.projects ||
    PortfolioAppId.trash ||
    PortfolioAppId.github => true,
    _ => false,
  };

  static bool usesMobileTranslucentTile(PortfolioAppId appId) =>
      switch (appId) {
        PortfolioAppId.introduction ||
        PortfolioAppId.projects ||
        PortfolioAppId.github ||
        PortfolioAppId.trash => true,
        _ => false,
      };

  static List<Color> colorsFor(PortfolioAppId appId) => switch (appId) {
    PortfolioAppId.profile => const <Color>[
      Color(0xFF833AB4),
      Color(0xFFE1306C),
      Color(0xFFFCAF45),
    ],
    PortfolioAppId.about => const <Color>[Color(0xFF79DCFF), Color(0xFF2167E8)],
    PortfolioAppId.introduction => const <Color>[
      Color(0x00000000),
      Color(0x00000000),
    ],
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
    PortfolioAppId.music => const <Color>[Color(0xFFFF375F), Color(0xFFB5179E)],
    PortfolioAppId.photos => const <Color>[
      Color(0xFFFF3B30),
      Color(0xFFFF9500),
      Color(0xFFFFCC00),
      Color(0xFF34C759),
      Color(0xFF00C7BE),
      Color(0xFF007AFF),
      Color(0xFF5856D6),
      Color(0xFFFF2D55),
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
      Color(0x00000000),
      Color(0x00000000),
    ],
    PortfolioAppId.mail => const <Color>[Color(0xFF5ED4FF), Color(0xFF0868E8)],
  };

  static IconData utilityIconFor(PortfolioAppId appId) => switch (appId) {
    PortfolioAppId.thisMac => Icons.folder_copy_rounded,
    _ => throw ArgumentError.value(
      appId,
      'appId',
      'Asset-backed and primary app artwork do not use a Material icon.',
    ),
  };

  Widget _buildAssetArtwork(BuildContext context, String assetPath) {
    final Widget image = assetPath.endsWith('.svg')
        ? SvgPicture.asset(
            assetPath,
            key: Key('apple-app-artwork-${appId.name}-svg'),
            width: size,
            height: size,
            fit: BoxFit.contain,
            theme: SvgTheme(
              currentColor: foregroundColor ?? AppleTheme.primaryLabel(context),
            ),
          )
        : Image.asset(
            assetPath,
            key: Key('apple-app-artwork-${appId.name}-image'),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          );

    if (appId == PortfolioAppId.introduction) {
      return Padding(
        key: Key('apple-app-artwork-${appId.name}-inset'),
        padding: EdgeInsets.all(size * 0.06),
        child: image,
      );
    }
    return image;
  }

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.28;
    final bespoke = usesBespokeArtwork(appId);
    final transparentFrame = !includeBackground || usesTransparentFrame(appId);
    final assetPath = assetPathFor(appId);

    final Widget artwork = assetPath == null
        ? switch (appId) {
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
            PortfolioAppId.trash => CustomPaint(
              key: Key(
                'apple-app-artwork-trash-${trashEmpty ? 'empty' : 'filled'}',
              ),
              painter: _AppleAppArtworkPainter(appId, trashEmpty: trashEmpty),
              child: const SizedBox.expand(),
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
          }
        : _buildAssetArtwork(context, assetPath);

    final content = transparentFrame
        ? Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: <Widget>[artwork],
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: appId == PortfolioAppId.photos
                    ? const <Color>[Color(0xFFFFFFFF), Color(0xFFF4F4F6)]
                    : colorsFor(appId),
              ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.44),
                width: math.max(0.5, size * 0.014),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: artwork,
            ),
          );

    return SizedBox.square(
      dimension: size,
      child: ExcludeSemantics(
        key: Key('apple-app-artwork-${appId.name}'),
        child: content,
      ),
    );
  }
}

class _AppleAppArtworkPainter extends CustomPainter {
  const _AppleAppArtworkPainter(this.appId, {this.trashEmpty = false});

  final PortfolioAppId appId;
  final bool trashEmpty;

  @override
  void paint(Canvas canvas, Size size) {
    if (!AppleAppArtwork.usesTransparentFrame(appId) &&
        appId != PortfolioAppId.terminal) {
      _drawGlassHighlight(canvas, size);
    }
    switch (appId) {
      case PortfolioAppId.profile:
        _drawProfile(canvas, size);
      case PortfolioAppId.about:
        _drawAbout(canvas, size);
      case PortfolioAppId.introduction:
      case PortfolioAppId.github:
        throw StateError('Asset artwork is rendered by Image.asset.');
      case PortfolioAppId.skills:
        _drawSkills(canvas, size);
      case PortfolioAppId.projects:
        _drawProjects(canvas, size);
      case PortfolioAppId.terminal:
        _drawTerminal(canvas, size);
      case PortfolioAppId.music:
        _drawMusic(canvas, size);
      case PortfolioAppId.photos:
        _drawPhotos(canvas, size);
      case PortfolioAppId.mail:
        _drawMail(canvas, size);
      case PortfolioAppId.settings:
        _drawSettings(canvas, size);
      case PortfolioAppId.trash:
        _drawTrash(canvas, size, empty: trashEmpty);
      case PortfolioAppId.thisMac:
        throw StateError('Utility artwork is rendered by its existing glyph.');
    }
  }

  void _drawProfile(Canvas canvas, Size size) {
    final unit = size.shortestSide;
    final center = size.center(Offset.zero);
    final ring = Paint()
      ..color = Colors.white.withValues(alpha: 0.94)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.8, unit * 0.055);
    canvas.drawCircle(center, unit * 0.31, ring);

    final silhouette = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(center.dx, size.height * 0.4),
      unit * 0.115,
      silhouette,
    );

    final shoulders = Path()
      ..moveTo(size.width * 0.28, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.31,
        size.height * 0.54,
        center.dx,
        size.height * 0.54,
      )
      ..quadraticBezierTo(
        size.width * 0.69,
        size.height * 0.54,
        size.width * 0.72,
        size.height * 0.7,
      )
      ..quadraticBezierTo(
        center.dx,
        size.height * 0.79,
        size.width * 0.28,
        size.height * 0.7,
      )
      ..close();
    canvas.drawPath(shoulders, silhouette);
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

  void _drawMusic(Canvas canvas, Size size) {
    final unit = size.shortestSide;
    final note = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final beam = Path()
      ..moveTo(size.width * 0.35, size.height * 0.28)
      ..lineTo(size.width * 0.72, size.height * 0.2)
      ..lineTo(size.width * 0.72, size.height * 0.32)
      ..lineTo(size.width * 0.35, size.height * 0.4)
      ..close();
    canvas.drawPath(beam, note);

    final stem = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = unit * 0.075
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.37, size.height * 0.34),
      Offset(size.width * 0.37, size.height * 0.69),
      stem,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, size.height * 0.27),
      Offset(size.width * 0.7, size.height * 0.61),
      stem,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.29, size.height * 0.72),
        width: unit * 0.25,
        height: unit * 0.18,
      ),
      note,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.62, size.height * 0.64),
        width: unit * 0.25,
        height: unit * 0.18,
      ),
      note,
    );
  }

  void _drawPhotos(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final palette = AppleAppArtwork.colorsFor(PortfolioAppId.photos);

    for (var index = 0; index < palette.length; index++) {
      final angle = (math.pi * 2 * index) / palette.length;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -size.height * 0.19),
          width: size.width * 0.23,
          height: size.height * 0.38,
        ),
        Paint()..color = palette[index].withValues(alpha: 0.92),
      );
      canvas.restore();
    }

    canvas.drawCircle(
      center,
      size.shortestSide * 0.105,
      Paint()..color = const Color(0xF2FFFFFF),
    );
  }

  void _drawTrash(Canvas canvas, Size size, {required bool empty}) {
    final unit = size.width;
    final contents = AppleAppArtwork.colorsFor(PortfolioAppId.trash);

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
    if (!empty) {
      for (var index = 0; index < contentShapes.length; index++) {
        canvas.drawPath(
          contentShapes[index],
          Paint()..color = contents[index % contents.length],
        );
      }
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
    return oldDelegate.appId != appId || oldDelegate.trashEmpty != trashEmpty;
  }
}
