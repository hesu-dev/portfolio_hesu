import '../data/portfolio_data.dart';
import 'terminal_git_history.dart';

class TerminalHelpEntry {
  const TerminalHelpEntry({required this.command, required this.description});

  final String command;
  final String description;
}

class TerminalResult {
  factory TerminalResult({
    required Iterable<String> lines,
    Iterable<TerminalHelpEntry> helpEntries = const <TerminalHelpEntry>[],
    bool clear = false,
  }) {
    return TerminalResult._(
      lines: List<String>.unmodifiable(lines),
      helpEntries: List<TerminalHelpEntry>.unmodifiable(helpEntries),
      clear: clear,
    );
  }

  const TerminalResult._({
    required this.lines,
    required this.helpEntries,
    required this.clear,
  });

  final List<String> lines;
  final List<TerminalHelpEntry> helpEntries;
  final bool clear;
}

class TerminalEngine {
  factory TerminalEngine(
    PortfolioData data, {
    Iterable<TerminalGitCommit>? gitHistory,
  }) {
    return TerminalEngine._(
      data,
      List<TerminalGitCommit>.unmodifiable(
        gitHistory ?? resolveTerminalGitHistory(),
      ),
    );
  }

  const TerminalEngine._(this.data, this.gitHistory);

  final PortfolioData data;
  final List<TerminalGitCommit> gitHistory;

  TerminalResult execute(String input) {
    final command = input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    return switch (command) {
      '' => TerminalResult(lines: const <String>[]),
      'help' => _help(),
      'whoami' => _whoAmI(),
      'ls' => _listPortfolio(),
      'cat skills.md' => _listSkills(),
      'git status' => _gitStatus(),
      'git log' => _gitLog(),
      'flutter run' => _flutterRunEasterEgg(),
      'clear' => TerminalResult(lines: const <String>[], clear: true),
      _ => TerminalResult(
        lines: const <String>[
          'command not found. Type "help" for available commands.',
        ],
      ),
    };
  }

  TerminalResult _help() {
    const entries = <TerminalHelpEntry>[
      TerminalHelpEntry(command: 'flutter run', description: '포트폴리오 개발 서버 실행'),
      TerminalHelpEntry(command: 'git log', description: '최신 커밋 내역'),
      TerminalHelpEntry(command: 'git status', description: '현재 상태'),
      TerminalHelpEntry(command: 'cat skills.md', description: '기술 스택 출력'),
      TerminalHelpEntry(command: 'ls', description: '개인 프로젝트 목록'),
      TerminalHelpEntry(command: 'whoami', description: '개발자 소개'),
      TerminalHelpEntry(command: 'clear', description: '화면 지우기'),
      TerminalHelpEntry(command: 'help', description: '명령어 안내'),
    ];
    return TerminalResult(
      helpEntries: entries,
      lines: <String>[
        for (final entry in entries) '${entry.command}\t${entry.description}',
      ],
    );
  }

  TerminalResult _whoAmI() {
    final identity = data.identity;

    return TerminalResult(
      lines: <String>[
        '${identity.name} (${identity.englishName})',
        identity.headline,
        'GitHub: ${identity.githubUrl}',
        'Email: ${identity.email}',
      ],
    );
  }

  TerminalResult _listPortfolio() {
    final personalProjects = data.projects.where(
      (project) => project.category == PortfolioProjectCategory.personal,
    );
    return TerminalResult(
      lines: <String>[
        '개인 프로젝트/',
        for (final project in personalProjects) '  ${project.title}/',
      ],
    );
  }

  TerminalResult _listSkills() {
    return TerminalResult(
      lines: <String>[
        for (final group in data.skillGroups)
          '${group.title}: ${group.skills.join(', ')}',
      ],
    );
  }

  TerminalResult _gitStatus() {
    return TerminalResult(
      lines: const <String>[
        'On branch dev',
        "Your branch is up to date with 'origin/dev'.",
        'nothing to commit, working tree clean',
      ],
    );
  }

  TerminalResult _gitLog() {
    return TerminalResult(
      lines: <String>[
        for (final commit in gitHistory) '${commit.hash}  ${commit.subject}',
      ],
    );
  }

  TerminalResult _flutterRunEasterEgg() {
    return TerminalResult(
      lines: <String>[
        'Launching ${data.appTitle} on Chrome in debug mode...',
        'Resolving dependencies... done',
        '[OK] Built build/web',
        '[HOT] Flutter hot reload is ready.',
        '[EASTER EGG] Easter egg unlocked — '
            '${data.identity.name}의 포트폴리오는 이미 실행 중입니다.',
      ],
    );
  }
}
