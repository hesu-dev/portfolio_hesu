import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/terminal/terminal_engine.dart';

void main() {
  late TerminalEngine engine;

  setUp(() {
    engine = TerminalEngine(portfolioData);
  });

  group('TerminalEngine', () {
    test('help lists every supported command', () {
      expect(engine.execute('help').lines, <String>[
        'Available commands:',
        '  help',
        '  whoami',
        '  ls',
        '  cat skills.md',
        '  git status',
        '  git log',
        '  npm run dev',
        '  clear',
      ]);
    });

    test('whoami returns the portfolio identity', () {
      final output = engine.execute('whoami').lines.join('\n');

      expect(output, contains('민희수'));
      expect(output, contains('Min He-su'));
      expect(output, contains('hesu-dev'));
    });

    test('ls lists portfolio files and project names', () {
      final output = engine.execute('ls').lines.join('\n');

      expect(output, contains('about.md'));
      expect(output, contains('skills.md'));
      for (final project in portfolioData.projects) {
        expect(output, contains(project.title), reason: project.title);
      }
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
        'On branch portfolio',
        'nothing to commit, working tree clean',
      ]);
    });

    test('git log returns one deterministic entry per project', () {
      final result = engine.execute('git log');

      expect(result.lines, hasLength(portfolioData.projects.length));
      for (final project in portfolioData.projects) {
        expect(
          result.lines.where((line) => line.contains(project.title)),
          hasLength(1),
          reason: project.title,
        );
      }
    });

    test('npm run dev reports a ready portfolio preview', () {
      final output = engine.execute('npm run dev').lines.join('\n');

      expect(output, contains('portfolio'));
      expect(output, contains('Min He-su'));
      expect(output, contains('ready'));
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
          engine.execute('  NPM   RUN   DEV  ').lines,
          engine.execute('npm run dev').lines,
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
      expect(
        customEngine.execute('git log').lines.join('\n'),
        contains('Test Project'),
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
        'npm run dev',
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
