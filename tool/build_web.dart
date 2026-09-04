import 'dart:convert';
import 'dart:io';

import '../lib/portfolio/terminal/terminal_git_history.dart';

const _historyLimit = 8;

String encodeTerminalGitHistory(String gitLogOutput) {
  final commits = <Map<String, String>>[];

  for (final line in const LineSplitter().convert(gitLogOutput)) {
    if (line.trim().isEmpty) {
      continue;
    }
    final separator = line.indexOf('\u0000');
    if (separator <= 0 || separator == line.length - 1) {
      throw const FormatException('Malformed git log output.');
    }
    commits.add(<String, String>{
      'hash': line.substring(0, separator),
      'subject': line.substring(separator + 1),
    });
  }

  if (commits.isEmpty) {
    throw const FormatException('Git history is empty.');
  }

  return base64Url.encode(utf8.encode(jsonEncode(commits))).replaceAll('=', '');
}

List<String> flutterBuildArguments(String encodedHistory) {
  return <String>[
    'build',
    'web',
    '--release',
    '--base-href',
    '/',
    '--pwa-strategy=none',
    '--dart-define=$terminalGitHistoryDefine=$encodedHistory',
  ];
}

Future<void> main(List<String> arguments) async {
  final flutterBinary = _flutterBinary(arguments);
  final gitLog = await Process.run(
    'git',
    <String>['log', '-$_historyLimit', '--pretty=format:%h%x00%s'],
    workingDirectory: Directory.current.path,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );

  if (gitLog.exitCode != 0) {
    stderr.writeln(gitLog.stderr);
    exitCode = gitLog.exitCode;
    return;
  }

  final encodedHistory = encodeTerminalGitHistory(gitLog.stdout as String);
  final build = await Process.start(
    flutterBinary,
    flutterBuildArguments(encodedHistory),
    workingDirectory: Directory.current.path,
    mode: ProcessStartMode.inheritStdio,
  );
  exitCode = await build.exitCode;
}

String _flutterBinary(List<String> arguments) {
  if (arguments.isEmpty) {
    return 'flutter';
  }
  if (arguments.length == 2 && arguments.first == '--flutter-bin') {
    return arguments.last;
  }
  throw const FormatException(
    'Usage: dart run tool/build_web.dart [--flutter-bin <path>]',
  );
}
