import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pixel_text_layout.dart';

/// A pixel-art study scene with deterministic stat-up timing.
class EducationPixelStudy extends StatefulWidget {
  const EducationPixelStudy({super.key});

  static const headerLabel = 'LEARNING';
  static const sessionCompleteLabel = 'SESSION COMPLETE';
  static const studySpriteAsset = 'assets/sprites/education_student_study.png';
  static const studySheetSize = Size(1536, 1024);
  static const studyFrameBottomPadding = 8.0;
  static const studyDecodeWidth = 384;

  static const semanticsLabel =
      '갈색 포니테일과 안경을 쓴 캐릭터가 현대적인 도서관 컴퓨터실에서 '
      '계속 공부하며 FLUTTER, DART, UX, SOLVE 능력치를 차례로 올리는 도트 애니메이션';

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
    RangeError.checkValidIndex(frameIndex, studySourceFrames, 'frameIndex');
    if (!scale.isFinite || scale <= 0) {
      throw ArgumentError.value(
        scale,
        'scale',
        'must be finite and greater than zero',
      );
    }
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

class _EducationPixelStudyState extends State<EducationPixelStudy>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(seconds: 4);
  static const _reducedMotionFrame = 0.72;

  late final AnimationController _timeline = AnimationController(
    vsync: this,
    duration: _duration,
  );
  final _textPainterCache = _StudyTextPainterCache();
  ui.Image? _studySpriteSheet;
  bool? _motionDisabled;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSpriteSheet());
  }

  Future<void> _loadSpriteSheet() async {
    late final ui.Image spriteSheet;
    try {
      spriteSheet = await _decodeAssetImage(
        EducationPixelStudy.studySpriteAsset,
        targetWidth: EducationPixelStudy.studyDecodeWidth,
      );
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'portfolio education pixel study',
          context: ErrorDescription('while loading the study sprite sheet'),
        ),
      );
      return;
    }

    if (!mounted) {
      spriteSheet.dispose();
      return;
    }
    setState(() {
      _studySpriteSheet = spriteSheet;
    });
  }

  Future<ui.Image> _decodeAssetImage(
    String assetPath, {
    required int targetWidth,
  }) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: targetWidth,
      allowUpscaling: false,
    );
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motionDisabled = MediaQuery.disableAnimationsOf(context);
    if (_motionDisabled == motionDisabled) {
      return;
    }
    _motionDisabled = motionDisabled;
    if (motionDisabled) {
      _timeline
        ..stop()
        ..value = _reducedMotionFrame;
    } else {
      _timeline.repeat();
    }
  }

  @override
  void dispose() {
    _timeline.dispose();
    _studySpriteSheet?.dispose();
    _textPainterCache.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motionDisabled = _motionDisabled ?? true;
    return Semantics(
      label: EducationPixelStudy.semanticsLabel,
      image: true,
      excludeSemantics: true,
      child: RepaintBoundary(
        child: SizedBox.expand(
          child: CustomPaint(
            painter: _EducationPixelStudyPainter(
              timeline: _timeline,
              brightness: Theme.of(context).brightness,
              studySpriteSheet: _studySpriteSheet,
              textPainterCache: _textPainterCache,
              repaint: _timeline,
            ),
            isComplex: true,
            willChange: !motionDisabled,
          ),
        ),
      ),
    );
  }
}

class _EducationPixelStudyPainter extends CustomPainter {
  _EducationPixelStudyPainter({
    required this.timeline,
    required this.brightness,
    required this.studySpriteSheet,
    required this.textPainterCache,
    required Listenable repaint,
  }) : super(repaint: repaint);

  static const _sceneHeight = 144.0;
  static const _spriteScale = 0.165;
  static const _baseStats = <int>[86, 79, 68, 74];
  static const _barProgress = <double>[0.70, 0.62, 0.54, 0.59];

  final Animation<double> timeline;
  final Brightness brightness;
  final ui.Image? studySpriteSheet;
  final _StudyTextPainterCache textPainterCache;

  final Paint _fillPaint = Paint()..isAntiAlias = false;
  final Paint _spritePaint = Paint()
    ..isAntiAlias = false
    ..filterQuality = FilterQuality.none;

  _StudyPalette get _palette =>
      brightness == Brightness.dark ? _StudyPalette.dark : _StudyPalette.light;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final scale = size.height / _sceneHeight;
    final sceneWidth = size.width / scale;
    final progress = timeline.value % 1;
    final palette = _palette;

    canvas.save();
    canvas.scale(scale, scale);
    canvas.clipRect(Rect.fromLTWH(0, 0, sceneWidth, _sceneHeight));

    _drawRoom(canvas, sceneWidth, progress, palette);
    _drawBackgroundWorkstations(canvas, sceneWidth, progress, palette);
    final studyCenter = _studyCenterFor(sceneWidth);
    _drawForegroundWorkstationBack(
      canvas,
      sceneWidth,
      studyCenter,
      progress,
      palette,
    );
    _drawStudent(canvas, studyCenter, progress);
    _drawForegroundWorkstationFront(canvas, sceneWidth, studyCenter, palette);
    _drawHud(canvas, sceneWidth, progress, palette);
    _drawSessionComplete(canvas, sceneWidth, progress, palette);
    _drawLoopMask(canvas, sceneWidth, progress, palette);
    _drawOverlayScrims(canvas, sceneWidth);

    canvas.restore();
  }

  double _studyCenterFor(double width) {
    final availableWidth = math.max(80.0, width - 56);
    return (availableWidth * 0.62).clamp(96.0, 220.0).toDouble();
  }

  void _drawRoom(
    Canvas canvas,
    double width,
    double progress,
    _StudyPalette palette,
  ) {
    _rect(canvas, 0, 0, width, 64, palette.wall);
    _rect(canvas, 0, 0, width, 8, palette.ceiling);
    _rect(canvas, 0, 8, width, 2, palette.ceilingEdge);
    _rect(canvas, 0, 58, width, 6, palette.wallBase);

    final lightPulse = 0.82 + (math.sin(progress * math.pi * 8).abs() * 0.18);
    for (var x = 18.0; x < width + 36; x += 54) {
      _rect(canvas, x, 3, 27, 2, palette.ceilingLight);
      _rect(
        canvas,
        x + 4,
        5,
        19,
        2,
        palette.ceilingGlow.withValues(alpha: 0.18 * lightPulse),
      );
    }

    _drawBookcase(canvas, 3, 25, palette);
    if (width > 225) {
      _drawBookcase(canvas, 61, 30, palette);
    }
    _drawWindows(canvas, width, progress, palette);
    _drawGlassPartitions(canvas, width, palette);
    _drawFloor(canvas, width, palette);
  }

  void _drawBookcase(Canvas canvas, double x, double y, _StudyPalette palette) {
    _rect(canvas, x, y, 51, 38, palette.shelfEdge);
    _rect(canvas, x + 3, y + 3, 45, 32, palette.shelfBack);
    for (var shelf = 0; shelf < 3; shelf++) {
      final shelfY = y + 5 + (shelf * 10);
      for (var book = 0; book < 8; book++) {
        final bookHeight = 5.0 + ((book + shelf) % 3);
        final colors = palette.books;
        _rect(
          canvas,
          x + 5 + (book * 5),
          shelfY + 7 - bookHeight,
          book.isEven ? 3 : 4,
          bookHeight,
          colors[(book + (shelf * 2)) % colors.length],
        );
      }
      _rect(canvas, x + 3, shelfY + 7, 45, 2, palette.shelfTrim);
    }
  }

  void _drawWindows(
    Canvas canvas,
    double width,
    double progress,
    _StudyPalette palette,
  ) {
    final windowWidth = math.min(112.0, math.max(66.0, width * 0.43));
    final left = width - windowWidth - 5;
    _rect(canvas, left, 12, windowWidth, 41, palette.windowFrame);
    _rect(canvas, left + 3, 15, windowWidth - 6, 35, palette.windowSky);
    _rect(canvas, left + 3, 15, windowWidth - 6, 9, palette.windowGlow);

    final skylineColor = palette.windowSkyline;
    for (var index = 0; index < (windowWidth / 15).ceil(); index++) {
      final buildingHeight = 7.0 + ((index * 5) % 12);
      final x = left + 4 + (index * 15);
      _rect(canvas, x, 50 - buildingHeight, 11, buildingHeight, skylineColor);
      if ((index + (progress * 10).floor()).isEven) {
        _rect(canvas, x + 3, 44 - (index % 4), 2, 2, palette.windowLight);
      }
    }

    for (var x = left + 24; x < width - 7; x += 25) {
      _rect(canvas, x, 13, 3, 39, palette.windowFrame);
    }
    _rect(canvas, left + 2, 31, windowWidth - 4, 2, palette.windowFrame);
    _rect(canvas, left + 7, 17, 2, 29, palette.glassShine);
    _rect(canvas, left + 10, 17, 1, 18, palette.glassShine);
  }

  void _drawGlassPartitions(
    Canvas canvas,
    double width,
    _StudyPalette palette,
  ) {
    final first = (width * 0.39).roundToDouble();
    _rect(canvas, first, 13, 2, 48, palette.glassFrame);
    _rect(canvas, first + 3, 16, 1, 39, palette.glassShine);
    if (width > 255) {
      final second = (width * 0.58).roundToDouble();
      _rect(canvas, second, 10, 2, 51, palette.glassFrame);
      _rect(canvas, second + 3, 14, 1, 34, palette.glassShine);
    }
  }

  void _drawFloor(Canvas canvas, double width, _StudyPalette palette) {
    _rect(canvas, 0, 64, width, 80, palette.floor);
    for (var y = 72.0; y < _sceneHeight; y += 14) {
      _rect(canvas, 0, y, width, 1, palette.floorLine);
    }

    final lanes = math.max(4, (width / 48).ceil());
    for (var lane = 0; lane <= lanes; lane++) {
      final horizonX = (lane * width / lanes).roundToDouble();
      final bottomX = ((lane * width / lanes) + ((lane - (lanes / 2)) * 8))
          .roundToDouble();
      for (var y = 65.0; y < _sceneHeight; y += 4) {
        final t = (y - 65) / (_sceneHeight - 65);
        final x = horizonX + ((bottomX - horizonX) * t);
        _rect(canvas, x, y, 1, 4, palette.floorLine);
      }
    }
  }

  void _drawBackgroundWorkstations(
    Canvas canvas,
    double width,
    double progress,
    _StudyPalette palette,
  ) {
    var workstation = 0;
    for (var x = -13.0; x < width + 48; x += 63) {
      _drawSmallWorkstation(canvas, x, 76, workstation++, progress, palette);
    }
    workstation = 5;
    for (var x = 14.0; x < width + 55; x += 76) {
      _drawSmallWorkstation(canvas, x, 94, workstation++, progress, palette);
    }
  }

  void _drawSmallWorkstation(
    Canvas canvas,
    double x,
    double deskY,
    int variant,
    double progress,
    _StudyPalette palette,
  ) {
    _rect(canvas, x, deskY, 48, 4, palette.backDeskTop);
    _rect(canvas, x + 3, deskY + 4, 3, 10, palette.backDeskLeg);
    _rect(canvas, x + 42, deskY + 4, 3, 10, palette.backDeskLeg);
    _rect(canvas, x + 13, deskY - 20, 22, 15, palette.monitorEdge);
    _rect(canvas, x + 16, deskY - 17, 16, 9, palette.monitorScreen);
    _rect(canvas, x + 22, deskY - 5, 4, 5, palette.monitorStand);
    _rect(canvas, x + 18, deskY, 13, 2, palette.monitorStand);
    final blink = ((progress * 16).floor() + variant).isEven;
    _rect(canvas, x + 18, deskY - 14, blink ? 8 : 12, 1, palette.screenCode);
    _rect(canvas, x + 18, deskY - 11, 10, 1, palette.screenCodeMuted);
    _rect(canvas, x + 11, deskY + 2, 25, 2, palette.keyboard);
  }

  void _drawForegroundWorkstationBack(
    Canvas canvas,
    double width,
    double center,
    double progress,
    _StudyPalette palette,
  ) {
    final deskLeft = math.max(5.0, center - 51);
    final deskRight = math.min(width - 5, center + 61);
    final deskWidth = deskRight - deskLeft;

    _rect(canvas, center - 27, 104, 19, 31, palette.chairFrame);
    _rect(canvas, center - 24, 106, 14, 22, palette.chairSeat);
    _rect(canvas, center - 22, 132, 3, 9, palette.chairFrame);
    _rect(canvas, center - 12, 132, 3, 9, palette.chairFrame);

    // A stepped top reads as a shallow perspective plane rather than a flat
    // stripe. Props and hands are drawn over it, while the student remains
    // behind the front fascia painted later.
    _rect(canvas, deskLeft, 119, deskWidth, 14, palette.deskEdge);
    _rect(canvas, deskLeft + 2, 120, deskWidth - 4, 3, palette.deskTop);
    _rect(canvas, deskLeft + 4, 123, deskWidth - 8, 3, palette.deskFront);
    _rect(canvas, deskLeft + 6, 126, deskWidth - 12, 6, palette.deskFrontInset);
    _rect(canvas, deskLeft + 10, 128, deskWidth - 20, 1, palette.deskTop);

    _drawTaskLamp(canvas, center - 45, progress, palette);
    _drawPrimaryMonitor(canvas, center + 24, progress, palette);
    _rect(canvas, center + 3, 118, 33, 5, palette.keyboard);
    _rect(canvas, center + 6, 117, 27, 2, palette.keyHighlight);
  }

  void _drawForegroundWorkstationFront(
    Canvas canvas,
    double width,
    double center,
    _StudyPalette palette,
  ) {
    final deskLeft = math.max(5.0, center - 51);
    final deskRight = math.min(width - 5, center + 61);
    final deskWidth = deskRight - deskLeft;

    _rect(canvas, deskLeft, 132, deskWidth, 5, palette.deskEdge);
    _rect(canvas, deskLeft + 2, 132, deskWidth - 4, 2, palette.deskFront);
    _rect(canvas, deskLeft + 5, 137, 4, 7, palette.deskLeg);
    _rect(canvas, deskRight - 9, 137, 4, 7, palette.deskLeg);

    _rect(canvas, deskLeft + 14, 133, 28, 4, palette.chargingPanel);
    _rect(canvas, deskLeft + 17, 134, 3, 2, palette.chargingPort);
    _rect(canvas, deskLeft + 24, 134, 5, 2, palette.chargingPort);
    _rect(canvas, deskLeft + 34, 134, 3, 2, palette.chargingLight);
    for (var vent = 0; vent < 4; vent++) {
      _rect(
        canvas,
        deskRight - 31 + (vent * 5),
        134,
        2,
        2,
        palette.chargingPanel,
      );
    }
  }

  void _drawTaskLamp(
    Canvas canvas,
    double x,
    double progress,
    _StudyPalette palette,
  ) {
    final pulse = 0.62 + (math.sin(progress * math.pi * 6).abs() * 0.20);
    _rect(
      canvas,
      x - 4,
      89,
      21,
      20,
      palette.lampGlow.withValues(alpha: 0.10 * pulse),
    );
    _rect(canvas, x + 4, 93, 3, 28, palette.lampFrame);
    _rect(canvas, x + 5, 92, 13, 3, palette.lampFrame);
    _rect(canvas, x + 15, 94, 7, 5, palette.lampShade);
    _rect(canvas, x + 16, 99, 5, 2, palette.lampLight.withValues(alpha: pulse));
    _rect(canvas, x, 119, 13, 3, palette.lampFrame);
  }

  void _drawPrimaryMonitor(
    Canvas canvas,
    double x,
    double progress,
    _StudyPalette palette,
  ) {
    final glow = 0.86 + (math.sin(progress * math.pi * 4).abs() * 0.14);
    _rect(
      canvas,
      x - 3,
      82,
      38,
      32,
      palette.monitorGlow.withValues(alpha: 0.12 * glow),
    );
    _rect(canvas, x, 84, 33, 27, palette.monitorEdge);
    _rect(canvas, x + 3, 87, 27, 19, palette.monitorScreen);
    _rect(canvas, x + 4, 88, 25, 3, palette.screenChrome);
    _rect(canvas, x + 5, 93, 16, 2, palette.screenCode);
    _rect(canvas, x + 5, 97, 21, 2, palette.screenCodeMuted);
    _rect(canvas, x + 5, 101, 12, 2, palette.screenCode);
    final cursorVisible = (progress * 18).floor().isEven;
    if (cursorVisible) {
      _rect(canvas, x + 18, 101, 2, 3, palette.screenCursor);
    }
    final scanY = 92 + ((progress * 11).floor() % 12);
    _rect(canvas, x + 4, scanY.toDouble(), 25, 1, palette.screenScan);
    _rect(canvas, x + 14, 111, 6, 9, palette.monitorStand);
    _rect(canvas, x + 9, 119, 16, 2, palette.monitorStand);
  }

  void _drawStudent(Canvas canvas, double center, double progress) {
    final spriteSheet = studySpriteSheet;
    if (spriteSheet == null) {
      return;
    }

    final frameIndex = _frameIndexFor(progress);
    final source = EducationPixelStudy.studySourceFrames[frameIndex];
    final sourceScaleX =
        spriteSheet.width / EducationPixelStudy.studySheetSize.width;
    final sourceScaleY =
        spriteSheet.height / EducationPixelStudy.studySheetSize.height;
    final decodedSource = Rect.fromLTWH(
      source.left * sourceScaleX,
      source.top * sourceScaleY,
      source.width * sourceScaleX,
      source.height * sourceScaleY,
    );
    final destination = EducationPixelStudy.destinationRectForFrame(
      frameIndex,
      baseline: Offset(center, 140),
      scale: _spriteScale,
    );
    final snappedDestination = Rect.fromLTRB(
      destination.left.roundToDouble(),
      destination.top.roundToDouble(),
      destination.right.roundToDouble(),
      destination.bottom.roundToDouble(),
    );
    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(
        snappedDestination.left,
        snappedDestination.top,
        snappedDestination.right,
        137,
      ),
    );
    canvas.drawImageRect(
      spriteSheet,
      decodedSource,
      snappedDestination,
      _spritePaint,
    );
    canvas.restore();
  }

  int _frameIndexFor(double progress) {
    if (progress < 0.22) {
      return (progress * 40).floor().isEven ? 0 : 1;
    }
    if (progress < 0.34) {
      return (progress * 72).floor() % 5 == 0 ? 3 : 2;
    }
    if (progress < 0.49) {
      return 4;
    }
    if (progress < 0.63) {
      return (progress * 28).floor().isEven ? 5 : 4;
    }
    if (progress < 0.75) {
      return 6;
    }
    if (progress < 0.81) {
      return 3;
    }
    return (progress * 40).floor().isEven ? 7 : 0;
  }

  void _drawHud(
    Canvas canvas,
    double width,
    double progress,
    _StudyPalette palette,
  ) {
    final panel = _hudRectFor(width);
    _rect(
      canvas,
      panel.left,
      panel.top,
      panel.width,
      panel.height,
      palette.hudEdge,
    );
    _rect(
      canvas,
      panel.left + 2,
      panel.top + 2,
      panel.width - 4,
      panel.height - 4,
      palette.hud,
    );
    final headerContentRect = _rect(
      canvas,
      panel.left + 4,
      panel.top + 4,
      panel.width - 8,
      6,
      palette.hudHeader,
    );
    _centeredPixelText(
      canvas,
      EducationPixelStudy.headerLabel,
      headerContentRect,
      size: 4.2,
      color: palette.hudTitle,
      shadow: palette.textShadow,
    );

    final barLeft = panel.left + 39;
    final barWidth = math.max(24.0, panel.width - 64);
    for (
      var index = 0;
      index < EducationPixelStudy.statLabels.length;
      index++
    ) {
      final rowY = panel.top + 13 + (index * 8.5);
      final (start, end) = EducationPixelStudy._statWindows[index];
      final active = progress >= start && progress < end;
      final gained = progress >= start;
      if (active) {
        _rect(
          canvas,
          panel.left + 4,
          rowY - 1,
          panel.width - 8,
          7,
          palette.activeRow,
        );
        _rect(canvas, panel.left + 4, rowY, 2, 5, palette.statAccent);
      }

      _pixelText(
        canvas,
        EducationPixelStudy.statLabels[index],
        Offset(panel.left + 7, rowY),
        size: 4.5,
        color: active ? palette.activeText : palette.hudText,
        shadow: palette.textShadow,
      );
      if (active) {
        _pixelText(
          canvas,
          '+1',
          Offset(panel.left + 29, rowY - 1),
          size: 4.2,
          color: palette.statPopup,
          shadow: palette.textShadow,
        );
      }

      _rect(canvas, barLeft, rowY + 1, barWidth, 4, palette.barTrack);
      _rect(
        canvas,
        barLeft + 1,
        rowY + 2,
        math.max(1, (barWidth - 2) * _barProgress[index]),
        2,
        gained ? palette.statGained : palette.statBase,
      );
      if (gained) {
        _rect(
          canvas,
          barLeft + ((barWidth - 2) * _barProgress[index]) + 1,
          rowY + 1,
          active ? 5 : 3,
          4,
          active ? palette.statPopup : palette.statGained,
        );
      }

      _pixelText(
        canvas,
        '${_baseStats[index] + (gained ? 1 : 0)}',
        Offset(panel.right - 20, rowY),
        size: 4.4,
        color: gained ? palette.statNumber : palette.hudText,
        shadow: palette.textShadow,
      );
    }
  }

  Rect _hudRectFor(double width) {
    final panelWidth = math.min(132.0, math.max(96.0, width - 64));
    return Rect.fromLTWH(6, 8, panelWidth, 50);
  }

  void _drawSessionComplete(
    Canvas canvas,
    double width,
    double progress,
    _StudyPalette palette,
  ) {
    if (progress < 0.84 || progress >= 0.97) {
      return;
    }
    final panel = _hudRectFor(width);
    final pulse = (progress * 32).floor().isEven;
    final boxWidth = math.min(91.0, panel.width);
    _rect(canvas, panel.left, 61, boxWidth, 12, palette.completeEdge);
    final completeContentRect = _rect(
      canvas,
      panel.left + 2,
      63,
      boxWidth - 4,
      8,
      palette.completeFill,
    );
    _centeredPixelText(
      canvas,
      EducationPixelStudy.sessionCompleteLabel,
      completeContentRect,
      size: 4.8,
      color: pulse ? palette.completeText : palette.hudTitle,
      shadow: palette.textShadow,
    );
  }

  void _drawLoopMask(
    Canvas canvas,
    double width,
    double progress,
    _StudyPalette palette,
  ) {
    final opacity = switch (progress) {
      < 0.05 => 1 - (progress / 0.05),
      > 0.95 => (progress - 0.95) / 0.05,
      _ => 0.0,
    };
    if (opacity <= 0) {
      return;
    }
    final panel = _hudRectFor(width);
    _rect(
      canvas,
      panel.left,
      panel.top,
      panel.width,
      66,
      palette.hud.withValues(alpha: (opacity * 0.96).clamp(0, 1)),
    );
  }

  void _drawOverlayScrims(Canvas canvas, double width) {
    _rect(canvas, 0, 0, width, 8, const Color(0x24000000));
    _rect(canvas, width - 32, 8, 32, 22, const Color(0x88000000));
    _rect(canvas, width - 56, 22, 56, 94, const Color(0x27000000));
    _rect(canvas, 0, 78, width, 18, const Color(0x10000000));
    _rect(canvas, 0, 96, width, 18, const Color(0x26000000));
    _rect(canvas, 0, 114, width, 16, const Color(0x48000000));
    _rect(canvas, 0, 130, width, 14, const Color(0x70000000));
  }

  void _pixelText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double size,
    required Color color,
    required Color shadow,
  }) {
    final painters = _resolvePixelTextPainters(
      text,
      size: size,
      color: color,
      shadow: shadow,
    );
    _paintPixelText(canvas, painters, offset);
  }

  void _centeredPixelText(
    Canvas canvas,
    String text,
    Rect contentRect, {
    required double size,
    required Color color,
    required Color shadow,
  }) {
    final painters = _resolvePixelTextPainters(
      text,
      size: size,
      color: color,
      shadow: shadow,
    );
    final (shadowPainter, painter) = painters;
    final origin = centeredPixelTextOrigin(
      contentRect: contentRect,
      foregroundSize: painter.size,
      shadowSize: shadowPainter.size,
    );
    _paintPixelText(canvas, painters, origin);
  }

  (TextPainter, TextPainter) _resolvePixelTextPainters(
    String text, {
    required double size,
    required Color color,
    required Color shadow,
  }) {
    final quantizedSize = (size * 10).round() / 10;
    final key = (text, quantizedSize, color.toARGB32(), shadow.toARGB32());
    return textPainterCache.resolve(key, () {
      final style = TextStyle(
        color: color,
        fontFamily: 'monospace',
        fontSize: quantizedSize,
        fontWeight: FontWeight.w900,
        height: 1,
        letterSpacing: -0.35,
      );
      final shadowPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: style.copyWith(color: shadow),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      return (shadowPainter, painter);
    });
  }

  void _paintPixelText(
    Canvas canvas,
    (TextPainter, TextPainter) painters,
    Offset offset,
  ) {
    final (shadowPainter, painter) = painters;
    shadowPainter.paint(
      canvas,
      Offset(offset.dx.roundToDouble() + 1, offset.dy.roundToDouble() + 1),
    );
    painter.paint(
      canvas,
      Offset(offset.dx.roundToDouble(), offset.dy.roundToDouble()),
    );
  }

  Rect _rect(
    Canvas canvas,
    double x,
    double y,
    double width,
    double height,
    Color color,
  ) {
    final rect = snapPixelRect(Rect.fromLTWH(x, y, width, height));
    canvas.drawRect(rect, _fillPaint..color = color);
    return rect;
  }

  @override
  bool shouldRepaint(covariant _EducationPixelStudyPainter oldDelegate) {
    return oldDelegate.timeline != timeline ||
        oldDelegate.brightness != brightness ||
        oldDelegate.studySpriteSheet != studySpriteSheet;
  }
}

class _StudyTextPainterCache {
  final Map<(String, double, int, int), (TextPainter, TextPainter)> _painters =
      <(String, double, int, int), (TextPainter, TextPainter)>{};

  (TextPainter, TextPainter) resolve(
    (String, double, int, int) key,
    (TextPainter, TextPainter) Function() create,
  ) => _painters.putIfAbsent(key, create);

  void dispose() {
    for (final (shadowPainter, painter) in _painters.values) {
      shadowPainter.dispose();
      painter.dispose();
    }
    _painters.clear();
  }
}

class _StudyPalette {
  const _StudyPalette({
    required this.wall,
    required this.ceiling,
    required this.ceilingEdge,
    required this.ceilingLight,
    required this.ceilingGlow,
    required this.wallBase,
    required this.shelfEdge,
    required this.shelfBack,
    required this.shelfTrim,
    required this.books,
    required this.windowFrame,
    required this.windowSky,
    required this.windowGlow,
    required this.windowSkyline,
    required this.windowLight,
    required this.glassFrame,
    required this.glassShine,
    required this.floor,
    required this.floorLine,
    required this.backDeskTop,
    required this.backDeskLeg,
    required this.monitorEdge,
    required this.monitorScreen,
    required this.monitorStand,
    required this.monitorGlow,
    required this.screenChrome,
    required this.screenCode,
    required this.screenCodeMuted,
    required this.screenCursor,
    required this.screenScan,
    required this.keyboard,
    required this.keyHighlight,
    required this.chairFrame,
    required this.chairSeat,
    required this.deskEdge,
    required this.deskTop,
    required this.deskLeg,
    required this.deskFront,
    required this.deskFrontInset,
    required this.chargingPanel,
    required this.chargingPort,
    required this.chargingLight,
    required this.lampFrame,
    required this.lampShade,
    required this.lampLight,
    required this.lampGlow,
    required this.hudEdge,
    required this.hud,
    required this.hudHeader,
    required this.hudTitle,
    required this.hudText,
    required this.textShadow,
    required this.activeRow,
    required this.activeText,
    required this.barTrack,
    required this.statBase,
    required this.statGained,
    required this.statAccent,
    required this.statPopup,
    required this.statNumber,
    required this.completeEdge,
    required this.completeFill,
    required this.completeText,
  });

  static const light = _StudyPalette(
    wall: Color(0xFFD8D8D2),
    ceiling: Color(0xFFF0EEE8),
    ceilingEdge: Color(0xFFADB8B9),
    ceilingLight: Color(0xFFFFF6C9),
    ceilingGlow: Color(0xFFFFE9A0),
    wallBase: Color(0xFF8D9A9C),
    shelfEdge: Color(0xFF49382F),
    shelfBack: Color(0xFF6A5042),
    shelfTrim: Color(0xFF98745C),
    books: <Color>[
      Color(0xFFB85249),
      Color(0xFF467B87),
      Color(0xFFD09B4D),
      Color(0xFF66734C),
      Color(0xFF765A8D),
    ],
    windowFrame: Color(0xFF52666E),
    windowSky: Color(0xFF8BC5D8),
    windowGlow: Color(0xFFDDF5ED),
    windowSkyline: Color(0xFF658C9B),
    windowLight: Color(0xFFFFE490),
    glassFrame: Color(0xFF7C969C),
    glassShine: Color(0x88E8FFFF),
    floor: Color(0xFF8C8177),
    floorLine: Color(0xFF766C64),
    backDeskTop: Color(0xFFB49B82),
    backDeskLeg: Color(0xFF66584E),
    monitorEdge: Color(0xFF29343B),
    monitorScreen: Color(0xFF285065),
    monitorStand: Color(0xFF68747A),
    monitorGlow: Color(0xFF79D7F3),
    screenChrome: Color(0xFF426F83),
    screenCode: Color(0xFF76D9E9),
    screenCodeMuted: Color(0xFF9FB8C0),
    screenCursor: Color(0xFFFFE27A),
    screenScan: Color(0x334EDCF3),
    keyboard: Color(0xFF48545A),
    keyHighlight: Color(0xFFACBAC0),
    chairFrame: Color(0xFF34383B),
    chairSeat: Color(0xFF59616A),
    deskEdge: Color(0xFF493B34),
    deskTop: Color(0xFFC49D77),
    deskLeg: Color(0xFF493B34),
    deskFront: Color(0xFF795A45),
    deskFrontInset: Color(0xFF9A7355),
    chargingPanel: Color(0xFF2E3439),
    chargingPort: Color(0xFF111619),
    chargingLight: Color(0xFF55E89C),
    lampFrame: Color(0xFF39454B),
    lampShade: Color(0xFF5F747C),
    lampLight: Color(0xFFFFDC72),
    lampGlow: Color(0xFFFFE9A6),
    hudEdge: Color(0xFF17212C),
    hud: Color(0xE8253340),
    hudHeader: Color(0xFF334F62),
    hudTitle: Color(0xFFE7F8FF),
    hudText: Color(0xFFD4E3E8),
    textShadow: Color(0xFF101820),
    activeRow: Color(0x6649B6C8),
    activeText: Color(0xFFFFFFFF),
    barTrack: Color(0xFF17222B),
    statBase: Color(0xFF5F8690),
    statGained: Color(0xFF44D4BC),
    statAccent: Color(0xFF8AF3DF),
    statPopup: Color(0xFFFFE36C),
    statNumber: Color(0xFFA8FFE9),
    completeEdge: Color(0xFF16232B),
    completeFill: Color(0xFF26766D),
    completeText: Color(0xFFFFE36C),
  );

  static const dark = _StudyPalette(
    wall: Color(0xFF283239),
    ceiling: Color(0xFF171F27),
    ceilingEdge: Color(0xFF40505B),
    ceilingLight: Color(0xFFFFD77C),
    ceilingGlow: Color(0xFFFFC75B),
    wallBase: Color(0xFF39474F),
    shelfEdge: Color(0xFF181418),
    shelfBack: Color(0xFF31242A),
    shelfTrim: Color(0xFF674B3D),
    books: <Color>[
      Color(0xFF9D4549),
      Color(0xFF376879),
      Color(0xFFB27B3B),
      Color(0xFF596947),
      Color(0xFF695080),
    ],
    windowFrame: Color(0xFF1B2931),
    windowSky: Color(0xFF173D58),
    windowGlow: Color(0xFF315D70),
    windowSkyline: Color(0xFF102939),
    windowLight: Color(0xFFFFD66E),
    glassFrame: Color(0xFF45616D),
    glassShine: Color(0x665D9BAA),
    floor: Color(0xFF302C31),
    floorLine: Color(0xFF211F24),
    backDeskTop: Color(0xFF675347),
    backDeskLeg: Color(0xFF302A29),
    monitorEdge: Color(0xFF111820),
    monitorScreen: Color(0xFF15394F),
    monitorStand: Color(0xFF414E55),
    monitorGlow: Color(0xFF3AC8F0),
    screenChrome: Color(0xFF27566D),
    screenCode: Color(0xFF54C5DD),
    screenCodeMuted: Color(0xFF6D929E),
    screenCursor: Color(0xFFFFD05A),
    screenScan: Color(0x334AD7F4),
    keyboard: Color(0xFF2A3439),
    keyHighlight: Color(0xFF70828A),
    chairFrame: Color(0xFF151A1D),
    chairSeat: Color(0xFF37424A),
    deskEdge: Color(0xFF211A19),
    deskTop: Color(0xFF765843),
    deskLeg: Color(0xFF2A211F),
    deskFront: Color(0xFF3B2B25),
    deskFrontInset: Color(0xFF513A2E),
    chargingPanel: Color(0xFF151B20),
    chargingPort: Color(0xFF05090B),
    chargingLight: Color(0xFF45E58D),
    lampFrame: Color(0xFF202B31),
    lampShade: Color(0xFF3B515B),
    lampLight: Color(0xFFFFC94C),
    lampGlow: Color(0xFFFFD76A),
    hudEdge: Color(0xFF080D12),
    hud: Color(0xEE111A24),
    hudHeader: Color(0xFF203D50),
    hudTitle: Color(0xFFDFF8FF),
    hudText: Color(0xFFB8CDD5),
    textShadow: Color(0xFF03070A),
    activeRow: Color(0x77408DA0),
    activeText: Color(0xFFFFFFFF),
    barTrack: Color(0xFF080D12),
    statBase: Color(0xFF496D78),
    statGained: Color(0xFF35D0B2),
    statAccent: Color(0xFF7EF3D9),
    statPopup: Color(0xFFFFD85D),
    statNumber: Color(0xFF9DFFE4),
    completeEdge: Color(0xFF070C10),
    completeFill: Color(0xFF1E665F),
    completeText: Color(0xFFFFD85D),
  );

  final Color wall;
  final Color ceiling;
  final Color ceilingEdge;
  final Color ceilingLight;
  final Color ceilingGlow;
  final Color wallBase;
  final Color shelfEdge;
  final Color shelfBack;
  final Color shelfTrim;
  final List<Color> books;
  final Color windowFrame;
  final Color windowSky;
  final Color windowGlow;
  final Color windowSkyline;
  final Color windowLight;
  final Color glassFrame;
  final Color glassShine;
  final Color floor;
  final Color floorLine;
  final Color backDeskTop;
  final Color backDeskLeg;
  final Color monitorEdge;
  final Color monitorScreen;
  final Color monitorStand;
  final Color monitorGlow;
  final Color screenChrome;
  final Color screenCode;
  final Color screenCodeMuted;
  final Color screenCursor;
  final Color screenScan;
  final Color keyboard;
  final Color keyHighlight;
  final Color chairFrame;
  final Color chairSeat;
  final Color deskEdge;
  final Color deskTop;
  final Color deskLeg;
  final Color deskFront;
  final Color deskFrontInset;
  final Color chargingPanel;
  final Color chargingPort;
  final Color chargingLight;
  final Color lampFrame;
  final Color lampShade;
  final Color lampLight;
  final Color lampGlow;
  final Color hudEdge;
  final Color hud;
  final Color hudHeader;
  final Color hudTitle;
  final Color hudText;
  final Color textShadow;
  final Color activeRow;
  final Color activeText;
  final Color barTrack;
  final Color statBase;
  final Color statGained;
  final Color statAccent;
  final Color statPopup;
  final Color statNumber;
  final Color completeEdge;
  final Color completeFill;
  final Color completeText;
}
