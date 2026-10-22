import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/projects_app.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/widgets/apple_app_artwork.dart';

void main() {
  testWidgets('Recent icons and labels share geometry in both themes', (
    tester,
  ) async {
    for (final width in [390.0, 834.0, 1100.0]) {
      for (final dark in [false, true]) {
        for (final scale in [1.0, 2.0]) {
          await _pumpFiles(tester, width: width, dark: dark, scale: scale);
          await tester.tap(
            find.byKey(const Key('projects-finder-location-recent')),
          );
          await tester.pumpAndSettle();
          final keys = [
            for (var i = 0; i < portfolioData.projects.length; i++)
              Key('project-selector-$i'),
            for (final app in [
              'music',
              'photos',
              'mail',
              'trash',
              if (width < 1024) 'printer' else 'settings',
            ])
              Key('projects-recent-app-$app'),
          ];
          Rect? referenceFrame;
          double? referenceTop;
          double? referenceLabelTop;
          for (final key in keys) {
            final tile = find.byKey(key);
            final frame = find.descendant(
              of: tile,
              matching: find.byKey(const Key('apple-finder-icon-background')),
            );
            expect(frame, findsOneWidget, reason: '$width/$dark/$scale/$key');
            final bounds = tester.getRect(tile);
            final rect = tester.getRect(frame);
            referenceFrame ??= rect;
            referenceTop ??= rect.top - bounds.top;
            expect(rect.width, closeTo(referenceFrame.width, 0.01));
            expect(rect.height, closeTo(referenceFrame.height, 0.01));
            expect(rect.width, closeTo(rect.height, 0.01));
            expect(rect.center.dx, closeTo(bounds.center.dx, 0.01));
            expect(rect.top - bounds.top, closeTo(referenceTop, 0.01));
            final background = tester.widget<AnimatedContainer>(frame);
            final decoration = background.decoration! as BoxDecoration;
            final context = tester.element(frame);
            final size = background.constraints!.maxWidth;
            final finish = background.foregroundDecoration;
            expect(
              finish,
              isA<BoxDecoration>(),
              reason: '$key shares the finish',
            );
            final glass = finish! as BoxDecoration;
            final border = glass.border! as Border;
            expect(border.top.color, Colors.white.withValues(alpha: 0.44));
            expect(border.top.width, closeTo(size * 0.014, 0.01));
            expect(glass.borderRadius, BorderRadius.circular(size * 0.24));
            expect(
              glass.gradient,
              const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x38FFFFFF), Color(0x00FFFFFF)],
                stops: [0, 0.62],
              ),
            );
            for (final artwork
                in find
                    .descendant(
                      of: frame,
                      matching: find.byType(AppleAppArtwork),
                    )
                    .evaluate()) {
              expect(
                find.descendant(
                  of: find.byWidget(artwork.widget),
                  matching: find.byWidgetPredicate(
                    (widget) =>
                        widget is DecoratedBox &&
                        widget.decoration is BoxDecoration &&
                        (widget.decoration as BoxDecoration).border != null,
                  ),
                ),
                findsNothing,
                reason: '$key does not double its border',
              );
            }
            final needsBackground = {
              const Key('project-selector-3'),
              const Key('projects-recent-app-trash'),
              const Key('projects-recent-app-printer'),
            }.contains(key);
            if (needsBackground) {
              expect(decoration.color, AppleTheme.surface(context));
              expect(
                decoration.borderRadius,
                BorderRadius.circular(size * 0.24),
              );
              expect(background.clipBehavior, Clip.antiAlias);
              expect(background.padding, EdgeInsets.all(size * 0.1));
            } else {
              expect(
                decoration.color,
                isNull,
                reason: '$key keeps its own background',
              );
              expect(decoration.borderRadius, isNull);
              expect(background.clipBehavior, Clip.none);
              expect(background.padding, EdgeInsets.zero);
              final fitted = find
                  .descendant(of: frame, matching: find.byType(FittedBox))
                  .first;
              expect(tester.getRect(fitted).width, closeTo(size, 0.01));
              expect(tester.getRect(fitted).height, closeTo(size, 0.01));
            }
            final label = find.descendant(
              of: tile,
              matching: find.byKey(const Key('apple-finder-folder-label')),
            );
            expect(label, findsOneWidget);
            final labelRect = tester.getRect(label);
            referenceLabelTop ??= labelRect.top - bounds.top;
            expect(
              labelRect.top - bounds.top,
              closeTo(referenceLabelTop, 0.01),
            );
            expect(labelRect.center.dx, closeTo(bounds.center.dx, 0.01));
          }
          expect(tester.takeException(), isNull);
        }
      }
    }
  });

  testWidgets('Files list adds backgrounds only to transparent shortcuts', (
    tester,
  ) async {
    for (final dark in [false, true]) {
      await _pumpFiles(tester, width: 390, dark: dark);
      await tester.tap(find.byKey(const Key('projects-finder-more')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('projects-view-list')));
      await tester.pumpAndSettle();
      for (final app in ['music', 'photos', 'mail', 'trash', 'printer']) {
        final frame = find.descendant(
          of: find.byKey(Key('projects-files-app-$app')),
          matching: find.byKey(const Key('apple-finder-icon-background')),
        );
        expect(tester.getSize(frame), const Size.square(40));
        final container = tester.widget<AnimatedContainer>(frame);
        final decoration = container.decoration! as BoxDecoration;
        final transparent = app == 'trash' || app == 'printer';
        expect(
          decoration.color,
          transparent ? AppleTheme.surface(tester.element(frame)) : isNull,
        );
        expect(
          decoration.borderRadius,
          transparent ? BorderRadius.circular(9.6) : isNull,
        );
        expect(
          container.clipBehavior,
          transparent ? Clip.antiAlias : Clip.none,
        );
      }
      expect(tester.takeException(), isNull);
    }
  });
}

Future<void> _pumpFiles(
  WidgetTester tester, {
  required double width,
  required bool dark,
  double scale = 1,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 1800);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? AppleTheme.dark() : AppleTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: ProjectsApp(
          compact: width < 600,
          tablet: width >= 600 && width < 1024,
          data: portfolioData,
          launcher: CallbackExternalLauncher((_) async => true),
          onOpenApp: (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
