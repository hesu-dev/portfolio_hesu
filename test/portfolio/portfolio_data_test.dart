import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';

const _portfolioDescription =
    'Flutter 개발자 민희수의 프로젝트와 기술 경험을 소개하는 반응형 포트폴리오입니다.';

File _projectFile(String relativePath) {
  var directory = Directory.current.absolute;

  while (true) {
    final pubspec = File(
      '${directory.path}${Platform.pathSeparator}pubspec.yaml',
    );
    if (pubspec.existsSync()) {
      return File(
        '${directory.path}${Platform.pathSeparator}'
        '${relativePath.replaceAll('/', Platform.pathSeparator)}',
      );
    }

    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('Flutter project root could not be found.');
    }
    directory = parent;
  }
}

void main() {
  group('portfolioData', () {
    test('contains only Min He-su identity and links', () {
      expect(portfolioData.name, '민희수');
      expect(portfolioData.email, 'hs0647@naver.com');
      expect(portfolioData.githubUrl, 'https://github.com/hesu-dev/');
      expect(portfolioData.allSearchableText, isNot(contains('천주아')));
      expect(portfolioData.allUrls, everyElement(isNot(contains('juah'))));
    });

    test('contains the six Min He-su portfolio projects', () {
      expect(
        portfolioData.projects.map((project) => project.title),
        containsAll(<String>[
          'PersonaChat AI Character Chat',
          'ReadingLog',
          'Blue Mentor',
          'IRIS',
          'AI-Bver',
          'HiddenTag',
        ]),
      );
      expect(portfolioData.projects, hasLength(6));
    });

    test('keeps every active project action', () {
      const expectedLinksByProject = <String, Set<String>>{
        'PersonaChat AI Character Chat': <String>{},
        'ReadingLog': <String>{
          'https://play.google.com/store/apps/details?id=com.reha.readinglog',
          'https://apps.apple.com/kr/app/%EB%A6%AC%EB%94%A9%EB%A1%9C%EA%B7%B8/id6759693995',
          'https://chromewebstore.google.com/detail/r20-jsonexporter/galgbmfkkpehcijjfcaffifmfjbmlfbo?authuser=1&hl=ko',
        },
        'Blue Mentor': <String>{
          'https://play.google.com/store/apps/details?id=com.lsmk.BlueMentor&pcampaignid=web_share',
          'https://apps.apple.com/us/app/%EB%B8%94%EB%A3%A8%EB%A9%98%ED%86%A0/id6475704951',
        },
        'IRIS': <String>{
          'https://www.dbpia.co.kr/journal/articleDetail?nodeId=NODE11488090',
        },
        'AI-Bver': <String>{
          'https://play.google.com/store/apps/details?id=com.aibver.lsmk&pcampaignid=web_share',
        },
        'HiddenTag': <String>{
          'https://play.google.com/store/apps/details?id=ScanTag.ndk.det&pcampaignid=web_share',
          'https://apps.apple.com/kr/app/hiddentag-%ED%9E%88%EB%93%A0%ED%83%9C%EA%B7%B8/id413494082',
        },
      };

      for (final project in portfolioData.projects) {
        expect(
          project.links.map((link) => link.url).toSet(),
          expectedLinksByProject[project.title],
          reason: project.title,
        );
      }
    });

    test('omits blank and malformed project actions', () {
      final links = portfolioData.projects
          .expand((project) => project.links)
          .toList();

      expect(links, isNotEmpty);
      for (final link in links) {
        expect(link.url.trim(), isNotEmpty, reason: link.label);
        expect(link.uri.isAbsolute, isTrue, reason: link.url);
        expect(
          link.uri.scheme,
          anyOf('http', 'https', 'mailto'),
          reason: link.url,
        );
        if (link.uri.scheme == 'mailto') {
          expect(link.uri.path, isNotEmpty, reason: link.url);
        } else {
          expect(link.uri.host, isNotEmpty, reason: link.url);
        }
      }
    });

    test('keeps the shared const collections immutable', () {
      expect(
        () => portfolioData.projects.add(portfolioData.projects.first),
        throwsUnsupportedError,
      );
      expect(
        () => portfolioData.skillGroups.first.skills.add('Reference content'),
        throwsUnsupportedError,
      );
      expect(
        () => portfolioData.projects.first.links.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => portfolioData.allUrls.add('https://example.com'),
        throwsUnsupportedError,
      );
    });

    test('skill groups defensively copy mutable runtime skills', () {
      final sourceSkills = <String>['Flutter', 'Dart'];
      final skillGroup = PortfolioSkillGroup(
        title: 'Development',
        skills: sourceSkills,
      );

      sourceSkills.add('Reference content');

      expect(skillGroup.skills, <String>['Flutter', 'Dart']);
      expect(
        () => skillGroup.skills.add('Another skill'),
        throwsUnsupportedError,
      );
    });

    test('projects defensively copy mutable runtime collections', () {
      final sourceTechnologies = <String>['Flutter', 'Dart'];
      final sourceLinks = <PortfolioProjectLink>[
        const PortfolioProjectLink(
          label: 'Source',
          url: 'https://example.com/source',
        ),
      ];
      final project = PortfolioProject(
        title: 'Project',
        description: 'Description',
        period: '2026',
        technologies: sourceTechnologies,
        links: sourceLinks,
      );

      sourceTechnologies.add('Reference technology');
      sourceLinks.clear();

      expect(project.technologies, <String>['Flutter', 'Dart']);
      expect(project.links, hasLength(1));
      expect(
        () => project.technologies.add('Another technology'),
        throwsUnsupportedError,
      );
      expect(() => project.links.clear(), throwsUnsupportedError);
    });

    test('portfolio data defensively copies mutable runtime collections', () {
      final sourceExperiences = <PortfolioExperience>[
        portfolioData.experiences.first,
      ];
      final sourceEducation = <PortfolioEducation>[
        portfolioData.education.first,
      ];
      final sourceSkillGroups = <PortfolioSkillGroup>[
        portfolioData.skillGroups.first,
      ];
      final sourceProjects = <PortfolioProject>[portfolioData.projects.first];
      final data = PortfolioData(
        identity: portfolioData.identity,
        experiences: sourceExperiences,
        education: sourceEducation,
        skillGroups: sourceSkillGroups,
        projects: sourceProjects,
      );

      sourceExperiences.clear();
      sourceEducation.clear();
      sourceSkillGroups.clear();
      sourceProjects.clear();

      expect(data.experiences, hasLength(1));
      expect(data.education, hasLength(1));
      expect(data.skillGroups, hasLength(1));
      expect(data.projects, hasLength(1));
      expect(() => data.experiences.clear(), throwsUnsupportedError);
      expect(() => data.education.clear(), throwsUnsupportedError);
      expect(() => data.skillGroups.clear(), throwsUnsupportedError);
      expect(() => data.projects.clear(), throwsUnsupportedError);
    });

    test('uses only the confirmed AI-Bver period', () {
      final aiBver = portfolioData.projects.singleWhere(
        (project) => project.title == 'AI-Bver',
      );

      expect(aiBver.period, '2021.12');
      expect(RegExp(r'^\d{4}\.\d{2}$').hasMatch(aiBver.period), isTrue);
    });

    test('uses const immutable value types', () {
      const identity = PortfolioIdentity(
        name: '민희수',
        englishName: 'Min He-su',
        email: 'hs0647@naver.com',
        githubUrl: 'https://github.com/hesu-dev/',
        headline: 'Flutter Developer',
        biography: '모바일 앱 개발자',
      );
      const experience = PortfolioExperience(
        role: 'Developer',
        organization: 'Company',
        period: '2020 - Present',
        description: 'Application development',
      );
      const projectLink = PortfolioProjectLink(
        label: 'Source',
        url: 'https://example.com/source',
      );
      const education = PortfolioEducation(
        program: 'Developer course',
        institution: 'Institute',
        period: '2020',
        link: projectLink,
      );
      const skillGroup = PortfolioSkillGroup.constant(
        title: 'Development',
        skills: <String>['Flutter', 'Dart'],
      );
      const project = PortfolioProject.constant(
        title: 'Project',
        description: 'Description',
        period: '2020',
        technologies: <String>['Flutter'],
        links: <PortfolioProjectLink>[projectLink],
      );
      const data = PortfolioData.constant(
        identity: identity,
        experiences: <PortfolioExperience>[experience],
        education: <PortfolioEducation>[education],
        skillGroups: <PortfolioSkillGroup>[skillGroup],
        projects: <PortfolioProject>[project],
      );

      expect(identity.name, '민희수');
      expect(experience.role, 'Developer');
      expect(education.link, same(projectLink));
      expect(data.skillGroups.single, same(skillGroup));
      expect(data.projects.single, same(project));
    });
  });

  test('PortfolioAppId exposes the shared app catalog', () {
    expect(PortfolioAppId.values, <PortfolioAppId>[
      PortfolioAppId.about,
      PortfolioAppId.skills,
      PortfolioAppId.projects,
      PortfolioAppId.terminal,
      PortfolioAppId.thisMac,
      PortfolioAppId.trash,
      PortfolioAppId.github,
      PortfolioAppId.mail,
    ]);
  });

  group('web portfolio metadata sources', () {
    test('index identifies Min He-su and keeps Flutter bootstrap intact', () {
      final indexHtml = _projectFile('web/index.html').readAsStringSync();

      expect(indexHtml, contains('<html lang="ko">'));
      expect(indexHtml, contains('<title>민희수 포트폴리오</title>'));
      expect(
        indexHtml,
        contains('name="description" content="$_portfolioDescription"'),
      );
      expect(
        indexHtml,
        contains(
          'name="viewport" content="width=device-width, initial-scale=1.0"',
        ),
      );
      expect(indexHtml, contains('name="theme-color" content="#121316"'));
      expect(
        indexHtml,
        contains('name="apple-mobile-web-app-title" content="민희수 포트폴리오"'),
      );
      expect(indexHtml, contains('<link rel="manifest" href="manifest.json">'));
      expect(indexHtml, contains('flutter_bootstrap.js'));
      expect(indexHtml, contains('<noscript>'));
      expect(indexHtml, contains('민희수의 포트폴리오'));

      final lowerCaseIndex = indexHtml.toLowerCase();
      expect(lowerCaseIndex, isNot(contains('a new flutter project')));
      expect(lowerCaseIndex, isNot(contains('portfolio_hesu')));
      expect(lowerCaseIndex, isNot(contains('portfolio-juah')));
      expect(indexHtml, isNot(contains('천주아')));
    });

    test('manifest is valid, consistent, and base-path safe', () {
      final manifestSource = _projectFile(
        'web/manifest.json',
      ).readAsStringSync();
      final manifest = jsonDecode(manifestSource) as Map<String, dynamic>;

      expect(manifest['name'], '민희수 포트폴리오');
      expect(manifest['short_name'], '민희수');
      expect(manifest['description'], _portfolioDescription);
      expect(manifest['start_url'], '.');
      expect(manifest['scope'], '.');
      expect(manifest['display'], 'standalone');
      expect(manifest['theme_color'], '#121316');
      expect(manifest['background_color'], '#121316');

      final icons = (manifest['icons'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(icons, isNotEmpty);
      for (final icon in icons) {
        final source = icon['src'] as String;
        expect(Uri.parse(source).hasScheme, isFalse, reason: source);
        expect(source.startsWith('/'), isFalse, reason: source);
      }

      final lowerCaseManifest = manifestSource.toLowerCase();
      expect(lowerCaseManifest, isNot(contains('a new flutter project')));
      expect(lowerCaseManifest, isNot(contains('portfolio_hesu')));
      expect(lowerCaseManifest, isNot(contains('portfolio-juah')));
      expect(manifestSource, isNot(contains('천주아')));
    });
  });

  test('README documents adaptive UI and both web build targets', () {
    final readme = _projectFile('README.md').readAsStringSync();

    expect(readme, contains('macOS'));
    expect(readme, contains('iPadOS'));
    expect(readme, contains('iPhone'));
    expect(readme, contains('Flutter'));
    expect(readme, contains('flutter run -d chrome'));
    expect(readme, contains('flutter test'));
    expect(readme, contains('flutter analyze'));
    expect(
      readme,
      contains(
        'flutter build web --release --base-href /portfolio_hesu/ '
        '--pwa-strategy=none',
      ),
    );
    expect(
      readme,
      contains('flutter build web --release --base-href / --pwa-strategy=none'),
    );
    expect(readme, contains('build/web'));
    expect(readme, contains('GitHub Pages'));
    expect(readme, contains('Vercel'));
    expect(readme, contains('현재 배포는 GitHub Pages를 유지'));
  });
}
