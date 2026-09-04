import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/terminal/terminal_engine.dart';
import 'package:portfolio_hesu/portfolio/terminal/terminal_git_history.dart';

void main() {
  late TerminalEngine engine;

  setUp(() {
    engine = TerminalEngine(portfolioData);
  });

  group('TerminalEngine', () {
    test('help pairs every supported English command with Korean guidance', () {
      final result = engine.execute('help');

      expect(
        result.helpEntries
            .map((entry) => (entry.command, entry.description))
            .toList(),
        <(String, String)>[
          ('flutter run', '포트폴리오 개발 서버 실행'),
          ('git log', '최신 커밋 내역'),
          ('git status', '현재 상태'),
          ('cat skills.md', '기술 스택 출력'),
          ('ls', '개인 프로젝트 목록'),
          ('whoami', '개발자 소개'),
          ('clear', '화면 지우기'),
        ],
      );
      expect(result.lines.join('\n'), isNot(contains('npm run dev')));
      expect(result.lines.join('\n'), isNot(contains('Available commands')));
    });

    test('whoami returns the portfolio identity', () {
      final output = engine.execute('whoami').lines.join('\n');

      expect(output, contains('민희수'));
      expect(output, contains('Min He-su'));
      expect(output, contains('hesu-dev'));
    });

    test('ls lists only personal projects in portfolio order', () {
      final output = engine.execute('ls').lines.join('\n');

      expect(output, isNot(contains('about.md')));
      expect(output, isNot(contains('skills.md')));
      final personalProjects = portfolioData.projects
          .where(
            (project) => project.category == PortfolioProjectCategory.personal,
          )
          .toList();
      for (final project in personalProjects) {
        expect(output, contains('${project.title}/'), reason: project.title);
      }
      for (final project in portfolioData.projects.where(
        (project) => project.category == PortfolioProjectCategory.career,
      )) {
        expect(output, isNot(contains(project.title)), reason: project.title);
      }
      expect(
        engine.execute('ls').lines.skip(1).toList(),
        personalProjects.map((project) => '  ${project.title}/').toList(),
      );
    });

    test('cat skills.md lists every skill grouped by category', () {
      final output = engine.execute('cat skills.md').lines.join('\n');

      for (final group in portfolioData.skillGroups) {
        expect(output, contains(group.title), reason: group.title);
        for (final skill in group.skills) {
          expect(output, contains(skill), reason: skill);
        }
      }
    });

    test('git status returns a clean deterministic status', () {
      expect(engine.execute('git status').lines, <String>[
        'On branch dev',
        "Your branch is up to date with 'origin/dev'.",
        'nothing to commit, working tree clean',
      ]);
    });

    test('git log renders injected real commit snapshots newest first', () {
      const history = <TerminalGitCommit>[
        TerminalGitCommit(
          hash: 'abc1234',
          subject: 'feat(terminal): 명령 인터페이스 추가',
        ),
        TerminalGitCommit(hash: 'def5678', subject: 'test(terminal): 명령 계약 보강'),
      ];
      final result = TerminalEngine(
        portfolioData,
        gitHistory: history,
      ).execute('git log');

      expect(result.lines, <String>[
        'abc1234  feat(terminal): 명령 인터페이스 추가',
        'def5678  test(terminal): 명령 계약 보강',
      ]);
      expect(result.lines.join('\n'), isNot(contains('portfolio-01')));
      for (final project in portfolioData.projects) {
        expect(result.lines.join('\n'), isNot(contains(project.title)));
      }
    });

    test('npm run dev is removed in favor of flutter run', () {
      final result = engine.execute('npm run dev');

      expect(result.lines.single, contains('command not found'));
      expect(result.lines.single, contains('help'));
    });

    test('flutter run unlocks the portfolio Easter egg', () {
      final result = engine.execute('  FLUTTER   RUN  ');
      final output = result.lines.join('\n');

      expect(result.clear, isFalse);
      expect(output, contains('Launching'));
      expect(output, contains('Flutter'));
      expect(output, contains(portfolioData.identity.name));
      expect(output, contains('[OK] Built build/web'));
      expect(output, contains('[HOT] Flutter hot reload is ready.'));
      expect(output, contains('[EASTER EGG]'));
      expect(output, contains('Easter egg'));
      expect(output, contains('이미 실행 중'));
      expect(output, isNot(contains('✓')));
      expect(output, isNot(contains('🔥')));
      expect(output, isNot(contains('✨')));
    });

    test('clear marks the transcript for clearing without output', () {
      final result = engine.execute('clear');

      expect(result.clear, isTrue);
      expect(result.lines, isEmpty);
    });

    test('empty input returns no output without clearing', () {
      final result = engine.execute('   \t\n ');

      expect(result.clear, isFalse);
      expect(result.lines, isEmpty);
    });

    test('unknown commands return helpful feedback without throwing', () {
      expect(() => engine.execute('oops'), returnsNormally);

      final result = engine.execute('oops');

      expect(result.clear, isFalse);
      expect(result.lines.single, contains('command not found'));
      expect(result.lines.single, contains('help'));
    });

    test(
      'commands ignore surrounding whitespace, repeated spaces, and case',
      () {
        expect(
          engine.execute('  CaT   SKILLS.MD  ').lines,
          engine.execute('cat skills.md').lines,
        );
        expect(
          engine.execute('  FLUTTER   RUN  ').lines,
          engine.execute('flutter run').lines,
        );
      },
    );

    test('identity, projects, and skills are derived from injected data', () {
      const customData = PortfolioData.constant(
        identity: PortfolioIdentity(
          name: '테스트 이름',
          englishName: 'Test Name',
          email: 'test@example.com',
          githubUrl: 'https://example.com/test-profile',
          headline: 'Test Headline',
          biography: 'Test Biography',
        ),
        experiences: <PortfolioExperience>[],
        education: <PortfolioEducation>[],
        skillGroups: <PortfolioSkillGroup>[
          PortfolioSkillGroup.constant(
            title: 'Test Skills',
            skills: <String>['Test Skill'],
          ),
        ],
        projects: <PortfolioProject>[
          PortfolioProject.constant(
            title: 'Test Project',
            description: 'Test Description',
            period: '2026',
            technologies: <String>['Test Skill'],
            links: <PortfolioProjectLink>[],
            category: PortfolioProjectCategory.personal,
          ),
        ],
      );
      final customEngine = TerminalEngine(customData);

      expect(
        customEngine.execute('whoami').lines.join('\n'),
        contains('Test Name'),
      );
      expect(
        customEngine.execute('ls').lines.join('\n'),
        contains('Test Project'),
      );
      expect(
        customEngine.execute('cat skills.md').lines.join('\n'),
        contains('Test Skill'),
      );
    });

    test('results defensively copy and expose immutable output', () {
      final sourceLines = <String>['first'];
      final result = TerminalResult(lines: sourceLines);

      sourceLines.add('second');

      expect(result.lines, <String>['first']);
      expect(() => result.lines.add('third'), throwsUnsupportedError);
    });

    test('command output contains no reference-site identity or URL', () {
      const commands = <String>[
        'help',
        'whoami',
        'ls',
        'cat skills.md',
        'git status',
        'git log',
        'flutter run',
        'clear',
        'https://portfolio-juah.vercel.app/',
      ];
      final output = commands
          .expand((command) => engine.execute(command).lines)
          .join('\n')
          .toLowerCase();

      expect(output, isNot(contains('천주아')));
      expect(output, isNot(contains('juah')));
      expect(output, isNot(contains('portfolio-juah')));
    });
  });
}
