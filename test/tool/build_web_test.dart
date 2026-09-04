import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/terminal/terminal_git_history.dart';

import '../../tool/build_web.dart' as build_web;

void main() {
  test('build history encoder preserves newest Git commits and Korean titles', () {
    final encoded = build_web.encodeTerminalGitHistory(
      'abc1234\u0000feat(terminal): 최신 커밋 연결\n'
      'def5678\u0000test(terminal): 명령 계약 보강',
    );

    final history = resolveTerminalGitHistory(encodedSnapshot: encoded);

    expect(
      history.map((commit) => (commit.hash, commit.subject)).toList(),
      <(String, String)>[
        ('abc1234', 'feat(terminal): 최신 커밋 연결'),
        ('def5678', 'test(terminal): 명령 계약 보강'),
      ],
    );
  });

  test('build history encoder rejects malformed Git output', () {
    expect(
      () => build_web.encodeTerminalGitHistory('missing-delimiter'),
      throwsFormatException,
    );
  });

  test('Flutter build arguments inject the encoded history', () {
    expect(
      build_web.flutterBuildArguments('encoded-history'),
      contains(
        '--dart-define=$terminalGitHistoryDefine=encoded-history',
      ),
    );
  });
}
