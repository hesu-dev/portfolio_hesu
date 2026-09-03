import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/about_app.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/mobile/apple_home_grid.dart';
import 'package:portfolio_hesu/portfolio/models/portfolio_app_id.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/widgets/apple_notes_surface.dart';

void main() {
  group('모바일 홈 Notes 프로필', () {
    for (final scenario in <(Size, bool, String)>[
      (const Size(390, 844), false, 'iphone-notes-profile'),
      (const Size(834, 1194), true, 'ipad-profile-widget'),
    ]) {
      testWidgets('${scenario.$2 ? 'iPad' : 'iPhone'}에서 메모 전체가 About 버튼이다', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await _pumpMobileHome(tester, size: scenario.$1, tablet: scenario.$2);

        final profile = find.byKey(Key(scenario.$3));
        expect(profile, findsOneWidget);
        expect(tester.widget(profile), isA<AppleNotesSurface>());
        expect(
          find.descendant(of: profile, matching: find.byType(AppleNotesPaper)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: profile, matching: find.text('메모')),
          findsNothing,
        );
        expect(
          find.descendant(
            of: profile,
            matching: find.text(portfolioData.monogram),
          ),
          findsNothing,
        );
        expect(find.byKey(const Key('ipad-profile-date')), findsNothing);
        expect(
          find.descendant(
            of: profile,
            matching: find.text(portfolioData.identity.name),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: profile,
            matching: find.text(portfolioData.identity.headline),
          ),
          findsOneWidget,
        );
        final semanticsData = tester.getSemantics(profile).getSemanticsData();
        expect(semanticsData.label, isNot(contains('메모')));
        expect(semanticsData.label, contains(portfolioData.identity.name));
        expect(semanticsData.flagsCollection.isButton, isTrue);
        expect(semanticsData.hasAction(ui.SemanticsAction.tap), isTrue);

        await tester.tap(profile);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('about-app')), findsOneWidget);
        semantics.dispose();
      });
    }

    testWidgets('iPad와 iPhone 메모는 Enter와 Space로 About을 연다', (tester) async {
      for (final scenario in <(Size, bool, String)>[
        (const Size(390, 844), false, 'iphone-notes-profile'),
        (const Size(834, 1194), true, 'ipad-profile-widget'),
      ]) {
        for (final key in <LogicalKeyboardKey>[
          LogicalKeyboardKey.enter,
          LogicalKeyboardKey.space,
        ]) {
          await tester.pumpWidget(const SizedBox.shrink());
          await _pumpMobileHome(tester, size: scenario.$1, tablet: scenario.$2);

          final profile = find.byKey(Key(scenario.$3));
          final detector = tester.widget<FocusableActionDetector>(
            find.descendant(
              of: profile,
              matching: find.byType(FocusableActionDetector),
            ),
          );
          detector.focusNode!.requestFocus();
          await tester.pump();
          await tester.sendKeyEvent(key);
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('about-app')),
            findsOneWidget,
            reason: '${scenario.$2 ? 'iPad' : 'iPhone'} $key',
          );
        }
      }
    });
  });

  group('About 연속 메모', () {
    testWidgets('소개부터 연락처까지 하나의 paper body 안에 이어진다', (tester) async {
      await _pumpAbout(tester, size: const Size(900, 700));

      final body = find.byKey(const Key('about-notes-body'));
      expect(find.byKey(const Key('about-notes-card')), findsNothing);
      expect(find.byKey(const Key('about-notes-header')), findsNothing);
      expect(find.byType(AppleNotesSurface), findsNothing);
      expect(find.byType(AppleNotesPaper), findsOneWidget);
      expect(body, findsOneWidget);
      expect(
        find.descendant(of: body, matching: find.byType(AppleSurfaceCard)),
        findsNothing,
      );

      for (final text in <String>[
        portfolioData.identity.name,
        portfolioData.identity.biography,
        'Career',
        portfolioData.experiences.first.role,
        'Education',
        portfolioData.education.first.program,
        'Contact',
        portfolioData.identity.email,
        portfolioData.identity.githubUrl,
      ]) {
        expect(
          find.descendant(of: body, matching: find.text(text)),
          findsAtLeastNWidgets(1),
          reason: text,
        );
      }
    });

    testWidgets('교육 링크와 feedback이 연속 메모 안에서 유지된다', (tester) async {
      final launcher = _RecordingLauncher(succeeds: false);
      await _pumpAbout(
        tester,
        size: const Size(320, 480),
        compact: true,
        textScaler: const TextScaler.linear(2),
        launcher: launcher,
      );

      final body = find.byKey(const Key('about-notes-body'));
      final action = find.byKey(const Key('about-education-link-0'));
      expect(find.descendant(of: body, matching: action), findsOneWidget);
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      await tester.tap(action);
      await tester.pumpAndSettle();

      expect(launcher.uris, <Uri>[portfolioData.education.first.link!.uri]);
      expect(
        find.descendant(
          of: body,
          matching: find.byKey(const Key('about-link-feedback')),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('about-scroll')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

class _RecordingLauncher implements ExternalLauncher {
  _RecordingLauncher({this.succeeds = true});

  final bool succeeds;
  final List<Uri> uris = <Uri>[];

  @override
  Future<bool> launch(Uri uri) async {
    uris.add(uri);
    return succeeds;
  }
}

Future<void> _pumpMobileHome(
  WidgetTester tester, {
  required Size size,
  required bool tablet,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: _MobileHomeHarness(data: portfolioData, tablet: tablet),
      ),
    ),
  );
  await tester.pump();
}

class _MobileHomeHarness extends StatefulWidget {
  const _MobileHomeHarness({required this.data, required this.tablet});

  final PortfolioData data;
  final bool tablet;

  @override
  State<_MobileHomeHarness> createState() => _MobileHomeHarnessState();
}

class _MobileHomeHarnessState extends State<_MobileHomeHarness> {
  PortfolioAppId? _openApp;

  @override
  Widget build(BuildContext context) {
    if (_openApp == PortfolioAppId.about) {
      return AboutApp(
        data: widget.data,
        launcher: _RecordingLauncher(),
        compact: !widget.tablet,
        tablet: widget.tablet,
      );
    }

    return AppleHomeGrid(
      data: widget.data,
      tablet: widget.tablet,
      onOpen: (appId) => setState(() => _openApp = appId),
    );
  }
}

Future<void> _pumpAbout(
  WidgetTester tester, {
  required Size size,
  bool compact = false,
  TextScaler textScaler = TextScaler.noScaling,
  ExternalLauncher? launcher,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(size: size, textScaler: textScaler),
        child: AboutApp(
          data: portfolioData,
          launcher: launcher ?? _RecordingLauncher(),
          compact: compact,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
