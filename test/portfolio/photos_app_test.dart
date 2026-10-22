import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/photos_app.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';

void main() {
  group('Photos gallery', () {
    testWidgets('shows a photo library and fixed bottom navigation', (
      tester,
    ) async {
      await _pumpPhotos(tester, size: const Size(390, 640), compact: true);

      expect(find.byKey(const Key('photos-app')), findsOneWidget);
      expect(find.byKey(const Key('photos-scroll')), findsOneWidget);
      expect(find.byKey(const Key('photos-library-tab')), findsOneWidget);
      expect(find.byKey(const Key('photos-albums-tab')), findsOneWidget);
      expect(find.byKey(const Key('photos-library-grid')), findsOneWidget);
      expect(find.text('보관함'), findsWidgets);
      expect(
        tester.getBottomRight(find.byKey(const Key('photos-tab-bar'))).dy,
        640,
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('photos-tab-bar'))).dy,
        greaterThan(500),
      );
      final assets = tester
          .widgetList<Image>(find.byType(Image))
          .map((image) => (image.image as AssetImage).assetName)
          .toSet();
      expect(assets, {for (var i = 1; i <= 12; i++) 'assets/photos/img$i.png'});
      await tester.runAsync(() async {
        final context = tester.element(find.byType(PhotosApp));
        await Future.wait(
          tester
              .widgetList<Image>(find.byType(Image))
              .map((image) => precacheImage(image.image, context)),
        );
      });
      await tester.pumpAndSettle();
      for (final image in tester.widgetList<Image>(find.byType(Image))) {
        final rect = tester.getRect(find.byWidget(image));
        expect(rect.width, greaterThan(120));
        expect(rect.height, greaterThan(120));
      }
      expect(find.text('갤러리 콘텐츠는 추후 추가할 예정입니다.'), findsNothing);
      expect(_photoTiles(), findsNWidgets(12));
      expect(_verticalScrollablesInsidePhotos(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'bottom tabs share a capsule with balanced margins and one safe area',
      (tester) async {
        final semantics = tester.ensureSemantics();
        for (final size in [
          const Size(320, 640),
          const Size(390, 640),
          const Size(834, 700),
        ]) {
          for (final brightness in Brightness.values) {
            for (final scale in [1.0, 2.0]) {
              await tester.pumpWidget(const SizedBox.shrink());
              await _pumpPhotos(
                tester,
                size: size,
                compact: size.width < 600,
                tablet: size.width >= 600,
                brightness: brightness,
                textScaler: TextScaler.linear(scale),
                safePadding: const EdgeInsets.only(bottom: 34),
              );
              final bar = tester.getRect(
                find.byKey(const Key('photos-tab-bar')),
              );
              final capsule = find.byKey(const Key('photos-tab-capsule'));
              expect(capsule, findsOneWidget);
              final bounds = tester.getRect(capsule);
              expect(bar.bottom, size.height - 34);
              expect(bar.bottom - bounds.bottom, 12);
              expect(bounds.top - bar.top, 8);
              expect(bounds.left, greaterThanOrEqualTo(14));
              expect(size.width - bounds.right, greaterThanOrEqualTo(14));
              expect(bounds.center.dx, size.width / 2);
              expect(bounds.width, lessThanOrEqualTo(440));
              final decoration =
                  tester.widget<Container>(capsule).decoration as BoxDecoration;
              expect(decoration.border, isNotNull);
              expect(decoration.borderRadius, BorderRadius.circular(999));
              final library = find.byKey(const Key('photos-library-tab'));
              final albums = find.byKey(const Key('photos-albums-tab'));
              final first = tester.getRect(library);
              final second = tester.getRect(albums);
              expect(first.size, second.size);
              expect(first.height, greaterThanOrEqualTo(44));
              expect(first.top, second.top);
              expect(first.left - bounds.left, bounds.right - second.right);
              expect(second.left - first.right, 4);
              for (final tab in ['library', 'albums']) {
                final surface = tester.widget<AnimatedContainer>(
                  find.byKey(Key('photos-$tab-tab-surface')),
                );
                final shape = surface.decoration as BoxDecoration;
                expect(shape.borderRadius, BorderRadius.circular(999));
                expect(
                  tester.getRect(find.byKey(Key('photos-$tab-tab-surface'))),
                  tester.getRect(find.byKey(Key('photos-$tab-tab'))),
                );
              }
              expect(
                tester
                    .getSemantics(library)
                    .getSemanticsData()
                    .flagsCollection
                    .isSelected,
                ui.Tristate.isTrue,
              );
              await tester.tap(albums);
              await tester.pumpAndSettle();
              expect(tester.getRect(capsule), bounds);
              expect(
                tester
                    .getSemantics(albums)
                    .getSemanticsData()
                    .flagsCollection
                    .isSelected,
                ui.Tristate.isTrue,
              );
              expect(
                find.byKey(const Key('photos-albums-grid')),
                findsOneWidget,
              );
              expect(
                tester.takeException(),
                isNull,
                reason: '$size $brightness scale=$scale',
              );
            }
          }
        }
        semantics.dispose();
      },
    );

    testWidgets('opens a selected photo detail and returns to the gallery', (
      tester,
    ) async {
      await _pumpPhotos(tester, size: const Size(390, 640), compact: true);

      await tester.tap(find.byKey(const Key('photos-photo-coffee')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('photos-library-grid')), findsNothing);
      expect(find.byKey(const Key('photos-detail-view')), findsOneWidget);
      expect(
        find.byKey(const Key('photos-detail-artwork-coffee')),
        findsOneWidget,
      );
      expect(find.text('오후의 커피'), findsOneWidget);
      expect(find.text('2026년 9월 4일 오후 3:24'), findsOneWidget);
      expect(find.byKey(const Key('photos-detail-close')), findsOneWidget);

      await tester.tap(find.byKey(const Key('photos-detail-close')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('photos-detail-view')), findsNothing);
      expect(find.byKey(const Key('photos-library-grid')), findsOneWidget);
      expect(_photoTiles(), findsNWidgets(12));
      expect(tester.takeException(), isNull);
    });

    testWidgets('exposes photo thumbnails as actionable semantic buttons', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpPhotos(tester, size: const Size(390, 640), compact: true);

      final node = tester.getSemantics(
        find.byKey(const Key('photos-photo-coffee')),
      );

      expect(node.label, '오후의 커피 열기, 일상 앨범');
      expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
      expect(node.getSemanticsData().flagsCollection.isButton, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        tester
            .getSemantics(find.byKey(const Key('photos-photo-coffee')))
            .getSemanticsData()
            .flagsCollection
            .isFocused,
        ui.Tristate.isTrue,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('photos-detail-view')), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('switches to Albums and filters the grid by selected album', (
      tester,
    ) async {
      await _pumpPhotos(tester, size: const Size(390, 640), compact: true);

      await tester.tap(find.byKey(const Key('photos-albums-tab')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('photos-library-grid')), findsNothing);
      expect(find.byKey(const Key('photos-albums-grid')), findsOneWidget);
      expect(find.byKey(const Key('photos-album-grid')), findsNothing);
      expect(find.byType(Image), findsNWidgets(3));

      await tester.tap(find.byKey(const Key('photos-album-work')));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<Text>(find.byKey(const Key('photos-active-album-title')))
            .data,
        '작업',
      );
      expect(find.byKey(const Key('photos-photo-coffee')), findsNothing);
      expect(find.byKey(const Key('photos-photo-workspace')), findsOneWidget);
      expect(_verticalScrollablesInsidePhotos(), findsOneWidget);
      await tester.tap(find.byKey(const Key('photos-photo-workspace')));
      await tester.pumpAndSettle();
      expect(
        (tester
                    .widget<Image>(
                      find.descendant(
                        of: find.byKey(
                          const Key('photos-detail-artwork-workspace'),
                        ),
                        matching: find.byType(Image),
                      ),
                    )
                    .image
                as AssetImage)
            .assetName,
        'assets/photos/img5.png',
      );
      await tester.tap(find.byKey(const Key('photos-detail-close')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('photos-active-album-title')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('photos-album-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('photos-albums-grid')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reports nested visibility until returning to the album list', (
      tester,
    ) async {
      final changes = <bool>[];
      await _pumpPhotos(
        tester,
        size: const Size(390, 640),
        compact: true,
        onDetailVisibilityChanged: changes.add,
      );
      await tester.tap(find.byKey(const Key('photos-albums-tab')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('photos-album-daily')));
      await tester.pumpAndSettle();
      expect(changes.last, isTrue);
      await tester.tap(find.byKey(const Key('photos-photo-coffee')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('photos-detail-close')));
      await tester.pumpAndSettle();
      expect(changes.last, isTrue);
      expect(find.byKey(const Key('photos-album-back')), findsOneWidget);
      await tester.tap(find.byKey(const Key('photos-album-back')));
      await tester.pumpAndSettle();
      expect(changes.last, isFalse);
      expect(find.byKey(const Key('photos-albums-grid')), findsOneWidget);
    });

    testWidgets('adapts the photo column count to compact and wide layouts', (
      tester,
    ) async {
      await _pumpPhotos(tester, size: const Size(390, 640), compact: true);
      expect(_libraryGridDelegate(tester).crossAxisCount, 3);

      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpPhotos(tester, size: const Size(900, 650));
      expect(_libraryGridDelegate(tester).crossAxisCount, 6);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps navigation usable in a short viewport with large text', (
      tester,
    ) async {
      await _pumpPhotos(
        tester,
        size: const Size(320, 180),
        compact: true,
        textScaler: const TextScaler.linear(2),
      );
      final tab = find.byKey(const Key('photos-albums-tab'));
      expect(tab.hitTestable(), findsOneWidget);
      await tester.tap(tab);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('photos-library-tab')).hitTestable(),
        findsOneWidget,
      );
      expect(_verticalScrollablesInsidePhotos(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'keeps tabs and albums usable at 200 percent text in dark mode',
      (tester) async {
        await _pumpPhotos(
          tester,
          size: const Size(320, 420),
          compact: true,
          brightness: Brightness.dark,
          textScaler: const TextScaler.linear(2),
        );

        await tester.tap(find.byKey(const Key('photos-albums-tab')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const Key('photos-album-travel')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('photos-album-travel')));
        await tester.pumpAndSettle();

        expect(
          tester
              .widget<Text>(find.byKey(const Key('photos-active-album-title')))
              .data,
          '여행',
        );
        expect(_verticalScrollablesInsidePhotos(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}

Finder _photoTiles() {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> && key.value.startsWith('photos-photo-');
  });
}

Finder _verticalScrollablesInsidePhotos() {
  return find.descendant(
    of: find.byKey(const Key('photos-scroll')),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          (widget.axisDirection == AxisDirection.down ||
              widget.axisDirection == AxisDirection.up),
    ),
  );
}

SliverGridDelegateWithFixedCrossAxisCount _libraryGridDelegate(
  WidgetTester tester,
) {
  final grid = tester.widget<SliverGrid>(
    find.byKey(const Key('photos-library-grid')),
  );
  return grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
}

Future<void> _pumpPhotos(
  WidgetTester tester, {
  required Size size,
  bool compact = false,
  bool tablet = false,
  Brightness brightness = Brightness.light,
  TextScaler textScaler = TextScaler.noScaling,
  EdgeInsets safePadding = EdgeInsets.zero,
  ValueChanged<bool>? onDetailVisibilityChanged,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.light(),
      darkTheme: AppleTheme.dark(),
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: textScaler,
          padding: safePadding,
          viewPadding: safePadding,
        ),
        child: child!,
      ),
      home: SizedBox.expand(
        child: PhotosApp(
          compact: compact,
          tablet: tablet,
          onDetailVisibilityChanged: onDetailVisibilityChanged,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
