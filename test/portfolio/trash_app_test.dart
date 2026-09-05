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
  testWidgets('휴지통은 한글 파일 목록과 작은 회색 비우기 버튼을 보여준다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppleTheme.light(),
        home: Scaffold(body: TrashApp(data: portfolioData)),
      ),
    );

    expect(find.byKey(const Key('trash-item-0')), findsOneWidget);
    expect(find.byKey(const Key('trash-item-1')), findsOneWidget);
    expect(find.byKey(const Key('trash-item-2')), findsOneWidget);
    expect(find.text('이전-이력서-초안.docx'), findsOneWidget);
    expect(find.text('워드 문서 · 84KB'), findsOneWidget);
    expect(find.text('오늘 오전 10:42'), findsOneWidget);
    expect(find.text('포트폴리오-미리보기.png'), findsOneWidget);
    expect(find.text('PNG 이미지 · 1.8MB'), findsOneWidget);
    expect(find.text('어제 오후 6:16'), findsOneWidget);
    expect(find.text('디버그-기록.log'), findsOneWidget);
    expect(find.text('로그 파일 · 32KB'), findsOneWidget);
    expect(find.text('9월 3일 오후 9:05'), findsOneWidget);

    for (final englishCopy in const <String>[
      'Recently Deleted',
      '3 temporary items',
      'No items',
      'old-resume-draft.docx',
      'Word document · 84 KB',
      'Today, 10:42',
      'portfolio-preview.png',
      'PNG image · 1.8 MB',
      'Yesterday, 18:16',
      'debug-session.log',
      'Log file · 32 KB',
      'Sep 3, 21:05',
      'Empty',
      'Trash is Empty',
      'There are no deleted portfolio items for Heesu Kim.',
    ]) {
      expect(find.text(englishCopy), findsNothing);
    }
    expect(find.text('비우기'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('trash-toolbar')),
        matching: find.byType(Text),
      ),
      findsOneWidget,
    );

    final emptyButtonFinder = find.byKey(const Key('trash-empty-button'));
    final emptyButton = tester.widget<FilledButton>(emptyButtonFinder);
    expect(
      emptyButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      const Color(0xFF6E6E73),
    );
    expect(tester.getSize(emptyButtonFinder).width, lessThan(80));
    expect(
      emptyButton.style?.minimumSize?.resolve(<WidgetState>{}),
      const Size(0, 32),
    );
    expect(
      emptyButton.style?.padding?.resolve(<WidgetState>{}),
      const EdgeInsets.symmetric(horizontal: 12),
    );
  });

  testWidgets('비우기 버튼은 테마별 글자 대비와 44픽셀 터치 영역을 유지한다', (tester) async {
    for (final theme in <ThemeData>[AppleTheme.light(), AppleTheme.dark()]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(body: TrashApp(data: portfolioData)),
        ),
      );

      final emptyButtonFinder = find.byKey(const Key('trash-empty-button'));
      final emptyButton = tester.widget<FilledButton>(emptyButtonFinder);
      final background = emptyButton.style!.backgroundColor!.resolve(
        <WidgetState>{},
      )!;
      final foreground = emptyButton.style!.foregroundColor!.resolve(
        <WidgetState>{},
      )!;

      expect(_contrastRatio(background, foreground), greaterThanOrEqualTo(4.5));
      expect(
        tester.getSize(emptyButtonFinder).height,
        greaterThanOrEqualTo(44),
      );
      final buttonSurface = find.descendant(
        of: emptyButtonFinder,
        matching: find.byType(Material),
      );
      expect(buttonSurface, findsOneWidget);
      expect(tester.getSize(buttonSurface).height, 32);
      expect(
        emptyButton.style?.minimumSize?.resolve(<WidgetState>{}),
        const Size(0, 32),
      );
    }
  });

  testWidgets('휴지통은 한글 확인 모달에서 동의한 뒤에만 비워진다', (tester) async {
    final semantics = tester.ensureSemantics();
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

    await tester.tap(find.byKey(const Key('trash-empty-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('trash-empty-dialog')), findsOneWidget);
    expect(find.text('휴지통을 비우겠습니까?'), findsOneWidget);
    expect(find.text('모든 파일이 삭제됩니다.'), findsOneWidget);
    expect(find.text('아니오'), findsOneWidget);
    expect(find.text('네'), findsOneWidget);
    expect(find.text('N'), findsNothing);
    expect(find.text('Y'), findsNothing);
    expect(find.bySemanticsLabel('Cancel empty Trash'), findsNothing);
    expect(find.bySemanticsLabel('Confirm empty Trash'), findsNothing);
    expect(
      tester
          .getSemantics(find.byKey(const Key('trash-empty-cancel')))
          .getSemanticsData()
          .label,
      '아니오',
    );
    expect(
      tester
          .getSemantics(find.byKey(const Key('trash-empty-confirm')))
          .getSemanticsData()
          .label,
      '네',
    );
    expect(
      tester
          .widget<AlertDialog>(find.byKey(const Key('trash-empty-dialog')))
          .actionsAlignment,
      MainAxisAlignment.spaceBetween,
    );
    expect(
      tester.getCenter(find.byKey(const Key('trash-empty-cancel'))).dx,
      lessThan(
        tester.getCenter(find.byKey(const Key('trash-empty-confirm'))).dx,
      ),
    );

    await tester.tap(find.byKey(const Key('trash-empty-cancel')));
    await tester.pumpAndSettle();
    expect(emptyRequests, 0);
    expect(find.byKey(const Key('trash-empty-dialog')), findsNothing);
    expect(find.byKey(const Key('trash-item-0')), findsOneWidget);
    expect(find.byKey(const Key('trash-item-1')), findsOneWidget);
    expect(find.byKey(const Key('trash-item-2')), findsOneWidget);

    await tester.tap(find.byKey(const Key('trash-empty-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('trash-empty-confirm')));
    await tester.pumpAndSettle();

    expect(emptyRequests, 1);
    expect(find.byKey(const Key('trash-item-0')), findsNothing);
    expect(find.byKey(const Key('trash-item-1')), findsNothing);
    expect(find.byKey(const Key('trash-item-2')), findsNothing);
    expect(find.byKey(const Key('trash-empty-state')), findsNothing);
    expect(find.text('Trash is Empty'), findsNothing);
    expect(find.text('휴지통이 비었습니다'), findsNothing);
    expect(
      find.text('There are no deleted portfolio items for Heesu Kim.'),
      findsNothing,
    );
    final trashList = find.byKey(const Key('trash-scroll'));
    final trashListWidget = tester.widget<ListView>(trashList);
    expect(trashListWidget.childrenDelegate.estimatedChildCount, 0);
    expect(find.byType(AppleEmptyState), findsNothing);
    expect(
      find.descendant(of: trashList, matching: find.byType(Text)),
      findsNothing,
    );
    semantics.dispose();
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
    expect(find.byKey(const Key('trash-empty-state')), findsNothing);
    final trashList = find.byKey(const Key('trash-scroll'));
    final trashListWidget = tester.widget<ListView>(trashList);
    expect(trashListWidget.childrenDelegate.estimatedChildCount, 0);
    expect(find.byType(AppleEmptyState), findsNothing);
    expect(
      find.descendant(of: trashList, matching: find.byType(Text)),
      findsNothing,
    );
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

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
