import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:portfolio_hesu/main.dart';
import 'package:portfolio_hesu/platform/browser_environment.dart';
import 'package:portfolio_hesu/views/sections/project/project.dart';
import 'package:portfolio_hesu/views/sections/project/project_item.dart';
import 'package:portfolio_hesu/views/widgets/animation/bounce_arrow_btn.dart';
import 'package:portfolio_hesu/views/widgets/custom_card.dart';

class FakeBrowserEnvironment implements BrowserEnvironment {
  FakeBrowserEnvironment({this.pageIndex = 0, bool isPrintMode = false})
    : _isPrintMode = isPrintMode;

  int pageIndex;

  bool _isPrintMode;
  final StreamController<bool> _printModeController =
      StreamController<bool>.broadcast();

  @override
  bool get isPrintMode => _isPrintMode;

  @override
  Stream<bool> get onPrintModeChanged => _printModeController.stream;

  void setPrintMode(bool value) {
    if (_isPrintMode == value) return;
    _isPrintMode = value;
    _printModeController.add(value);
  }

  @override
  int loadPageIndex() => pageIndex;

  @override
  void savePageIndex(int index) {
    pageIndex = index;
  }
}

void main() {
  testWidgets('keeps paged home layout during normal browsing', (tester) async {
    final browserEnvironment = FakeBrowserEnvironment();

    await tester.pumpWidget(
      PortfolioClone(browserEnvironment: browserEnvironment),
    );

    expect(find.byType(PageView), findsOneWidget);
    expect(find.byType(BounceArrowButton), findsWidgets);
  });

  testWidgets('switches to a continuous print layout for printing', (
    tester,
  ) async {
    final browserEnvironment = FakeBrowserEnvironment();

    await tester.pumpWidget(
      PortfolioClone(browserEnvironment: browserEnvironment),
    );

    browserEnvironment.setPrintMode(true);
    await tester.pump();

    expect(find.byType(PageView), findsNothing);
    expect(find.byType(BounceArrowButton), findsNothing);
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Skills'), findsOneWidget);
  });

  testWidgets('lays out project cards with dates without vertical overflow', (
    tester,
  ) async {
    final flutterErrors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = flutterErrors.add;
    addTearDown(() {
      FlutterError.onError = previousOnError;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 260,
                child: ProjectsGrid(
                  items: const [
                    Project(
                      'APP : Blue Mentor Develop',
                      '블루멘토 기계점검 안전설비 보고서 작성 어플 기획 및 개발',
                      ['Flutter', 'Dart', 'node.js'],
                      'https://play.google.com/store/apps/details?id=com.lsmk.BlueMentor',
                      'https://apps.apple.com/us/app/%EB%B8%94%EB%A3%A8%EB%A9%98%ED%86%A0/id6475704951',
                      '2023-012-04~2023, 7, 17',
                      '',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    FlutterError.onError = previousOnError;

    expect(
      flutterErrors
          .where(
            (error) =>
                error.exceptionAsString().contains('A RenderFlex overflowed'),
          )
          .toList(),
      isEmpty,
    );
  });

  testWidgets('keeps project card actions close to the bottom edge', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 260,
                child: ProjectsGrid(
                  items: const [
                    Project(
                      'APP : ReadingLog Develop',
                      '채팅로그 리더기 어플 기획 및 개발 및 크롬 웹스토어 확장프로그램 개발.',
                      ['Flutter', 'Dart', 'node.js'],
                      'https://play.google.com/store/apps/details?id=com.reha.readinglog',
                      'https://apps.apple.com/kr/app/%EB%A6%AC%EB%94%A9%EB%A1%9C%EA%B7%B8/id6759693995',
                      '2026-02 ~ 2026-5',
                      'https://chromewebstore.google.com/detail/r20-jsonexporter/galgbmfkkpehcijjfcaffifmfjbmlfbo',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cardRect = tester.getRect(find.byType(CustomCard));
    final actionRect = tester.getRect(
      find.widgetWithIcon(IconButton, FontAwesomeIcons.link),
    );

    expect(cardRect.bottom - actionRect.bottom, lessThanOrEqualTo(24));
  });
}
