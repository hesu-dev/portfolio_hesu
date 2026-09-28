import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/safari_project_page.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';

void main() {
  testWidgets(
    'wide engineering report fills space and groups troubleshooting',
    (tester) async {
      await _pumpReport(tester, _project, const Size(900, 1000));

      expect(
        tester.getSize(find.byKey(const Key('safari-project-page'))).width,
        900,
      );
      for (final title in [
        '프로젝트 구조',
        'Troubleshooting',
        '운영 환경',
        '구조 요약',
        '기술 스택',
        '작업 링크',
      ]) {
        expect(find.text(title), findsOneWidget);
      }
      final troubleshooting = find.byKey(const Key('safari-troubleshooting'));
      for (final kind in [
        PortfolioProjectSectionKind.problem,
        PortfolioProjectSectionKind.cause,
        PortfolioProjectSectionKind.measurement,
        PortfolioProjectSectionKind.solution,
        PortfolioProjectSectionKind.evaluation,
      ]) {
        expect(
          find.descendant(
            of: troubleshooting,
            matching: find.text('${kind.label} 기록'),
          ),
          findsOneWidget,
        );
      }
      expect(find.text('임시 성과 예시: 검증 후 교체할 초안입니다.'), findsOneWidget);
      expect(find.text('공개 배포 채널'), findsOneWidget);
      expect(find.text('Google Play'), findsNWidgets(2));
      expect(find.text('보고서 소개'), findsOneWidget);
      expect(find.text('ENGINEERING REPORT'), findsNothing);
      expect(find.text('play.google.com'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const Key('safari-report-support'))).dy,
        tester.getTopLeft(find.byKey(const Key('safari-project-title'))).dy,
      );
      final environment = tester.getRect(
        find.byKey(const Key('safari-environment-summary')),
      );
      final structure = tester.getRect(
        find.byKey(const Key('safari-structure-summary')),
      );
      expect(environment.top, structure.top);
      expect(environment.right, lessThan(structure.left));
      expect(
        tester.getRect(find.byKey(const Key('safari-report-support'))).left,
        greaterThan(
          tester.getRect(find.byKey(const Key('safari-report-main'))).right,
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'large text stacks report metadata without clipping populated content',
    (tester) async {
      await _pumpReport(tester, _project, const Size(320, 700), scale: 2);
      expect(
        tester.getTopLeft(find.byKey(const Key('safari-report-support'))).dy,
        greaterThanOrEqualTo(
          tester.getBottomLeft(find.byKey(const Key('safari-report-main'))).dy,
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'empty mobile report keeps missing facts explicit without overflow',
    (tester) async {
      await _pumpReport(
        tester,
        const PortfolioProject.constant(
          title: '빈 프로젝트',
          description: '',
          period: '',
          technologies: [],
          links: [],
        ),
        const Size(320, 700),
        scale: 2,
      );

      expect(find.text('등록된 구조 설명이 없습니다.'), findsOneWidget);
      expect(find.text('등록된 트러블슈팅 기록이 없습니다.'), findsOneWidget);
      expect(find.text('등록된 기술 스택이 없습니다.'), findsOneWidget);
      expect(find.text('공개된 작업 링크가 없습니다.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('work links preserve callbacks, loading state and feedback', (
    tester,
  ) async {
    PortfolioProjectLink? opened;
    await _pumpReport(
      tester,
      _project,
      const Size(1600, 1000),
      onOpen: (link) => opened = link,
    );
    final button = find.byKey(const Key('safari-project-link-0'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    expect(opened, _project.links.first);

    await _pumpReport(
      tester,
      _project,
      const Size(1600, 1000),
      pendingLinks: {_project.links.first.uri},
      feedback: '링크를 열 수 없습니다.',
    );
    expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
    expect(find.text('링크를 열 수 없습니다.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

const _project = PortfolioProject.constant(
  title: 'Engineering report',
  description: '보고서 소개',
  period: '2026.01 - 2026.03',
  technologies: ['Flutter', 'Dart'],
  links: [
    PortfolioProjectLink(
      label: 'Google Play',
      url: 'https://play.google.com/store/apps/details?id=example',
    ),
  ],
  highlights: ['구조 설계와 구현'],
  architecture: PortfolioProjectArchitecture.constant(
    title: '입력과 저장 흐름',
    description: '입력을 처리해서 저장합니다.',
    nodes: ['입력', '처리', '저장'],
    presentation: PortfolioArchitecturePresentation.flow,
  ),
  sections: [
    PortfolioProjectSection(
      kind: PortfolioProjectSectionKind.work,
      body: '보고서 소개',
    ),
    PortfolioProjectSection(
      kind: PortfolioProjectSectionKind.problem,
      body: '문제 기록',
    ),
    PortfolioProjectSection(
      kind: PortfolioProjectSectionKind.cause,
      body: '원인 기록',
    ),
    PortfolioProjectSection(
      kind: PortfolioProjectSectionKind.measurement,
      body: '측정 기록',
    ),
    PortfolioProjectSection(
      kind: PortfolioProjectSectionKind.solution,
      body: '해결 기록',
    ),
    PortfolioProjectSection(
      kind: PortfolioProjectSectionKind.evaluation,
      body: '평가 기록',
    ),
    PortfolioProjectSection(
      kind: PortfolioProjectSectionKind.outcome,
      body: '임시 성과 예시: 검증 후 교체할 초안입니다.',
    ),
  ],
);

Future<void> _pumpReport(
  WidgetTester tester,
  PortfolioProject project,
  Size size, {
  double scale = 1,
  Set<Uri> pendingLinks = const {},
  String? feedback,
  ValueChanged<PortfolioProjectLink>? onOpen,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Scaffold(
          body: SingleChildScrollView(
            child: SafariProjectPage(
              project: project,
              compact: size.width < 560,
              onOpenLink: onOpen ?? (_) {},
              pendingLinks: pendingLinks,
              feedback: feedback,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
