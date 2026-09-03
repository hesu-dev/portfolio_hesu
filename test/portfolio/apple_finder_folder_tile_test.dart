import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/widgets/apple_finder_scaffold.dart';

void main() {
  testWidgets(
    'selected tile keeps folder artwork unchanged and uses neutral surfaces',
    (tester) async {
      await _pumpTilePair(tester);

      final unselected = find.byKey(const Key('folder-tile-unselected'));
      final selected = find.byKey(const Key('folder-tile-selected'));
      final unselectedArtwork = _folderArtwork(tester, unselected);
      final selectedArtwork = _folderArtwork(tester, selected);

      expect(selectedArtwork.icon, unselectedArtwork.icon);
      expect(selectedArtwork.color, unselectedArtwork.color);
      expect(selectedArtwork.size, unselectedArtwork.size);
      expect(
        find.descendant(of: selected, matching: find.byType(Opacity)),
        findsNothing,
      );
      expect(
        find.descendant(of: selected, matching: find.byType(CustomPaint)),
        findsNothing,
      );

      final unselectedDecoration = _tileDecoration(tester, unselected);
      final selectedDecoration = _tileDecoration(tester, selected);
      expect(unselectedDecoration.color, Colors.transparent);
      expect(selectedDecoration.color, isNot(Colors.transparent));
      expect(_isNeutralGray(selectedDecoration.color!), isTrue);
      expect(
        selectedDecoration.color,
        isNot(
          AppleTheme.selectionBackground(
            tester.element(selected),
            AppleTheme.blue,
          ),
        ),
      );
      expect(selectedDecoration.border, isNull);

      final unselectedLabel = _labelText(tester, unselected, 'A');
      final selectedLabel = _labelText(tester, selected, 'Selected name');
      expect(selectedLabel.style?.color, unselectedLabel.style?.color);
      expect(
        selectedLabel.style?.fontWeight,
        unselectedLabel.style?.fontWeight,
      );
      expect(selectedLabel.style?.color, isNot(AppleTheme.blue));

      final selectedLabelSurface = find.descendant(
        of: selected,
        matching: find.byKey(const Key('apple-finder-folder-label-background')),
      );
      expect(selectedLabelSurface, findsOneWidget);
      final labelDecoration =
          tester.widget<DecoratedBox>(selectedLabelSurface).decoration
              as BoxDecoration;
      expect(_isNeutralGray(labelDecoration.color!), isTrue);
      expect(labelDecoration.border, isNull);
    },
  );

  testWidgets(
    'long names wrap and keep every tile and artwork aligned at fixed height',
    (tester) async {
      for (final scenario
          in const <
            ({
              Size viewport,
              double tileWidth,
              bool compact,
              TextScaler textScaler,
            })
          >[
            (
              viewport: Size(320, 480),
              tileWidth: 144,
              compact: true,
              textScaler: TextScaler.linear(2),
            ),
            (
              viewport: Size(700, 500),
              tileWidth: 180,
              compact: false,
              textScaler: TextScaler.noScaling,
            ),
          ]) {
        await _pumpTilePair(
          tester,
          viewport: scenario.viewport,
          tileWidth: scenario.tileWidth,
          compact: scenario.compact,
          textScaler: scenario.textScaler,
          longLabel: '아주 긴 프로젝트 폴더 이름으로 두 줄 개행 확인',
        );

        final shortTile = find.byKey(const Key('folder-tile-unselected'));
        final longTile = find.byKey(const Key('folder-tile-selected'));
        final shortArtwork = _folderArtworkFinder(shortTile);
        final longArtwork = _folderArtworkFinder(longTile);
        final shortLabel = find.descendant(
          of: shortTile,
          matching: find.text('A'),
        );
        final longLabel = find.descendant(
          of: longTile,
          matching: find.text('아주 긴 프로젝트 폴더 이름으로 두 줄 개행 확인'),
        );

        expect(
          tester.getSize(shortTile).height,
          tester.getSize(longTile).height,
        );
        expect(
          tester.getTopLeft(shortArtwork).dy,
          closeTo(tester.getTopLeft(longArtwork).dy, 0.01),
        );
        expect(
          tester.getTopLeft(shortLabel).dy,
          closeTo(tester.getTopLeft(longLabel).dy, 0.01),
        );
        expect(
          tester.getSize(longLabel).height,
          greaterThan(tester.getSize(shortLabel).height),
        );

        final longText = tester.widget<Text>(longLabel);
        expect(longText.maxLines, 2);
        expect(longText.overflow, TextOverflow.ellipsis);
        expect(tester.takeException(), isNull, reason: '${scenario.viewport}');
      }
    },
  );
}

Future<void> _pumpTilePair(
  WidgetTester tester, {
  Size viewport = const Size(500, 300),
  double tileWidth = 180,
  bool compact = false,
  TextScaler textScaler = TextScaler.noScaling,
  String longLabel = 'Selected name',
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = viewport;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(size: viewport, textScaler: textScaler),
        child: Material(
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: tileWidth,
                  child: AppleFinderFolderTile(
                    key: const Key('folder-tile-unselected'),
                    label: 'A',
                    semanticsLabel: 'A open',
                    compact: compact,
                    onPressed: () {},
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: AppleFinderFolderTile(
                    key: const Key('folder-tile-selected'),
                    label: longLabel,
                    semanticsLabel: '$longLabel open',
                    compact: compact,
                    selected: true,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Icon _folderArtwork(WidgetTester tester, Finder tile) =>
    tester.widget<Icon>(_folderArtworkFinder(tile));

Finder _folderArtworkFinder(Finder tile) => find.descendant(
  of: tile,
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is Icon &&
        (widget.icon == Icons.folder_rounded ||
            widget.icon == Icons.folder_open_rounded),
    description: 'Finder folder artwork icon',
  ),
);

BoxDecoration _tileDecoration(WidgetTester tester, Finder tile) =>
    tester
            .widget<AnimatedContainer>(
              find.descendant(
                of: tile,
                matching: find.byType(AnimatedContainer),
              ),
            )
            .decoration
        as BoxDecoration;

Text _labelText(WidgetTester tester, Finder tile, String label) =>
    tester.widget<Text>(find.descendant(of: tile, matching: find.text(label)));

bool _isNeutralGray(Color color) {
  const tolerance = 0.001;
  return (color.r - color.g).abs() <= tolerance &&
      (color.g - color.b).abs() <= tolerance;
}
