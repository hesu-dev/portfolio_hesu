import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/about_app.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/widgets/apple_notes_surface.dart';

void main() {
  group('About Notes 카드', () {
    testWidgets('identity와 소개를 중첩 카드 없는 한 장의 메모 본문에 렌더한다', (tester) async {
      final data = _dataWithIdentity(
        name: '테스트 민희수',
        englishName: 'Test He-su',
        headline: 'Thoughtful Flutter developer',
        biography: '사용자의 문제를 차분하게 해결하는 개발자입니다.',
      );

      await _pumpAbout(tester, data: data, size: const Size(900, 700));

      final body = find.byKey(const Key('about-notes-body'));
      expect(find.byType(AppleToolbar), findsNothing);
      expect(find.byType(AppleNotesSurface), findsNothing);
      expect(find.byType(AppleNotesPaper), findsOneWidget);
      expect(find.byKey(const Key('about-notes-card')), findsNothing);
      expect(find.byKey(const Key('about-notes-header')), findsNothing);
      expect(body, findsOneWidget);

      for (final text in <String>[
        data.identity.name,
        data.identity.englishName,
        data.identity.headline,
        data.identity.biography,
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
        expect(
          find.descendant(of: body, matching: find.text(text)),
          findsOneWidget,
          reason: '$text must live inside the Notes body',
        );
      }
      expect(
        find.descendant(of: body, matching: find.byType(Image)),
        findsNothing,
      );
      expect(find.text('경력'), findsOneWidget);
      expect(find.text('교육'), findsOneWidget);
      expect(
        tester.getTopLeft(body).dy,
        lessThan(tester.getTopLeft(find.text('경력')).dy),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('넓은 화면과 compact 화면은 섹션을 한글로 표시하고 연락처 꼬리를 만들지 않는다', (
      tester,
    ) async {
      for (final scenario in const <({String label, Size size, bool compact})>[
        (label: 'wide', size: Size(900, 700), compact: false),
        (label: 'compact', size: Size(360, 600), compact: true),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpAbout(
          tester,
          data: portfolioData,
          size: scenario.size,
          compact: scenario.compact,
        );

        final body = find.byKey(const Key('about-notes-body'));
        for (final text in <String>[
          '경력',
          '교육',
          portfolioData.experiences.first.organization,
          portfolioData.education.first.program,
          portfolioData.education.first.institution,
        ]) {
          expect(
            find.descendant(of: body, matching: find.text(text)),
            findsOneWidget,
            reason: '${scenario.label} $text',
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
            reason: '${scenario.label} $removedText',
          );
        }

        final dividers = find.descendant(
          of: body,
          matching: find.byType(Divider),
        );
        expect(
          dividers,
          findsNWidgets(
            portfolioData.experiences.length + portfolioData.education.length,
          ),
          reason: '${scenario.label} must not keep the Contact section divider',
        );
        expect(
          tester.getBottomLeft(dividers.last).dy,
          lessThan(
            tester
                .getTopLeft(find.text(portfolioData.education.last.program))
                .dy,
          ),
          reason:
              '${scenario.label} final divider must separate education entries, '
              'not trail the final one',
        );
        expect(tester.takeException(), isNull, reason: scenario.label);
      }
    });

    testWidgets('밝은 메모 본문 텍스트는 두 테마에서 AA 대비를 충족한다', (tester) async {
      for (final brightness in Brightness.values) {
        await _pumpAbout(
          tester,
          data: portfolioData,
          size: const Size(900, 700),
          brightness: brightness,
        );

        final bodyBackground = _decorationAt(
          tester,
          const Key('about-notes-body'),
        ).color!;
        for (final text in <String>[
          portfolioData.identity.name,
          portfolioData.identity.englishName,
          portfolioData.identity.headline,
          portfolioData.identity.biography,
        ]) {
          final foreground = tester.widget<Text>(find.text(text)).style!.color!;
          expect(
            _contrastRatio(foreground, bodyBackground),
            greaterThanOrEqualTo(4.5),
            reason: '$brightness $text',
          );
        }
        expect(tester.takeException(), isNull, reason: '$brightness');
      }
    });

    testWidgets('다크 모드에서 메모 종이와 주요 본문이 어두운 팔레트를 사용한다', (tester) async {
      await _pumpAbout(
        tester,
        data: portfolioData,
        size: const Size(900, 700),
        brightness: Brightness.light,
      );
      final lightPaper = _decorationAt(
        tester,
        const Key('about-notes-body'),
      ).color!;
      final lightName = tester
          .widget<Text>(find.text(portfolioData.identity.name))
          .style!
          .color!;

      await _pumpAbout(
        tester,
        data: portfolioData,
        size: const Size(900, 700),
        brightness: Brightness.dark,
      );
      final darkPaper = _decorationAt(
        tester,
        const Key('about-notes-body'),
      ).color!;
      final darkName = tester
          .widget<Text>(find.text(portfolioData.identity.name))
          .style!
          .color!;

      expect(lightPaper, const Color(0xFFFFFEFC));
      expect(darkPaper, const Color(0xFF1B2433));
      expect(
        darkPaper.computeLuminance(),
        lessThan(lightPaper.computeLuminance()),
      );
      expect(darkName, isNot(lightName));

      for (final text in <String>[
        portfolioData.identity.name,
        portfolioData.identity.englishName,
        portfolioData.identity.headline,
        portfolioData.identity.biography,
        '경력',
        portfolioData.experiences.first.role,
        portfolioData.experiences.first.organization,
        portfolioData.experiences.first.description,
        '교육',
        portfolioData.education.first.program,
        portfolioData.education.first.institution,
      ]) {
        final foreground = tester
            .widget<Text>(find.text(text).first)
            .style!
            .color!;
        expect(
          _contrastRatio(foreground, darkPaper),
          greaterThanOrEqualTo(4.5),
          reason: '다크 모드 $text',
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('320x480의 200% 글자 크기에서도 스크롤되며 넘치지 않는다', (tester) async {
      await _pumpAbout(
        tester,
        data: portfolioData,
        size: const Size(320, 480),
        compact: true,
        textScaler: const TextScaler.linear(2),
      );

      expect(find.byKey(const Key('about-notes-card')), findsNothing);
      expect(find.byKey(const Key('about-notes-header')), findsNothing);
      expect(find.byKey(const Key('about-notes-body')), findsOneWidget);
      expect(find.text('경력'), findsOneWidget);
      expect(find.text('교육'), findsOneWidget);
      expect(find.text('Contact'), findsNothing);
      expect(find.text(portfolioData.identity.email), findsNothing);
      expect(find.text(portfolioData.identity.githubUrl), findsNothing);
      expect(tester.takeException(), isNull);

      final scrollFinder = find.byKey(const Key('about-scroll'));
      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: scrollFinder, matching: find.byType(Scrollable)),
      );
      expect(scrollable.position.maxScrollExtent, greaterThan(0));
      await tester.drag(scrollFinder, const Offset(0, -220));
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _pumpAbout(
  WidgetTester tester, {
  required PortfolioData data,
  required Size size,
  bool compact = false,
  TextScaler textScaler = TextScaler.noScaling,
  Brightness brightness = Brightness.light,
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
      home: MediaQuery(
        data: MediaQueryData(size: size, textScaler: textScaler),
        child: AboutApp(
          data: data,
          launcher: const _FakeLauncher(),
          compact: compact,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

BoxDecoration _decorationAt(WidgetTester tester, Key key) {
  final container = tester.widget<Container>(find.byKey(key));
  return container.decoration! as BoxDecoration;
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

PortfolioData _dataWithIdentity({
  required String name,
  required String englishName,
  required String headline,
  required String biography,
}) {
  final identity = portfolioData.identity;
  return PortfolioData(
    identity: PortfolioIdentity(
      name: name,
      englishName: englishName,
      email: identity.email,
      githubUrl: identity.githubUrl,
      headline: headline,
      biography: biography,
    ),
    experiences: portfolioData.experiences,
    education: portfolioData.education,
    skillGroups: portfolioData.skillGroups,
    projects: portfolioData.projects,
  );
}

class _FakeLauncher implements ExternalLauncher {
  const _FakeLauncher();

  @override
  Future<bool> launch(Uri uri) async => true;
}
