import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';

void main() {
  group('portfolioData', () {
    test('contains only Min He-su identity and links', () {
      expect(portfolioData.name, '민희수');
      expect(portfolioData.email, 'hs0647@naver.com');
      expect(portfolioData.githubUrl, 'https://github.com/hesu-dev/');
      expect(portfolioData.allSearchableText, isNot(contains('천주아')));
      expect(portfolioData.allUrls, everyElement(isNot(contains('juah'))));
    });

    test('contains three verified public GitHub repositories', () {
      const repositories = <String, String>{
        'portfolio_hesu': 'https://github.com/hesu-dev/portfolio_hesu',
        'chrome_extension': 'https://github.com/hesu-dev/chrome_extension',
        'code_study': 'https://github.com/hesu-dev/code_study',
      };

      expect(
        portfolioData.repositories.map((repository) => repository.name),
        repositories.keys,
      );
      expect(
        portfolioData.repositories.map((repository) => repository.url),
        repositories.values,
      );
      expect(portfolioData.allUrls, containsAll(repositories.values));
      for (final name in repositories.keys) {
        expect(portfolioData.allSearchableText, contains(name));
      }
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

    test('uses the confirmed current Flutter career copy', () {
      final currentRole = portfolioData.experiences.first;

      expect(currentRole.role, 'Junior Flutter Developer');
      expect(currentRole.organization, '(주)상상력 집단');
      expect(currentRole.description, 'node 웹사이트 서비스 기획 및 개발, 출시 후 유지보수');
    });

    test('classifies work and personal projects for Finder locations', () {
      final titlesByCategory = <PortfolioProjectCategory, Set<String>>{
        for (final category in PortfolioProjectCategory.values)
          category: portfolioData.projects
              .where((project) => project.category == category)
              .map((project) => project.title)
              .toSet(),
      };

      expect(titlesByCategory[PortfolioProjectCategory.personal], <String>{
        'PersonaChat AI Character Chat',
        'ReadingLog',
      });
      expect(titlesByCategory[PortfolioProjectCategory.career], <String>{
        'Blue Mentor',
        'IRIS',
        'AI-Bver',
        'HiddenTag',
      });
      final projectWithoutExplicitCategory = PortfolioProject(
        title: 'Unclassified project',
        description: 'Defaults safely',
        period: '2026',
        technologies: const <String>[],
        links: const <PortfolioProjectLink>[],
      );
      expect(
        projectWithoutExplicitCategory.category,
        PortfolioProjectCategory.career,
      );
    });

    test('orders ReadingLog before the other personal project', () {
      expect(
        portfolioData.projects
            .where(
              (project) =>
                  project.category == PortfolioProjectCategory.personal,
            )
            .map((project) => project.title)
            .toList(),
        <String>['ReadingLog', 'PersonaChat AI Character Chat'],
      );
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
    expect(PortfolioAppId.values.map((appId) => appId.name), <String>[
      'profile',
      'about',
      'introduction',
      'skills',
      'projects',
      'terminal',
      'music',
      'photos',
      'thisMac',
      'trash',
      'github',
      'mail',
      'settings',
    ]);
  });

  group('project case-study content', () {
    test('exposes the narrative labels in portfolio reading order', () {
      expect(
        PortfolioProjectSectionKind.values.map((kind) => kind.label),
        <String>['업무', '문제', '원인', '측정', '해결', '평가', '비고'],
      );
    });

    test('derives a numeric display year without inventing one', () {
      final datedProject = PortfolioProject(
        title: 'Dated project',
        description: 'Description',
        period: '2023.06 - 2024.02',
        technologies: const <String>[],
        links: const <PortfolioProjectLink>[],
      );
      final undatedProject = PortfolioProject(
        title: 'Undated project',
        description: 'Description',
        period: '설계 중',
        technologies: const <String>[],
        links: const <PortfolioProjectLink>[],
      );

      expect(datedProject.displayYear, '2023');
      expect(undatedProject.displayYear, isNull);
    });

    test('defensively copies every runtime case-study collection', () {
      final sourceHighlights = <String>['First highlight'];
      final sourceSections = <PortfolioProjectSection>[
        const PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.work,
          body: 'Designed the application.',
        ),
      ];
      final sourceNodes = <String>['Client', 'API'];
      final architecture = PortfolioProjectArchitecture(
        title: 'System architecture',
        description: 'Request flow',
        nodes: sourceNodes,
      );
      final project = PortfolioProject(
        title: 'Case study',
        description: 'Description',
        period: '2026',
        technologies: const <String>['Flutter'],
        links: const <PortfolioProjectLink>[],
        highlights: sourceHighlights,
        architecture: architecture,
        sections: sourceSections,
      );

      sourceHighlights.add('Reference highlight');
      sourceSections.clear();
      sourceNodes.add('Database');

      expect(project.highlights, <String>['First highlight']);
      expect(project.sections, hasLength(1));
      expect(project.architecture!.nodes, <String>['Client', 'API']);
      expect(
        project.architecture!.presentation,
        PortfolioArchitecturePresentation.components,
      );
      expect(
        () => project.highlights.add('Another highlight'),
        throwsUnsupportedError,
      );
      expect(() => project.sections.clear(), throwsUnsupportedError);
      expect(
        () => project.architecture!.nodes.add('Another node'),
        throwsUnsupportedError,
      );
    });

    test('adds case-study copy to searchable portfolio text', () {
      const project = PortfolioProject.constant(
        title: 'Searchable project',
        description: 'Description',
        period: '2026',
        technologies: <String>['Flutter'],
        links: <PortfolioProjectLink>[],
        highlights: <String>['SEARCHABLE_HIGHLIGHT'],
        architecture: PortfolioProjectArchitecture.constant(
          title: 'SEARCHABLE_ARCHITECTURE',
          description: 'SEARCHABLE_ARCHITECTURE_DESCRIPTION',
          nodes: <String>['SEARCHABLE_NODE'],
        ),
        sections: <PortfolioProjectSection>[
          PortfolioProjectSection(
            kind: PortfolioProjectSectionKind.solution,
            body: 'SEARCHABLE_SOLUTION',
          ),
        ],
      );
      const data = PortfolioData.constant(
        identity: PortfolioIdentity(
          name: 'Test',
          englishName: 'Test User',
          email: 'test@example.com',
          githubUrl: 'https://example.com',
          headline: 'Headline',
          biography: 'Biography',
        ),
        experiences: <PortfolioExperience>[],
        education: <PortfolioEducation>[],
        skillGroups: <PortfolioSkillGroup>[],
        projects: <PortfolioProject>[project],
      );

      for (final fragment in <String>[
        'SEARCHABLE_HIGHLIGHT',
        'SEARCHABLE_ARCHITECTURE',
        'SEARCHABLE_ARCHITECTURE_DESCRIPTION',
        'SEARCHABLE_NODE',
        'SEARCHABLE_SOLUTION',
      ]) {
        expect(data.allSearchableText, contains(fragment), reason: fragment);
      }
    });

    test('gives every portfolio project verified work and highlights', () {
      for (final project in portfolioData.projects) {
        expect(project.highlights, isNotEmpty, reason: project.title);
        expect(
          project.sections.map((section) => section.kind),
          contains(PortfolioProjectSectionKind.work),
          reason: project.title,
        );
        expect(
          project.sections.map((section) => section.kind.index),
          orderedEquals(
            project.sections.map((section) => section.kind.index).toList()
              ..sort(),
          ),
          reason: project.title,
        );
      }
    });

    test('documents only the verified ReadingLog app and extension flow', () {
      final project = portfolioData.projects.singleWhere(
        (project) => project.title == 'ReadingLog',
      );

      expect(project.architecture, isNotNull);
      expect(
        project.architecture!.presentation,
        PortfolioArchitecturePresentation.flow,
      );
      expect(project.architecture!.nodes, <String>[
        '채팅 로그',
        'Chrome 확장 프로그램',
        'JSON 내보내기',
        'ReadingLog 앱',
      ]);
      expect(
        project.sections.map((section) => section.kind),
        <PortfolioProjectSectionKind>[
          PortfolioProjectSectionKind.work,
          PortfolioProjectSectionKind.solution,
        ],
      );
    });

    test('marks PersonaChat as measured design work rather than a launch', () {
      final project = portfolioData.projects.singleWhere(
        (project) => project.title == 'PersonaChat AI Character Chat',
      );

      expect(project.architecture, isNotNull);
      expect(
        project.architecture!.presentation,
        PortfolioArchitecturePresentation.components,
      );
      expect(
        project.sections
            .singleWhere(
              (section) =>
                  section.kind == PortfolioProjectSectionKind.measurement,
            )
            .body,
        allOf(contains('2026-07-12'), contains('19개 활성 공고')),
      );
      expect(
        project.sections
            .singleWhere(
              (section) =>
                  section.kind == PortfolioProjectSectionKind.evaluation,
            )
            .body,
        contains('설계 단계'),
      );
      expect(
        project.sections
            .singleWhere(
              (section) => section.kind == PortfolioProjectSectionKind.note,
            )
            .body,
        contains('출시 성과가 아닌'),
      );
    });
  });
}
