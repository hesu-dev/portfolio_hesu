import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/widgets/project_app_icon.dart';

void main() {
  testWidgets('AIQ keeps a full white square in either theme', (tester) async {
    for (final dark in [false, true]) {
      for (final size in [40.0, 58.0, 120.0]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppleTheme.dark() : AppleTheme.light(),
            home: Scaffold(
              body: Center(
                child: ProjectAppIcon(
                  assetPath: 'assets/icons/projects/aiq.png',
                  size: size,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final background = find.byKey(const Key('project-icon-aiq-background'));
        expect(background, findsOneWidget);
        expect(tester.getSize(background), Size.square(size));
        expect(
          (tester.widget<Container>(background).decoration as BoxDecoration)
              .color,
          Colors.white,
        );
        final logo = tester.widget<Image>(find.byType(Image));
        expect(
          (logo.image as AssetImage).assetName,
          'assets/icons/projects/aiq.png',
        );
        expect(logo.fit, BoxFit.contain);
        expect(tester.takeException(), isNull);
      }
    }
    expect(
      ProjectAppIcon.hasOwnBackground('assets/icons/projects/aiq.png'),
      isTrue,
    );
  });

  testWidgets(
    'IRIS keeps a full white square and vector logo in either theme',
    (tester) async {
      for (final dark in [false, true]) {
        for (final size in [40.0, 58.0, 120.0]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppleTheme.dark() : AppleTheme.light(),
              home: Scaffold(
                body: Center(
                  child: ProjectAppIcon(
                    assetPath: 'assets/icons/projects/iris.svg',
                    size: size,
                    alignment: Alignment.center,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final background = find.byKey(
            const Key('project-icon-iris-background'),
          );
          expect(background, findsOneWidget);
          expect(tester.getSize(background), Size.square(size));
          final container = tester.widget<Container>(background);
          expect((container.decoration as BoxDecoration).color, Colors.white);
          final logo = tester.widget<SvgPicture>(find.byType(SvgPicture));
          expect(
            (logo.bytesLoader as SvgAssetLoader).assetName,
            'assets/icons/projects/iris.svg',
          );
          expect(logo.fit, BoxFit.contain);
          expect(tester.takeException(), isNull);
        }
      }
      expect(
        ProjectAppIcon.hasOwnBackground('assets/icons/projects/iris.svg'),
        isTrue,
      );
    },
  );
}
