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
      const data = portfolioData;

      expect(identity.name, '민희수');
      expect(experience.role, 'Developer');
      expect(education.link, same(projectLink));
      expect(data, same(portfolioData));
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
}
