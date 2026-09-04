class TerminalGitCommit {
  const TerminalGitCommit({required this.hash, required this.subject});

  final String hash;
  final String subject;
}

/// Recent commits captured when this portfolio release was prepared.
///
/// Flutter Web cannot execute the visitor's local Git binary. Keeping a small
/// checked-in snapshot makes `git log` deterministic and available offline.
const portfolioGitHistory = <TerminalGitCommit>[
  TerminalGitCommit(hash: '67a9eaa', subject: 'docs(terminal): 명령 인터페이스 설계 추가'),
  TerminalGitCommit(
    hash: '92e8185',
    subject: 'docs(requirements): 모바일 프로필 검증 반영',
  ),
  TerminalGitCommit(hash: 'ad1bad2', subject: 'feat(profile): 경력 피드와 릴스 상세 구현'),
  TerminalGitCommit(
    hash: '07d5e81',
    subject: 'test(profile): 피드 카드 정보 영역 계약 추가',
  ),
  TerminalGitCommit(hash: 'b634c0b', subject: 'test(profile): 릴스 텍스트 탐색 범위 보정'),
  TerminalGitCommit(
    hash: 'a9aae44',
    subject: 'test(profile): 릴스 메타데이터와 복원 계약 보강',
  ),
];
