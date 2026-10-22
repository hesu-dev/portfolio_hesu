import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory.current.path;
  late Directory temporary;
  late File flutter;
  late File dart;
  late File calls;
  late File remoteCalls;
  late Directory remoteTools;

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('portfolio deploy ');
    calls = File('${temporary.path}/calls');
    remoteCalls = File('${temporary.path}/remote-calls');
    flutter = File('${temporary.path}/flutter');
    await flutter.writeAsString(r'''#!/bin/sh
if [ "$1" = devices ]; then
  printf '%s\n' "$TEST_DEVICES"
  exit "${TEST_DISCOVERY_EXIT:-0}"
fi
printf '%s\n' "$PWD" "$@" > "$TEST_CALLS"
exit "${TEST_RUN_EXIT:-0}"
''');
    await Process.run('chmod', ['+x', flutter.path]);
    dart = File('${temporary.path}/dart-wrapper');
    await dart.writeAsString(r'''#!/bin/sh
if [ "$1" = tool/deploy.dart ]; then
  exec dart "$@"
fi
printf '%s\n' "$PWD" "$@" > "$TEST_CALLS"
exit "${TEST_BUILD_EXIT:-0}"
''');
    await Process.run('chmod', ['+x', dart.path]);
    remoteTools = await Directory('${temporary.path}/remote-tools').create();
    for (final name in ['npx', 'wrangler', 'open']) {
      final executable = File('${remoteTools.path}/$name');
      await executable.writeAsString(r'''#!/bin/sh
printf '%s\n' "$0" "$@" >> "$TEST_REMOTE_CALLS"
exit 99
''');
      await Process.run('chmod', ['+x', executable.path]);
    }
  });

  tearDown(() => temporary.delete(recursive: true));

  Future<ProcessResult> deploy({
    String input = '',
    List<String> arguments = const [],
    List<Map<String, Object>> devices = const [],
    Map<String, String> environment = const {},
  }) async {
    final process = await Process.start(
      'sh',
      ['$root/deploy.sh', ...arguments],
      workingDirectory: temporary.path,
      environment: {
        'FLUTTER_BIN': flutter.path,
        'DART_BIN': dart.path,
        'TEST_CALLS': calls.path,
        'TEST_REMOTE_CALLS': remoteCalls.path,
        'TEST_DEVICES': jsonEncode(devices),
        'PATH': '${remoteTools.path}:${Platform.environment['PATH']}',
        ...environment,
      },
    );
    final output = process.stdout.transform(utf8.decoder).join();
    final errors = process.stderr.transform(utf8.decoder).join();
    process.stdin.write(input);
    await process.stdin.close();
    return ProcessResult(
      process.pid,
      await process.exitCode,
      await output,
      await errors,
    );
  }

  test('menu 1 starts development Chrome at a stable localhost URL', () async {
    final result = await deploy(input: '1\n');
    expect(result.exitCode, 0, reason: '${result.stderr}');
    final port = RegExp(
      r'http://localhost:(\d+)',
    ).allMatches(result.stdout as String).last.group(1)!;
    expect(await calls.readAsLines(), [
      root,
      'run',
      '-d',
      'chrome',
      '--debug',
      '--web-hostname=localhost',
      '--web-port=$port',
      '--dart-define-from-file=config/development.json',
    ]);
    expect(int.parse(port), inInclusiveRange(1, 65535));
  });

  test('an occupied default port selects another localhost port', () async {
    ServerSocket? occupied;
    try {
      occupied = await ServerSocket.bind('localhost', 8080);
    } on SocketException {
      // Another local service already occupies the port, which also exercises this case.
    }
    try {
      final result = await deploy(arguments: ['1']);
      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(await calls.readAsLines(), isNot(contains('--web-port=8080')));
    } finally {
      await occupied?.close();
    }
  });

  test('web-server mode and a custom port can be selected', () async {
    final result = await deploy(
      arguments: ['1'],
      environment: {'WEB_DEVICE': 'web-server', 'WEB_PORT': '9090'},
    );
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(
      await calls.readAsLines(),
      containsAll([
        'web-server',
        '--web-port=9090',
        '--dart-define-from-file=config/development.json',
      ]),
    );
  });

  test(
    'menu 2 installs and launches production release on the only phone',
    () async {
      final result = await deploy(
        input: '2\n',
        devices: [
          _device('chrome', 'web-javascript'),
          _device('simulator', 'ios', emulator: true),
          _device('unsupported', 'android-arm64', supported: false),
          _device('phone', 'android-arm64'),
        ],
      );
      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(await calls.readAsLines(), [
        root,
        'run',
        '-d',
        'phone',
        '--release',
        '--dart-define-from-file=config/production.json',
      ]);
    },
  );

  test('multiple phones require an explicit device choice', () async {
    final result = await deploy(
      input: '2\n2\n',
      devices: [_device('android', 'android-arm64'), _device('iphone', 'ios')],
    );
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(await calls.readAsLines(), contains('iphone'));
    expect(await calls.readAsLines(), isNot(contains('android')));
  });

  test('no physical phone exits without building or installing', () async {
    final result = await deploy(
      arguments: ['2'],
      devices: [_device('emulator', 'android-x64', emulator: true)],
    );
    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('실기기'));
    expect(calls.existsSync(), isFalse);
  });

  test(
    'menu 3 prepares the static web build without connecting to Cloudflare',
    () async {
      final result = await deploy(input: '3\n');
      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(await calls.readAsLines(), [
        root,
        'run',
        'tool/build_web.dart',
        '--flutter-bin',
        flutter.path,
      ]);
      expect(result.stdout, contains('build/web'));
      expect(
        result.stdout,
        contains('npx wrangler deploy --config wrangler.json'),
      );
      expect(remoteCalls.existsSync(), isFalse);
    },
  );

  test(
    'hosting build failures propagate without a ready or deploy message',
    () async {
      final result = await deploy(
        arguments: ['3'],
        environment: {'TEST_BUILD_EXIT': '8'},
      );
      expect(result.exitCode, 8);
      expect(result.stdout, isNot(contains('npx wrangler deploy')));
      expect(remoteCalls.existsSync(), isFalse);
    },
  );

  test('help lists hosting preparation without starting any command', () async {
    final result = await deploy(arguments: ['--help']);
    expect(result.exitCode, 0);
    expect(result.stdout, contains('3.'));
    expect(result.stdout, contains('Cloudflare'));
    expect(calls.existsSync(), isFalse);
    expect(remoteCalls.existsSync(), isFalse);
  });

  test('invalid input and closed stdin never launch a build', () async {
    for (final input in ['4\n', '']) {
      final result = await deploy(input: input);
      expect(result.exitCode, isNot(0));
      expect(calls.existsSync(), isFalse);
    }
    final result = await deploy(
      input: '0\n',
      arguments: ['2'],
      devices: [_device('android', 'android-arm64'), _device('iphone', 'ios')],
    );
    expect(result.exitCode, isNot(0));
    expect(calls.existsSync(), isFalse);
  });

  test('invalid web settings fail before starting Flutter', () async {
    for (final environment in [
      {'WEB_PORT': '0'},
      {'WEB_PORT': '65536'},
      {'WEB_PORT': 'abc'},
      {'WEB_DEVICE': 'macos'},
    ]) {
      final result = await deploy(arguments: ['1'], environment: environment);
      expect(result.exitCode, isNot(0));
      expect(calls.existsSync(), isFalse);
    }
  });

  test('Flutter discovery and run failures propagate to the caller', () async {
    final discovery = await deploy(
      arguments: ['2'],
      environment: {'TEST_DISCOVERY_EXIT': '7'},
    );
    expect(discovery.exitCode, 7);
    expect(calls.existsSync(), isFalse);
    final run = await deploy(
      arguments: ['1'],
      environment: {'TEST_RUN_EXIT': '9'},
    );
    expect(run.exitCode, 9);
  });
}

Map<String, Object> _device(
  String id,
  String platform, {
  bool emulator = false,
  bool supported = true,
}) => {
  'id': id,
  'name': 'Test $id',
  'targetPlatform': platform,
  'emulator': emulator,
  'isSupported': supported,
};
