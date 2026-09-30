import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/portfolio_data.dart';

/// Builds the same selectable text document used by the print fallback.
Future<Uint8List> buildPortfolioPdfDocument(
  PortfolioData data, {
  required ByteData regularFont,
  required ByteData boldFont,
  required String introduction,
}) async {
  final identity = data.identity;
  final document = pw.Document(
    title: '${identity.name} — 이력서 · 자기소개서 · 프로젝트',
    author: identity.name,
    theme: pw.ThemeData.withFont(
      base: pw.Font.ttf(regularFont),
      bold: pw.Font.ttf(boldFont),
    ),
  );
  final content = <pw.Widget>[
    _eyebrow('RESUME · PORTFOLIO'),
    pw.SizedBox(height: 12),
    pw.Text(
      identity.name,
      style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold),
    ),
    ..._paragraph(identity.englishName, muted: true),
    pw.SizedBox(height: 7),
    ..._paragraph(identity.headline, size: 12),
    ..._link(identity.email, data.mailUrl, showUrl: false),
    ..._link('GitHub', identity.githubUrl),
    ..._heading('이력서', size: 15),
    ..._paragraph(identity.biography),
  ];

  if (data.experiences.isNotEmpty) {
    content.addAll(_heading('경력', size: 13));
    for (final experience in data.experiences) {
      content.addAll([
        ..._entryHeading(experience.organization, experience.period),
        ..._paragraph(experience.role, muted: true),
        ..._paragraph(experience.description),
        pw.SizedBox(height: 8),
      ]);
    }
  }
  if (data.education.isNotEmpty) {
    content.addAll(_heading('교육', size: 13));
    for (final education in data.education) {
      content.addAll([
        ..._entryHeading(education.institution, education.period),
        ..._paragraph(education.program),
        if (education.link case final link?) ..._link(link.label, link.url),
        pw.SizedBox(height: 8),
      ]);
    }
  }
  if (data.skillGroups.isNotEmpty) {
    content.addAll(_heading('기술 · 협업 도구', size: 13));
    for (final group in data.skillGroups) {
      content.addAll([
        ..._paragraph('${group.title}    ${_joined(group.skills)}', size: 9),
      ]);
    }
  }
  if (data.certifications.isNotEmpty) {
    content.addAll(_heading('자격', size: 13));
    content.addAll(_list(data.certifications));
  }

  content.addAll([
    pw.NewPage(),
    _eyebrow('SELF INTRODUCTION'),
    ..._heading('자기소개서'),
    ..._paragraph(introduction, size: 11),
    pw.NewPage(),
    _eyebrow('PROJECTS'),
    ..._heading('프로젝트'),
  ]);
  for (final project in data.projects) {
    final sections = project.sections.where((section) {
      return section.body.trim().isNotEmpty &&
          !(section.kind == PortfolioProjectSectionKind.work &&
              section.body.trim() == project.description.trim());
    }).toList()..sort((a, b) => a.kind.index.compareTo(b.kind.index));
    content.addAll([
      pw.NewPage(freeSpace: 120),
      pw.SizedBox(height: 12),
      _eyebrow(
        project.category == PortfolioProjectCategory.career
            ? '경력 프로젝트'
            : '개인 프로젝트',
      ),
      ..._entryHeading(project.title, project.period, size: 16),
      ..._paragraph(project.description),
      ..._paragraph(_joined(project.technologies), muted: true),
      ..._list(project.highlights),
    ]);
    if (project.architecture case final architecture?) {
      content.addAll([
        ..._label(architecture.title),
        ..._paragraph(architecture.description),
        ..._paragraph(
          _joined(
            architecture.nodes,
            separator:
                architecture.presentation ==
                    PortfolioArchitecturePresentation.flow
                ? ' → '
                : ' · ',
          ),
          muted: true,
        ),
      ]);
    }
    for (final section in sections) {
      content.addAll([
        ..._label(section.kind.label),
        ..._paragraph(section.body),
      ]);
    }
    for (final link in project.links) {
      content.addAll(_link(link.label, link.url));
    }
    content.addAll([
      pw.SizedBox(height: 14),
      pw.Divider(color: PdfColors.grey300, thickness: 0.5),
    ]);
  }

  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(51, 48, 51, 42),
      maxPages: 200,
      build: (_) => content,
      footer: (context) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 15),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '${identity.name} · PORTFOLIO',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
            pw.Text(
              '${context.pageNumber} / ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
      ),
    ),
  );
  return document.save();
}

pw.Widget _eyebrow(String text) => pw.Text(
  text,
  style: pw.TextStyle(
    fontSize: 8,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.grey600,
    letterSpacing: 1,
  ),
);

List<pw.Widget> _heading(String text, {double size = 21}) => [
  pw.NewPage(freeSpace: 75),
  pw.SizedBox(height: size > 15 ? 18 : 12),
  pw.Text(
    text,
    style: pw.TextStyle(fontSize: size, fontWeight: pw.FontWeight.bold),
  ),
  pw.SizedBox(height: 8),
  pw.Divider(
    color: PdfColors.grey700,
    thickness: size > 13 ? 1.2 : 0.5,
    height: 1.2,
  ),
  pw.SizedBox(height: 6),
];

List<pw.Widget> _entryHeading(
  String text,
  String period, {
  double size = 11,
}) => [
  pw.NewPage(freeSpace: 65),
  pw.SizedBox(height: 6),
  pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: size, fontWeight: pw.FontWeight.bold),
        ),
      ),
      pw.SizedBox(width: 14),
      pw.Text(
        period,
        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
      ),
    ],
  ),
  pw.SizedBox(height: 6),
];

List<pw.Widget> _label(String text) => [
  pw.NewPage(freeSpace: 45),
  pw.SizedBox(height: 7),
  pw.Text(
    text,
    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
  ),
  pw.SizedBox(height: 4),
];

// Text stays a direct MultiPage child so even a single long paragraph can span.
List<pw.Widget> _paragraph(
  String text, {
  double size = 10,
  bool muted = false,
}) => text.trim().isEmpty
    ? []
    : [
        pw.Text(
          text,
          overflow: pw.TextOverflow.span,
          style: pw.TextStyle(
            fontSize: muted ? 8.5 : size,
            lineSpacing: 4,
            color: muted ? PdfColors.grey600 : PdfColors.grey900,
          ),
        ),
        pw.SizedBox(height: 6),
      ];

List<pw.Widget> _list(Iterable<String> values) => [
  for (final value in values.where((value) => value.trim().isNotEmpty))
    ..._paragraph('• $value'),
];

String _joined(Iterable<String> values, {String separator = ' · '}) =>
    values.where((value) => value.trim().isNotEmpty).join(separator);

List<pw.Widget> _link(String label, String url, {bool showUrl = true}) {
  if (url.trim().isEmpty) return [];
  final uri = Uri.tryParse(url);
  final safe =
      uri != null &&
      ((<String>['https', 'http'].contains(uri.scheme) &&
              uri.host.isNotEmpty) ||
          (uri.scheme == 'mailto' &&
              !uri.hasAuthority &&
              RegExp(r'^[^\s@]+@[^\s@]+$').hasMatch(uri.path)));
  return [
    pw.RichText(
      overflow: pw.TextOverflow.span,
      text: pw.TextSpan(
        text: showUrl ? '$label  $url' : label,
        annotation: safe ? pw.AnnotationUrl(url) : null,
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
    ),
    pw.SizedBox(height: 5),
  ];
}
