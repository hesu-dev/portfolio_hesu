import 'dart:convert';

class TerminalGitCommit {
  const TerminalGitCommit({required this.hash, required this.subject});

  final String hash;
  final String subject;
}

const terminalGitHistoryDefine = 'PORTFOLIO_GIT_HISTORY';

const _encodedBuildGitHistory = String.fromEnvironment(
  terminalGitHistoryDefine,
);

List<TerminalGitCommit> resolveTerminalGitHistory({
  String encodedSnapshot = _encodedBuildGitHistory,
}) {
  if (encodedSnapshot.isEmpty) {
    return portfolioGitHistory;
  }

  try {
    final decoded = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(encodedSnapshot))),
    );
    if (decoded is! List || decoded.isEmpty) {
      return portfolioGitHistory;
    }

    final commits = <TerminalGitCommit>[
      for (final item in decoded)
        if (item case <String, dynamic>{
          'hash': final String hash,
          'subject': final String subject,
        } when hash.isNotEmpty && subject.isNotEmpty)
          TerminalGitCommit(hash: hash, subject: subject)
        else
          throw const FormatException('Invalid terminal Git history entry.'),
    ];
    return List<TerminalGitCommit>.unmodifiable(commits);
  } on FormatException {
    return portfolioGitHistory;
  }
}

/// Recent commits captured when this portfolio release was prepared.
///
/// Flutter Web cannot execute the visitor's local Git binary. Keeping a small
/// checked-in snapshot makes `git log` deterministic and available offline.
const portfolioGitHistory = <TerminalGitCommit>[
  TerminalGitCommit(hash: 'dfcc84e', subject: 'docs(build): 최신 이력 빌드 방법 안내'),
  TerminalGitCommit(hash: 'b92430d', subject: 'feat(build): 최신 깃 이력 자동 주입'),
  TerminalGitCommit(hash: 'de8fb65', subject: 'test(build): 깃 이력 주입 계약 추가'),
  TerminalGitCommit(hash: 'afddff0', subject: 'feat(terminal): 도움말과 빌드 이력 연결'),
  TerminalGitCommit(
    hash: '7534b55',
    subject: 'test(terminal): 도움말과 최신 이력 계약 보강',
  ),
  TerminalGitCommit(
    hash: '6d08cc3',
    subject: 'refactor(terminal): 출력 행 생성자 명확화',
  ),
  TerminalGitCommit(
    hash: '05c16a3',
    subject: 'docs(requirements): 터미널 명령 검증 반영',
  ),
  TerminalGitCommit(hash: '675c737', subject: 'chore(terminal): 최근 커밋 스냅샷 갱신'),
];
