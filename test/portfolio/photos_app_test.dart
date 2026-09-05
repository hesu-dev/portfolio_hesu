import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/photos_app.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';

void main() {
  group('Photos gallery', () {
    testWidgets('shows library tabs and a populated code-native photo grid', (
      tester,
    ) async {
      await _pumpPhotos(tester, size: const Size(390, 640), compact: true);

      expect(find.byKey(const Key('photos-app')), findsOneWidget);
      expect(find.byKey(const Key('photos-scroll')), findsOneWidget);
      expect(find.byKey(const Key('photos-library-tab')), findsOneWidget);
      expect(find.byKey(const Key('photos-albums-tab')), findsOneWidget);
      expect(find.byKey(const Key('photos-library-grid')), findsOneWidget);
      expect(find.text('최근 항목'), findsOneWidget);
      expect(find.text('갤러리 콘텐츠는 추후 추가할 예정입니다.'), findsNothing);
      expect(_photoTiles(), findsNWidgets(12));
      expect(_verticalScrollablesInsidePhotos(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

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
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
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
      expect(find.byKey(const Key('photos-album-grid')), findsOneWidget);
      expect(
        find.byKey(const Key('photos-active-album-title')),
        findsOneWidget,
      );
      expect(find.text('일상'), findsWidgets);
      expect(find.byKey(const Key('photos-photo-coffee')), findsOneWidget);
      expect(find.byKey(const Key('photos-photo-workspace')), findsNothing);

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
      expect(tester.takeException(), isNull);
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
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: SizedBox.expand(
        child: PhotosApp(compact: compact, tablet: tablet),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
