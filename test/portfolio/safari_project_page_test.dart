import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/safari_project_page.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';

void main() {
  testWidgets('project details explain decisions and show icon architecture', (
    tester,
  ) async {
    for (final project in portfolioData.projects) {
      await _pumpReport(tester, project, const Size(1200, 1000));
      expect(find.text('핵심 기술'), findsOneWidget, reason: project.title);
      expect(find.text('기술 의사결정'), findsOneWidget, reason: project.title);
      expect(
        find.byKey(const Key('architecture-diagram')),
        findsOneWidget,
        reason: project.title,
      );
      expect(
        tester.getTopLeft(find.text('기술 의사결정')).dy,
        greaterThan(tester.getTopLeft(find.text('프로젝트 구조')).dy),
        reason: project.title,
      );
      final summary = find.byKey(const Key('safari-structure-summary'));
      for (final node in project.architecture!.diagram!.nodes) {
        expect(
          find.descendant(
            of: summary,
            matching: find.textContaining(node.label),
          ),
          findsWidgets,
          reason: '${project.title}: ${node.label}',
        );
        if (node.detail.isNotEmpty) {
          expect(
            find.descendant(
              of: summary,
              matching: find.textContaining(node.detail),
            ),
            findsWidgets,
          );
        }
      }
      expect(tester.takeException(), isNull, reason: project.title);
    }
  });

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
      expect(find.text('Google Play'), findsOneWidget);
      expect(find.text('보고서 소개'), findsOneWidget);
      expect(find.text('ENGINEERING REPORT'), findsNothing);
      expect(find.text('play.google.com'), findsNothing);
      final title = tester.getRect(
        find.byKey(const Key('safari-project-title')),
      );
      final icon = tester.getRect(find.byKey(const Key('project-detail-icon')));
      expect(title.left, greaterThan(icon.right));
      expect(
        tester.getRect(find.text(_project.period)).top,
        greaterThanOrEqualTo(title.bottom),
      );
      final link = find.byKey(const Key('safari-project-link-0'));
      expect(
        find.descendant(of: link, matching: find.byType(Text)),
        findsNothing,
      );
      expect(
        tester.getRect(link).top,
        lessThan(tester.getRect(find.text('프로젝트 구조')).top),
      );
      expect(find.text('작업 링크'), findsNothing);
      expect(find.text('1. 입력'), findsOneWidget);
      expect(find.text('2. 처리'), findsOneWidget);
      expect(find.text('3. 저장'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const Key('safari-report-support'))).dy,
        tester.getTopLeft(find.byKey(const Key('safari-report-main'))).dy,
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
        tester.getTopLeft(find.byKey(const Key('safari-report-main'))).dy,
        greaterThanOrEqualTo(
          tester
              .getBottomLeft(find.byKey(const Key('safari-report-support')))
              .dy,
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
      expect(find.byKey(const Key('safari-project-link-0')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('work links align left with a lower-right link badge', (
    tester,
  ) async {
    for (final width in [390.0, 1200.0]) {
      await _pumpReport(tester, _project, Size(width, 1000));
      final button = find.byKey(const Key('safari-project-link-0'));
      final bounds = tester.getRect(button);
      expect(
        bounds.left,
        tester.getRect(find.byKey(const Key('safari-project-page'))).left,
      );
      expect(bounds.width, greaterThanOrEqualTo(44));
      expect(bounds.height, greaterThanOrEqualTo(44));
      final destination = find.descendant(
        of: button,
        matching: find.byIcon(Icons.play_arrow_rounded),
      );
      final badge = find.descendant(
        of: button,
        matching: find.byIcon(Icons.link_rounded),
      );
      expect(badge, findsOneWidget);
      expect(
        find.descendant(
          of: button,
          matching: find.byIcon(Icons.north_east_rounded),
        ),
        findsNothing,
      );
      final iconBounds = tester.getRect(destination);
      final badgeBounds = tester.getRect(badge);
      expect(badgeBounds.center.dx, greaterThan(iconBounds.center.dx));
      expect(badgeBounds.center.dy, greaterThan(iconBounds.center.dy));
      expect(bounds.contains(badgeBounds.bottomRight), isTrue);
      expect(
        find.descendant(of: button, matching: find.byType(Text)),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    }
  });

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
    final title = tester.widget<Text>(
      find.byKey(const Key('safari-project-title')),
    );
    expect(title.style?.color, AppleTheme.light().textTheme.bodyMedium?.color);
    expect(
      tester.widget<Text>(find.text('프로젝트 구조')).style?.color,
      title.style?.color,
    );
    await tester.ensureVisible(button);
    await tester.tap(button);
    expect(opened, _project.links.first);

    await _pumpReport(
      tester,
      _project,
      const Size(1600, 1000),
      pendingLinks: {_project.links.first.uri},
      feedback: '링크를 열 수 없습니다.',
      theme: AppleTheme.dark(),
    );
    await tester.pumpAndSettle();
    final darkTitle = tester.widget<Text>(
      find.byKey(const Key('safari-project-title')),
    );
    expect(
      darkTitle.style?.color,
      AppleTheme.dark().textTheme.bodyMedium?.color,
    );
    expect(
      tester.widget<Text>(find.text('프로젝트 구조')).style?.color,
      darkTitle.style?.color,
    );
    expect(
      tester.widget<OutlinedButton>(button).style?.foregroundColor?.resolve({}),
      darkTitle.style?.color,
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
  ThemeData? theme,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppleTheme.light(),
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
