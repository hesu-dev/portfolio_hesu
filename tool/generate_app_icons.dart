// Run on macOS from the repository root:
// flutter test tool/generate_app_icons.dart
// Reuses Flutter's SVG renderer and macOS ImageIO; no extra packages are needed.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('regenerate native launcher icons from the portfolio project icon', () async {
    final picture = await vg.loadPicture(
      SvgStringLoader(
        File('assets/icons/settings-display-mode.svg').readAsStringSync(),
      ),
      null,
    );
    final targets = <String, int>{};
    final ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
    for (final directory in [
      ios,
      'macos/Runner/Assets.xcassets/AppIcon.appiconset',
    ]) {
      final manifest =
          jsonDecode(File('$directory/Contents.json').readAsStringSync())
              as Map<String, dynamic>;
      for (final entry in manifest['images'] as List<dynamic>) {
        final item = entry as Map<String, dynamic>;
        final size = double.parse((item['size'] as String).split('x').first);
        final scale = double.parse(
          (item['scale'] as String).replaceAll('x', ''),
        );
        targets['$directory/${item['filename']}'] = (size * scale).round();
      }
    }
    const androidSizes = {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    };
    for (final density in androidSizes.entries) {
      targets['android/app/src/main/res/mipmap-${density.key}/ic_launcher.png'] =
          density.value;
    }
    try {
      for (final target in targets.entries) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        canvas.scale(
          target.value / picture.size.width,
          target.value / picture.size.height,
        );
        canvas.drawPicture(picture.picture);
        final rendered = recorder.endRecording();
        final image = await rendered.toImage(target.value, target.value);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File(target.key).writeAsBytesSync(png!.buffer.asUint8List());
        image.dispose();
        rendered.dispose();
      }
    } finally {
      picture.picture.dispose();
    }
    // Remove the alpha channel itself, rather than only making its pixels opaque.
    final temporary = Directory.systemTemp.createTempSync(
      'portfolio-app-icons-',
    );
    try {
      final swift = File('${temporary.path}/opaque.swift')
        ..writeAsStringSync(_removeAlpha);
      final result = await Process.run('swift', [
        swift.path,
        ...targets.keys.where((path) => path.startsWith(ios)),
      ]);
      expect(result.exitCode, 0, reason: '${result.stderr}');
    } finally {
      temporary.deleteSync(recursive: true);
    }
    for (final target in targets.entries) {
      final png = File(target.key).readAsBytesSync();
      final codec = await ui.instantiateImageCodec(png);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, target.value, reason: target.key);
      expect(frame.image.height, target.value, reason: target.key);
      final rgba = (await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!.buffer.asUint8List();
      final center =
          ((target.value ~/ 2) * target.value + target.value ~/ 2) * 4;
      expect(
        rgba.sublist(center, center + 3),
        isNot([255, 255, 255]),
        reason: '${target.key} must contain the SVG artwork',
      );
      for (var alpha = 3; alpha < rgba.length; alpha += 4) {
        if (rgba[alpha] != 255) fail('${target.key} has a transparent pixel');
      }
      // Check the canvas edges and the old inset border position. The background
      // must remain blue here, without a white matte or translucent white rim.
      for (final inset in [0, (target.value * 2.75 / 64).floor()]) {
        final far = target.value - 1 - inset;
        final middle = target.value ~/ 2;
        for (final (x, y) in [
          (inset, inset),
          (far, inset),
          (inset, far),
          (far, far),
          (middle, inset),
          (middle, far),
          (inset, middle),
          (far, middle),
        ]) {
          final pixel = (y * target.value + x) * 4;
          expect(
            rgba[pixel + 2] - rgba[pixel],
            greaterThan(110),
            reason:
                '${target.key} must have an uninterrupted blue background at $x,$y',
          );
        }
      }
      if (target.key.startsWith(ios)) {
        expect(png[25], 2, reason: '${target.key} must be RGB without alpha');
      }
      frame.image.dispose();
      codec.dispose();
    }
    _writeWindowsIcon();
    // ignore: avoid_print
    print(
      'Updated and verified ${targets.length} native PNG icons and Windows ICO (6 sizes).',
    );
  });
}

void _writeWindowsIcon() {
  // ICO supports PNG entries. Reuse the same SVG renders already verified above.
  const mac = 'macos/Runner/Assets.xcassets/AppIcon.appiconset';
  final images = <int, Uint8List>{
    for (final size in [16, 32, 48, 64, 128, 256])
      size: File(
        size == 48
            ? 'android/app/src/main/res/mipmap-mdpi/ic_launcher.png'
            : '$mac/app_icon_$size.png',
      ).readAsBytesSync(),
  };
  final header = ByteData(6 + 16 * images.length)
    ..setUint16(2, 1, Endian.little)
    ..setUint16(4, images.length, Endian.little);
  var offset = header.lengthInBytes;
  var index = 0;
  for (final entry in images.entries) {
    final row = 6 + 16 * index++;
    header
      ..setUint8(row, entry.key == 256 ? 0 : entry.key)
      ..setUint8(row + 1, entry.key == 256 ? 0 : entry.key)
      ..setUint16(row + 4, 1, Endian.little)
      ..setUint16(row + 6, 32, Endian.little)
      ..setUint32(row + 8, entry.value.length, Endian.little)
      ..setUint32(row + 12, offset, Endian.little);
    offset += entry.value.length;
  }
  final result = BytesBuilder(copy: false)..add(header.buffer.asUint8List());
  for (final image in images.values) {
    result.add(image);
  }
  final file = File('windows/runner/resources/app_icon.ico')
    ..writeAsBytesSync(result.takeBytes());
  final bytes = file.readAsBytesSync();
  final data = ByteData.sublistView(bytes);
  expect(data.getUint16(0, Endian.little), 0);
  expect(data.getUint16(2, Endian.little), 1);
  expect(data.getUint16(4, Endian.little), images.length);
  index = 0;
  for (final entry in images.entries) {
    final row = 6 + 16 * index++;
    final start = data.getUint32(row + 12, Endian.little);
    final length = data.getUint32(row + 8, Endian.little);
    expect(data.getUint8(row), entry.key == 256 ? 0 : entry.key);
    expect(data.getUint8(row + 1), entry.key == 256 ? 0 : entry.key);
    expect(bytes.sublist(start, start + length), entry.value);
    expect(data.getUint32(start + 16), entry.key); // PNG IHDR width.
    expect(data.getUint32(start + 20), entry.key); // PNG IHDR height.
  }
  expect(bytes.length, offset);
}

const _removeAlpha = r'''
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
for path in CommandLine.arguments.dropFirst() {
    let url = URL(fileURLWithPath: path) as CFURL
    let source = CGImageSourceCreateWithURL(url, nil)!
    let image = CGImageSourceCreateImageAtIndex(source, 0, nil)!
    let context = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    let destination = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    precondition(CGImageDestinationFinalize(destination))
}
''';
