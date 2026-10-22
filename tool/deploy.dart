import 'dart:convert';
import 'dart:io';

const _usage = '''사용법: ./deploy.sh [1|2|3]
  1. 로컬 웹 실행 (개발 환경, Chrome, http://localhost:8080)
  2. 연결된 휴대폰에 릴리스 설치 및 실행 (운영 환경)
  3. Cloudflare 정적 웹 호스팅 준비 (운영 빌드만, 로그인·업로드 없음)

선택 인자를 생략하면 메뉴가 표시됩니다.
WEB_DEVICE=web-server ./deploy.sh 1  # 다른 브라우저에서 URL 직접 열기
WEB_PORT=9090 ./deploy.sh 1          # localhost 포트 변경
''';

Future<void> main(List<String> arguments) async {
  if (arguments.length == 1 && arguments.single == '--help') {
    stdout.write(_usage);
    return;
  }
  if (arguments.length > 1) {
    stderr.write(_usage);
    exitCode = 2;
    return;
  }

  try {
    final String choice;
    if (arguments.isEmpty) {
      stdout.write(_usage);
      choice = _readChoice('실행 방식 선택 [1/2/3]: ');
    } else {
      choice = arguments.single;
    }

    final flutter = Platform.environment['FLUTTER_BIN'] ?? 'flutter';
    final List<String> runArguments;
    switch (choice) {
      case '1':
        final device = Platform.environment['WEB_DEVICE'] ?? 'chrome';
        if (device != 'chrome' && device != 'web-server') {
          throw const FormatException('WEB_DEVICE는 chrome 또는 web-server입니다.');
        }
        var port = int.tryParse(Platform.environment['WEB_PORT'] ?? '8080');
        if (port == null || port < 1 || port > 65535) {
          throw const FormatException('WEB_PORT는 1~65535 범위의 숫자여야 합니다.');
        }
        if (!Platform.environment.containsKey('WEB_PORT')) {
          ServerSocket socket;
          try {
            socket = await ServerSocket.bind('localhost', port);
          } on SocketException {
            socket = await ServerSocket.bind('localhost', 0);
            stdout.writeln('기본 포트 8080을 사용할 수 없어 ${socket.port}로 실행합니다.');
          }
          port = socket.port;
          await socket.close();
        }
        stdout.writeln('개발 웹: http://localhost:$port');
        if (device == 'web-server') {
          stdout.writeln('서버 준비가 끝나면 위 주소를 브라우저에서 열어 주세요.');
        }
        runArguments = [
          'run',
          '-d',
          device,
          '--debug',
          '--web-hostname=localhost',
          '--web-port=$port',
          '--dart-define-from-file=config/development.json',
        ];
      case '2':
        stdout.writeln('연결된 Android/iOS 실기기를 찾고 있습니다...');
        final result = await Process.run(flutter, ['devices', '--machine']);
        if (result.exitCode != 0) {
          stderr.write(result.stderr);
          stderr.writeln(
            '기기 검색 실패: flutter doctor 및 flutter devices를 확인해 주세요.',
          );
          exitCode = result.exitCode;
          return;
        }
        final devices = (jsonDecode(result.stdout as String) as List)
            .cast<Map<String, dynamic>>()
            .where((device) {
              final platform = device['targetPlatform'] as String? ?? '';
              return device['isSupported'] == true &&
                  device['emulator'] == false &&
                  (platform == 'ios' || platform.startsWith('android-'));
            })
            .toList();
        if (devices.isEmpty) {
          stderr.writeln(
            '연결된 Android/iOS 실기기가 없습니다.\n'
            'Android: USB 디버깅을 켜고 이 컴퓨터를 허용해 주세요.\n'
            'iPhone: 컴퓨터 신뢰 및 개발자 모드를 확인해 주세요.',
          );
          exitCode = 1;
          return;
        }
        var index = 0;
        if (devices.length > 1) {
          for (var i = 0; i < devices.length; i++) {
            stdout.writeln(
              '${i + 1}. ${devices[i]['name']} (${devices[i]['id']})',
            );
          }
          final selected = int.tryParse(_readChoice('휴대폰 선택: '));
          if (selected == null || selected < 1 || selected > devices.length) {
            throw const FormatException('목록에 표시된 휴대폰 번호를 선택해 주세요.');
          }
          index = selected - 1;
        }
        final device = devices[index];
        stdout.writeln('운영 릴리스 설치 및 실행: ${device['name']}');
        runArguments = [
          'run',
          '-d',
          device['id'] as String,
          '--release',
          '--dart-define-from-file=config/production.json',
        ];
      case '3':
        stdout.writeln('정적 웹 호스팅용 운영 빌드를 준비합니다.');
        final build = await Process.start(
          Platform.environment['DART_BIN'] ?? 'dart',
          ['run', 'tool/build_web.dart', '--flutter-bin', flutter],
          mode: ProcessStartMode.inheritStdio,
        );
        exitCode = await build.exitCode;
        if (exitCode != 0) return;
        stdout.writeln(
          '호스팅 준비 완료: build/web\n'
          'Cloudflare 로그인·계정 연결·업로드는 실행하지 않았습니다.\n'
          '나중에 개인 계정 인증과 배포 대상을 확인한 뒤 별도로 실행하세요:\n'
          '  npx wrangler deploy --config wrangler.json',
        );
        return;
      default:
        throw const FormatException('실행 방식은 1, 2 또는 3을 선택해 주세요.');
    }

    final process = await Process.start(
      flutter,
      runArguments,
      mode: ProcessStartMode.inheritStdio,
    );
    exitCode = await process.exitCode;
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 2;
  } on ProcessException catch (error) {
    stderr.writeln('명령 실행 실패: ${error.message}');
    exitCode = 1;
  } on SocketException catch (error) {
    stderr.writeln('localhost 포트를 열 수 없습니다: ${error.message}');
    exitCode = 1;
  }
}

String _readChoice(String prompt) {
  stdout.write(prompt);
  final value = stdin.readLineSync()?.trim();
  if (value == null || value.isEmpty) {
    throw const FormatException('선택이 입력되지 않아 종료합니다.');
  }
  return value;
}
