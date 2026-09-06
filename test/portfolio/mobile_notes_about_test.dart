import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/about_app.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/mobile/apple_home_grid.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/widgets/apple_notes_surface.dart';

void main() {
  group('모바일 홈 프로필 앱', () {
    for (final scenario in <(Size, bool, String)>[
      (const Size(390, 844), false, 'iPhone'),
      (const Size(834, 1194), true, 'iPad'),
    ]) {
      testWidgets('${scenario.$3} 홈은 기존 Notes 위젯 없이 프로필 앱을 첫 칸에 둔다', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await _pumpMobileHome(tester, size: scenario.$1, tablet: scenario.$2);

        for (final legacyKey in const <String>[
          'iphone-notes-profile',
          'ipad-profile-widget',
          'mobile-notes-profile-header',
          'mobile-notes-profile-body',
        ]) {
          expect(find.byKey(Key(legacyKey)), findsNothing);
        }
        expect(find.text('프로필 보러가기'), findsNothing);
        expect(find.text(portfolioData.identity.name), findsNothing);

        final profile = find.byKey(const Key('home-app-profile'));
        final skills = find.byKey(const Key('home-app-skills'));
        expect(profile, findsOneWidget);
        expect(skills, findsOneWidget);
        expect(find.bySemanticsLabel('Open 프로필'), findsOneWidget);

        final profileRect = tester.getRect(profile);
        final skillsRect = tester.getRect(skills);
        expect(profileRect.top, closeTo(skillsRect.top, 0.1));
        expect(profileRect.left, lessThan(skillsRect.left));
        semantics.dispose();
      });
    }
  });

  group('About 연속 메모', () {
    testWidgets('소개부터 경력과 교육까지 하나의 paper body 안에 이어진다', (tester) async {
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
        '경력',
        portfolioData.experiences.first.role,
        '교육',
        portfolioData.education.first.program,
      ]) {
        expect(
          find.descendant(of: body, matching: find.text(text)),
          findsAtLeastNWidgets(1),
          reason: text,
        );
      }
      for (final removedText in <String>[
        'Career',
        'Education',
        'Contact',
        'Let’s build something thoughtful',
        'Email',
        portfolioData.identity.email,
        'GitHub',
        portfolioData.identity.githubUrl,
      ]) {
        expect(
          find.descendant(of: body, matching: find.text(removedText)),
          findsNothing,
          reason: removedText,
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
  TextScaler textScaler = TextScaler.noScaling,
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
        child: AppleHomeGrid(
          data: portfolioData,
          tablet: tablet,
          onOpen: (_) {},
        ),
      ),
    ),
  );
  await tester.pump();
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
