import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_introduction.dart';
import 'package:portfolio_hesu/portfolio/models/introduction_section.dart';

void main() {
  test(
    'preserves six headings and every bullet without dropping source text',
    () {
      final sections = introductionSections(portfolioIntroduction);
      expect(sections, hasLength(6));
      expect(sections.first.title, '1. 자기소개');
      expect(sections.last.title, '6. 입사 후 기여');
      final restored = sections
          .map(
            (section) =>
                '${section.title}\n${section.paragraphs.map((line) => '- $line').join('\n')}',
          )
          .join('\n\n');
      expect(restored, portfolioIntroduction);
    },
  );

  test('supports plain biographies, empty input, and Windows line endings', () {
    expect(introductionSections('  '), isEmpty);
    final plain = introductionSections('plain text\nwith line breaks');
    expect(plain.single.title, isNull);
    expect(plain.single.paragraphs, ['plain text\nwith line breaks']);
    final numbered = introductionSections(
      '1. First\r\n- Item\r\n\r\n2. Next\r\n• More',
    );
    expect(numbered.map((section) => section.paragraphs.single), [
      'Item',
      'More',
    ]);
  });
}
