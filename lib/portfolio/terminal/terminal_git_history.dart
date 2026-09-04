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
  TerminalGitCommit(
    hash: '3618446',
    subject: 'feat(terminal): 점멸 프롬프트 입력 경험 구현',
  ),
  TerminalGitCommit(
    hash: '9cca48d',
    subject: 'test(terminal): 점멸 입력과 초기화 계약 추가',
  ),
  TerminalGitCommit(hash: 'ee243a6', subject: 'feat(terminal): 실제 포트폴리오 명령 출력'),
  TerminalGitCommit(hash: '00fa9ee', subject: 'test(terminal): 포트폴리오 명령 계약 갱신'),
  TerminalGitCommit(hash: '67a9eaa', subject: 'docs(terminal): 명령 인터페이스 설계 추가'),
  TerminalGitCommit(
    hash: '92e8185',
    subject: 'docs(requirements): 모바일 프로필 검증 반영',
  ),
];
