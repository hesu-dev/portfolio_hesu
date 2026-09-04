import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/portfolio_app.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/portfolio_theme_controller.dart';
import 'package:portfolio_hesu/portfolio/widgets/adaptive_portfolio_shell.dart';

void main() {
  group('PortfolioApp', () {
    testWidgets('builds a MaterialApp root and injects its launcher', (
      tester,
    ) async {
      final launcher = CallbackExternalLauncher((_) async => true);

      await tester.pumpWidget(PortfolioApp(externalLauncher: launcher));

      expect(find.byType(MaterialApp), findsOneWidget);
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.title, '민희수 포트폴리오');
      expect(app.color, const Color(0xFFF4F4F7));
      final shell = tester.widget<AdaptivePortfolioShell>(
        find.byType(AdaptivePortfolioShell),
      );
      expect(shell.externalLauncher, same(launcher));
    });

    testWidgets('shows only the canonical portfolio identity', (tester) async {
      await _pumpAtWidth(tester, 390);

      expect(find.byKey(const Key('home-app-profile')), findsOneWidget);
      expect(find.text('민희수'), findsNothing);
      expect(
        find.byKey(const Key('mobile-notes-profile-header')),
        findsNothing,
      );
      expect(find.byKey(const Key('mobile-notes-profile-body')), findsNothing);

      await tester.tap(find.byKey(const Key('home-app-profile')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('profile-app')),
          matching: find.text('민희수'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('천주아'), findsNothing);
      expect(find.textContaining('juah'), findsNothing);
    });

    testWidgets('derives metadata and shell content from injected data', (
      tester,
    ) async {
      final data = PortfolioData(
        identity: const PortfolioIdentity(
          name: '테스트 사용자',
          englishName: 'Test User',
          email: 'test@example.com',
          githubUrl: 'https://example.com/test',
          headline: 'Injected developer',
          biography: 'Injected biography',
        ),
        experiences: portfolioData.experiences,
        education: portfolioData.education,
        skillGroups: portfolioData.skillGroups,
        projects: portfolioData.projects,
      );
      final launcher = CallbackExternalLauncher((_) async => true);

      await tester.pumpWidget(
        PortfolioApp(data: data, externalLauncher: launcher),
      );

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.title, '테스트 사용자 포트폴리오');
      expect(app.color, const Color(0xFFF4F4F7));
      final shell = tester.widget<AdaptivePortfolioShell>(
        find.byType(AdaptivePortfolioShell),
      );
      expect(shell.data, same(data));
      expect(shell.externalLauncher, same(launcher));
    });

    testWidgets('defaults to light even when the platform is dark', (
      tester,
    ) async {
      tester.binding.platformDispatcher.platformBrightnessTestValue =
          Brightness.dark;
      addTearDown(
        tester.binding.platformDispatcher.clearPlatformBrightnessTestValue,
      );

      await tester.pumpWidget(
        PortfolioApp(
          externalLauncher: CallbackExternalLauncher((_) async => true),
        ),
      );

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final shellContext = tester.element(find.byType(AdaptivePortfolioShell));
      expect(app.themeMode, ThemeMode.light);
      expect(Theme.of(shellContext).brightness, Brightness.light);
      expect(app.title, portfolioData.appTitle);
      expect(app.color, const Color(0xFFF4F4F7));
    });

    testWidgets('reacts immediately to an injected theme controller', (
      tester,
    ) async {
      final controller = PortfolioThemeController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        PortfolioApp(
          themeController: controller,
          externalLauncher: CallbackExternalLauncher((_) async => true),
        ),
      );
      final originalShellElement = tester.element(
        find.byType(AdaptivePortfolioShell),
      );
      var shell = tester.widget<AdaptivePortfolioShell>(
        find.byType(AdaptivePortfolioShell),
      );
      expect(shell.themeController, same(controller));

      controller.select(PortfolioThemePreference.dark);
      await tester.pump();

      var app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      var shellContext = tester.element(find.byType(AdaptivePortfolioShell));
      expect(app.themeMode, ThemeMode.dark);
      expect(Theme.of(shellContext).brightness, Brightness.dark);
      expect(
        tester.element(find.byType(AdaptivePortfolioShell)),
        same(originalShellElement),
      );

      controller.select(PortfolioThemePreference.light);
      await tester.pump();

      app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      shellContext = tester.element(find.byType(AdaptivePortfolioShell));
      shell = tester.widget<AdaptivePortfolioShell>(
        find.byType(AdaptivePortfolioShell),
      );
      expect(app.themeMode, ThemeMode.light);
      expect(Theme.of(shellContext).brightness, Brightness.light);
      expect(shell.themeController, same(controller));
    });

    testWidgets('does not dispose an injected theme controller on unmount', (
      tester,
    ) async {
      final controller = PortfolioThemeController();

      await tester.pumpWidget(
        PortfolioApp(
          themeController: controller,
          externalLauncher: CallbackExternalLauncher((_) async => true),
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());

      expect(
        () => controller.select(PortfolioThemePreference.dark),
        returnsNormally,
      );
      expect(controller.preference, PortfolioThemePreference.dark);
      controller.dispose();
    });
  });

  group('AdaptivePortfolioShell', () {
    testWidgets('selects representative iPhone, iPad, and Mac widths', (
      tester,
    ) async {
      await _expectShellAtWidth(tester, 390, 'iphone-shell');
      await _expectShellAtWidth(tester, 834, 'ipad-shell');
      await _expectShellAtWidth(tester, 1440, 'mac-shell');
    });

    testWidgets('switches at the exact 600 and 1024 pixel boundaries', (
      tester,
    ) async {
      await _expectShellAtWidth(tester, 599, 'iphone-shell');
      await _expectShellAtWidth(tester, 600, 'ipad-shell');
      await _expectShellAtWidth(tester, 1023, 'ipad-shell');
      await _expectShellAtWidth(tester, 1024, 'mac-shell');
    });
  });

  group('UrlLauncherExternalLauncher', () {
    test('rejects malformed and unsupported URIs before delegating', () async {
      final delegatedUris = <Uri>[];
      final launcher = UrlLauncherExternalLauncher(
        delegate: (uri) async {
          delegatedUris.add(uri);
          return true;
        },
      );

      expect(await launcher.launch(Uri.parse('/relative')), isFalse);
      expect(
        await launcher.launch(Uri.parse('https:///missing-host')),
        isFalse,
      );
      expect(await launcher.launch(Uri.parse('mailto:')), isFalse);
      expect(await launcher.launch(Uri.parse('mailto:@')), isFalse);
      expect(await launcher.launch(Uri.parse('mailto:user@')), isFalse);
      expect(await launcher.launch(Uri.parse('mailto:@example.com')), isFalse);
      expect(
        await launcher.launch(Uri.parse('mailto:%FF@example.com')),
        isFalse,
      );
      expect(
        await launcher.launch(Uri.parse('ftp://downloads.example.com/file')),
        isFalse,
      );
      expect(delegatedUris, isEmpty);
    });

    test('delegates supported web and email URIs', () async {
      final delegatedUris = <Uri>[];
      final launcher = UrlLauncherExternalLauncher(
        delegate: (uri) async {
          delegatedUris.add(uri);
          return true;
        },
      );
      final httpsUri = Uri.parse('https://github.com/hesu-dev/');
      final mailUri = Uri.parse('mailto:hs0647@naver.com');

      expect(await launcher.launch(httpsUri), isTrue);
      expect(await launcher.launch(mailUri), isTrue);
      expect(delegatedUris, <Uri>[httpsUri, mailUri]);
    });

    test('returns false when the delegate cannot launch', () async {
      final launcher = UrlLauncherExternalLauncher(
        delegate: (_) async => false,
      );

      expect(await launcher.launch(Uri.parse('https://example.com')), isFalse);
    });

    test('converts delegate errors into a false result', () async {
      final launcher = UrlLauncherExternalLauncher(
        delegate: (_) async => throw StateError('launcher unavailable'),
      );

      expect(await launcher.launch(Uri.parse('https://example.com')), isFalse);
    });
  });
}

Future<void> _expectShellAtWidth(
  WidgetTester tester,
  double width,
  String expectedKey,
) async {
  await _pumpAtWidth(tester, width);

  expect(
    find.byKey(Key(expectedKey)),
    findsOneWidget,
    reason: 'Expected $expectedKey at width $width',
  );
  for (final key in const <String>['iphone-shell', 'ipad-shell', 'mac-shell']) {
    if (key != expectedKey) {
      expect(
        find.byKey(Key(key)),
        findsNothing,
        reason: 'Did not expect $key at width $width',
      );
    }
  }
}

Future<void> _pumpAtWidth(WidgetTester tester, double width) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    PortfolioApp(externalLauncher: CallbackExternalLauncher((_) async => true)),
  );
}
