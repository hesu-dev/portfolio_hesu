import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _portfolioDescription =
    'Flutter 개발자 민희수의 프로젝트와 기술 경험을 소개하는 반응형 포트폴리오입니다.';

Directory _projectRoot() {
  var directory = Directory.current.absolute;

  while (true) {
    final pubspec = File(
      '${directory.path}${Platform.pathSeparator}pubspec.yaml',
    );
    if (pubspec.existsSync()) {
      return directory;
    }

    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('Flutter project root could not be found.');
    }
    directory = parent;
  }
}

File _projectFile(String relativePath) =>
    File.fromUri(_projectRoot().uri.resolve(relativePath));

Map<String, String> _attributes(String element) {
  final attributes = <String, String>{};
  final pattern = RegExp(r'''([^\s=]+)\s*=\s*["']([^"']*)["']''');

  for (final match in pattern.allMatches(element)) {
    attributes[match.group(1)!.toLowerCase()] = match.group(2)!;
  }
  return attributes;
}

Iterable<Map<String, String>> _elements(String html, String tagName) {
  final pattern = RegExp('<$tagName\\b[^>]*>', caseSensitive: false);
  return pattern.allMatches(html).map((match) => _attributes(match.group(0)!));
}

String? _metaContent(String html, String name) {
  for (final attributes in _elements(html, 'meta')) {
    if (attributes['name'] == name) {
      return attributes['content'];
    }
  }
  return null;
}

String? _linkHref(String html, String rel) {
  return _linkAttributes(html, rel)?['href'];
}

Map<String, String>? _linkAttributes(String html, String rel) {
  for (final attributes in _elements(html, 'link')) {
    if (attributes['rel'] == rel) {
      return attributes;
    }
  }
  return null;
}

String? _scriptSource(String html) {
  for (final attributes in _elements(html, 'script')) {
    final source = attributes['src'];
    if (source != null && source.contains('flutter_bootstrap.js')) {
      return source;
    }
  }
  return null;
}

String? _elementText(String html, String tagName) {
  final pattern = RegExp(
    '<$tagName\\b[^>]*>(.*?)</$tagName>',
    caseSensitive: false,
    dotAll: true,
  );
  return pattern.firstMatch(html)?.group(1)?.trim();
}

void main() {
  group('web portfolio metadata sources', () {
    test('index identifies Min He-su and keeps Flutter bootstrap intact', () {
      final indexHtml = _projectFile('web/index.html').readAsStringSync();
      final htmlAttributes = _elements(indexHtml, 'html').single;

      expect(htmlAttributes['lang'], 'ko');
      expect(_elementText(indexHtml, 'title'), '민희수 포트폴리오');
      expect(_metaContent(indexHtml, 'description'), _portfolioDescription);
      expect(_metaContent(indexHtml, 'theme-color'), '#121316');
      expect(
        _metaContent(indexHtml, 'viewport'),
        isNull,
        reason: 'Flutter bootstrap owns responsive viewport configuration.',
      );
      expect(
        _metaContent(indexHtml, 'apple-mobile-web-app-title'),
        '민희수 포트폴리오',
      );
      expect(_linkHref(indexHtml, 'manifest'), 'manifest.json');
      expect(_scriptSource(indexHtml), isNotNull);
      expect(_elementText(indexHtml, 'noscript'), contains('민희수의 포트폴리오'));

      final lowerCaseIndex = indexHtml.toLowerCase();
      expect(lowerCaseIndex, isNot(contains('a new flutter project')));
      expect(lowerCaseIndex, isNot(contains('portfolio_hesu')));
      expect(lowerCaseIndex, isNot(contains('portfolio-juah')));
      expect(indexHtml, isNot(contains('천주아')));
    });

    test('manifest is valid, consistent, and base-path safe', () {
      final manifestSource = _projectFile(
        'web/manifest.json',
      ).readAsStringSync();
      final manifest = jsonDecode(manifestSource) as Map<String, dynamic>;

      expect(manifest['name'], '민희수 포트폴리오');
      expect(manifest['short_name'], '민희수');
      expect(manifest['description'], _portfolioDescription);
      expect(manifest['start_url'], '.');
      expect(manifest['scope'], '.');
      expect(manifest['display'], 'standalone');
      expect(manifest['theme_color'], '#121316');
      expect(manifest['background_color'], '#121316');

      final icons = (manifest['icons'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(icons, isNotEmpty);
      for (final icon in icons) {
        final source = icon['src'] as String;
        expect(Uri.parse(source).hasScheme, isFalse, reason: source);
        expect(source.startsWith('/'), isFalse, reason: source);
      }

      final lowerCaseManifest = manifestSource.toLowerCase();
      expect(lowerCaseManifest, isNot(contains('a new flutter project')));
      expect(lowerCaseManifest, isNot(contains('portfolio_hesu')));
      expect(lowerCaseManifest, isNot(contains('portfolio-juah')));
      expect(manifestSource, isNot(contains('천주아')));
    });

    test('uses the Min He-su monogram instead of Flutter starter icons', () {
      final indexHtml = _projectFile('web/index.html').readAsStringSync();
      final favicon = _linkAttributes(indexHtml, 'icon');
      final touchIcon = _linkAttributes(indexHtml, 'apple-touch-icon');
      final manifest =
          jsonDecode(_projectFile('web/manifest.json').readAsStringSync())
              as Map<String, dynamic>;
      final icons = (manifest['icons'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      expect(favicon?['href'], 'icons/min-hesu-monogram.svg');
      expect(favicon?['type'], 'image/svg+xml');
      expect(touchIcon?['href'], 'icons/min-hesu-monogram.svg');
      expect(icons, hasLength(1));
      expect(icons.single['src'], 'icons/min-hesu-monogram.svg');
      expect(icons.single['sizes'], 'any');
      expect(icons.single['type'], 'image/svg+xml');

      final monogramFile = _projectFile('web/icons/min-hesu-monogram.svg');
      expect(monogramFile.existsSync(), isTrue);
      if (monogramFile.existsSync()) {
        final monogram = monogramFile.readAsStringSync();
        expect(_elementText(monogram, 'title'), '민희수 모노그램');
        expect(monogram.toLowerCase(), isNot(contains('flutter')));
      }

      for (final stalePath in <String>[
        'web/favicon.png',
        'web/icons/Icon-192.png',
        'web/icons/Icon-512.png',
        'web/icons/Icon-maskable-192.png',
        'web/icons/Icon-maskable-512.png',
      ]) {
        expect(
          _projectFile(stalePath).existsSync(),
          isFalse,
          reason: stalePath,
        );
      }
    });
  });

  test('README documents adaptive UI and both web build targets', () {
    final readme = _projectFile('README.md').readAsStringSync();

    expect(readme, contains('macOS'));
    expect(readme, contains('iPadOS'));
    expect(readme, contains('iPhone'));
    expect(readme, contains('Flutter'));
    expect(readme, contains('flutter run -d chrome'));
    expect(readme, contains('flutter test'));
    expect(readme, contains('flutter analyze'));
    expect(
      readme,
      contains(
        'flutter build web --release --base-href /portfolio_hesu/ '
        '--pwa-strategy=none',
      ),
    );
    expect(
      readme,
      contains('flutter build web --release --base-href / --pwa-strategy=none'),
    );
    expect(readme, contains('build/web'));
    expect(readme, contains('GitHub Pages'));
    expect(readme, contains('Vercel'));
    expect(readme, contains('현재 배포는 GitHub Pages를 유지'));
  });

  test('README gives reproducible Vercel Flutter build settings', () {
    final readme = _projectFile('README.md').readAsStringSync();

    expect(readme, contains('Vercel 기본 빌드 이미지에는 Flutter SDK가'));
    expect(readme, contains('Framework Preset'));
    expect(readme, contains('Install Command'));
    expect(
      readme,
      contains(
        'git clone --depth 1 --branch stable '
        'https://github.com/flutter/flutter.git .flutter',
      ),
    );
    expect(readme, contains('./.flutter/bin/flutter config --enable-web'));
    expect(readme, contains('./.flutter/bin/flutter pub get'));
    expect(readme, contains('Build Command'));
    expect(
      readme,
      contains(
        './.flutter/bin/flutter build web --release --base-href / '
        '--pwa-strategy=none',
      ),
    );
    expect(readme, contains('Output Directory'));
    expect(readme, contains('사전 빌드'));
    expect(readme, contains('정적 배포'));
  });

  group('repository output hygiene', () {
    test('keeps generated Flutter web bundles out of the repository root', () {
      const staleRootPaths = <String>[
        'index.html',
        'manifest.json',
        'version.json',
        'favicon.png',
        'flutter.js',
        'flutter_bootstrap.js',
        'flutter_service_worker.js',
        'main.dart.js',
        'icons',
        'canvaskit',
        'assets/AssetManifest.bin',
        'assets/AssetManifest.bin.json',
        'assets/AssetManifest.json',
        'assets/FontManifest.json',
        'assets/NOTICES',
        'assets/assets',
        'assets/fonts',
        'assets/packages',
        'assets/shaders',
      ];

      for (final relativePath in staleRootPaths) {
        final entityPath = _projectRoot().uri
            .resolve(relativePath)
            .toFilePath();
        expect(
          FileSystemEntity.typeSync(entityPath),
          FileSystemEntityType.notFound,
          reason: relativePath,
        );
      }
    });

    test('anchors every generated root bundle path in gitignore', () {
      final ignoreRules = _projectFile('.gitignore')
          .readAsLinesSync()
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty && !line.startsWith('#'))
          .toSet();

      expect(
        ignoreRules,
        containsAll(<String>[
          '/index.html',
          '/manifest.json',
          '/version.json',
          '/favicon.png',
          '/flutter.js',
          '/flutter_bootstrap.js',
          '/flutter_service_worker.js',
          '/main.dart.js',
          '/icons/',
          '/canvaskit/',
          '/assets/AssetManifest*',
          '/assets/FontManifest.json',
          '/assets/NOTICES',
          '/assets/assets/',
          '/assets/fonts/',
          '/assets/packages/',
          '/assets/shaders/',
        ]),
      );
      expect(ignoreRules, isNot(contains('/assets/')));
    });

    test('preserves source assets, web sources, and Pages workflows', () {
      expect(_projectFile('assets/image/pixelphoto.png').existsSync(), isTrue);
      expect(_projectFile('web/index.html').existsSync(), isTrue);
      expect(
        _projectFile('.github/workflows/flutter-web.yml').existsSync(),
        isTrue,
      );
    });

    test('ignores the project-local Flutter SDK used by Vercel', () {
      final ignoreRules = _projectFile(
        '.gitignore',
      ).readAsLinesSync().map((line) => line.trim()).toSet();

      expect(ignoreRules, contains('/.flutter/'));
    });
  });
}
