import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;
import 'dart:ui'
    as ui
    show ImageByteFormat, SemanticsAction, Tristate, instantiateImageCodec;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/profile_app.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/mobile/apple_mobile_shell.dart';
import 'package:portfolio_hesu/portfolio/portfolio_app.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/theme/portfolio_theme_controller.dart';
import 'package:portfolio_hesu/portfolio/widgets/career_pixel_runner.dart';
import 'package:portfolio_hesu/portfolio/widgets/education_pixel_study.dart';
import 'package:portfolio_hesu/portfolio/widgets/pixel_text_layout.dart';

import 'support/music_test_controller.dart';

TextPainter _layoutPixelStatusText(String text, double fontSize) {
  return TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        height: 1,
        letterSpacing: -0.35,
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
}

void main() {
  group('모바일 Instagram형 프로필 앱', () {
    test('교육과 경력 상태 박스는 정확한 문구만 표시한다', () {
      expect(EducationPixelStudy.headerLabel, 'LEARNING');
      expect(EducationPixelStudy.headerLabel, isNot(contains('21C')));
      expect(CareerPixelRunner.levelUpLabel, 'LV + UP!');
      expect(EducationPixelStudy.sessionCompleteLabel, 'SESSION COMPLETE');
    });

    test('픽셀 상태 문구는 1px 그림자를 포함해 상자 중앙에 정렬한다', () {
      const educationPanel = Rect.fromLTWH(6, 8, 132, 50);
      final educationHeaderRect = Rect.fromLTWH(
        educationPanel.left + 4,
        educationPanel.top + 4,
        educationPanel.width - 8,
        6,
      );
      final educationCompleteRect = Rect.fromLTWH(
        educationPanel.left + 2,
        63,
        91 - 4,
        8,
      );
      const careerLevelUpRect = Rect.fromLTWH(42, 15, 54, 10);

      final cases = <(String, Rect, double)>[
        (EducationPixelStudy.headerLabel, educationHeaderRect, 4.2),
        (EducationPixelStudy.sessionCompleteLabel, educationCompleteRect, 4.8),
        (CareerPixelRunner.levelUpLabel, careerLevelUpRect, 7.2),
        (CareerPixelRunner.levelUpLabel, careerLevelUpRect, 8.2),
      ];

      for (final (label, contentRect, fontSize) in cases) {
        final foreground = _layoutPixelStatusText(label, fontSize);
        final shadow = _layoutPixelStatusText(label, fontSize);
        final origin = centeredPixelTextOrigin(
          contentRect: contentRect,
          foregroundSize: foreground.size,
          shadowSize: shadow.size,
        );
        final visualBounds = (origin & foreground.size).expandToInclude(
          (origin + const Offset(1, 1)) & shadow.size,
        );

        expect(origin.dx, origin.dx.roundToDouble(), reason: label);
        expect(origin.dy, origin.dy.roundToDouble(), reason: label);
        expect(
          (visualBounds.center.dx - contentRect.center.dx).abs(),
          lessThanOrEqualTo(0.5),
          reason: '$label horizontal center at $fontSize',
        );
        expect(
          (visualBounds.center.dy - contentRect.center.dy).abs(),
          lessThanOrEqualTo(0.5),
          reason: '$label vertical center at $fontSize',
        );
      }
    });

    test('분수 좌표의 상태 박스와 문구는 같은 픽셀 rect를 사용한다', () {
      final cases = <(String, Rect, double)>[
        (
          CareerPixelRunner.levelUpLabel,
          const Rect.fromLTWH(42.37, 8.63, 54, 10),
          7.2,
        ),
        (
          CareerPixelRunner.levelUpLabel,
          const Rect.fromLTWH(41.68, 7.42, 54, 10),
          8.2,
        ),
        (
          EducationPixelStudy.headerLabel,
          const Rect.fromLTWH(10.25, 12.35, 108.55, 6),
          4.2,
        ),
        (
          EducationPixelStudy.sessionCompleteLabel,
          const Rect.fromLTWH(8.4, 62.6, 86.6, 8),
          4.8,
        ),
      ];

      for (final (label, rawContentRect, fontSize) in cases) {
        final contentRect = snapPixelRect(rawContentRect);
        expect(
          contentRect,
          Rect.fromLTWH(
            rawContentRect.left.roundToDouble(),
            rawContentRect.top.roundToDouble(),
            math.max(1, rawContentRect.width.roundToDouble()),
            math.max(1, rawContentRect.height.roundToDouble()),
          ),
          reason: '$label pixel rect',
        );

        final foreground = _layoutPixelStatusText(label, fontSize);
        final shadow = _layoutPixelStatusText(label, fontSize);
        final origin = centeredPixelTextOrigin(
          contentRect: contentRect,
          foregroundSize: foreground.size,
          shadowSize: shadow.size,
        );
        final visualBounds = (origin & foreground.size).expandToInclude(
          (origin + const Offset(1, 1)) & shadow.size,
        );

        expect(
          (visualBounds.center.dx - contentRect.center.dx).abs(),
          lessThanOrEqualTo(0.5),
          reason: '$label horizontal center at $fontSize',
        );
        expect(
          (visualBounds.center.dy - contentRect.center.dy).abs(),
          lessThanOrEqualTo(0.5),
          reason: '$label vertical center at $fontSize',
        );
      }
    });

    test('구름·후경 빌딩·메인 빌딩은 앞쪽일수록 빠르게 무한 스크롤한다', () {
      expect(CareerPixelRunner.cloudSpeedMultiplier, 1.0);
      expect(CareerPixelRunner.farCitySpeedMultiplier, 1.25);
      expect(CareerPixelRunner.mainBuildingSpeedMultiplier, 1.5);
      expect(
        CareerPixelRunner.cloudSpeedMultiplier,
        lessThan(CareerPixelRunner.farCitySpeedMultiplier),
      );
      expect(
        CareerPixelRunner.farCitySpeedMultiplier,
        lessThan(CareerPixelRunner.mainBuildingSpeedMultiplier),
      );
    });

    test('플레이어는 초당 6프레임이며 편의점보다 작게 그린다', () {
      expect(CareerPixelRunner.runFramesPerSecond, 6);
      expect(CareerPixelRunner.runFrameVerticalLift, hasLength(8));
      expect(CareerPixelRunner.runFrameVerticalLift[1], -1);
      expect(CareerPixelRunner.runFrameVerticalLift[2], 1);
      expect(CareerPixelRunner.runFrameVerticalLift[3], 1);
      expect(CareerPixelRunner.runFrameVerticalLift[5], -1);
      expect(CareerPixelRunner.runFrameVerticalLift[6], 1);
      expect(CareerPixelRunner.runFrameVerticalLift[7], 2);
      expect(
        CareerPixelRunner.maxRunnerHeight,
        lessThanOrEqualTo(CareerPixelRunner.convenienceStoreHeight),
      );
    });

    test('승인한 달리기와 점프 스프라이트 시트를 번들 자산으로 제공한다', () async {
      expect(CareerPixelRunner.runDecodeWidth, 384);
      expect(CareerPixelRunner.jumpDecodeWidth, 314);
      for (final assetPath in <String>[
        CareerPixelRunner.runSpriteAsset,
        CareerPixelRunner.jumpSpriteAsset,
      ]) {
        final asset = await rootBundle.load(assetPath);
        expect(asset.lengthInBytes, greaterThan(0), reason: assetPath);
      }
    });

    test('교육 장면은 네 능력치를 정해진 순서로 올린다', () {
      expect(EducationPixelStudy.statLabels, <String>[
        'FLUTTER',
        'DART',
        'UX',
        'SOLVE',
      ]);
      expect(EducationPixelStudy.activeStatIndexFor(0.16), 0);
      expect(EducationPixelStudy.activeStatIndexFor(0.34), 1);
      expect(EducationPixelStudy.activeStatIndexFor(0.52), 2);
      expect(EducationPixelStudy.activeStatIndexFor(0.70), 3);
      expect(EducationPixelStudy.activeStatIndexFor(0.90), -1);
    });

    test('교육 능력치 타이밍은 반열린 구간 밖의 진행률을 비활성화한다', () {
      for (final boundary in const <(double, int)>[
        (0.12, 0),
        (0.24, -1),
        (0.30, 1),
        (0.42, -1),
        (0.48, 2),
        (0.60, -1),
        (0.66, 3),
        (0.78, -1),
      ]) {
        expect(
          EducationPixelStudy.activeStatIndexFor(boundary.$1),
          boundary.$2,
          reason: 'progress=${boundary.$1}',
        );
      }

      for (final inactiveProgress in <double>[
        0,
        0.27,
        0.45,
        0.63,
        1,
        -0.01,
        1.01,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          EducationPixelStudy.activeStatIndexFor(inactiveProgress),
          -1,
          reason: 'progress=$inactiveProgress',
        );
      }
    });

    test('교육 캐릭터는 별도 투명 스프라이트 자산을 사용한다', () async {
      expect(
        EducationPixelStudy.studySpriteAsset,
        'assets/sprites/education_student_study.png',
      );
      final asset = await rootBundle.load(EducationPixelStudy.studySpriteAsset);
      expect(asset.lengthInBytes, greaterThan(0));

      final codec = await ui.instantiateImageCodec(
        asset.buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes),
      );
      try {
        final frame = await codec.getNextFrame();
        final image = frame.image;
        try {
          expect(image.width, 1536);
          expect(image.height, 1024);

          final rgba = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          expect(rgba, isNotNull);
          var transparentPixels = 0;
          var visiblePixels = 0;
          for (var offset = 3; offset < rgba!.lengthInBytes; offset += 4) {
            if (rgba.getUint8(offset) == 0) {
              transparentPixels++;
            } else {
              visiblePixels++;
            }
          }
          expect(transparentPixels, greaterThan(0));
          expect(visiblePixels, greaterThan(0));
        } finally {
          image.dispose();
        }
      } finally {
        codec.dispose();
      }
    });

    test('교육 스프라이트 crop은 여덟 포즈를 공통 기준선에 정렬한다', () {
      expect(EducationPixelStudy.studySheetSize, const Size(1536, 1024));
      expect(EducationPixelStudy.studySourceFrames, const <Rect>[
        Rect.fromLTRB(56, 107, 336, 448),
        Rect.fromLTRB(449, 108, 720, 447),
        Rect.fromLTRB(810, 113, 1062, 448),
        Rect.fromLTRB(1178, 113, 1430, 448),
        Rect.fromLTRB(68, 525, 331, 866),
        Rect.fromLTRB(408, 526, 704, 866),
        Rect.fromLTRB(810, 530, 1062, 866),
        Rect.fromLTRB(1169, 534, 1447, 866),
      ]);

      final sheetBounds = Offset.zero & EducationPixelStudy.studySheetSize;
      const cellSize = Size(384, 512);
      const baseline = Offset(160, 200);
      const scale = 0.25;
      for (var index = 0; index < 8; index++) {
        final source = EducationPixelStudy.studySourceFrames[index];
        final cell = Rect.fromLTWH(
          (index % 4) * cellSize.width,
          (index ~/ 4) * cellSize.height,
          cellSize.width,
          cellSize.height,
        );
        expect(sheetBounds.contains(source.topLeft), isTrue);
        expect(source.right, lessThanOrEqualTo(sheetBounds.right));
        expect(source.bottom, lessThanOrEqualTo(sheetBounds.bottom));
        expect(cell.contains(source.topLeft), isTrue);
        expect(source.right, lessThan(cell.right));
        expect(source.bottom, lessThan(cell.bottom));
        expect(source.width, lessThan(cell.width));
        expect(source.height, lessThan(cell.height));

        final destination = EducationPixelStudy.destinationRectForFrame(
          index,
          baseline: baseline,
          scale: scale,
        );
        expect(destination.center.dx, baseline.dx);
        expect(
          destination.bottom -
              (EducationPixelStudy.studyFrameBottomPadding * scale),
          closeTo(baseline.dy, 0.000001),
          reason: 'frame=$index',
        );
      }
    });

    test('교육 스프라이트 destination은 잘못된 프레임과 배율을 거부한다', () {
      Rect destination(int frameIndex, double scale) =>
          EducationPixelStudy.destinationRectForFrame(
            frameIndex,
            baseline: const Offset(160, 200),
            scale: scale,
          );

      expect(() => destination(-1, 0.25), throwsRangeError);
      expect(
        () => destination(EducationPixelStudy.studySourceFrames.length, 0.25),
        throwsRangeError,
      );
      for (final scale in <double>[
        0,
        -0.25,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => destination(0, scale),
          throwsArgumentError,
          reason: 'scale=$scale',
        );
      }
    });

    testWidgets('교육 도트 장면은 공부 흐름을 하나의 이미지로 설명한다', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpStandaloneEducationStudy(
        tester,
        size: const Size(320, 258),
        disableAnimations: true,
      );

      final study = find.byType(EducationPixelStudy);
      expect(study, findsOneWidget);
      expect(
        find.bySemanticsLabel(_educationPixelStudySemantics),
        findsOneWidget,
      );
      final data = tester.getSemantics(study).getSemanticsData();
      expect(data.flagsCollection.isImage, isTrue);
      expect(data.label, _educationPixelStudySemantics);
      expect(
        find.descendant(of: study, matching: find.byType(RepaintBoundary)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: study, matching: find.byType(CustomPaint)),
        findsOneWidget,
      );

      semantics.dispose();
    });

    testWidgets('교육 도트 장면은 고정된 iPhone·iPad 미디어 크기를 채운다', (tester) async {
      for (final size in const <Size>[Size(320, 258), Size(714, 288)]) {
        await _pumpStandaloneEducationStudy(
          tester,
          size: size,
          disableAnimations: true,
        );

        final study = find.byType(EducationPixelStudy);
        expect(tester.getRect(study), Offset.zero & size, reason: '$size');
        expect(tester.takeException(), isNull, reason: '$size');
      }
    });

    testWidgets('교육 캐릭터는 측면 노트북 작업대에서 계속 공부한다', (tester) async {
      for (final brightness in Brightness.values) {
        for (final size in const <Size>[Size(320, 258), Size(714, 288)]) {
          await tester.pumpWidget(const SizedBox.shrink());
          await _pumpStandaloneEducationStudy(
            tester,
            size: size,
            disableAnimations: false,
            brightness: brightness,
          );
          final study = find.byType(EducationPixelStudy);
          await _waitForEducationStudySprite(tester, study);
          await tester.pump(const Duration(milliseconds: 640));
          final typingFrame = await _renderedBytes(tester, study);
          await tester.pump(const Duration(milliseconds: 1440));
          final notebookFrame = await _renderedBytes(tester, study);

          final sceneScale = size.height / 144;
          final sceneWidth = size.width / sceneScale;
          final studyCenter = (math.max(80.0, sceneWidth - 56) * 0.62)
              .clamp(96.0, 220.0)
              .toDouble();
          Rect sceneRect(
            double left,
            double top,
            double right,
            double bottom,
          ) => Rect.fromLTRB(
            left * sceneScale,
            top * sceneScale,
            right * sceneScale,
            bottom * sceneScale,
          );

          final foregroundScreenRegion = sceneRect(
            studyCenter + 34,
            80,
            studyCenter + 56,
            123,
          );
          final laptopBaseRegion = sceneRect(
            studyCenter + 2,
            114,
            studyCenter + 44,
            126,
          );
          final keypadRegion = sceneRect(
            studyCenter + 5,
            116,
            studyCenter + 40,
            121,
          );
          final typingHandRegion = sceneRect(
            studyCenter + 5,
            116,
            studyCenter + 28,
            126,
          );
          final chairRegion = sceneRect(
            studyCenter - 31,
            96,
            studyCenter - 15,
            132,
          );
          final backgroundWorkstationsRegion = sceneRect(
            0,
            55,
            math.max(1, studyCenter - 34),
            98,
          );
          final pageRegion = sceneRect(
            studyCenter - 4,
            119,
            studyCenter + 32,
            132,
          );
          final fasciaRegion = sceneRect(
            studyCenter - 31,
            132,
            studyCenter + 42,
            137,
          );
          final belowDeskRegion = sceneRect(
            studyCenter - 31,
            137,
            studyCenter + 42,
            144,
          );

          final screenPixels = _pixelCoordinatesInRect(
            typingFrame,
            imageSize: size,
            rect: foregroundScreenRegion,
            matches: _isCoolScreenPixel,
          );
          final screenBounds = _pixelBounds(screenPixels, imageSize: size);
          final screenWidth =
              _widestHorizontalRun(screenPixels, imageSize: size) / sceneScale;
          final screenHeight = screenBounds.height / sceneScale;
          final laptopHardwarePixels = _pixelCoordinatesInRect(
            typingFrame,
            imageSize: size,
            rect: laptopBaseRegion,
            matches: _isCoolHardwarePixel,
          );
          final laptopBaseWidth =
              _widestHorizontalRun(laptopHardwarePixels, imageSize: size) /
              sceneScale;
          final keypadCandidates = _pixelCoordinatesInRect(
            typingFrame,
            imageSize: size,
            rect: keypadRegion,
            matches: _isCoolHardwarePixel,
          );
          final keypadPixels = _pixelsInHorizontalRuns(
            keypadCandidates,
            imageSize: size,
            minimumRunLength: (6 * sceneScale).ceil(),
          );
          final keypadBounds = _pixelBounds(keypadPixels, imageSize: size);
          final typingHandPixels = _pixelCoordinatesInRect(
            typingFrame,
            imageSize: size,
            rect: typingHandRegion,
            matches: _isHandSkinPixel,
          );
          final typingHandBounds = _pixelBounds(
            typingHandPixels,
            imageSize: size,
          );
          final nearbyHandPixels = _pixelsWithinRadiusOf(
            typingHandPixels,
            keypadPixels,
            imageSize: size,
            radius: (2 * sceneScale).ceil(),
          );
          final handBelowKeypad =
              (typingHandBounds.bottom - keypadBounds.bottom) / sceneScale;
          final chairPixels = _pixelCoordinatesInRect(
            typingFrame,
            imageSize: size,
            rect: chairRegion,
            matches: _isCoolHardwarePixel,
          );
          final chairBackHeight =
              _tallestVerticalRun(chairPixels, imageSize: size) / sceneScale;
          final backgroundScreenRatio = _pixelRatioInRect(
            typingFrame,
            imageSize: size,
            rect: backgroundWorkstationsRegion,
            matches: _isCoolScreenPixel,
          );
          final typingPageRatio = _pixelRatioInRect(
            typingFrame,
            imageSize: size,
            rect: pageRegion,
            matches: _isLightPagePixel,
          );
          final notebookPageRatio = _pixelRatioInRect(
            notebookFrame,
            imageSize: size,
            rect: pageRegion,
            matches: _isLightPagePixel,
          );
          final typingFasciaExposureRatio = _pixelRatioInRect(
            typingFrame,
            imageSize: size,
            rect: fasciaRegion,
            matches: _isSpriteLeakPixel,
          );
          final notebookFasciaExposureRatio = _pixelRatioInRect(
            notebookFrame,
            imageSize: size,
            rect: fasciaRegion,
            matches: _isSpriteLeakPixel,
          );
          final typingExposureRatio = _pixelRatioInRect(
            typingFrame,
            imageSize: size,
            rect: belowDeskRegion,
            matches: _isSpriteLeakPixel,
          );
          final notebookExposureRatio = _pixelRatioInRect(
            notebookFrame,
            imageSize: size,
            rect: belowDeskRegion,
            matches: _isSpriteLeakPixel,
          );

          expect(screenPixels, isNotEmpty, reason: '$brightness $size laptop');
          expect(
            screenWidth,
            lessThanOrEqualTo(14),
            reason:
                '$brightness $size 노트북 뚜껑이 넓은 정면 모니터로 '
                '남아 있으면 안 된다. width=${screenWidth.toStringAsFixed(2)}',
          );
          expect(
            screenHeight,
            greaterThanOrEqualTo(13),
            reason:
                '$brightness $size 세로로 세운 측면 노트북 화면이 '
                '보여야 한다. height=${screenHeight.toStringAsFixed(2)}',
          );
          expect(
            screenHeight,
            greaterThan(screenWidth * 1.1),
            reason: '$brightness $size 노트북 뚜껑은 세로형이어야 한다.',
          );
          expect(
            laptopBaseWidth,
            greaterThanOrEqualTo(30),
            reason:
                '$brightness $size 바닥과 구분되는 가로 노트북 베이스가 '
                '남아야 한다. width=${laptopBaseWidth.toStringAsFixed(2)}',
          );
          expect(
            nearbyHandPixels.length,
            greaterThanOrEqualTo((2 * sceneScale).ceil()),
            reason:
                '$brightness $size 타이핑 손 픽셀이 키패드 장축과 실제로 '
                '맞닿아야 한다. nearby=${nearbyHandPixels.length}',
          );
          expect(
            handBelowKeypad,
            lessThanOrEqualTo(2),
            reason:
                '$brightness $size 손 하단이 키패드보다 지나치게 낮으면 '
                '안 된다. offset=${handBelowKeypad.toStringAsFixed(2)}',
          );
          expect(
            chairBackHeight,
            greaterThanOrEqualTo(15),
            reason:
                '$brightness $size 바닥과 구분되는 세로 의자 등받이가 '
                '보여야 한다. height=${chairBackHeight.toStringAsFixed(2)}',
          );
          expect(
            backgroundScreenRatio,
            greaterThanOrEqualTo(0.01),
            reason:
                '$brightness $size 도서관 후경의 정면 컴퓨터는 유지해야 '
                '한다. ratio=${backgroundScreenRatio.toStringAsFixed(3)}',
          );
          expect(
            notebookPageRatio,
            greaterThanOrEqualTo(typingPageRatio + 0.02),
            reason:
                '$brightness $size 노트 포즈의 밝은 페이지가 타이핑 포즈보다 '
                '작업면에 더 많아야 한다. '
                'typing=${typingPageRatio.toStringAsFixed(3)}, '
                'notebook=${notebookPageRatio.toStringAsFixed(3)}',
          );
          expect(
            math.max(typingFasciaExposureRatio, notebookFasciaExposureRatio),
            lessThanOrEqualTo(0.10),
            reason:
                '$brightness $size 넓힌 fascia 영역에 캐릭터 색이 과도하게 '
                '드러나면 안 된다. typing='
                '${typingFasciaExposureRatio.toStringAsFixed(3)}, notebook='
                '${notebookFasciaExposureRatio.toStringAsFixed(3)}',
          );
          expect(
            math.max(typingExposureRatio, notebookExposureRatio),
            lessThanOrEqualTo(0.01),
            reason:
                '$brightness $size 책상 아래에 피부·빨강·네이비 픽셀이 '
                '남으면 캐릭터가 책상 앞에 앉은 것처럼 본다. '
                'typing=${typingExposureRatio.toStringAsFixed(3)}, '
                'notebook=${notebookExposureRatio.toStringAsFixed(3)}',
          );
        }
      }
    });

    testWidgets('교육 노트 포즈는 종이를 책상 전면 위로 충분히 드러낸다', (tester) async {
      for (final brightness in Brightness.values) {
        for (final size in const <Size>[Size(320, 258), Size(714, 288)]) {
          await tester.pumpWidget(const SizedBox.shrink());
          await _pumpStandaloneEducationStudy(
            tester,
            size: size,
            disableAnimations: false,
            brightness: brightness,
          );
          final study = find.byType(EducationPixelStudy);
          await _waitForEducationStudySprite(tester, study);
          await tester.pump(const Duration(milliseconds: 2080));
          final notebookFrame = await _renderedBytes(tester, study);

          final sceneScale = size.height / 144;
          final sceneWidth = size.width / sceneScale;
          final studyCenter = (math.max(80.0, sceneWidth - 56) * 0.62)
              .clamp(96.0, 220.0)
              .toDouble();
          final pageRegion = Rect.fromLTRB(
            (studyCenter + 3) * sceneScale,
            114 * sceneScale,
            (studyCenter + 27) * sceneScale,
            126 * sceneScale,
          );
          final pagePixels = _pixelCoordinatesInRect(
            notebookFrame,
            imageSize: size,
            rect: pageRegion,
            matches: _isLightPagePixel,
          );
          final visiblePage = _largestConnectedPixelComponent(
            pagePixels,
            imageSize: size,
          );
          final pageBounds = _pixelBounds(visiblePage, imageSize: size);
          final pageArea = visiblePage.length / (sceneScale * sceneScale);
          final pageHeight = pageBounds.height / sceneScale;

          expect(visiblePage, isNotEmpty, reason: '$brightness $size page');
          expect(
            pageArea,
            greaterThanOrEqualTo(16),
            reason:
                '$brightness $size 페이지 넘김 종이가 절대 면적으로 충분히 '
                '보여야 한다. area=${pageArea.toStringAsFixed(2)}',
          );
          expect(
            pageHeight,
            greaterThanOrEqualTo(4),
            reason:
                '$brightness $size 종이가 fascia 위에서 얇은 한 줄로만 '
                '남으면 안 된다. height=${pageHeight.toStringAsFixed(2)}',
          );
        }
      }
    });

    testWidgets('교육 라이트 장면은 흰색 카메라 아이콘 배경을 3:1로 유지한다', (tester) async {
      for (final scenario in const <(String, Size, bool)>[
        ('iPhone', Size(320, 258), true),
        ('iPad', Size(714, 288), false),
      ]) {
        await _pumpStandaloneEducationStudy(
          tester,
          size: scenario.$2,
          disableAnimations: true,
        );

        final study = find.byType(EducationPixelStudy);
        final pixels = await _renderedBytes(tester, study);
        final compact = scenario.$3;
        final cameraCenter = Offset(
          scenario.$2.width - (compact ? 28 : 32),
          compact ? 32 : 36,
        );
        final cameraFootprint = Rect.fromCenter(
          center: cameraCenter,
          width: 28,
          height: 28,
        );
        final minimumContrast = _minimumWhiteContrastInRect(
          pixels,
          imageSize: scenario.$2,
          rect: cameraFootprint,
        );

        expect(
          minimumContrast,
          greaterThanOrEqualTo(3),
          reason:
              '${scenario.$1} camera footprint contrast '
              '${minimumContrast.toStringAsFixed(2)}:1',
        );
      }
    });

    testWidgets('교육 창밖 건물 불빛은 여러 층에서 서로 다른 박자로 반짝인다', (tester) async {
      const size = Size(288, 144);
      const skylineRect = Rect.fromLTRB(174, 24, 280, 50);
      const progressSamples = <double>[0.05, 0.20, 0.35, 0.50, 0.65, 0.80];

      for (final brightness in Brightness.values) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpStandaloneEducationStudy(
          tester,
          size: size,
          disableAnimations: false,
          brightness: brightness,
        );
        final study = find.byType(EducationPixelStudy);
        await _waitForEducationStudySprite(tester, study);

        final lightMasks = <Set<int>>[];
        final unlitMasks = <Set<int>>[];
        final unlitColor = brightness == Brightness.dark
            ? const (26, 73, 96)
            : const (70, 108, 120);
        var previousProgress = 0.0;
        for (final progress in progressSamples) {
          await tester.pump(
            Duration(
              milliseconds: ((progress - previousProgress) * 4000).round(),
            ),
          );
          final frame = await _renderedBytes(tester, study);
          lightMasks.add(
            _pixelCoordinatesInRect(
              frame,
              imageSize: size,
              rect: skylineRect,
              matches: (red, green, blue) =>
                  red >= 155 && green >= 100 && blue <= 150 && red > blue + 45,
            ),
          );
          unlitMasks.add(
            _pixelCoordinatesInRect(
              frame,
              imageSize: size,
              rect: skylineRect,
              matches: (red, green, blue) =>
                  red == unlitColor.$1 &&
                  green == unlitColor.$2 &&
                  blue == unlitColor.$3,
            ),
          );
          previousProgress = progress;
        }

        final union = <int>{for (final mask in lightMasks) ...mask};
        final intersection = <int>{...lightMasks.first};
        for (final mask in lightMasks.skip(1)) {
          intersection.retainAll(mask);
        }
        final steadyOffPixels = <int>{...unlitMasks.first};
        for (final mask in unlitMasks.skip(1)) {
          steadyOffPixels.retainAll(mask);
        }
        final distinctMasks = lightMasks
            .map((mask) => (mask.toList()..sort()).join(','))
            .toSet();
        final litRows = union
            .map((pixel) => pixel ~/ size.width.round())
            .toSet();

        expect(
          union.length,
          greaterThan(72),
          reason: '$brightness skyline should contain many fixed light sites',
        );
        expect(
          litRows.length,
          greaterThanOrEqualTo(10),
          reason: '$brightness lights should span multiple building floors',
        );
        expect(
          distinctMasks.length,
          greaterThanOrEqualTo(4),
          reason: '$brightness lights should not share one global blink phase',
        );
        expect(
          intersection.length,
          greaterThanOrEqualTo(12),
          reason: '$brightness skyline should retain some steady-on lights',
        );
        expect(
          steadyOffPixels.length,
          greaterThanOrEqualTo(4),
          reason: '$brightness skyline should retain some steady-off lights',
        );
      }
    });

    testWidgets('교육 도트 장면은 공부와 능력치 상승을 계속 애니메이션한다', (tester) async {
      await _pumpStandaloneEducationStudy(
        tester,
        size: const Size(320, 258),
        disableAnimations: false,
      );

      final study = find.byType(EducationPixelStudy);
      final firstFrame = await _renderedBytes(tester, study);

      await tester.pump(const Duration(milliseconds: 733));

      final secondFrame = await _renderedBytes(tester, study);
      expect(
        secondFrame,
        isNot(equals(firstFrame)),
        reason: '타이핑, 모니터, 능력치 UI가 시간에 따라 실제 픽셀을 바꿔야 한다.',
      );

      await tester.pump(const Duration(milliseconds: 733));

      final thirdFrame = await _renderedBytes(tester, study);
      expect(
        thirdFrame,
        isNot(equals(secondFrame)),
        reason: '자산 로딩이 끝난 뒤에도 controller가 다음 공부 프레임을 그려야 한다.',
      );
    });

    testWidgets('교육 도트 장면은 동작 줄이기에서 ticker 없이 정지한다', (tester) async {
      await _pumpStandaloneEducationStudy(
        tester,
        size: const Size(320, 258),
        disableAnimations: true,
      );

      final study = find.byType(EducationPixelStudy);
      final firstFrame = await _renderedBytes(tester, study);

      await tester.pump(const Duration(milliseconds: 733));

      final secondFrame = await _renderedBytes(tester, study);
      expect(secondFrame, equals(firstFrame));
      expect(
        tester.binding.hasScheduledFrame,
        isFalse,
        reason: '동작 줄이기에서는 무한 ticker가 다음 프레임을 예약하면 안 된다.',
      );
    });

    testWidgets('iPhone과 iPad는 About과 분리된 프로필 앱을 연다', (tester) async {
      final semantics = tester.ensureSemantics();

      for (final scenario in const <(Size, bool)>[
        (Size(390, 844), false),
        (Size(834, 1194), true),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProfileShell(tester, size: scenario.$1, tablet: scenario.$2);

        final launcher = find.byKey(const Key('home-app-profile'));
        expect(launcher, findsOneWidget);
        final launcherSemantics = find.descendant(
          of: launcher,
          matching: find.byKey(const Key('apple-app-icon-profile')),
        );
        expect(launcherSemantics, findsOneWidget);
        expect(
          tester.getSemantics(launcherSemantics).getSemanticsData().label,
          'Open 프로필',
        );
        expect(find.byKey(const Key('about-app')), findsNothing);

        await tester.tap(launcher);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('profile-app')), findsOneWidget);
        expect(find.byKey(const Key('about-app')), findsNothing);
        expect(
          find.byKey(const Key('mobile-app-navigation-bar')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('mobile-app-more-profile')),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('Close 프로필 window'), findsOneWidget);
      }

      semantics.dispose();
    });

    testWidgets('인스타그램형 프로필 요약을 보이고 사이드바는 iPad에만 둔다', (tester) async {
      final semantics = tester.ensureSemantics();

      for (final scenario in const <(String, Size, bool)>[
        ('iPhone', Size(390, 844), false),
        ('iPad', Size(834, 1194), true),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProfileShell(tester, size: scenario.$2, tablet: scenario.$3);
        await _openProfile(tester);

        final profile = find.byKey(const Key('profile-app'));
        expect(
          find.descendant(of: profile, matching: find.text('민희수')),
          findsOneWidget,
          reason: scenario.$1,
        );
        expect(
          find.descendant(
            of: profile,
            matching: find.byKey(const Key('profile-handle')),
          ),
          findsOneWidget,
          reason: scenario.$1,
        );
        expect(
          find.descendant(of: profile, matching: find.text('@min_hesu')),
          findsOneWidget,
          reason: scenario.$1,
        );
        _expectButtonSemantics(
          tester,
          find.byKey(const Key('profile-follow-action')),
          label: '팔로우',
        );
        _expectButtonSemantics(
          tester,
          find.byKey(const Key('profile-message-action')),
          label: '메시지 보내기',
        );
        expect(
          find.byKey(const Key('profile-sidebar')),
          scenario.$3 ? findsOneWidget : findsNothing,
          reason: scenario.$1,
        );
        expect(
          find.byKey(const Key('profile-sidebar-reels-action')),
          scenario.$3 ? findsOneWidget : findsNothing,
          reason: scenario.$1,
        );
        if (scenario.$3) {
          final profileRect = tester.getRect(profile);
          final sidebarRect = tester.getRect(
            find.byKey(const Key('profile-sidebar')),
          );
          expect(sidebarRect.width, closeTo(72, 0.1));
          expect(sidebarRect.top, closeTo(profileRect.top, 0.1));
          expect(sidebarRect.bottom, closeTo(profileRect.bottom, 0.1));
          expect(
            tester
                .getRect(
                  find.byKey(const Key('profile-sidebar-settings-action')),
                )
                .bottom,
            greaterThan(profileRect.bottom - 72),
          );
        }
        expect(
          find.byKey(const Key('profile-suggested-friends')),
          findsNothing,
          reason: scenario.$1,
        );
        expect(find.text('추천 친구'), findsNothing, reason: scenario.$1);
      }

      semantics.dispose();
    });

    testWidgets('독립 프로필은 연결 콜백이 없는 이동 제어를 비활성화한다', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpStandaloneProfile(
        tester,
        size: const Size(834, 1194),
        tablet: true,
      );

      for (final actionKey in const <Key>[
        Key('profile-message-action'),
        Key('profile-sidebar-projects-action'),
        Key('profile-sidebar-message-action'),
        Key('profile-sidebar-settings-action'),
      ]) {
        final semanticsData = tester
            .getSemantics(find.byKey(actionKey))
            .getSemanticsData();
        expect(semanticsData.flagsCollection.isEnabled, ui.Tristate.isFalse);
        expect(semanticsData.hasAction(ui.SemanticsAction.tap), isFalse);
      }
      expect(
        find.byKey(const Key('profile-career-projects-link')),
        findsNothing,
      );

      semantics.dispose();
    });

    testWidgets('팔로우 버튼은 팔로잉 상태를 두 번 토글한다', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpProfileShell(
        tester,
        size: const Size(390, 844),
        tablet: false,
      );
      await _openProfile(tester);

      final follow = find.byKey(const Key('profile-follow-action'));
      _expectButtonSemantics(tester, follow, label: '팔로우');
      expect(
        find.descendant(of: follow, matching: find.text('팔로우')),
        findsOneWidget,
      );

      await tester.tap(follow);
      await tester.pumpAndSettle();

      _expectButtonSemantics(tester, follow, label: '팔로우 취소');
      expect(
        find.descendant(of: follow, matching: find.text('팔로잉')),
        findsOneWidget,
      );

      await tester.tap(follow);
      await tester.pumpAndSettle();

      _expectButtonSemantics(tester, follow, label: '팔로우');
      expect(
        find.descendant(of: follow, matching: find.text('팔로우')),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('메시지 보내기는 메일 앱을 열고 닫으면 프로필로 돌아온다', (tester) async {
      final semantics = tester.ensureSemantics();

      for (final scenario in const <(String, Size, bool)>[
        ('iPhone', Size(390, 844), false),
        ('iPad', Size(834, 1194), true),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProfileShell(tester, size: scenario.$2, tablet: scenario.$3);
        await _openProfile(tester);

        await tester.tap(find.byKey(const Key('profile-message-action')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('mail-app')),
          findsOneWidget,
          reason: scenario.$1,
        );
        expect(
          find.byKey(const Key('profile-app')),
          findsOneWidget,
          reason: scenario.$1,
        );
        await tester.tap(find.byKey(const Key('mobile-back-close-mail')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('mail-app')),
          findsNothing,
          reason: scenario.$1,
        );
        expect(
          find.byKey(const Key('profile-app')),
          findsOneWidget,
          reason: scenario.$1,
        );
      }

      semantics.dispose();
    });

    testWidgets('경력 갤러리는 포트폴리오 회사를 열고 닫으면 프로필로 돌아온다', (tester) async {
      final semantics = tester.ensureSemantics();

      for (final scenario in const <(String, Size, bool)>[
        ('iPhone', Size(390, 844), false),
        ('iPad', Size(834, 1194), true),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProfileShell(
          tester,
          size: scenario.$2,
          tablet: scenario.$3,
          data: _injectedProfileData(),
        );
        await _openProfile(tester);

        final career = find.byKey(const Key('profile-history-post-experience'));
        await _ensureCardBuilt(tester, career);
        _expectButtonSemantics(tester, career, label: '경력 게시물 열기');
        final companyLink = find.byKey(
          const Key('profile-career-projects-link'),
        );
        _expectButtonSemantics(tester, companyLink, label: '포트폴리오 회사 열기');
        final linkRect = tester.getRect(companyLink);
        expect(linkRect.width, greaterThanOrEqualTo(44));
        expect(linkRect.height, greaterThanOrEqualTo(44));
        await tester.ensureVisible(career);
        await tester.tap(companyLink);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('projects-app')),
          findsOneWidget,
          reason: scenario.$1,
        );
        expect(
          tester
              .getSemantics(
                find.byKey(const Key('projects-finder-location-career')),
              )
              .getSemanticsData()
              .flagsCollection
              .isSelected,
          ui.Tristate.isTrue,
          reason: scenario.$1,
        );
        await tester.tap(find.byKey(const Key('mobile-back-close-projects')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('projects-app')), findsNothing);
        expect(find.byKey(const Key('profile-app')), findsOneWidget);
        expect(find.byKey(const Key('profile-history-grid')), findsOneWidget);
      }

      semantics.dispose();
    });

    testWidgets('경력 상세는 Reels 문구 대신 도심 픽셀 러너를 미디어 슬롯에 채운다', (tester) async {
      final semantics = tester.ensureSemantics();
      final data = _injectedProfileData();
      await _pumpProfileShell(
        tester,
        size: const Size(390, 844),
        tablet: false,
        data: data,
      );
      await _openProfile(tester);

      await _openHistoryCard(
        tester,
        const Key('profile-history-post-experience'),
      );

      final detail = find.byKey(const Key('profile-history-detail'));
      final mediaSlot = find.byKey(const Key('profile-reel-media-slot'));
      final runner = find.byKey(const Key('profile-career-pixel-runner'));
      expect(detail, findsOneWidget);
      expect(find.byKey(const Key('projects-app')), findsNothing);
      expect(
        find.descendant(of: detail, matching: find.text('Reels')),
        findsNothing,
      );
      expect(find.descendant(of: mediaSlot, matching: runner), findsOneWidget);
      expect(tester.widget(runner).runtimeType.toString(), 'CareerPixelRunner');
      expect(tester.getRect(runner), tester.getRect(mediaSlot));
      expect(
        find.descendant(of: runner, matching: find.byType(CustomPaint)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: runner, matching: find.byType(RepaintBoundary)),
        findsOneWidget,
      );

      final runnerSemantics = tester.getSemantics(runner).getSemanticsData();
      expect(runnerSemantics.flagsCollection.isImage, isTrue);
      expect(runnerSemantics.label, _careerPixelRunnerSemantics);
      expect(
        find.byKey(const Key('profile-reel-reply-item-experience-0')),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('경력 픽셀 러너는 시간이 지나면 서로 다른 프레임을 그린다', (tester) async {
      await _pumpProfileShell(
        tester,
        size: const Size(390, 844),
        tablet: false,
        data: _injectedProfileData(),
        disableAnimations: false,
      );
      await _openProfile(tester);
      await _openHistoryCard(
        tester,
        const Key('profile-history-post-experience'),
      );

      final runner = find.byKey(const Key('profile-career-pixel-runner'));
      expect(runner, findsOneWidget);
      final firstFrame = await _renderedBytes(tester, runner);

      await tester.pump(const Duration(milliseconds: 733));

      final secondFrame = await _renderedBytes(tester, runner);
      expect(
        secondFrame,
        isNot(equals(firstFrame)),
        reason: '달리기, 점프, 배경 이동, 코인 획득이 시간에 따라 실제 픽셀을 바꿔야 한다.',
      );
    });

    testWidgets('5초 뒤 점프는 반복되지만 1.5배 배경은 계속 전진한다', (tester) async {
      await _pumpProfileShell(
        tester,
        size: const Size(390, 844),
        tablet: false,
        data: _injectedProfileData(),
        disableAnimations: false,
      );
      await _openProfile(tester);
      await _openHistoryCard(
        tester,
        const Key('profile-history-post-experience'),
      );

      final runner = find.byKey(const Key('profile-career-pixel-runner'));
      final firstFrame = await _renderedBytes(tester, runner);

      await tester.pump(const Duration(seconds: 5));

      final advancedFrame = await _renderedBytes(tester, runner);
      expect(
        advancedFrame,
        isNot(equals(firstFrame)),
        reason: '점프 타임라인은 그대로 반복되어도 배경은 독립된 1.5배 루프로 계속 전진해야 한다.',
      );
    });

    testWidgets('경력 픽셀 러너는 동작 줄이기에서 같은 정지 장면만 제공한다', (tester) async {
      await _pumpProfileShell(
        tester,
        size: const Size(390, 844),
        tablet: false,
        data: _injectedProfileData(),
        disableAnimations: true,
      );
      await _openProfile(tester);
      await _openHistoryCard(
        tester,
        const Key('profile-history-post-experience'),
      );

      final runner = find.byKey(const Key('profile-career-pixel-runner'));
      expect(runner, findsOneWidget);
      final firstFrame = await _renderedBytes(tester, runner);

      await tester.pump(const Duration(milliseconds: 733));

      final secondFrame = await _renderedBytes(tester, runner);
      expect(secondFrame, equals(firstFrame));
      expect(
        tester.binding.hasScheduledFrame,
        isFalse,
        reason: '동작 줄이기에서는 무한 ticker가 다음 프레임을 예약하면 안 된다.',
      );
    });

    testWidgets('iPad 경력 바로가기는 릴스 명칭 없이 경력 상세를 연다', (tester) async {
      final semantics = tester.ensureSemantics();
      final data = _injectedProfileData();
      await _pumpProfileShell(
        tester,
        size: const Size(834, 1194),
        tablet: true,
        data: data,
      );
      await _openProfile(tester);

      final careerAction = find.byKey(
        const Key('profile-sidebar-reels-action'),
      );
      _expectButtonSemantics(tester, careerAction, label: '경력 보기');
      expect(find.bySemanticsLabel('릴스 보기'), findsNothing);
      await _openCareerReelFromSidebar(tester);

      expect(find.byKey(const Key('profile-history-detail')), findsOneWidget);
      expect(find.byKey(const Key('projects-app')), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('profile-reel-info')),
          matching: find.text('경력'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('profile-sidebar')), findsOneWidget);

      await tester.tap(find.byKey(const Key('mobile-back-close-profile')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile-history-detail')), findsNothing);
      expect(find.byKey(const Key('profile-history-grid')), findsOneWidget);
      expect(find.byKey(const Key('profile-sidebar')), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('경력이 없으면 iPad 경력 바로가기는 교육을 대신 열지 않는다', (tester) async {
      final semantics = tester.ensureSemantics();
      final source = _injectedProfileData();
      final data = _profileDataWithHistory(
        source,
        experiences: const <PortfolioExperience>[],
        education: source.education,
      );
      await _pumpProfileShell(
        tester,
        size: const Size(834, 1194),
        tablet: true,
        data: data,
      );
      await _openProfile(tester);

      final careerAction = find.byKey(
        const Key('profile-sidebar-reels-action'),
      );
      final careerSemantics = tester
          .getSemantics(careerAction)
          .getSemanticsData();
      expect(careerSemantics.label, '경력 보기');
      expect(careerSemantics.flagsCollection.isEnabled, ui.Tristate.isFalse);
      expect(careerSemantics.hasAction(ui.SemanticsAction.tap), isFalse);
      expect(find.byKey(const Key('profile-history-detail')), findsNothing);

      semantics.dispose();
    });

    testWidgets('피드는 identity와 단위가 있는 게시물·경력·교육 통계만 보여준다', (tester) async {
      final semantics = tester.ensureSemantics();
      final source = _injectedProfileData();
      final data = _profileDataWithHistory(
        source,
        experiences: source.experiences.take(1),
        education: source.education,
      );
      await _pumpProfileShell(
        tester,
        size: const Size(390, 844),
        tablet: false,
        data: data,
      );

      await _openProfile(tester);

      final profile = find.byKey(const Key('profile-app'));
      expect(profile, findsOneWidget);
      for (final text in <String>[
        data.identity.name,
        data.identity.englishName,
        data.identity.headline,
        data.identity.biography,
      ]) {
        expect(
          find.descendant(of: profile, matching: find.text(text)),
          findsOneWidget,
          reason: text,
        );
      }
      expect(find.bySemanticsLabel('게시물 2개'), findsOneWidget);
      expect(find.bySemanticsLabel('경력 3년'), findsOneWidget);
      expect(find.bySemanticsLabel('교육 2번'), findsOneWidget);
      expect(find.bySemanticsLabel('프로젝트 1개'), findsNothing);
      expect(find.bySemanticsLabel('스킬 2개'), findsNothing);
      final stats = find.byKey(const Key('profile-stats'));
      expect(
        find.descendant(of: stats, matching: find.text('2개')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: stats, matching: find.text('3년')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: stats, matching: find.text('2번')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('profile-github-action')), findsNothing);
      expect(find.byKey(const Key('profile-mail-action')), findsNothing);
      expect(find.byKey(const Key('profile-history-grid')), findsOneWidget);
      expect(find.byKey(const Key('profile-highlights')), findsNothing);
      expect(find.byKey(const Key('profile-project-grid')), findsNothing);
      expect(find.text(_sentinelSkillGroup), findsNothing);
      expect(find.text(_sentinelSkill), findsNothing);
      expect(find.text(_sentinelProjectTitle), findsNothing);
      expect(find.text(_sentinelProjectDescription), findsNothing);
      expect(_fakeSocialMetricTextInside(profile), findsNothing);
      semantics.dispose();
    });

    testWidgets('경력과 교육은 각각 하나의 정사각형 게시물로 피드에 배치한다', (tester) async {
      final semantics = tester.ensureSemantics();
      final data = _injectedProfileData();
      for (final scenario in const <(String, Size, bool)>[
        ('iPhone', Size(390, 844), false),
        ('iPad', Size(834, 1194), true),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProfileShell(
          tester,
          size: scenario.$2,
          tablet: scenario.$3,
          data: data,
        );
        await _openProfile(tester);

        final grid = find.byKey(const Key('profile-history-grid'));
        final experiencePost = find.byKey(
          const Key('profile-history-post-experience'),
        );
        final educationPost = find.byKey(
          const Key('profile-history-post-education'),
        );
        expect(grid, findsOneWidget, reason: scenario.$1);
        for (final post in <Finder>[experiencePost, educationPost]) {
          await _ensureCardBuilt(tester, post);
          expect(find.descendant(of: grid, matching: post), findsOneWidget);
          final postRect = tester.getRect(post);
          expect(postRect.width, greaterThan(0), reason: scenario.$1);
          expect(
            postRect.width,
            closeTo(postRect.height, 0.5),
            reason: scenario.$1,
          );
        }
        expect(
          _widgetsWithKeyPrefixInside(grid, 'profile-history-card-experience-'),
          findsNothing,
        );
        expect(
          _widgetsWithKeyPrefixInside(grid, 'profile-history-card-education-'),
          findsNothing,
        );
        expect(find.byKey(const Key('profile-history-post')), findsNothing);
        _expectButtonSemantics(tester, experiencePost, label: '경력 게시물 열기');
        _expectButtonSemantics(tester, educationPost, label: '교육 게시물 열기');
        expect(
          find.descendant(of: experiencePost, matching: find.text('경력')),
          findsWidgets,
        );
        expect(
          find.descendant(
            of: experiencePost,
            matching: find.text('경력 ${data.experiences.length}개'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: educationPost, matching: find.text('교육')),
          findsWidgets,
        );
        expect(
          find.descendant(
            of: educationPost,
            matching: find.text('교육 ${data.education.length}개'),
          ),
          findsOneWidget,
        );
      }
      semantics.dispose();
    });

    testWidgets('교육 상세는 스터디 장면을 미디어 슬롯에 채운다', (tester) async {
      final semantics = tester.ensureSemantics();
      final data = _injectedProfileData();
      await _pumpProfileShell(
        tester,
        size: const Size(390, 844),
        tablet: false,
        data: data,
      );
      await _openProfile(tester);
      await _openHistoryCard(
        tester,
        const Key('profile-history-post-education'),
      );

      final detail = find.byKey(const Key('profile-history-detail'));
      final mediaSlot = find.byKey(const Key('profile-reel-media-slot'));
      final study = find.byKey(const Key('profile-education-pixel-study'));
      expect(study, findsOneWidget);
      expect(find.descendant(of: mediaSlot, matching: study), findsOneWidget);
      expect(tester.widget(study), isA<EducationPixelStudy>());
      expect(tester.getRect(study), tester.getRect(mediaSlot));
      expect(
        find.byKey(const Key('profile-career-pixel-runner')),
        findsNothing,
      );
      expect(
        tester.getSemantics(study).getSemanticsData().label,
        _educationPixelStudySemantics,
      );
      expect(
        find.byKey(const Key('profile-reel-reply-item-education-0')),
        findsOneWidget,
      );
      expect(find.descendant(of: detail, matching: study), findsOneWidget);
      _expectHistoryDetailTemplate(tester, data: data);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets('iPhone·iPad에서 경력과 교육은 같은 미디어 rect를 쓴다', (tester) async {
      for (final scenario in const <(String, Size, bool, double)>[
        ('iPhone', Size(390, 844), false, 258),
        ('iPad', Size(834, 1194), true, 288),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProfileShell(
          tester,
          size: scenario.$2,
          tablet: scenario.$3,
          data: _injectedProfileData(),
        );
        await _openProfile(tester);
        await _openHistoryCard(
          tester,
          const Key('profile-history-post-education'),
        );

        final educationSlot = find.byKey(const Key('profile-reel-media-slot'));
        final study = find.byKey(const Key('profile-education-pixel-study'));
        expect(study, findsOneWidget, reason: scenario.$1);
        expect(
          find.byKey(const Key('profile-career-pixel-runner')),
          findsNothing,
          reason: scenario.$1,
        );
        final educationRect = tester.getRect(educationSlot);
        expect(
          tester.getRect(study),
          educationRect,
          reason: '${scenario.$1} education fills slot',
        );
        expect(
          educationRect.height,
          scenario.$4,
          reason: '${scenario.$1} existing reel height',
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProfileShell(
          tester,
          size: scenario.$2,
          tablet: scenario.$3,
          data: _injectedProfileData(),
        );
        await _openProfile(tester);
        await _openHistoryCard(
          tester,
          const Key('profile-history-post-experience'),
        );

        final careerSlot = find.byKey(const Key('profile-reel-media-slot'));
        final runner = find.byKey(const Key('profile-career-pixel-runner'));
        expect(runner, findsOneWidget, reason: scenario.$1);
        expect(
          find.byKey(const Key('profile-education-pixel-study')),
          findsNothing,
          reason: scenario.$1,
        );
        final careerRect = tester.getRect(careerSlot);
        expect(
          tester.getRect(runner),
          careerRect,
          reason: '${scenario.$1} career fills slot',
        );
        expect(
          careerRect,
          educationRect,
          reason: '${scenario.$1} education and career use one reel rule',
        );
      }
    });

    testWidgets('릴스 미디어는 공유 액션 직후 끝나고 첫 답글을 바로 보여준다', (tester) async {
      for (final scenario in const <(String, Size, bool)>[
        ('iPhone', Size(390, 844), false),
        ('iPad', Size(834, 1194), true),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProfileShell(
          tester,
          size: scenario.$2,
          tablet: scenario.$3,
          data: _injectedProfileData(),
        );
        await _openProfile(tester);
        await _openHistoryCard(
          tester,
          const Key('profile-history-post-education'),
        );

        final detail = find.byKey(const Key('profile-history-detail'));
        final overlay = find.byKey(const Key('profile-reel-overlay'));
        final thread = find.byKey(const Key('profile-reel-reply-thread'));
        final firstReply = find.byKey(
          const Key('profile-reel-reply-item-education-0'),
        );
        final shareAction = find.byKey(const Key('profile-reel-share-action'));
        final detailRect = tester.getRect(detail);
        final overlayRect = tester.getRect(overlay);
        final threadRect = tester.getRect(thread);
        final firstReplyRect = tester.getRect(firstReply);
        final shareActionRect = tester.getRect(shareAction);

        expect(
          overlayRect.left,
          closeTo(detailRect.left, 1),
          reason: '${scenario.$1} left edge',
        );
        expect(
          overlayRect.right,
          closeTo(detailRect.right, 1),
          reason: '${scenario.$1} right edge',
        );
        expect(
          overlayRect.top,
          closeTo(detailRect.top, 1),
          reason: '${scenario.$1} top edge',
        );
        expect(
          overlayRect.height,
          lessThan(detailRect.height),
          reason: '${scenario.$1} compact reel height',
        );
        expect(
          threadRect.top,
          closeTo(overlayRect.bottom, 1),
          reason: '${scenario.$1} thread follows the reel surface',
        );
        expect(
          overlayRect.bottom - shareActionRect.bottom,
          inInclusiveRange(0, 24),
          reason: '${scenario.$1} reel ends near the share action',
        );
        expect(
          threadRect.top,
          lessThan(detailRect.bottom),
          reason: '${scenario.$1} thread starts in the initial viewport',
        );
        expect(
          firstReplyRect.top,
          lessThan(detailRect.bottom),
          reason: '${scenario.$1} first reply is initially visible',
        );
        expect(
          firstReplyRect.bottom,
          greaterThan(detailRect.top),
          reason: '${scenario.$1} first reply intersects the viewport',
        );
        expect(tester.widget<Stack>(overlay), isA<Stack>());
        expect(
          tester
              .element(overlay)
              .findAncestorWidgetOfExactType<ClipRRect>()
              ?.key,
          const Key('mobile-app-clip'),
          reason: '${scenario.$1} overlay is not a rounded inset card',
        );
      }
    });

    testWidgets('컬러 미디어 위 오버레이 컨트롤은 라이트·다크 모두 흰색이다', (tester) async {
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProfileShell(
          tester,
          size: const Size(390, 844),
          tablet: false,
          brightness: brightness,
          data: _injectedProfileData(),
        );
        await _openProfile(tester);
        await _openHistoryCard(
          tester,
          const Key('profile-history-post-education'),
        );

        final overlay = find.byKey(const Key('profile-reel-overlay'));
        final mediaSlot = find.byKey(const Key('profile-reel-media-slot'));
        final topBar = find.byKey(const Key('profile-reel-top-bar'));
        final actionRail = find.byKey(const Key('profile-reel-action-rail'));
        final info = find.byKey(const Key('profile-reel-info'));
        expect(
          find.descendant(of: overlay, matching: mediaSlot),
          findsOneWidget,
        );

        final mediaColor = tester.widget<ColoredBox>(mediaSlot).color;
        const foreground = Colors.white;
        if (brightness == Brightness.light) {
          expect(mediaColor.computeLuminance(), greaterThan(0.7));
        } else {
          expect(mediaColor.computeLuminance(), lessThan(0.2));
        }

        final overlayText = <Text>[
          ...find
              .descendant(of: topBar, matching: find.byType(Text))
              .evaluate()
              .map((element) => element.widget as Text),
          ...find
              .descendant(of: info, matching: find.byType(Text))
              .evaluate()
              .map((element) => element.widget as Text),
        ];
        expect(overlayText, isNotEmpty);
        for (final text in overlayText) {
          expect(text.style?.color, foreground, reason: text.data);
        }

        final actionIcons = find
            .descendant(of: actionRail, matching: find.byType(Icon))
            .evaluate()
            .map((element) => element.widget as Icon)
            .toList();
        expect(actionIcons, hasLength(3));
        for (final icon in actionIcons) {
          expect(icon.color, foreground);
        }
        final cameraIcon = tester.widget<Icon>(
          find.descendant(of: topBar, matching: find.byType(Icon)),
        );
        expect(cameraIcon.color, foreground);

        final avatar = tester.widget<Container>(
          find.byKey(const Key('profile-reel-avatar')),
        );
        final avatarDecoration = avatar.decoration! as BoxDecoration;
        expect(avatarDecoration.border!.top.color, foreground);

        final likeAction = find.byKey(const Key('profile-reel-like-action'));
        await tester.tap(likeAction);
        await tester.pump();
        final filledHeart = find.descendant(
          of: likeAction,
          matching: find.byIcon(Icons.favorite_rounded),
        );
        expect(filledHeart, findsOneWidget);
        expect(tester.widget<Icon>(filledHeart).color, AppleTheme.red);
      }
    });

    testWidgets('하트는 카운트 없이 outline과 빨간 filled 상태를 두 번 토글한다', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpProfileShell(
        tester,
        size: const Size(390, 844),
        tablet: false,
        data: _injectedProfileData(),
      );
      await _openProfile(tester);
      await _openHistoryCard(
        tester,
        const Key('profile-history-post-education'),
      );

      final detail = find.byKey(const Key('profile-history-detail'));
      final actionRail = find.byKey(const Key('profile-reel-action-rail'));
      final likeAction = find.byKey(const Key('profile-reel-like-action'));
      expect(
        find.descendant(of: actionRail, matching: likeAction),
        findsOneWidget,
      );
      _expectButtonSemantics(tester, likeAction, label: '좋아요');
      expect(
        find.descendant(
          of: likeAction,
          matching: find.byIcon(Icons.favorite_border_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: likeAction,
          matching: find.byIcon(Icons.favorite_rounded),
        ),
        findsNothing,
      );

      await tester.tap(likeAction);
      await tester.pump();

      _expectButtonSemantics(tester, likeAction, label: '좋아요 취소');
      final filledHeart = find.descendant(
        of: likeAction,
        matching: find.byIcon(Icons.favorite_rounded),
      );
      expect(filledHeart, findsOneWidget);
      expect(tester.widget<Icon>(filledHeart).color, AppleTheme.red);
      expect(
        find.descendant(
          of: likeAction,
          matching: find.byIcon(Icons.favorite_border_rounded),
        ),
        findsNothing,
      );

      await tester.tap(likeAction);
      await tester.pump();

      _expectButtonSemantics(tester, likeAction, label: '좋아요');
      expect(
        find.descendant(
          of: likeAction,
          matching: find.byIcon(Icons.favorite_border_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: likeAction,
          matching: find.byIcon(Icons.favorite_rounded),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: actionRail, matching: find.byType(Text)),
        findsNothing,
        reason: '행동 레일에 임의의 좋아요·댓글 수를 만들지 않는다.',
      );
      expect(find.byKey(const Key('profile-reel-like-count')), findsNothing);
      expect(find.byKey(const Key('profile-reel-comment-count')), findsNothing);
      expect(_fakeSocialMetricTextInside(detail), findsNothing);
      expect(_fakeSocialMetricSemanticsInside(detail), findsNothing);
      semantics.dispose();
    });

    testWidgets('좋아요는 같은 게시물에 보존되고 경력·교육 사이에서 분리된다', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpProfileShell(
        tester,
        size: const Size(834, 1194),
        tablet: true,
        data: _injectedProfileData(),
      );
      await _openProfile(tester);
      await _openCareerReelFromSidebar(tester);

      var likeAction = find.byKey(const Key('profile-reel-like-action'));
      await tester.tap(likeAction);
      await tester.pump();
      _expectButtonSemantics(tester, likeAction, label: '좋아요 취소');

      await tester.tap(find.byKey(const Key('mobile-back-close-profile')));
      await tester.pumpAndSettle();
      await _openCareerReelFromSidebar(tester);

      likeAction = find.byKey(const Key('profile-reel-like-action'));
      _expectButtonSemantics(tester, likeAction, label: '좋아요 취소');
      final persistedHeart = find.descendant(
        of: likeAction,
        matching: find.byIcon(Icons.favorite_rounded),
      );
      expect(persistedHeart, findsOneWidget);
      expect(tester.widget<Icon>(persistedHeart).color, AppleTheme.red);

      await tester.tap(find.byKey(const Key('mobile-back-close-profile')));
      await tester.pumpAndSettle();
      await _openHistoryCard(
        tester,
        const Key('profile-history-post-education'),
      );

      likeAction = find.byKey(const Key('profile-reel-like-action'));
      _expectButtonSemantics(tester, likeAction, label: '좋아요');
      expect(
        find.descendant(
          of: likeAction,
          matching: find.byIcon(Icons.favorite_border_rounded),
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('동일 경력 재빌드는 상태를 보존하고 변경된 경력은 상세와 좋아요를 초기화한다', (tester) async {
      final semantics = tester.ensureSemantics();
      final original = _injectedProfileData();
      await _pumpProfileShell(
        tester,
        size: const Size(834, 1194),
        tablet: true,
        data: original,
      );
      await _openProfile(tester);
      await _openCareerReelFromSidebar(tester);

      final profileState = tester.state(find.byType(ProfileApp));
      var likeAction = find.byKey(const Key('profile-reel-like-action'));
      await tester.tap(likeAction);
      await tester.pump();
      _expectButtonSemantics(tester, likeAction, label: '좋아요 취소');

      final copiedExperiences = <PortfolioExperience>[
        for (final item in original.experiences)
          PortfolioExperience(
            role: item.role,
            organization: item.organization,
            period: item.period,
            description: item.description,
          ),
      ];
      final copiedEducation = <PortfolioEducation>[
        for (final item in original.education)
          PortfolioEducation(
            program: item.program,
            institution: item.institution,
            period: item.period,
            link: switch (item.link) {
              final link? => PortfolioProjectLink(
                label: link.label,
                url: link.url,
              ),
              null => null,
            },
          ),
      ];
      final identicalHistory = _profileDataWithHistory(
        original,
        experiences: copiedExperiences,
        education: copiedEducation,
      );

      await _pumpProfileShell(
        tester,
        size: const Size(834, 1194),
        tablet: true,
        data: identicalHistory,
      );

      expect(
        identical(tester.state(find.byType(ProfileApp)), profileState),
        isTrue,
      );
      expect(find.byKey(const Key('profile-history-detail')), findsOneWidget);
      likeAction = find.byKey(const Key('profile-reel-like-action'));
      _expectButtonSemantics(tester, likeAction, label: '좋아요 취소');

      final changedHistory = _profileDataWithHistory(
        identicalHistory,
        experiences: <PortfolioExperience>[
          copiedExperiences[1],
          copiedExperiences[0],
          copiedExperiences[2],
        ],
        education: <PortfolioEducation>[copiedEducation[1], copiedEducation[0]],
      );

      await _pumpProfileShell(
        tester,
        size: const Size(834, 1194),
        tablet: true,
        data: changedHistory,
      );

      expect(
        identical(tester.state(find.byType(ProfileApp)), profileState),
        isTrue,
      );
      expect(find.byKey(const Key('profile-history-detail')), findsNothing);
      expect(find.byKey(const Key('profile-history-grid')), findsOneWidget);
      final feedPosition = tester
          .state<ScrollableState>(
            _scrollableInside(const Key('profile-scroll')),
          )
          .position;
      expect(feedPosition.pixels, closeTo(0, 0.5));

      await _openCareerReelFromSidebar(tester);
      likeAction = find.byKey(const Key('profile-reel-like-action'));
      _expectButtonSemantics(tester, likeAction, label: '좋아요');
      expect(
        find.descendant(
          of: likeAction,
          matching: find.byIcon(Icons.favorite_border_rounded),
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('댓글 버튼은 같은 상세 스크롤을 답글 스레드까지 이동시킨다', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpProfileShell(
        tester,
        size: const Size(390, 560),
        tablet: false,
        data: _injectedProfileData(),
      );
      await _openProfile(tester);
      await _openHistoryCard(
        tester,
        const Key('profile-history-post-education'),
      );

      final detail = find.byKey(const Key('profile-history-detail'));
      final detailScroll = find.byKey(
        const Key('profile-history-detail-scroll'),
      );
      final scrollable = _scrollableInside(
        const Key('profile-history-detail-scroll'),
      );
      final commentAction = find.byKey(
        const Key('profile-reel-comment-action'),
      );
      final replyThread = find.byKey(const Key('profile-reel-reply-thread'));
      expect(scrollable, findsOneWidget);
      expect(commentAction, findsOneWidget);
      _expectButtonSemantics(tester, commentAction, label: '댓글 보기');
      expect(
        find.descendant(of: detailScroll, matching: replyThread),
        findsOneWidget,
      );

      final scrollableState = tester.state<ScrollableState>(scrollable);
      final position = scrollableState.position;
      final offsetBeforeTap = position.pixels;
      final bottomSheetCountBefore = find.byType(BottomSheet).evaluate().length;
      final dialogCountBefore = find.byType(Dialog).evaluate().length;
      final modalBarrierCountBefore = find
          .byType(ModalBarrier)
          .evaluate()
          .length;

      await tester.tap(commentAction);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile-history-detail')), findsOneWidget);
      expect(
        find.byKey(const Key('profile-reel-comments-sheet')),
        findsNothing,
      );
      expect(find.byType(BottomSheet), findsNWidgets(bottomSheetCountBefore));
      expect(find.byType(Dialog), findsNWidgets(dialogCountBefore));
      expect(find.byType(ModalBarrier), findsNWidgets(modalBarrierCountBefore));
      expect(_verticalScrollablesInside(detail), findsOneWidget);
      expect(
        identical(tester.state<ScrollableState>(scrollable), scrollableState),
        isTrue,
      );
      expect(identical(scrollableState.position, position), isTrue);
      expect(position.pixels, greaterThan(offsetBeforeTap));
      expect(
        tester.getRect(replyThread).top,
        inInclusiveRange(
          tester.getRect(detail).top,
          tester.getRect(detail).bottom,
        ),
      );
      semantics.dispose();
    });

    testWidgets('경력 게시물은 실제 경력만 각각의 답글로 서술한다', (tester) async {
      final semantics = tester.ensureSemantics();
      final data = _injectedProfileData();
      await _pumpProfileShell(
        tester,
        size: const Size(834, 1194),
        tablet: true,
        data: data,
      );
      await _openProfile(tester);
      await _openCareerReelFromSidebar(tester);

      final detail = find.byKey(const Key('profile-history-detail'));
      final overlay = find.byKey(const Key('profile-reel-overlay'));
      final info = find.byKey(const Key('profile-reel-info'));
      final thread = find.byKey(const Key('profile-reel-reply-thread'));
      expect(thread, findsOneWidget);
      expect(
        tester.getRect(overlay).bottom,
        lessThanOrEqualTo(tester.getRect(thread).top),
      );
      expect(
        find.descendant(of: info, matching: find.text('경력')),
        findsOneWidget,
      );

      final expectedItemKeys = <String>[
        for (var index = 0; index < data.experiences.length; index++)
          'profile-reel-reply-item-experience-$index',
      ];
      final replyItems = _widgetsWithKeyPrefixInside(
        thread,
        'profile-reel-reply-item-',
      );
      expect(replyItems, findsNWidgets(expectedItemKeys.length));
      expect(
        replyItems.evaluate().map((element) {
          return (element.widget.key! as ValueKey<String>).value;
        }).toList(),
        expectedItemKeys,
        reason: '경력 게시물에는 경력 답글만 원본 순서로 이어져야 한다.',
      );
      expect(
        _widgetsWithKeyPrefixInside(
          thread,
          'profile-reel-reply-item-education-',
        ),
        findsNothing,
      );
      expect(
        _widgetsWithKeyPrefixInside(thread, 'profile-reel-reply-author-'),
        findsNWidgets(expectedItemKeys.length),
      );
      for (final forbidden in <String>[
        _sentinelSkillGroup,
        _sentinelSkill,
        _sentinelProjectTitle,
        _sentinelProjectDescription,
      ]) {
        expect(
          find.descendant(
            of: thread,
            matching: find.textContaining(forbidden, findRichText: true),
          ),
          findsNothing,
          reason: '실제 경력·교육 외 콘텐츠를 reply로 섞지 않는다.',
        );
      }

      for (var index = 0; index < data.experiences.length; index++) {
        final experience = data.experiences[index];
        _expectReplyItem(
          tester,
          thread: thread,
          authorTitle: experience.organization,
          kind: 'experience',
          index: index,
          expectedText: <String>[experience.period, experience.description],
        );
        final item = find.byKey(
          Key('profile-reel-reply-item-experience-$index'),
        );
        expect(
          find.descendant(of: item, matching: find.text(experience.role)),
          findsNothing,
        );
        expect(
          find.descendant(of: item, matching: find.text(data.identity.name)),
          findsNothing,
        );
      }

      for (final education in data.education) {
        expect(
          find.descendant(of: thread, matching: find.text(education.program)),
          findsNothing,
        );
      }
      expect(
        find.byKey(const Key('profile-reel-comment-composer')),
        findsNothing,
      );
      expect(
        find.descendant(of: detail, matching: find.byType(TextField)),
        findsNothing,
      );
      semantics.dispose();
    });

    testWidgets('교육 게시물은 실제 교육만 각각의 답글로 서술하고 링크를 유지한다', (tester) async {
      final semantics = tester.ensureSemantics();
      final data = _injectedProfileData();
      final launcher = _RecordingLauncher();
      await _pumpProfileShell(
        tester,
        size: const Size(390, 844),
        tablet: false,
        data: data,
        launcher: launcher,
      );
      await _openProfile(tester);
      await _openHistoryCard(
        tester,
        const Key('profile-history-post-education'),
      );

      final detail = find.byKey(const Key('profile-history-detail'));
      final info = find.byKey(const Key('profile-reel-info'));
      final thread = find.byKey(const Key('profile-reel-reply-thread'));
      expect(
        find.descendant(of: info, matching: find.text('교육')),
        findsOneWidget,
      );
      final expectedItemKeys = <String>[
        for (var index = 0; index < data.education.length; index++)
          'profile-reel-reply-item-education-$index',
      ];
      final replyItems = _widgetsWithKeyPrefixInside(
        thread,
        'profile-reel-reply-item-',
      );
      expect(replyItems, findsNWidgets(expectedItemKeys.length));
      expect(
        replyItems.evaluate().map((element) {
          return (element.widget.key! as ValueKey<String>).value;
        }).toList(),
        expectedItemKeys,
        reason: '교육 게시물에는 교육 답글만 원본 순서로 이어져야 한다.',
      );
      expect(
        _widgetsWithKeyPrefixInside(
          thread,
          'profile-reel-reply-item-experience-',
        ),
        findsNothing,
      );

      for (var index = 0; index < data.education.length; index++) {
        final education = data.education[index];
        _expectReplyItem(
          tester,
          thread: thread,
          authorTitle: education.institution,
          kind: 'education',
          index: index,
          expectedText: <String>[
            education.period,
            education.program,
            if (education.link case final link?) link.label,
          ],
        );
        final item = find.byKey(
          Key('profile-reel-reply-item-education-$index'),
        );
        expect(
          find.descendant(of: item, matching: find.text(data.identity.name)),
          findsNothing,
        );
      }
      for (final experience in data.experiences) {
        expect(
          find.descendant(of: thread, matching: find.text(experience.role)),
          findsNothing,
        );
      }

      final linkedEducation = data.education.first;
      final link = linkedEducation.link!;
      final linkedItem = find.byKey(
        const Key('profile-reel-reply-item-education-0'),
      );
      final unlinkedItem = find.byKey(
        const Key('profile-reel-reply-item-education-1'),
      );
      final linkAction = find.byKey(
        const Key('profile-reel-reply-link-education-0'),
      );
      expect(
        find.descendant(of: linkedItem, matching: linkAction),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: linkedItem,
          matching: find.bySemanticsLabel('Open ${link.label}'),
        ),
        findsOneWidget,
      );
      _expectButtonSemantics(tester, linkAction, label: 'Open ${link.label}');
      expect(
        find.descendant(
          of: unlinkedItem,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget.key == const Key('profile-reel-reply-link-education-1'),
          ),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: detail,
          matching: find.bySemanticsLabel('Open ${link.label}'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(const Key('profile-reel-comment-composer')),
        findsNothing,
      );
      expect(
        find.descendant(of: detail, matching: find.byType(TextField)),
        findsNothing,
      );
      expect(
        find.descendant(of: detail, matching: find.byType(EditableText)),
        findsNothing,
      );

      await tester.ensureVisible(linkAction);
      await tester.pumpAndSettle();
      await tester.tap(linkAction);
      await tester.pumpAndSettle();
      expect(launcher.uris, <Uri>[link.uri]);
      semantics.dispose();
    });

    testWidgets('상세 문구 계층은 iPhone·iPad·desktop과 큰 글씨에서 동일하다', (tester) async {
      final data = _injectedProfileData();
      for (final scenario in const <(String, Size, bool, bool)>[
        ('iPhone', Size(390, 844), false, false),
        ('iPad', Size(834, 1194), true, false),
        ('desktop', Size(900, 650), false, true),
      ]) {
        for (final history
            in <
              ({
                String kind,
                Key postKey,
                String sectionTitle,
                String authorTitle,
                List<String> content,
              })
            >[
              (
                kind: 'experience',
                postKey: const Key('profile-history-post-experience'),
                sectionTitle: '경력',
                authorTitle: data.experiences.first.organization,
                content: <String>[
                  data.experiences.first.period,
                  data.experiences.first.description,
                ],
              ),
              (
                kind: 'education',
                postKey: const Key('profile-history-post-education'),
                sectionTitle: '교육',
                authorTitle: data.education.first.institution,
                content: <String>[
                  data.education.first.period,
                  data.education.first.program,
                  data.education.first.link!.label,
                ],
              ),
            ]) {
          await tester.pumpWidget(const SizedBox.shrink());
          if (scenario.$4) {
            await _pumpStandaloneProfile(
              tester,
              size: scenario.$2,
              tablet: false,
              data: data,
              textScaler: const TextScaler.linear(2),
            );
          } else {
            await _pumpProfileShell(
              tester,
              size: scenario.$2,
              tablet: scenario.$3,
              data: data,
              textScaler: const TextScaler.linear(2),
            );
            await _openProfile(tester);
          }
          await _openHistoryCard(tester, history.postKey);

          final info = find.byKey(const Key('profile-reel-info'));
          final infoText = find
              .descendant(of: info, matching: find.byType(Text))
              .evaluate()
              .map((element) => (element.widget as Text).data)
              .whereType<String>()
              .toList();
          expect(infoText, <String>[
            data.monogram,
            data.identity.name,
            history.sectionTitle,
          ], reason: '${scenario.$1} ${history.kind} overlay');

          final thread = find.byKey(const Key('profile-reel-reply-thread'));
          _expectReplyItem(
            tester,
            thread: thread,
            authorTitle: history.authorTitle,
            kind: history.kind,
            index: 0,
            expectedText: history.content,
          );
          final item = find.byKey(
            Key('profile-reel-reply-item-${history.kind}-0'),
          );
          final author = find.byKey(
            Key('profile-reel-reply-author-${history.kind}-0'),
          );
          final content = find.byKey(
            Key('profile-reel-reply-content-${history.kind}-0'),
          );
          final itemRect = tester.getRect(item);
          for (final rect in <Rect>[
            tester.getRect(author),
            tester.getRect(content),
          ]) {
            expect(
              rect.left,
              greaterThanOrEqualTo(itemRect.left),
              reason: '${scenario.$1} ${history.kind} left bound',
            );
            expect(
              rect.right,
              lessThanOrEqualTo(itemRect.right),
              reason: '${scenario.$1} ${history.kind} right bound',
            );
          }
          expect(
            tester.takeException(),
            isNull,
            reason: '${scenario.$1} ${history.kind}',
          );
        }
      }
    });

    testWidgets('공용 헤더는 상세에서 뒤로 가고 피드 루트에서 앱을 닫는다', (tester) async {
      final semantics = tester.ensureSemantics();
      final data = _injectedProfileData();
      for (final scenario in const <(String, Size, bool)>[
        ('iPhone', Size(390, 844), false),
        ('iPad', Size(834, 1194), true),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProfileShell(
          tester,
          size: scenario.$2,
          tablet: scenario.$3,
          data: data,
        );
        await _openProfile(tester);

        final control = find.byKey(const Key('mobile-back-close-profile'));
        expect(
          find.byKey(const Key('mobile-app-navigation-bar')),
          findsOneWidget,
          reason: scenario.$1,
        );
        expect(control, findsOneWidget, reason: scenario.$1);
        expect(
          tester.getSemantics(control).getSemanticsData().label,
          'Close 프로필 window',
          reason: scenario.$1,
        );

        await _openHistoryCard(
          tester,
          const Key('profile-history-post-education'),
        );
        expect(
          find.byKey(const Key('mobile-app-navigation-bar')),
          findsOneWidget,
          reason: scenario.$1,
        );
        expect(find.byKey(const Key('profile-history-detail')), findsOneWidget);
        expect(
          tester.getSemantics(control).getSemanticsData().label,
          'Back in 프로필',
          reason: scenario.$1,
        );
        expect(find.bySemanticsLabel('Close 프로필 window'), findsNothing);
        final detail = find.byKey(const Key('profile-history-detail'));
        expect(find.byKey(const Key('profile-history-grid')), findsNothing);
        expect(find.byKey(const Key('profile-app')), findsOneWidget);
        expect(find.byKey(const Key('mobile-app-surface')), findsOneWidget);
        expect(_fakeSocialMetricTextInside(detail), findsNothing);
        expect(_fakeSocialMetricSemanticsInside(detail), findsNothing);

        await tester.tap(control);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('profile-history-detail')), findsNothing);
        expect(find.byKey(const Key('profile-history-grid')), findsOneWidget);
        expect(find.byKey(const Key('mobile-app-surface')), findsOneWidget);
        expect(
          find.byKey(const Key('mobile-app-navigation-bar')),
          findsOneWidget,
          reason: scenario.$1,
        );
        expect(
          tester.getSemantics(control).getSemanticsData().label,
          'Close 프로필 window',
          reason: scenario.$1,
        );

        await tester.tap(control);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('mobile-home')), findsOneWidget);
        expect(find.byKey(const Key('mobile-app-surface')), findsNothing);
      }
      semantics.dispose();
    });

    testWidgets('상세에서 돌아오면 iPhone과 iPad 피드의 비영 스크롤 위치를 복원한다', (tester) async {
      final data = _injectedProfileData();
      for (final scenario in const <(String, Size, bool)>[
        ('iPhone', Size(390, 420), false),
        ('iPad', Size(834, 420), true),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProfileShell(
          tester,
          size: scenario.$2,
          tablet: scenario.$3,
          data: data,
        );
        await _openProfile(tester);

        final card = find.byKey(const Key('profile-history-post-education'));
        await _ensureCardBuilt(tester, card);
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        final feedPosition = tester
            .state<ScrollableState>(
              _scrollableInside(const Key('profile-scroll')),
            )
            .position;
        final offsetBeforeDetail = feedPosition.pixels;
        expect(
          offsetBeforeDetail,
          greaterThan(0),
          reason: '${scenario.$1} precondition',
        );

        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('profile-history-detail')), findsOneWidget);
        await tester.tap(find.byKey(const Key('mobile-back-close-profile')));
        await tester.pumpAndSettle();

        final restoredPosition = tester
            .state<ScrollableState>(
              _scrollableInside(const Key('profile-scroll')),
            )
            .position;
        expect(
          restoredPosition.pixels,
          closeTo(offsetBeforeDetail, 1),
          reason: scenario.$1,
        );
        expect(card, findsOneWidget, reason: scenario.$1);
        final cardRect = tester.getRect(card);
        expect(cardRect.bottom, greaterThan(0), reason: scenario.$1);
        expect(cardRect.top, lessThan(scenario.$2.height), reason: scenario.$1);
      }
    });

    testWidgets('라이트와 다크의 iPhone·iPad 200% 피드와 상세가 넘치지 않는다', (tester) async {
      for (final formFactor in const <(Size, bool)>[
        (Size(320, 480), false),
        (Size(600, 720), true),
        (Size(834, 620), true),
      ]) {
        final backgroundColors = <Brightness, Color>{};
        for (final brightness in Brightness.values) {
          final data = _injectedProfileData();
          await tester.pumpWidget(const SizedBox.shrink());
          await _pumpProfileShell(
            tester,
            size: formFactor.$1,
            tablet: formFactor.$2,
            brightness: brightness,
            textScaler: const TextScaler.linear(2),
            data: data,
          );

          await _openProfile(tester);

          final profile = find.byKey(const Key('profile-app'));
          expect(profile, findsOneWidget);
          final background = find.byKey(const Key('profile-background'));
          expect(background, findsOneWidget);
          backgroundColors[brightness] = tester
              .widget<ColoredBox>(background)
              .color;
          expect(find.byKey(const Key('profile-scroll')), findsOneWidget);
          expect(find.byKey(const Key('profile-history-grid')), findsOneWidget);
          final firstCard = find.byKey(
            const Key('profile-history-post-experience'),
          );
          await _ensureCardBuilt(tester, firstCard);
          await tester.ensureVisible(firstCard);
          await tester.pumpAndSettle();
          final metadata = find.byKey(
            const Key('profile-history-post-meta-experience'),
          );
          final title = find.byKey(
            const Key('profile-history-post-title-experience'),
          );
          expect(metadata, findsOneWidget);
          expect(title, findsOneWidget);
          expect(
            tester.getRect(metadata).bottom,
            lessThanOrEqualTo(tester.getRect(title).top + 0.5),
            reason: '${formFactor.$1} $brightness card text overlap',
          );
          expect(
            Theme.of(tester.element(profile)).brightness,
            brightness,
            reason: '${formFactor.$1} $brightness',
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '${formFactor.$1} $brightness feed',
          );

          if (formFactor.$2) {
            await _openCareerReelFromSidebar(tester);
          } else {
            await _openHistoryCard(
              tester,
              const Key('profile-history-post-education'),
            );
          }
          expect(
            find.byKey(const Key('profile-history-detail')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('profile-history-detail-scroll')),
            findsOneWidget,
          );
          expect(
            Theme.of(
              tester.element(find.byKey(const Key('profile-history-detail'))),
            ).brightness,
            brightness,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '${formFactor.$1} $brightness detail',
          );

          if (formFactor.$2) {
            await tester.tap(
              find.byKey(const Key('mobile-back-close-profile')),
            );
            await tester.pumpAndSettle();
            await _openHistoryCard(
              tester,
              const Key('profile-history-post-education'),
            );
            expect(
              find.byKey(const Key('profile-history-detail')),
              findsOneWidget,
            );
            expect(
              tester.takeException(),
              isNull,
              reason: '${formFactor.$1} $brightness education detail',
            );
          }
        }
        expect(
          backgroundColors[Brightness.light],
          isNot(backgroundColors[Brightness.dark]),
          reason: '${formFactor.$1} light and dark surfaces',
        );
      }
    });

    testWidgets('iPhone과 iPad의 피드와 상세는 터치와 마우스 드래그로 스크롤된다', (tester) async {
      for (final scenario in const <(String, Size, bool)>[
        ('iPhone', Size(320, 480), false),
        ('iPad', Size(834, 620), true),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProfileShell(
          tester,
          size: scenario.$2,
          tablet: scenario.$3,
          data: _injectedProfileData(),
        );
        await _openProfile(tester);
        await _expectTouchAndMouseScroll(
          tester,
          const Key('profile-scroll'),
          reason: '${scenario.$1} feed',
        );
        if (scenario.$3) {
          await _openCareerReelFromSidebar(tester);
        } else {
          await _openHistoryCard(
            tester,
            const Key('profile-history-post-education'),
          );
        }
        await _expectTouchAndMouseScroll(
          tester,
          const Key('profile-history-detail-scroll'),
          reason: '${scenario.$1} detail',
        );
        expect(tester.takeException(), isNull, reason: scenario.$1);
      }
    });
  });
}

Future<void> _pumpProfileShell(
  WidgetTester tester, {
  required Size size,
  required bool tablet,
  PortfolioData data = portfolioData,
  ExternalLauncher? launcher,
  Brightness brightness = Brightness.light,
  TextScaler textScaler = TextScaler.noScaling,
  bool disableAnimations = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final themeController = PortfolioThemeController(
    initial: brightness == Brightness.dark
        ? PortfolioThemePreference.dark
        : PortfolioThemePreference.light,
  );
  addTearDown(themeController.dispose);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.light(),
      darkTheme: AppleTheme.dark(),
      themeMode: themeController.themeMode,
      scrollBehavior: const PortfolioScrollBehavior(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: textScaler,
          disableAnimations: disableAnimations,
        ),
        child: AppleMobileShell(
          data: data,
          externalLauncher: launcher ?? _RecordingLauncher(),
          themeController: themeController,
          musicController: createTestMusicController(),
          tablet: tablet,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpStandaloneProfile(
  WidgetTester tester, {
  required Size size,
  required bool tablet,
  PortfolioData data = portfolioData,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.light(),
      darkTheme: AppleTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: textScaler,
          disableAnimations: true,
        ),
        child: ProfileApp(
          data: data,
          launcher: _RecordingLauncher(),
          tablet: tablet,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpStandaloneEducationStudy(
  WidgetTester tester, {
  required Size size,
  required bool disableAnimations,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.light(),
      darkTheme: AppleTheme.dark(),
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      home: MediaQuery(
        data: MediaQueryData(size: size, disableAnimations: disableAnimations),
        child: const EducationPixelStudy(),
      ),
    ),
  );
  if (disableAnimations) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

PortfolioData _injectedProfileData() {
  return PortfolioData(
    identity: const PortfolioIdentity(
      name: '프로필 사용자',
      englishName: 'Profile User',
      email: 'profile@example.com',
      githubUrl: 'https://github.com/profile-user/',
      headline: 'Injected profile headline',
      biography: 'Injected profile biography',
    ),
    experiences: const <PortfolioExperience>[
      PortfolioExperience(
        role: 'Lead Flutter Developer',
        organization: 'Profile Company Alpha',
        period: '2024 - Present',
        description: _longExperienceDescription,
      ),
      PortfolioExperience(
        role: 'Mobile Engineer',
        organization: 'Profile Company Beta',
        period: '2022 - 2024',
        description: 'Flutter와 Dart 기반 모바일 제품의 설계와 출시를 담당했습니다.',
      ),
      PortfolioExperience(
        role: 'Junior Java Developer',
        organization: 'Profile Company Gamma',
        period: '2020 - 2021',
        description: 'Java 기반 애플리케이션 개발과 운영 자동화를 경험했습니다.',
      ),
    ],
    education: const <PortfolioEducation>[
      PortfolioEducation(
        program: 'Advanced Mobile Application Development Program',
        institution: 'Profile Technology Academy',
        period: '2019 - 2020',
        link: PortfolioProjectLink(
          label: 'Education certificate',
          url: 'https://example.com/education/certificate',
        ),
      ),
      PortfolioEducation(
        program: 'Game Entertainment and Business Degree',
        institution: 'Profile University',
        period: '2009 - 2011',
      ),
    ],
    skillGroups: const <PortfolioSkillGroup>[
      PortfolioSkillGroup.constant(
        title: _sentinelSkillGroup,
        skills: <String>[_sentinelSkill, 'SECOND_SENTINEL_SKILL'],
      ),
    ],
    projects: const <PortfolioProject>[
      PortfolioProject.constant(
        title: _sentinelProjectTitle,
        description: _sentinelProjectDescription,
        period: '2026',
        technologies: <String>['SENTINEL_PROJECT_TECHNOLOGY'],
        links: <PortfolioProjectLink>[],
      ),
    ],
  );
}

PortfolioData _profileDataWithHistory(
  PortfolioData source, {
  required Iterable<PortfolioExperience> experiences,
  required Iterable<PortfolioEducation> education,
}) {
  return PortfolioData(
    identity: source.identity,
    experiences: experiences,
    education: education,
    skillGroups: source.skillGroups,
    projects: source.projects,
  );
}

final class _RecordingLauncher implements ExternalLauncher {
  final List<Uri> uris = <Uri>[];

  @override
  Future<bool> launch(Uri uri) async {
    uris.add(uri);
    return true;
  }
}

Finder _scrollableInside(Key key) {
  return find.descendant(
    of: find.byKey(key),
    matching: find.byType(Scrollable),
  );
}

Future<void> _openProfile(WidgetTester tester) async {
  final profileLauncher = find.byKey(const Key('home-app-profile'));
  expect(profileLauncher, findsOneWidget);
  await tester.tap(profileLauncher);
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('profile-app')), findsOneWidget);
}

Future<void> _openHistoryCard(WidgetTester tester, Key cardKey) async {
  final card = find.byKey(cardKey);
  await _ensureCardBuilt(tester, card);
  expect(card, findsOneWidget);
  await tester.ensureVisible(card);
  await tester.pumpAndSettle();
  await tester.tap(card);
  await tester.pump();
}

Future<void> _openCareerReelFromSidebar(WidgetTester tester) async {
  final reelsAction = find.byKey(const Key('profile-sidebar-reels-action'));
  expect(find.byKey(const Key('profile-sidebar')), findsOneWidget);
  expect(reelsAction, findsOneWidget);
  await tester.tap(reelsAction);
  await tester.pump();
}

Future<void> _ensureCardBuilt(WidgetTester tester, Finder card) async {
  final scrollable = _scrollableInside(const Key('profile-scroll'));
  final position = tester.state<ScrollableState>(scrollable).position;
  while (card.evaluate().isEmpty &&
      position.pixels < position.maxScrollExtent) {
    await tester.drag(
      find.byKey(const Key('profile-scroll')),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _expectTouchAndMouseScroll(
  WidgetTester tester,
  Key scrollKey, {
  required String reason,
}) async {
  final target = find.byKey(scrollKey);
  expect(target, findsOneWidget, reason: reason);
  final scrollable = find.descendant(
    of: target,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          (widget.axisDirection == AxisDirection.down ||
              widget.axisDirection == AxisDirection.up),
      description: 'vertical Scrollable',
    ),
  );
  expect(scrollable, findsOneWidget, reason: reason);
  final position = tester.state<ScrollableState>(scrollable).position;
  expect(position.maxScrollExtent, greaterThan(0), reason: reason);

  await tester.drag(target, const Offset(0, -180));
  await tester.pump(const Duration(milliseconds: 300));
  expect(position.pixels, greaterThan(0), reason: '$reason touch');

  position.jumpTo(0);
  await tester.pump();
  final targetRect = tester.getRect(target);
  final dragStart = Offset(targetRect.left + 8, targetRect.center.dy);
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: dragStart);
  await mouse.down(dragStart);
  await mouse.moveBy(const Offset(0, -180));
  await mouse.up();
  await tester.pump(const Duration(milliseconds: 300));
  expect(position.pixels, greaterThan(0), reason: '$reason mouse');
  await mouse.removePointer();

  position.jumpTo(0);
  await tester.pump();
}

Finder _fakeSocialMetricTextInside(Finder scope) {
  return find.descendant(
    of: scope,
    matching: find.textContaining(_fakeSocialMetricPattern, findRichText: true),
  );
}

Finder _fakeSocialMetricSemanticsInside(Finder scope) {
  return find.descendant(
    of: scope,
    matching: find.bySemanticsLabel(_fakeSocialMetricPattern),
  );
}

void _expectButtonSemantics(
  WidgetTester tester,
  Finder finder, {
  required String label,
}) {
  expect(finder, findsOneWidget);
  final semantics = tester.getSemantics(finder).getSemanticsData();
  expect(semantics.label, label);
  expect(semantics.flagsCollection.isButton, isTrue);
  expect(semantics.hasAction(ui.SemanticsAction.tap), isTrue);
}

Finder _widgetsWithKeyPrefixInside(Finder scope, String prefix) {
  return find.descendant(
    of: scope,
    matching: find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> && key.value.startsWith(prefix);
    }, description: 'widget with a key beginning with $prefix'),
  );
}

Finder _verticalScrollablesInside(Finder scope) {
  return find.descendant(
    of: scope,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          (widget.axisDirection == AxisDirection.down ||
              widget.axisDirection == AxisDirection.up),
      description: 'vertical Scrollable',
    ),
  );
}

Future<Uint8List> _renderedBytes(WidgetTester tester, Finder scope) async {
  final boundary = find.descendant(
    of: scope,
    matching: find.byType(RepaintBoundary),
  );
  expect(boundary, findsOneWidget);
  final renderBoundary = tester.renderObject<RenderRepaintBoundary>(boundary);
  final rendered = await tester.runAsync<Uint8List>(() async {
    final image = await renderBoundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (bytes == null) {
        throw StateError('The pixel scene did not render RGBA bytes.');
      }
      return Uint8List.fromList(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
    } finally {
      image.dispose();
    }
  });
  expect(rendered, isNotNull);
  return rendered!;
}

Future<void> _waitForEducationStudySprite(
  WidgetTester tester,
  Finder study,
) async {
  final paint = find.descendant(of: study, matching: find.byType(CustomPaint));
  expect(paint, findsOneWidget);

  for (var attempt = 0; attempt < 100; attempt++) {
    final painter = tester.widget<CustomPaint>(paint).painter as dynamic;
    if (painter.studySpriteSheet != null) {
      return;
    }
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    });
    await tester.pump();
  }

  fail('교육 스프라이트가 제한 시간 안에 디코딩되지 않았다.');
}

double _minimumWhiteContrastInRect(
  Uint8List rgba, {
  required Size imageSize,
  required Rect rect,
}) {
  final width = imageSize.width.round();
  final height = imageSize.height.round();
  var brightestBackdrop = 0.0;
  for (
    var y = rect.top.floor().clamp(0, height);
    y < rect.bottom.ceil().clamp(0, height);
    y++
  ) {
    for (
      var x = rect.left.floor().clamp(0, width);
      x < rect.right.ceil().clamp(0, width);
      x++
    ) {
      final byteOffset = ((y * width) + x) * 4;
      final backdrop = Color.fromARGB(
        rgba[byteOffset + 3],
        rgba[byteOffset],
        rgba[byteOffset + 1],
        rgba[byteOffset + 2],
      );
      brightestBackdrop = math.max(
        brightestBackdrop,
        backdrop.computeLuminance(),
      );
    }
  }
  return 1.05 / (brightestBackdrop + 0.05);
}

double _pixelRatioInRect(
  Uint8List rgba, {
  required Size imageSize,
  required Rect rect,
  required bool Function(int red, int green, int blue) matches,
}) {
  final width = imageSize.width.round();
  final height = imageSize.height.round();
  var matchingPixels = 0;
  var pixelCount = 0;
  for (
    var y = rect.top.floor().clamp(0, height);
    y < rect.bottom.ceil().clamp(0, height);
    y++
  ) {
    for (
      var x = rect.left.floor().clamp(0, width);
      x < rect.right.ceil().clamp(0, width);
      x++
    ) {
      final byteOffset = ((y * width) + x) * 4;
      if (matches(
        rgba[byteOffset],
        rgba[byteOffset + 1],
        rgba[byteOffset + 2],
      )) {
        matchingPixels++;
      }
      pixelCount++;
    }
  }
  return pixelCount == 0 ? 0 : matchingPixels / pixelCount;
}

Set<int> _pixelCoordinatesInRect(
  Uint8List rgba, {
  required Size imageSize,
  required Rect rect,
  required bool Function(int red, int green, int blue) matches,
}) {
  final width = imageSize.width.round();
  final height = imageSize.height.round();
  final matchingPixels = <int>{};
  for (
    var y = rect.top.floor().clamp(0, height);
    y < rect.bottom.ceil().clamp(0, height);
    y++
  ) {
    for (
      var x = rect.left.floor().clamp(0, width);
      x < rect.right.ceil().clamp(0, width);
      x++
    ) {
      final byteOffset = ((y * width) + x) * 4;
      final red = rgba[byteOffset];
      final green = rgba[byteOffset + 1];
      final blue = rgba[byteOffset + 2];
      if (matches(red, green, blue)) {
        matchingPixels.add((y * width) + x);
      }
    }
  }
  return matchingPixels;
}

Rect _pixelBounds(Set<int> pixels, {required Size imageSize}) {
  if (pixels.isEmpty) {
    return Rect.zero;
  }
  final width = imageSize.width.round();
  var left = width;
  var top = imageSize.height.round();
  var right = 0;
  var bottom = 0;
  for (final pixel in pixels) {
    final x = pixel % width;
    final y = pixel ~/ width;
    left = math.min(left, x);
    top = math.min(top, y);
    right = math.max(right, x + 1);
    bottom = math.max(bottom, y + 1);
  }
  return Rect.fromLTRB(
    left.toDouble(),
    top.toDouble(),
    right.toDouble(),
    bottom.toDouble(),
  );
}

int _widestHorizontalRun(Set<int> pixels, {required Size imageSize}) {
  if (pixels.isEmpty) {
    return 0;
  }
  final width = imageSize.width.round();
  final sortedPixels = pixels.toList()..sort();
  var widestRun = 1;
  var currentRun = 1;
  for (var index = 1; index < sortedPixels.length; index++) {
    final previous = sortedPixels[index - 1];
    final current = sortedPixels[index];
    if (current == previous + 1 && current ~/ width == previous ~/ width) {
      currentRun++;
      widestRun = math.max(widestRun, currentRun);
    } else {
      currentRun = 1;
    }
  }
  return widestRun;
}

Set<int> _pixelsInHorizontalRuns(
  Set<int> pixels, {
  required Size imageSize,
  required int minimumRunLength,
}) {
  if (pixels.isEmpty) {
    return <int>{};
  }
  final width = imageSize.width.round();
  final sortedPixels = pixels.toList()..sort();
  final runPixels = <int>{};
  var runStart = 0;

  void addRun(int runEnd) {
    if (runEnd - runStart >= minimumRunLength) {
      runPixels.addAll(sortedPixels.sublist(runStart, runEnd));
    }
  }

  for (var index = 1; index < sortedPixels.length; index++) {
    final previous = sortedPixels[index - 1];
    final current = sortedPixels[index];
    if (current != previous + 1 || current ~/ width != previous ~/ width) {
      addRun(index);
      runStart = index;
    }
  }
  addRun(sortedPixels.length);
  return runPixels;
}

int _tallestVerticalRun(Set<int> pixels, {required Size imageSize}) {
  if (pixels.isEmpty) {
    return 0;
  }
  final width = imageSize.width.round();
  var tallestRun = 1;
  for (final pixel in pixels) {
    if (pixels.contains(pixel - width)) {
      continue;
    }
    var run = 1;
    var next = pixel + width;
    while (pixels.contains(next)) {
      run++;
      next += width;
    }
    tallestRun = math.max(tallestRun, run);
  }
  return tallestRun;
}

Set<int> _pixelsWithinRadiusOf(
  Set<int> source,
  Set<int> target, {
  required Size imageSize,
  required int radius,
}) {
  if (source.isEmpty || target.isEmpty) {
    return <int>{};
  }
  final width = imageSize.width.round();
  final height = imageSize.height.round();
  final nearby = <int>{};
  for (final pixel in source) {
    final x = pixel % width;
    final y = pixel ~/ width;
    search:
    for (var dy = -radius; dy <= radius; dy++) {
      final candidateY = y + dy;
      if (candidateY < 0 || candidateY >= height) {
        continue;
      }
      final horizontalRadius = radius - dy.abs();
      for (var dx = -horizontalRadius; dx <= horizontalRadius; dx++) {
        final candidateX = x + dx;
        if (candidateX < 0 || candidateX >= width) {
          continue;
        }
        if (target.contains((candidateY * width) + candidateX)) {
          nearby.add(pixel);
          break search;
        }
      }
    }
  }
  return nearby;
}

Set<int> _largestConnectedPixelComponent(
  Set<int> pixels, {
  required Size imageSize,
}) {
  if (pixels.isEmpty) {
    return <int>{};
  }
  final width = imageSize.width.round();
  final height = imageSize.height.round();
  final remaining = Set<int>.of(pixels);
  var largest = <int>{};

  while (remaining.isNotEmpty) {
    final first = remaining.first;
    final component = <int>{first};
    final queue = <int>[first];
    remaining.remove(first);
    for (var index = 0; index < queue.length; index++) {
      final pixel = queue[index];
      final x = pixel % width;
      final y = pixel ~/ width;
      final neighbors = <int>[
        if (x > 0) pixel - 1,
        if (x + 1 < width) pixel + 1,
        if (y > 0) pixel - width,
        if (y + 1 < height) pixel + width,
      ];
      for (final neighbor in neighbors) {
        if (remaining.remove(neighbor)) {
          component.add(neighbor);
          queue.add(neighbor);
        }
      }
    }
    if (component.length > largest.length) {
      largest = component;
    }
  }
  return largest;
}

bool _isSkinPixel(int red, int green, int blue) =>
    red >= 70 && red > green * 1.35 && green > blue * 1.10;

bool _isHandSkinPixel(int red, int green, int blue) =>
    red >= 100 && red > green * 1.35 && green > blue * 1.10;

bool _isCoolScreenPixel(int red, int green, int blue) =>
    blue >= 45 && green >= 32 && blue > red * 1.18 && blue > green * 1.06;

bool _isCoolHardwarePixel(int red, int green, int blue) {
  final brightest = math.max(red, math.max(green, blue));
  return red >= 8 &&
      brightest <= 205 &&
      green >= red + 3 &&
      blue >= green + 2 &&
      blue - red <= 40;
}

bool _isLightPagePixel(int red, int green, int blue) =>
    red >= 125 &&
    green >= 125 &&
    blue >= 120 &&
    math.max(red, math.max(green, blue)) -
            math.min(red, math.min(green, blue)) <
        45;

bool _isSpriteLeakPixel(int red, int green, int blue) =>
    _isSkinPixel(red, green, blue) ||
    (red >= 45 && red > green * 1.55 && red > blue * 1.35) ||
    (blue >= 25 && blue > green * 1.30 && green > red * 1.15);

void _expectReplyItem(
  WidgetTester tester, {
  required Finder thread,
  required String authorTitle,
  required String kind,
  required int index,
  required List<String> expectedText,
}) {
  final item = find.byKey(Key('profile-reel-reply-item-$kind-$index'));
  final author = find.byKey(Key('profile-reel-reply-author-$kind-$index'));
  final content = find.byKey(Key('profile-reel-reply-content-$kind-$index'));
  expect(find.descendant(of: thread, matching: item), findsOneWidget);
  expect(find.descendant(of: item, matching: author), findsOneWidget);
  expect(find.descendant(of: item, matching: content), findsOneWidget);
  expect(
    find.descendant(of: author, matching: find.text(authorTitle)),
    findsOneWidget,
  );

  final authorText = find
      .descendant(of: author, matching: find.byType(Text))
      .evaluate()
      .map((element) => (element.widget as Text).data)
      .whereType<String>()
      .toList();
  expect(authorText, <String>[authorTitle], reason: '각 답글의 소속 기관을 제목으로 노출한다.');

  final contentTextWidgets = find.descendant(
    of: content,
    matching: find.byType(Text),
  );
  final contentText = contentTextWidgets
      .evaluate()
      .map((element) => (element.widget as Text).data)
      .whereType<String>()
      .toList();
  expect(contentText, expectedText, reason: '임의의 댓글 대신 실제 포트폴리오 데이터만 서술한다.');
  for (final text in expectedText) {
    final textWidget = find.descendant(of: content, matching: find.text(text));
    expect(textWidget, findsOneWidget, reason: text);
    final widget = tester.widget<Text>(textWidget);
    expect(widget.maxLines, isNull, reason: text);
    expect(widget.overflow, isNot(TextOverflow.ellipsis), reason: text);
  }
}

void _expectHistoryDetailTemplate(
  WidgetTester tester, {
  required PortfolioData data,
}) {
  final detail = find.byKey(const Key('profile-history-detail'));
  final overlay = find.byKey(const Key('profile-reel-overlay'));
  final topBar = find.byKey(const Key('profile-reel-top-bar'));
  final actionRail = find.byKey(const Key('profile-reel-action-rail'));
  final info = find.byKey(const Key('profile-reel-info'));
  final account = find.byKey(const Key('profile-reel-account-row'));

  expect(detail, findsOneWidget);
  expect(overlay, findsOneWidget);
  final overlayRect = tester.getRect(overlay);
  expect(overlayRect.height, greaterThan(0));
  expect(overlayRect.width, greaterThan(tester.getSize(detail).width * 0.55));

  for (final section in <Finder>[topBar, actionRail, info]) {
    expect(
      find.descendant(of: overlay, matching: section),
      findsOneWidget,
      reason: 'Reel controls must stay inside the overlay',
    );
  }
  final topBarRect = tester.getRect(topBar);
  final actionRailRect = tester.getRect(actionRail);
  final infoRect = tester.getRect(info);
  for (final sectionRect in <Rect>[topBarRect, actionRailRect, infoRect]) {
    expect(sectionRect.left, greaterThanOrEqualTo(overlayRect.left));
    expect(sectionRect.top, greaterThanOrEqualTo(overlayRect.top));
    expect(sectionRect.right, lessThanOrEqualTo(overlayRect.right));
    expect(sectionRect.bottom, lessThanOrEqualTo(overlayRect.bottom));
  }
  expect(
    topBarRect.center.dy,
    lessThan(overlayRect.top + (overlayRect.height * 0.25)),
    reason: '상단 액션은 미디어 슬롯 상단에 오버레이한다.',
  );
  expect(
    actionRailRect.center.dx,
    greaterThan(overlayRect.center.dx),
    reason: '하트·댓글·공유 액션은 미디어 슬롯 오른쪽에 세로 배치한다.',
  );
  expect(
    infoRect.center.dy,
    greaterThan(overlayRect.center.dy),
    reason: '계정과 설명은 미디어 슬롯 하단에 오버레이한다.',
  );
  expect(
    infoRect.right,
    lessThanOrEqualTo(actionRailRect.left),
    reason: '하단 정보와 오른쪽 액션 레일이 겹치지 않아야 한다.',
  );
  expect(
    find.descendant(of: topBar, matching: find.text('Reels')),
    findsNothing,
  );
  final cameraAction = find.byKey(const Key('profile-reel-camera-action'));
  expect(find.descendant(of: topBar, matching: cameraAction), findsOneWidget);
  _expectButtonSemantics(tester, cameraAction, label: '카메라');
  final likeAction = find.byKey(const Key('profile-reel-like-action'));
  final commentAction = find.byKey(const Key('profile-reel-comment-action'));
  final shareAction = find.byKey(const Key('profile-reel-share-action'));
  for (final action in <Finder>[likeAction, commentAction, shareAction]) {
    expect(find.descendant(of: actionRail, matching: action), findsOneWidget);
  }
  _expectButtonSemantics(tester, likeAction, label: '좋아요');
  _expectButtonSemantics(tester, commentAction, label: '댓글 보기');
  _expectButtonSemantics(tester, shareAction, label: '공유');
  expect(find.descendant(of: info, matching: account), findsOneWidget);
  expect(
    find.descendant(of: account, matching: find.text(data.identity.name)),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: account,
      matching: find.byKey(const Key('profile-reel-avatar')),
    ),
    findsOneWidget,
  );

  expect(find.byKey(const Key('profile-reel-visual')), findsNothing);
  expect(find.byKey(const Key('profile-reel-artwork')), findsNothing);
  expect(find.byKey(const Key('profile-reel-caption')), findsNothing);
  expect(find.byKey(const Key('profile-reel-like-count')), findsNothing);
  expect(find.byKey(const Key('profile-reel-comment-count')), findsNothing);
  expect(find.byKey(const Key('profile-reel-follower-count')), findsNothing);
  expect(find.byKey(const Key('mobile-app-navigation-bar')), findsOneWidget);
  expect(_fakeSocialMetricTextInside(detail), findsNothing);
  expect(_fakeSocialMetricSemanticsInside(detail), findsNothing);
}

const _sentinelSkillGroup = 'SENTINEL_SKILL_GROUP';
const _sentinelSkill = 'SENTINEL_SKILL';
const _sentinelProjectTitle = 'SENTINEL_PROJECT_TITLE';
const _sentinelProjectDescription = 'SENTINEL_PROJECT_DESCRIPTION';
const _careerPixelRunnerSemantics =
    '밝은 피부에 갈색 포니테일과 안경, 비즈니스 정장을 갖춘 여성 캐릭터가 '
    '오른쪽을 바라보고 구름과 AT Center, 판교역, 편의점이 이어지는 도심을 달리고 점프하며 '
    '골드 코인을 모아 LV UP 하는 도트 애니메이션';
const _educationPixelStudySemantics =
    '갈색 포니테일과 안경을 쓴 캐릭터가 현대적인 도서관 컴퓨터실에서 '
    '계속 공부하며 FLUTTER, DART, UX, SOLVE 능력치를 차례로 올리는 도트 애니메이션';
const _longExperienceDescription =
    '사용자 문제를 분석하고 Flutter 애플리케이션의 구조를 설계한 뒤 구현과 출시를 '
    '담당했습니다. 다양한 화면 크기와 접근성 글자 크기를 함께 검증하고, 제품 출시 이후에는 '
    '사용자 피드백과 운영 지표를 바탕으로 긴 호흡의 개선 작업을 반복했습니다. 이 설명은 작은 '
    'iPhone과 iPad의 상세 화면에서 실제 스크롤이 필요한 길이를 보장하기 위한 테스트 데이터입니다.';

final _fakeSocialMetricPattern = RegExp(
  r'(?:\d[\d,.]*\s*(?:[KkMm]|만)?\s*'
  r'(?:좋아요|팔로워|팔로잉|likes?|followers?|following))|'
  r'(?:(?:좋아요|팔로워|팔로잉|likes?|followers?|following)\s*'
  r'\d[\d,.]*\s*(?:[KkMm]|만)?)',
  caseSensitive: false,
);
