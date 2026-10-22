import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/data/project_architecture.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/widgets/project_architecture_diagram.dart';

const _diagram = PortfolioArchitectureDiagram(
  width: 800,
  height: 400,
  summary: 'Flutter 클라이언트가 API를 통해 저장소를 사용합니다.',
  nodes: [
    PortfolioArchitectureNode(
      id: 'client',
      label: 'Flutter',
      detail: '사용자 화면',
      icon: 'flutter',
      x: 130,
      y: 180,
    ),
    PortfolioArchitectureNode(
      id: 'api',
      label: 'API',
      detail: '요청 처리',
      icon: 'server',
      x: 410,
      y: 180,
    ),
    PortfolioArchitectureNode(
      id: 'storage',
      label: '저장소',
      detail: '파일 보관',
      icon: 'storage',
      x: 670,
      y: 180,
    ),
  ],
  edges: [
    PortfolioArchitectureEdge(from: 'client', to: 'api', label: 'HTTPS'),
    PortfolioArchitectureEdge(from: 'api', to: 'storage', label: '업로드'),
  ],
  groups: [
    PortfolioArchitectureGroup(
      label: '서버',
      x: 310,
      y: 70,
      width: 450,
      height: 220,
    ),
  ],
);

void main() {
  testWidgets(
    'diagram exposes directed relationships to assistive technology',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester);

      expect(find.byKey(const Key('architecture-diagram')), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Flutter.*API.*HTTPS', dotAll: true)),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('API.*저장소.*업로드', dotAll: true)),
        findsOneWidget,
      );
      expect(find.text('Flutter'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('expanded diagram can zoom and closes back to the page', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('architecture-expand')));
    await tester.pumpAndSettle();

    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(viewer.maxScale, greaterThan(1));
    expect(viewer.panEnabled, isTrue);
    await tester.tap(find.byKey(const Key('architecture-close')));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsNothing);
    expect(find.byKey(const Key('architecture-expand')), findsOneWidget);
  });

  testWidgets('zoom controls magnify around the viewport center and reset', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('architecture-expand')));
    await tester.pumpAndSettle();
    final viewerFinder = find.byType(InteractiveViewer);
    final controller = tester
        .widget<InteractiveViewer>(viewerFinder)
        .transformationController!;
    final initial = controller.value.clone();
    final center = tester.getSize(viewerFinder).center(Offset.zero);
    final initialSceneCenter = controller.toScene(center);
    final zoomIn = find.byKey(const Key('architecture-zoom-in'));
    final zoomOut = find.byKey(const Key('architecture-zoom-out'));
    final reset = find.byKey(const Key('architecture-zoom-reset'));
    for (final button in [zoomIn, zoomOut, reset]) {
      expect(tester.getSize(button).shortestSide, greaterThanOrEqualTo(44));
    }

    await tester.tap(zoomIn);
    await tester.pump();
    final enlargedScale = controller.value.getMaxScaleOnAxis();
    expect(enlargedScale, greaterThan(initial.getMaxScaleOnAxis()));
    expect(
      (controller.toScene(center) - initialSceneCenter).distance,
      lessThan(0.001),
    );
    await tester.tap(zoomOut);
    await tester.pump();
    expect(controller.value.getMaxScaleOnAxis(), lessThan(enlargedScale));
    await tester.tap(zoomIn);
    await tester.pump();
    await tester.tap(reset);
    await tester.pump();
    expect(controller.value, initial);
  });

  for (final dark in [false, true]) {
    testWidgets('320px diagram stays legible with 200% text, dark=$dark', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pump(tester, dark: dark, scale: 2);

      expect(tester.takeException(), isNull);
      final scroller = find.byKey(const Key('architecture-scroll'));
      expect(scroller, findsOneWidget);
      await tester.drag(scroller, const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('architecture-expand')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('architecture-close')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _pump(
  WidgetTester tester, {
  bool dark = false,
  double scale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? AppleTheme.dark() : AppleTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: const Scaffold(
        body: SingleChildScrollView(
          child: ProjectArchitectureDiagram(diagram: _diagram),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
