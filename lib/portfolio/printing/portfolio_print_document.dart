import 'dart:convert';

import '../data/portfolio_data.dart';

/// A text-based document so browser printing retains selectable Korean text.
String buildPortfolioPrintDocument(
  PortfolioData data, {
  required String introduction,
}) {
  final identity = data.identity;
  final content = StringBuffer('''
<section class="sheet" id="resume" aria-labelledby="resume-title">
  <div class="eyebrow">RESUME · PORTFOLIO</div>
  <h1>${_escape(identity.name)}</h1>
  ${_paragraph(identity.englishName, className: 'english-name')}
  ${_paragraph(identity.headline, className: 'headline')}
  <div class="contact">
    ${_link(identity.email, data.mailUrl, showUrl: false)}
    ${_link('GitHub', identity.githubUrl)}
  </div>
  <h2 id="resume-title">이력서</h2>
  ${_paragraph(identity.biography)}
''');

  if (data.experiences.isNotEmpty) {
    content.writeln('<h3>경력</h3>');
    for (final experience in data.experiences) {
      content.writeln('''<div class="entry">
  <div class="entry-heading"><h4>${_escape(experience.organization)}</h4>
    ${_paragraph(experience.period, className: 'period')}</div>
  ${_paragraph(experience.role, className: 'role')}
  ${_paragraph(experience.description)}
</div>''');
    }
  }
  if (data.education.isNotEmpty) {
    content.writeln('<h3>교육</h3>');
    for (final education in data.education) {
      content.writeln('''<div class="entry">
  <div class="entry-heading"><h4>${_escape(education.institution)}</h4>
    ${_paragraph(education.period, className: 'period')}</div>
  ${_paragraph(education.program)}
  ${education.link != null ? _link(education.link!.label, education.link!.url) : ''}
</div>''');
    }
  }
  if (data.skillGroups.isNotEmpty) {
    content.writeln('<h3>기술 · 협업 도구</h3><dl class="details">');
    for (final group in data.skillGroups) {
      content.writeln('''<div>
  <dt>${_escape(group.title)}</dt>
  <dd>${_escape(_nonEmpty(group.skills).join(' · '))}</dd>
</div>''');
    }
    content.writeln('</dl>');
  }
  if (data.certifications.isNotEmpty) {
    content.writeln('<h3>자격</h3>${_list(data.certifications)}');
  }
  content.writeln('''</section>
<section class="sheet" id="introduction" aria-labelledby="introduction-title">
  <div class="eyebrow">SELF INTRODUCTION</div>
  <h2 id="introduction-title">자기소개서</h2>
  ${_paragraph(introduction, className: 'introduction')}
</section>
<section class="sheet" id="projects" aria-labelledby="projects-title">
  <div class="eyebrow">PROJECTS</div>
  <h2 id="projects-title">프로젝트</h2>
''');

  for (final project in data.projects) {
    final sections =
        project.sections
            .where(
              (section) =>
                  section.body.trim().isNotEmpty &&
                  !(section.kind == PortfolioProjectSectionKind.work &&
                      section.body.trim() == project.description.trim()),
            )
            .toList()
          ..sort((left, right) => left.kind.index.compareTo(right.kind.index));
    content.writeln('''<article class="project">
  <div class="project-category">${project.category == PortfolioProjectCategory.career ? '경력 프로젝트' : '개인 프로젝트'}</div>
  <div class="entry-heading"><h3>${_escape(project.title)}</h3>
    ${_paragraph(project.period, className: 'period')}</div>
  ${_paragraph(project.description)}
  ${_paragraph(_nonEmpty(project.technologies).join(' · '), className: 'technologies')}
  ${_list(project.highlights)}
''');
    if (project.architecture case final architecture?) {
      content.writeln('''<div class="architecture">
  <h4>${_escape(architecture.title)}</h4>
  ${_paragraph(architecture.description)}
  ${_paragraph(_nonEmpty(architecture.nodes).join(architecture.presentation == PortfolioArchitecturePresentation.flow ? ' → ' : ' · '), className: 'architecture-nodes')}
</div>''');
    }
    if (sections.isNotEmpty) {
      content.writeln('<dl class="details project-details">');
      for (final section in sections) {
        content.writeln('''<div>
  <dt>${_escape(section.kind.label)}</dt>
  <dd>${_escape(section.body)}</dd>
</div>''');
      }
      content.writeln('</dl>');
    }
    if (project.links.isNotEmpty) {
      content.writeln('<div class="project-links">');
      for (final link in project.links) {
        content.writeln(_link(link.label, link.url));
      }
      content.writeln('</div>');
    }
    content.writeln('</article>');
  }
  content.writeln('</section>');

  return '''<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="color-scheme" content="light">
  <title>${_escape(identity.name)} — 이력서 · 자기소개서 · 프로젝트</title>
  <style>
    * { box-sizing: border-box; }
    html { color-scheme: light; }
    body { margin: 0; background: #eeeff1; color: #222; font-family: -apple-system, BlinkMacSystemFont, "Apple SD Gothic Neo", "Malgun Gothic", sans-serif; font-size: 10pt; line-height: 1.75; word-break: keep-all; overflow-wrap: anywhere; }
    .toolbar { position: sticky; top: 0; z-index: 1; display: flex; align-items: center; justify-content: center; gap: 20px; padding: 14px 20px; background: #fff; border-bottom: 1px solid #d8d8d8; }
    .toolbar p { margin: 0; color: #666; font-size: 12px; }
    button { padding: 10px 18px; border: 0; border-radius: 7px; background: #222; color: #fff; font: inherit; font-weight: 600; cursor: pointer; white-space: nowrap; }
    button:focus-visible { outline: 3px solid #777; outline-offset: 3px; }
    main { padding: 28px 16px; }
    .sheet { width: 210mm; max-width: 100%; margin: 0 auto 24px; padding: 18mm; background: #fff; box-shadow: 0 2px 14px #0000000b; }
    h1, h2, h3, h4, p, ul, dl, dd { margin: 0; }
    h1 { margin-top: 10px; font-size: 32pt; font-weight: 750; letter-spacing: -.06em; line-height: 1.2; }
    h2 { margin-bottom: 20px; padding-bottom: 12px; border-bottom: 2px solid #222; font-size: 22pt; letter-spacing: -.04em; line-height: 1.4; }
    #resume h2 { margin-top: 30px; font-size: 15pt; }
    h3 { margin: 27px 0 12px; font-size: 13pt; line-height: 1.5; }
    h4 { font-size: 10.5pt; line-height: 1.7; font-weight: 700; }
    p, dd { white-space: pre-line; }
    p + p { margin-top: 6px; }
    .eyebrow { font-size: 8pt; font-weight: 700; color: #777; letter-spacing: .16em; }
    .eyebrow + h2 { margin-top: 10px; }
    .english-name { margin-top: 8px; color: #666; }
    .headline { margin-top: 14px; font-size: 12pt; font-weight: 600; }
    .contact { margin-top: 15px; display: flex; flex-wrap: wrap; gap: 4px 20px; font-size: 9pt; }
    a { color: inherit; text-decoration-color: #aaa; text-underline-offset: 3px; }
    .link-url { color: #666; font-size: 8pt; overflow-wrap: anywhere; word-break: break-all; }
    .entry + .entry { margin-top: 16px; padding-top: 15px; border-top: 1px solid #e5e5e5; }
    .entry-heading { display: flex; align-items: baseline; justify-content: space-between; gap: 8px 16px; }
    .period { flex: 0 0 auto; color: #666; font-size: 8.5pt; }
    .role { color: #666; font-size: 9pt; }
    ul { padding-left: 18px; }
    li + li { margin-top: 3px; }
    .details > div { display: grid; grid-template-columns: 30mm minmax(0, 1fr); gap: 12px; padding: 7px 0; }
    dt { font-weight: 650; color: #555; }
    .introduction { font-size: 11pt; line-height: 2; }
    .project + .project { margin-top: 30px; padding-top: 26px; border-top: 1px solid #ccc; }
    .project-category { margin-bottom: 5px; color: #777; font-size: 8pt; }
    .project h3 { margin: 0 0 12px; font-size: 16pt; letter-spacing: -.025em; }
    .technologies { margin: 12px 0; color: #666; font-size: 8.5pt; }
    .architecture { margin: 18px 0; padding-left: 12px; border-left: 2px solid #bbb; }
    .architecture-nodes { margin-top: 8px; color: #666; font-size: 9pt; }
    .project-details { margin-top: 12px; }
    .project-details > div { border-top: 1px solid #eee; grid-template-columns: 22mm minmax(0, 1fr); }
    .project-links { margin-top: 18px; display: grid; gap: 5px; }
    @media screen and (max-width: 600px) {
      .toolbar { align-items: flex-start; gap: 12px; }
      main { padding: 14px 8px; }
      .sheet { padding: 28px 22px; }
      .entry-heading { flex-wrap: wrap; gap: 0 12px; }
      .details > div, .project-details > div { grid-template-columns: 1fr; gap: 2px; }
      h1 { font-size: 28pt; }
    }
    @page { size: A4; margin: 17mm 18mm; }
    @media print {
      body { background: #fff; }
      .toolbar { display: none !important; }
      main { padding: 0; }
      .sheet { width: auto; max-width: none; margin: 0; padding: 0; box-shadow: none; }
      .sheet + .sheet { break-before: page; }
      h1, h2, h3, h4, dt, .entry-heading, .project-category { break-after: avoid; }
      .entry { break-inside: avoid; }
      p, li, dd { orphans: 3; widows: 3; }
      a { text-decoration: none; }
    }
  </style>
</head>
<body>
  <div class="toolbar">
    <button id="print-document" type="button" onclick="window.print()">PDF 저장 / 인쇄</button>
    <p>인쇄 대상에서 ‘PDF로 저장’을 선택하면 하나의 문서로 저장됩니다.</p>
  </div>
  <main>$content</main>
</body>
</html>''';
}

String _escape(String value) => const HtmlEscape().convert(value);

Iterable<String> _nonEmpty(Iterable<String> values) =>
    values.where((value) => value.trim().isNotEmpty);

String _paragraph(String value, {String className = ''}) => value.trim().isEmpty
    ? ''
    : '<p${className.isEmpty ? '' : ' class="$className"'}>${_escape(value)}</p>';

String _list(Iterable<String> values) {
  final items = _nonEmpty(
    values,
  ).map((value) => '<li>${_escape(value)}</li>').join();
  return items.isEmpty ? '' : '<ul>$items</ul>';
}

String _link(String label, String url, {bool showUrl = true}) {
  if (url.trim().isEmpty) return '';
  final uri = Uri.tryParse(url);
  final safe =
      uri != null &&
      ((<String>['https', 'http'].contains(uri.scheme) &&
              uri.host.isNotEmpty) ||
          (uri.scheme == 'mailto' &&
              !uri.hasAuthority &&
              RegExp(r'^[^\s@]+@[^\s@]+$').hasMatch(uri.path)));
  final text =
      '${_escape(label)}${showUrl ? ' <span class="link-url">${_escape(url)}</span>' : ''}';
  return safe ? '<a href="${_escape(url)}">$text</a>' : '<span>$text</span>';
}
