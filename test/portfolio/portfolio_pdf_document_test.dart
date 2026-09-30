import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/printing/portfolio_pdf_document.dart';

void main() {
  late ByteData regular;
  late ByteData bold;

  setUpAll(() async {
    regular = ByteData.sublistView(
      await File('assets/pdf_fonts/NanumGothic-Regular.ttf').readAsBytes(),
    );
    bold = ByteData.sublistView(
      await File('assets/pdf_fonts/NanumGothic-Bold.ttf').readAsBytes(),
    );
  });

  test(
    'builds a multipage PDF with embedded selectable Korean fonts',
    () async {
      final bytes = await buildPortfolioPdfDocument(
        portfolioData,
        regularFont: regular,
        boldFont: bold,
        introduction: '자기소개서 내용을 추가할 예정입니다.',
      );
      final source = latin1.decode(bytes);
      expect(source, startsWith('%PDF-'));
      expect(source.trimRight(), endsWith('%%EOF'));
      expect(
        RegExp(r'/Type\s*/Page\b').allMatches(source).length,
        greaterThan(3),
      );
      expect(source, contains('NanumGothic'));
      expect(source, contains('/FontFile2'));
      expect(source, contains('/ToUnicode'));
      expect(source, contains('/URI'));
    },
  );

  test(
    'long introduction and project paragraphs span multiple pages',
    () async {
      final longText = List<String>.filled(
        100,
        '한글로 된 긴 문단도 페이지를 넘기며 끝까지 보존되어야 합니다. 프로젝트의 내용을 설명합니다.',
      ).join('\n');
      final data = PortfolioData(
        identity: portfolioData.identity,
        experiences: const <PortfolioExperience>[],
        education: const <PortfolioEducation>[],
        skillGroups: const <PortfolioSkillGroup>[],
        projects: <PortfolioProject>[
          PortfolioProject(
            title: '긴 프로젝트',
            description: longText,
            period: '',
            technologies: const <String>[],
            links: const <PortfolioProjectLink>[
              PortfolioProjectLink(label: 'Safe', url: 'https://example.com'),
              PortfolioProjectLink(label: 'Unsafe', url: 'javascript:alert(1)'),
            ],
            sections: <PortfolioProjectSection>[
              PortfolioProjectSection(
                kind: PortfolioProjectSectionKind.learning,
                body: longText,
              ),
            ],
          ),
        ],
      );
      final bytes = await buildPortfolioPdfDocument(
        data,
        regularFont: regular,
        boldFont: bold,
        introduction: longText,
      );
      final source = latin1.decode(bytes);
      expect(
        RegExp(r'/Type\s*/Page\b').allMatches(source).length,
        greaterThan(6),
      );
      expect(source, isNot(contains('/URI(javascript:')));
      expect(source.trimRight(), endsWith('%%EOF'));
    },
  );
}
