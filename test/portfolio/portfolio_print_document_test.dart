import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/printing/portfolio_print_document.dart';

void main() {
  const escape = HtmlEscape();

  test('combines resume, supplied introduction, and all project content', () {
    const introduction = '함께 일하는 사람을 위한 개발을 지향합니다.\n두 번째 문단입니다.';
    final html = buildPortfolioPrintDocument(
      portfolioData,
      introduction: introduction,
    );

    for (final text in <String>[
      portfolioData.name,
      portfolioData.identity.englishName,
      portfolioData.email,
      portfolioData.identity.headline,
      portfolioData.identity.biography,
      introduction,
      ...portfolioData.certifications,
      for (final experience in portfolioData.experiences) ...<String>[
        experience.role,
        experience.organization,
        experience.period,
        experience.description,
      ],
      for (final education in portfolioData.education) ...<String>[
        education.program,
        education.institution,
        education.period,
      ],
      for (final group in portfolioData.skillGroups) ...<String>[
        group.title,
        ...group.skills,
      ],
      for (final project in portfolioData.projects) ...<String>[
        project.title,
        project.description,
        project.period,
        ...project.technologies,
        ...project.highlights,
        if (project.architecture case final architecture?) ...<String>[
          architecture.title,
          architecture.description,
          ...architecture.nodes,
        ],
        for (final section in project.sections) section.body,
        for (final link in project.links) ...<String>[link.label, link.url],
      ],
    ]) {
      expect(html, contains(escape.convert(text)), reason: text);
    }
    expect(html, contains('임시 예시'));
    expect(html, contains('실제 운영 기록으로 교체할 초안'));
    expect(
      html.indexOf('id="resume"'),
      lessThan(html.indexOf('id="introduction"')),
    );
    expect(
      html.indexOf('id="introduction"'),
      lessThan(html.indexOf('id="projects"')),
    );
    expect(html, contains('id="print-document"'));
    expect(html, contains('onclick="window.print()"'));
    expect(html, contains('PDF 저장 / 인쇄'));
  });

  test(
    'omits empty fields and duplicate work while ordering project sections',
    () {
      final data = _data(
        projects: <PortfolioProject>[
          PortfolioProject(
            title: 'Only project',
            description: 'Distinct project description',
            period: '',
            technologies: <String>[' ', 'Dart'],
            highlights: <String>[' '],
            sections: const <PortfolioProjectSection>[
              PortfolioProjectSection(
                kind: PortfolioProjectSectionKind.outcome,
                body: 'Measured result',
              ),
              PortfolioProjectSection(
                kind: PortfolioProjectSectionKind.work,
                body: ' Distinct project description ',
              ),
              PortfolioProjectSection(
                kind: PortfolioProjectSectionKind.problem,
                body: 'Initial problem',
              ),
              PortfolioProjectSection(
                kind: PortfolioProjectSectionKind.note,
                body: ' ',
              ),
            ],
            links: const <PortfolioProjectLink>[],
          ),
        ],
      );
      final html = buildPortfolioPrintDocument(data, introduction: 'Ready');
      expect('Distinct project description'.allMatches(html), hasLength(1));
      expect(
        html.indexOf('Initial problem'),
        lessThan(html.indexOf('Measured result')),
      );
      expect(html, isNot(contains('>업무</')));
      expect(html, isNot(contains('>비고</')));
      expect(html, isNot(contains('<li> </li>')));
      expect(html, isNot(contains('<p class="period"></p>')));
    },
  );

  test('escapes supplied text and makes only safe links clickable', () {
    const unsafe = '<script>alert("x")</script> & <img src=x onerror=alert(1)>';
    final data = _data(
      projects: <PortfolioProject>[
        PortfolioProject(
          title: unsafe,
          description: unsafe,
          period: '',
          technologies: const <String>[],
          links: const <PortfolioProjectLink>[
            PortfolioProjectLink(label: unsafe, url: 'javascript:alert(1)'),
            PortfolioProjectLink(label: 'Data', url: 'data:text/html,<script>'),
            PortfolioProjectLink(label: 'Local', url: '//example.com'),
            PortfolioProjectLink(
              label: 'Web',
              url: 'https://example.com/?a=1&b="two"',
            ),
            PortfolioProjectLink(label: 'HTTP', url: 'http://example.com'),
          ],
        ),
      ],
    );
    final html = buildPortfolioPrintDocument(data, introduction: unsafe);
    expect(html, contains(escape.convert(unsafe)));
    expect(html, isNot(contains('<script>')));
    expect(html, isNot(contains('<img')));
    expect(html, isNot(contains('href="javascript:')));
    expect(html, isNot(contains('href="data:')));
    expect(html, isNot(contains('href="//')));
    expect(
      html,
      contains('href="${escape.convert('https://example.com/?a=1&b="two"')}"'),
    );
    expect(html, contains('href="${escape.convert('http://example.com')}"'));
    expect(html, contains('href="mailto:test@example.com"'));
    expect(html, contains('javascript:alert(1)'));
  });
}

PortfolioData _data({required List<PortfolioProject> projects}) =>
    PortfolioData(
      identity: const PortfolioIdentity(
        name: 'Test',
        englishName: 'Tester',
        email: 'test@example.com',
        githubUrl: 'https://github.com/example',
        headline: 'Developer',
        biography: 'Biography',
      ),
      experiences: const <PortfolioExperience>[],
      education: const <PortfolioEducation>[],
      skillGroups: const <PortfolioSkillGroup>[],
      projects: projects,
    );
