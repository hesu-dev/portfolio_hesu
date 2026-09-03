import '../data/portfolio_data.dart';

class TerminalResult {
  factory TerminalResult({
    required Iterable<String> lines,
    bool clear = false,
  }) {
    return TerminalResult._(
      lines: List<String>.unmodifiable(lines),
      clear: clear,
    );
  }

  const TerminalResult._({required this.lines, required this.clear});

  final List<String> lines;
  final bool clear;
}

class TerminalEngine {
  const TerminalEngine(this.data);

  final PortfolioData data;

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
      'npm run dev' => _startPreview(),
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
    return TerminalResult(
      lines: const <String>[
        'Available commands:',
        '  help',
        '  whoami',
        '  ls',
        '  cat skills.md',
        '  git status',
        '  git log',
        '  npm run dev',
        '  clear',
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
    return TerminalResult(
      lines: <String>[
        'about.md',
        'skills.md',
        'projects/',
        for (final project in data.projects) '  ${project.title}',
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
        'On branch portfolio',
        'nothing to commit, working tree clean',
      ],
    );
  }

  TerminalResult _gitLog() {
    return TerminalResult(
      lines: <String>[
        for (final entry in data.projects.indexed)
          'portfolio-${(entry.$1 + 1).toString().padLeft(2, '0')} '
              '${entry.$2.title}',
      ],
    );
  }

  TerminalResult _startPreview() {
    return TerminalResult(
      lines: <String>[
        '> portfolio@1.0.0 dev',
        '> flutter run -d chrome',
        'Portfolio preview for ${data.identity.englishName} is ready.',
      ],
    );
  }

  TerminalResult _flutterRunEasterEgg() {
    return TerminalResult(
      lines: <String>[
        'Launching ${data.appTitle} on Chrome in debug mode...',
        'Resolving dependencies... done',
        '✓ Built build/web',
        '🔥 Flutter hot reload is ready.',
        '✨ Easter egg unlocked — ${data.identity.name}의 포트폴리오는 이미 실행 중입니다.',
      ],
    );
  }
}
