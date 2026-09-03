import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';

void main() {
  testWidgets('feedback banners announce asynchronous updates', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppleTheme.light(),
        home: const Material(
          child: AppleFeedbackBanner(
            key: Key('feedback-banner'),
            message: '링크를 열었습니다.',
            success: true,
          ),
        ),
      ),
    );

    final data = tester
        .getSemantics(find.byKey(const Key('feedback-banner')))
        .getSemanticsData();
    expect(data.flagsCollection.isLiveRegion, isTrue);
    semantics.dispose();
  });
}
