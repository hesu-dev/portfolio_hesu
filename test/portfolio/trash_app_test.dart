import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/system_apps.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';
import 'package:portfolio_hesu/portfolio/portfolio_app.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/widgets/apple_app_artwork.dart';

void main() {
  testWidgets('Trash shows temporary items and only empties after Y', (
    tester,
  ) async {
    var emptyRequests = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppleTheme.light(),
        home: Scaffold(
          body: TrashApp(
            data: portfolioData,
            onTrashEmptied: () => emptyRequests++,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('trash-item-0')), findsOneWidget);
    expect(find.byKey(const Key('trash-item-1')), findsOneWidget);
    expect(find.byKey(const Key('trash-item-2')), findsOneWidget);
    expect(find.text('Trash is Empty'), findsNothing);

    await tester.tap(find.byKey(const Key('trash-empty-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('trash-empty-dialog')), findsOneWidget);
    expect(find.text('휴지통을 비우겠습니까?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('trash-empty-cancel')));
    await tester.pumpAndSettle();
    expect(emptyRequests, 0);
    expect(find.byKey(const Key('trash-item-0')), findsOneWidget);

    await tester.tap(find.byKey(const Key('trash-empty-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('trash-empty-confirm')));
    await tester.pumpAndSettle();

    expect(emptyRequests, 1);
    expect(find.byKey(const Key('trash-item-0')), findsNothing);
    expect(find.byKey(const Key('trash-empty-state')), findsOneWidget);
    expect(find.text('Trash is Empty'), findsOneWidget);
  });

  testWidgets('Y key confirms emptying the Trash', (tester) async {
    var emptied = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppleTheme.light(),
        home: Scaffold(
          body: TrashApp(
            data: portfolioData,
            onTrashEmptied: () => emptied = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('trash-empty-button')));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyY);
    await tester.pumpAndSettle();

    expect(emptied, isTrue);
    expect(find.byKey(const Key('trash-empty-state')), findsOneWidget);
  });

  testWidgets('Trash artwork switches between filled and empty states', (
    tester,
  ) async {
    Future<void> pump({required bool empty}) {
      return tester.pumpWidget(
        MaterialApp(
          theme: AppleTheme.light(),
          home: Center(
            child: AppleAppArtworkFrame(
              appId: PortfolioAppId.trash,
              size: 72,
              trashEmpty: empty,
            ),
          ),
        ),
      );
    }

    await pump(empty: false);
    expect(
      find.byKey(const Key('apple-app-artwork-trash-filled')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('apple-app-artwork-trash-empty')),
      findsNothing,
    );

    await pump(empty: true);
    expect(
      find.byKey(const Key('apple-app-artwork-trash-filled')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('apple-app-artwork-trash-empty')),
      findsOneWidget,
    );
  });

  testWidgets('empty Trash state updates Dock and survives a shell resize', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    tester.view.physicalSize = const Size(1200, 800);

    await tester.pumpWidget(const PortfolioApp());
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('dock-app-trash')),
        matching: find.byKey(const Key('apple-app-artwork-trash-filled')),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('dock-app-trash')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('trash-empty-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('trash-empty-confirm')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('dock-app-trash')),
        matching: find.byKey(const Key('apple-app-artwork-trash-empty')),
      ),
      findsOneWidget,
    );

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    final homeTrash = find.byKey(const Key('home-app-trash'));
    await tester.ensureVisible(homeTrash);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: homeTrash,
        matching: find.byKey(const Key('apple-app-artwork-trash-empty')),
      ),
      findsOneWidget,
    );
  });
}
