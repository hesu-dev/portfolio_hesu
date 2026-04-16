import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/main.dart';
import 'package:portfolio_hesu/platform/browser_environment.dart';
import 'package:portfolio_hesu/views/widgets/animation/bounce_arrow_btn.dart';

class FakeBrowserEnvironment implements BrowserEnvironment {
  FakeBrowserEnvironment({
    this.pageIndex = 0,
    bool isPrintMode = false,
  }) : _isPrintMode = isPrintMode;

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
}
