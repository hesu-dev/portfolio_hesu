import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pixel_text_layout.dart';

/// A deterministic pixel-art city scene using approved runner sprite sheets.
class CareerPixelRunner extends StatefulWidget {
  const CareerPixelRunner({super.key});

  static const levelUpLabel = 'LV + UP!';

  /// Every scenery motif advances one common 240 px world unit per loop.
  static const landmarkScrollPerLoop = 240.0;
  static const cloudScrollPerLoop = 240.0;
  static const farCityScrollPerLoop = 240.0;
  static const cloudSpeedMultiplier = 1.0;
  static const farCitySpeedMultiplier = 1.25;
  static const mainBuildingSpeedMultiplier = 1.5;
  static const runFramesPerSecond = 6;
  static const runFrameVerticalLift = <double>[0, -1, 1, 1, 0, -1, 1, 2];
  static const maxRunnerHeight = 30.0;
  static const convenienceStoreHeight = 31.0;
  static const runDecodeWidth = 384;
  static const jumpDecodeWidth = 314;
  static const runSpriteAsset = 'assets/sprites/career_runner_run.png';
  static const jumpSpriteAsset = 'assets/sprites/career_runner_jump.png';

  static const semanticsLabel =
      '밝은 피부에 갈색 포니테일과 안경, 비즈니스 정장을 갖춘 여성 캐릭터가 '
      '오른쪽을 바라보고 구름과 AT Center, 판교역, 편의점이 이어지는 도심을 달리고 점프하며 '
      '골드 코인을 모아 LV UP 하는 도트 애니메이션';

  @override
  State<CareerPixelRunner> createState() => _CareerPixelRunnerState();
}

class _CareerPixelRunnerState extends State<CareerPixelRunner>
    with TickerProviderStateMixin {
  static const _duration = Duration(seconds: 5);
  static const _farCityDuration = Duration(seconds: 4);
  static const _mainBuildingDuration = Duration(microseconds: 3333333);
  static const _reducedMotionFrame = 0.37;

  late final AnimationController _timeline = AnimationController(
    vsync: this,
    duration: _duration,
  );
  late final AnimationController _farCityTimeline = AnimationController(
    vsync: this,
    duration: _farCityDuration,
  );
  late final AnimationController _mainBuildingTimeline = AnimationController(
    vsync: this,
    duration: _mainBuildingDuration,
  );
  late final Listenable _sceneRepaint = Listenable.merge(<Listenable>[
    _timeline,
    _farCityTimeline,
    _mainBuildingTimeline,
  ]);
  ui.Image? _runSpriteSheet;
  ui.Image? _jumpSpriteSheet;
  final _textPainterCache = _PixelTextPainterCache();
  bool? _motionDisabled;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSpriteSheets());
  }

  Future<void> _loadSpriteSheets() async {
    late final List<ui.Image> sheets;
    try {
      sheets = await Future.wait(
        <Future<ui.Image>>[
          _decodeAssetImage(
            CareerPixelRunner.runSpriteAsset,
            targetWidth: CareerPixelRunner.runDecodeWidth,
          ),
          _decodeAssetImage(
            CareerPixelRunner.jumpSpriteAsset,
            targetWidth: CareerPixelRunner.jumpDecodeWidth,
          ),
        ],
        eagerError: true,
        cleanUp: (image) => image.dispose(),
      );
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'portfolio career pixel runner',
          context: ErrorDescription('while loading runner sprite sheets'),
        ),
      );
      return;
    }
    if (!mounted) {
      for (final sheet in sheets) {
        sheet.dispose();
      }
      return;
    }
    setState(() {
      _runSpriteSheet = sheets[0];
      _jumpSpriteSheet = sheets[1];
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
      _farCityTimeline
        ..stop()
        ..value = _reducedMotionFrame;
      _mainBuildingTimeline
        ..stop()
        ..value = _reducedMotionFrame;
    } else {
      _timeline.repeat();
      _farCityTimeline.repeat();
      _mainBuildingTimeline.repeat();
    }
  }

  @override
  void dispose() {
    _timeline.dispose();
    _farCityTimeline.dispose();
    _mainBuildingTimeline.dispose();
    _runSpriteSheet?.dispose();
    _jumpSpriteSheet?.dispose();
    _textPainterCache.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motionDisabled = _motionDisabled ?? true;
    return Semantics(
      label: CareerPixelRunner.semanticsLabel,
      image: true,
      excludeSemantics: true,
      child: RepaintBoundary(
        child: SizedBox.expand(
          child: CustomPaint(
            painter: _CareerPixelRunnerPainter(
              timeline: _timeline,
              farCityTimeline: _farCityTimeline,
              mainBuildingTimeline: _mainBuildingTimeline,
              repaint: _sceneRepaint,
              brightness: Theme.of(context).brightness,
              runSpriteSheet: _runSpriteSheet,
              jumpSpriteSheet: _jumpSpriteSheet,
              textPainterCache: _textPainterCache,
            ),
            isComplex: true,
            willChange: !motionDisabled,
          ),
        ),
      ),
    );
  }
}

class _CareerPixelRunnerPainter extends CustomPainter {
  _CareerPixelRunnerPainter({
    required this.timeline,
    required this.farCityTimeline,
    required this.mainBuildingTimeline,
    required Listenable repaint,
    required this.brightness,
    required this.runSpriteSheet,
    required this.jumpSpriteSheet,
    required this.textPainterCache,
  }) : super(repaint: repaint);

  final Animation<double> timeline;
  final Animation<double> farCityTimeline;
  final Animation<double> mainBuildingTimeline;
  final Brightness brightness;
  final ui.Image? runSpriteSheet;
  final ui.Image? jumpSpriteSheet;
  final _PixelTextPainterCache textPainterCache;

  static const _sceneHeight = 144.0;
  static const _loopSeconds = 5;
  static const _runnerScale = CareerPixelRunner.maxRunnerHeight / 392;
  static const _runSheetSize = Size(1536, 1024);
  static const _jumpSheetSize = Size(1254, 1254);
  static const _runSourceFrames = <Rect>[
    Rect.fromLTWH(24, 88, 336, 360),
    Rect.fromLTWH(422, 94, 310, 356),
    Rect.fromLTWH(784, 74, 322, 374),
    Rect.fromLTWH(1164, 72, 348, 340),
    Rect.fromLTWH(14, 578, 340, 380),
    Rect.fromLTWH(406, 586, 326, 372),
    Rect.fromLTWH(772, 566, 334, 392),
    Rect.fromLTWH(1158, 562, 358, 352),
  ];
  static const _jumpSourceFrames = <Rect>[
    Rect.fromLTWH(72, 310, 280, 262),
    Rect.fromLTWH(460, 204, 376, 356),
    Rect.fromLTWH(836, 200, 266, 268),
    Rect.fromLTWH(104, 677, 314, 314),
    Rect.fromLTWH(418, 703, 368, 328),
    Rect.fromLTWH(862, 797, 290, 254),
  ];

  final Paint _spritePaint = Paint()
    ..isAntiAlias = false
    ..filterQuality = FilterQuality.none;
  final Paint _fillPaint = Paint()..isAntiAlias = false;
  bool get _dark => brightness == Brightness.dark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final scale = size.height / _sceneHeight;
    final sceneWidth = size.width / scale;
    final progress = timeline.value % 1;
    final cloudProgress = progress;
    final farCityProgress = farCityTimeline.value % 1;
    final mainBuildingProgress = mainBuildingTimeline.value % 1;

    canvas.save();
    canvas.scale(scale, scale);
    canvas.clipRect(Rect.fromLTWH(0, 0, sceneWidth, _sceneHeight));

    _drawSky(canvas, sceneWidth, cloudProgress);
    _drawClouds(canvas, sceneWidth, cloudProgress);
    _drawFarCity(canvas, sceneWidth, farCityProgress);
    _drawLandmarks(canvas, sceneWidth, mainBuildingProgress);
    _drawStreet(canvas, sceneWidth, mainBuildingProgress);

    final runnerX = (sceneWidth * 0.57).clamp(68.0, 118.0);
    final eventPhase = (progress * 2) % 1;
    final jumpProgress = _jumpProgress(eventPhase);
    final jump = math.sin(jumpProgress * math.pi) * 24;
    _drawSpeed(canvas, sceneWidth, mainBuildingProgress, eventPhase, jump);
    _drawCoin(canvas, sceneWidth, runnerX, eventPhase);
    _drawRunner(canvas, runnerX, 94 - jump, progress, jumpProgress);
    _drawCollectionBurst(canvas, runnerX, eventPhase);
    _drawLevelUp(canvas, sceneWidth, runnerX, eventPhase);
    _drawOverlayScrims(canvas, sceneWidth);

    canvas.restore();
  }

  void _drawSky(Canvas canvas, double width, double progress) {
    final colors = _dark
        ? const <Color>[
            Color(0xFF17264D),
            Color(0xFF203967),
            Color(0xFF31527A),
            Color(0xFF536F8E),
          ]
        : const <Color>[
            Color(0xFF399EE6),
            Color(0xFF57B7F1),
            Color(0xFF82CDF4),
            Color(0xFFB6E3F8),
          ];
    for (var index = 0; index < colors.length; index++) {
      _rect(canvas, 0, index * 21, width, 22, colors[index]);
    }

    // Subtle pixel haze makes the otherwise uniform sky visibly scroll too.
    const hazeSpacing = 60.0;
    final hazeTravel = progress * CareerPixelRunner.cloudScrollPerLoop;
    final hazeTile = (hazeTravel / hazeSpacing).floor();
    final hazeOffset = hazeTravel % hazeSpacing;
    final hazeCount = (width / hazeSpacing).ceil() + 3;
    final haze = Colors.white.withValues(alpha: _dark ? 0.07 : 0.12);
    for (var index = -1; index < hazeCount; index++) {
      final worldIndex = index + hazeTile;
      final variant = _positiveModulo(worldIndex, 4);
      final x = (index * hazeSpacing) - hazeOffset;
      final y = 9.0 + (variant * 13);
      _rect(canvas, x, y, 9 + (variant * 3), 1, haze);
      if (variant.isEven) {
        _rect(canvas, x + 18, y + 5, 5, 1, haze);
      }
    }
  }

  void _drawClouds(Canvas canvas, double width, double progress) {
    final cloud = _dark ? const Color(0xFFD8E1EE) : const Color(0xFFF7FBFF);
    final shade = _dark ? const Color(0xFF9FB5CB) : const Color(0xFFC9E8F8);
    const spacing = 80.0;
    final scroll = progress * CareerPixelRunner.cloudScrollPerLoop;
    final scrolledTiles = (scroll / spacing).floor();
    final tileOffset = scroll % spacing;
    final count = (width / spacing).ceil() + 3;
    for (var index = -1; index < count; index++) {
      final worldIndex = index + scrolledTiles;
      final variant = _positiveModulo(worldIndex, 3);
      final x = (index * spacing) - tileOffset;
      final y = 18 + (variant * 12);
      final mirrored = variant == 1;
      _pixelCloud(canvas, x, y.toDouble(), cloud, shade, mirrored);
    }
  }

  void _pixelCloud(
    Canvas canvas,
    double x,
    double y,
    Color color,
    Color shade,
    bool mirrored,
  ) {
    final shift = mirrored ? 4.0 : 0.0;
    _rect(canvas, x + 8 + shift, y, 18, 4, color);
    _rect(canvas, x + 4, y + 4, 30, 5, color);
    _rect(canvas, x, y + 9, 40, 6, color);
    _rect(canvas, x + 7, y + 15, 28, 3, shade);
    _rect(canvas, x + 28, y + 6, 8, 3, shade);
  }

  void _drawFarCity(Canvas canvas, double width, double progress) {
    const spacing = 30.0;
    const heights = <double>[31, 45, 28, 39, 48, 34, 42, 26];
    final scroll = progress * CareerPixelRunner.farCityScrollPerLoop;
    final scrolledTiles = (scroll / spacing).floor();
    final tileOffset = scroll % spacing;
    final base = _dark ? const Color(0xFF28415B) : const Color(0xFF7199B0);
    final alternate = _dark ? const Color(0xFF344D68) : const Color(0xFF89AABE);
    final window = _dark ? const Color(0xFFFFD86A) : const Color(0xFFD7F0F5);
    final count = (width / spacing).ceil() + 4;
    for (var index = -2; index < count; index++) {
      final worldIndex = index + scrolledTiles;
      final variant = _positiveModulo(worldIndex, heights.length);
      final x = (index * spacing) - tileOffset;
      final buildingHeight = heights[variant];
      final top = 84 - buildingHeight;
      _rect(
        canvas,
        x,
        top,
        27,
        buildingHeight,
        variant.isEven ? base : alternate,
      );
      if (variant % 4 == 0) {
        _rect(canvas, x + 8, top - 7, 3, 7, base);
        _rect(canvas, x + 7, top - 8, 5, 2, alternate);
      }
      for (var row = 0; row < 4; row++) {
        for (var column = 0; column < 3; column++) {
          if ((variant + row + column) % 3 != 0) {
            _rect(
              canvas,
              x + 4 + (column * 6),
              top + 5 + (row * 7),
              3,
              3,
              window.withValues(alpha: _dark ? 0.84 : 0.62),
            );
          }
        }
      }
    }
  }

  void _drawLandmarks(Canvas canvas, double width, double progress) {
    const period = CareerPixelRunner.landmarkScrollPerLoop;
    final scroll = progress * period;
    final cycleCount = (width / period).ceil() + 3;
    for (var cycle = -1; cycle < cycleCount; cycle++) {
      final origin = cycle * period - (scroll % period);
      _drawAtCenter(canvas, origin + 4);
      _drawPangyoStation(canvas, origin + 81);
      _drawConvenienceStore(canvas, origin + 166);
    }
  }

  void _drawAtCenter(Canvas canvas, double x) {
    final body = _dark ? const Color(0xFF26354C) : const Color(0xFFD7E1E7);
    final edge = _dark ? const Color(0xFF172235) : const Color(0xFF718695);
    final glass = _dark ? const Color(0xFF355778) : const Color(0xFF85C4DC);
    _rect(canvas, x, 42, 66, 43, edge);
    _rect(canvas, x + 3, 45, 60, 40, body);
    _rect(canvas, x + 8, 33, 48, 12, const Color(0xFF243B53));
    _pixelText(
      canvas,
      'AT CENTER',
      Offset(x + 11, 35),
      size: 6.2,
      color: const Color(0xFFFFD447),
      shadow: const Color(0xFF111A25),
    );
    for (var row = 0; row < 3; row++) {
      for (var column = 0; column < 5; column++) {
        _rect(canvas, x + 7 + (column * 11), 50 + (row * 9), 7, 5, glass);
      }
    }
    _rect(canvas, x + 27, 75, 12, 10, const Color(0xFF40576A));
  }

  void _drawPangyoStation(Canvas canvas, double x) {
    final body = _dark ? const Color(0xFF35394D) : const Color(0xFFE7E4DB);
    final trim = _dark ? const Color(0xFF6C7595) : const Color(0xFF9B978D);
    _rect(canvas, x, 56, 70, 29, trim);
    _rect(canvas, x + 2, 59, 66, 26, body);
    _rect(canvas, x - 3, 52, 76, 7, const Color(0xFF394650));
    _rect(canvas, x + 5, 55, 60, 8, const Color(0xFF704CA0));
    _pixelText(
      canvas,
      '판교역',
      Offset(x + 21, 55),
      size: 6.3,
      color: Colors.white,
      shadow: const Color(0xFF34204B),
    );
    _rect(canvas, x + 8, 67, 18, 18, const Color(0xFF6AA8C5));
    _rect(canvas, x + 30, 67, 30, 4, const Color(0xFFB4C5CC));
    _rect(canvas, x + 30, 75, 30, 4, const Color(0xFFB4C5CC));
  }

  void _drawConvenienceStore(Canvas canvas, double x) {
    final wall = _dark ? const Color(0xFFDDD8CF) : const Color(0xFFF6F1E7);
    _rect(canvas, x, 58, 61, 27, wall);
    _rect(canvas, x - 2, 54, 65, 7, const Color(0xFF57368D));
    _rect(canvas, x + 1, 55, 61, 2, const Color(0xFF74D35C));
    _pixelText(
      canvas,
      '24H STORE',
      Offset(x + 11, 54),
      size: 5.6,
      color: Colors.white,
      shadow: const Color(0xFF2A1846),
    );
    for (var stripe = 0; stripe < 7; stripe++) {
      _rect(
        canvas,
        x + (stripe * 9),
        61,
        7,
        5,
        stripe.isEven ? const Color(0xFF6FCB55) : const Color(0xFF7248A1),
      );
    }
    _rect(canvas, x + 5, 68, 25, 14, const Color(0xFF73BCD2));
    _rect(canvas, x + 34, 68, 20, 17, const Color(0xFF415B67));
    _rect(canvas, x + 50, 75, 2, 3, const Color(0xFFFFD447));
  }

  void _drawStreet(Canvas canvas, double width, double progress) {
    final sidewalk = _dark ? const Color(0xFF78818A) : const Color(0xFFB6BDC1);
    final curb = _dark ? const Color(0xFFCBD0D3) : const Color(0xFFF1F0E9);
    final asphalt = _dark ? const Color(0xFF222633) : const Color(0xFF454A52);
    _rect(canvas, 0, 84, width, 6, sidewalk);
    _rect(canvas, 0, 90, width, 4, curb);
    _rect(canvas, 0, 94, width, 50, asphalt);
    _rect(canvas, 0, 98, width, 2, const Color(0xFF303742));

    final dashScroll = (progress * 272) % 34;
    final dashCount = (width / 34).ceil() + 2;
    for (var index = -1; index < dashCount; index++) {
      _rect(
        canvas,
        (index * 34) - dashScroll,
        119,
        18,
        3,
        const Color(0xFFF4D35E),
      );
    }

    final nearScroll = (progress * 396) % 22;
    for (var index = -1; index < (width / 22).ceil() + 2; index++) {
      _rect(
        canvas,
        (index * 22) - nearScroll,
        140,
        12,
        4,
        const Color(0xFF151923),
      );
    }
  }

  void _drawSpeed(
    Canvas canvas,
    double width,
    double progress,
    double phase,
    double jump,
  ) {
    final intensity = jump > 0 ? 1.0 : 0.64;
    final color = Colors.white.withValues(alpha: 0.28 * intensity);
    for (var index = 0; index < 8; index++) {
      final lane = 33.0 + ((index * 13) % 54);
      final travel =
          (progress * (width + 45) * (2 + (index % 3))) % (width + 45);
      final x = width - travel;
      final length = 8.0 + ((index % 3) * 6);
      if ((phase + (index * 0.09)) % 1 > 0.18) {
        _rect(canvas, x, lane, length, index.isEven ? 2 : 1, color);
      }
    }
  }

  double _jumpProgress(double phase) {
    const start = 0.47;
    const end = 0.73;
    if (phase <= start || phase >= end) {
      return 0;
    }
    return (phase - start) / (end - start);
  }

  void _drawCoin(Canvas canvas, double width, double runnerX, double phase) {
    const collection = 0.69;
    if (phase >= collection) {
      return;
    }
    final travel = Curves.linear.transform((phase / collection).clamp(0, 1));
    final x = _lerp(width + 10, runnerX + 1, travel);
    final y = 56 - (math.sin(phase * math.pi * 5) * 2);
    final spinFrame = (phase * 28).floor() % 4;
    final coinWidth = <double>[14, 10, 4, 10][spinFrame];
    const outline = Color(0xFF2A2113);
    const rim = Color(0xFFE08A16);
    const gold = Color(0xFFFFC928);
    const shine = Color(0xFFFFF4A3);

    if (coinWidth <= 4) {
      _rect(canvas, x - 3, y - 8, 6, 16, outline);
      _rect(canvas, x - 1, y - 7, 3, 14, gold);
      _rect(canvas, x, y - 5, 1, 5, shine);
    } else {
      // Three stepped bands form a crisp round/octagonal pixel silhouette.
      _rect(canvas, x - (coinWidth / 2) + 3, y - 9, coinWidth - 6, 18, outline);
      _rect(canvas, x - (coinWidth / 2) + 1, y - 7, coinWidth - 2, 14, outline);
      _rect(canvas, x - (coinWidth / 2), y - 5, coinWidth, 10, outline);
      _rect(canvas, x - (coinWidth / 2) + 3, y - 7, coinWidth - 6, 14, rim);
      _rect(canvas, x - (coinWidth / 2) + 2, y - 5, coinWidth - 4, 10, gold);
      _rect(canvas, x - (coinWidth / 2) + 1, y - 3, coinWidth - 2, 6, gold);
      _rect(canvas, x - (coinWidth / 2) + 3, y - 5, 2, 7, shine);
      _rect(canvas, x + (coinWidth / 2) - 4, y - 4, 2, 8, rim);
      _rect(canvas, x - 1, y - 4, 2, 9, shine);
      _rect(canvas, x + 1, y - 3, 2, 7, rim);
    }
  }

  void _drawRunner(
    Canvas canvas,
    double centerX,
    double baseline,
    double progress,
    double jumpProgress,
  ) {
    final jumping = jumpProgress > 0;
    final sheet = jumping ? jumpSpriteSheet : runSpriteSheet;
    if (sheet == null) {
      return;
    }

    final runPosition =
        progress * CareerPixelRunner.runFramesPerSecond * _loopSeconds;
    final frame = jumping
        ? math.min(5, (jumpProgress * 6).floor())
        : runPosition.floor() % _runSourceFrames.length;
    final verticalLift = jumping
        ? 0.0
        : _lerp(
            CareerPixelRunner.runFrameVerticalLift[frame],
            CareerPixelRunner.runFrameVerticalLift[(frame + 1) %
                _runSourceFrames.length],
            Curves.easeInOut.transform(runPosition - runPosition.floor()),
          );
    final source = jumping ? _jumpSourceFrames[frame] : _runSourceFrames[frame];
    final nominalSheetSize = jumping ? _jumpSheetSize : _runSheetSize;
    final decodedSource = Rect.fromLTWH(
      source.left * sheet.width / nominalSheetSize.width,
      source.top * sheet.height / nominalSheetSize.height,
      source.width * sheet.width / nominalSheetSize.width,
      source.height * sheet.height / nominalSheetSize.height,
    );
    final targetWidth = source.width * _runnerScale;
    final targetHeight = source.height * _runnerScale;
    final target = Rect.fromLTWH(
      (centerX - (targetWidth * 0.5)).roundToDouble(),
      (baseline - targetHeight - verticalLift).roundToDouble(),
      targetWidth,
      targetHeight,
    );
    canvas.drawImageRect(sheet, decodedSource, target, _spritePaint);

    if (!jumping && verticalLift < 0.6) {
      _drawDust(canvas, centerX, baseline, progress, frame);
    }
  }

  void _drawDust(
    Canvas canvas,
    double x,
    double baseline,
    double progress,
    int runFrame,
  ) {
    final color = const Color(0xFFDCE3E7).withValues(alpha: 0.56);
    final drift = (progress * 40) % 8;
    _rect(canvas, x - 15 - drift, baseline - 2, 5, 3, color);
    if (runFrame.isEven) {
      _rect(canvas, x - 23 - drift, baseline - 5, 4, 3, color);
      _rect(canvas, x - 29 - drift, baseline - 2, 3, 2, color);
    }
  }

  void _drawCollectionBurst(Canvas canvas, double runnerX, double phase) {
    const start = 0.68;
    const end = 0.82;
    if (phase < start || phase > end) {
      return;
    }
    final t = (phase - start) / (end - start);
    final radius = 4 + (t * 22);
    final alpha = (1 - t).clamp(0.0, 1.0);
    const centerY = 55.0;
    for (var index = 0; index < 10; index++) {
      final angle = (math.pi * 2 * index / 10) + (t * 0.4);
      final x = runnerX + (math.cos(angle) * radius);
      final y = centerY + (math.sin(angle) * radius);
      final color =
          (index.isEven ? const Color(0xFFFFE66D) : const Color(0xFFFF8C42))
              .withValues(alpha: alpha);
      _rect(canvas, x - 2, y - 2, index.isEven ? 4 : 3, 4, color);
    }
    _rect(
      canvas,
      runnerX - 2,
      centerY - 2,
      5,
      5,
      Colors.white.withValues(alpha: alpha),
    );
  }

  void _drawLevelUp(Canvas canvas, double width, double runnerX, double phase) {
    const start = 0.71;
    const end = 0.94;
    if (phase < start || phase > end) {
      return;
    }
    final t = (phase - start) / (end - start);
    final lift = Curves.easeOut.transform(t) * 9;
    final pulse = 1 + (math.sin(t * math.pi * 4).abs() * 0.14);
    final anchorX = math.min(width - 61, math.max(6.0, runnerX - 30));
    final anchorY = 14 - lift;
    _rect(canvas, anchorX - 4, anchorY - 3, 62, 18, const Color(0xCC171C2C));
    _rect(canvas, anchorX - 2, anchorY - 1, 58, 14, const Color(0xFFE98E24));
    _rect(canvas, anchorX, anchorY + 1, 54, 10, const Color(0xFF29334C));
    _centeredPixelText(
      canvas,
      CareerPixelRunner.levelUpLabel,
      Rect.fromLTWH(anchorX, anchorY + 1, 54, 10),
      size: 7.2 * pulse,
      color: const Color(0xFFFFE66D),
      shadow: const Color(0xFF7D4213),
    );
    _rect(canvas, anchorX - 7, anchorY + 3, 3, 3, const Color(0xFFFFF5A5));
    _rect(canvas, anchorX + 60, anchorY + 7, 4, 4, const Color(0xFFFFF5A5));
  }

  void _drawOverlayScrims(Canvas canvas, double width) {
    _rect(canvas, 0, 0, width, 14, const Color(0x3A000000));
    _rect(canvas, 0, 14, width, 14, const Color(0x18000000));
    _rect(canvas, width - 34, 34, 34, 72, const Color(0x22000000));
    _rect(canvas, 0, 72, width, 18, const Color(0x16000000));
    _rect(canvas, 0, 90, width, 18, const Color(0x30000000));
    _rect(canvas, 0, 108, width, 18, const Color(0x52000000));
    _rect(canvas, 0, 126, width, 18, const Color(0x73000000));
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

  void _rect(
    Canvas canvas,
    double x,
    double y,
    double width,
    double height,
    Color color,
  ) {
    canvas.drawRect(
      Rect.fromLTWH(
        x.roundToDouble(),
        y.roundToDouble(),
        math.max(1, width.roundToDouble()),
        math.max(1, height.roundToDouble()),
      ),
      _fillPaint..color = color,
    );
  }

  double _lerp(double begin, double end, double t) {
    return begin + ((end - begin) * t);
  }

  int _positiveModulo(int value, int modulus) {
    return ((value % modulus) + modulus) % modulus;
  }

  @override
  bool shouldRepaint(covariant _CareerPixelRunnerPainter oldDelegate) {
    return oldDelegate.timeline != timeline ||
        oldDelegate.farCityTimeline != farCityTimeline ||
        oldDelegate.mainBuildingTimeline != mainBuildingTimeline ||
        oldDelegate.brightness != brightness ||
        oldDelegate.runSpriteSheet != runSpriteSheet ||
        oldDelegate.jumpSpriteSheet != jumpSpriteSheet;
  }
}

class _PixelTextPainterCache {
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
