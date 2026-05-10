# Portfolio Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rebuild the current portfolio into a section-based, reference-inspired design that preserves the existing content, supports `ko/en` localization, supports light/dark mode, remains responsive, and keeps the current implementation available under an `old` namespace.

**Architecture:** Keep the current one-page vertical section navigation pattern, but replace the visual layer with a new app shell, design system, and data-driven sections. Extract every display string into ARB localization files, keep links, assets, and skill scores in structured data, and centralize theme, locale, and section navigation in a small app settings controller.

**Tech Stack:** Flutter, Material 3, `flutter_localizations`, `intl`, `url_launcher`, existing animation widgets where still useful, widget tests, `flutter analyze`

---

**Implementation Notes**

- Follow `@superpowers:test-driven-development` for each task: write or update the targeted test first, confirm the failure, then implement the minimum needed code.
- Follow `@superpowers:verification-before-completion` before claiming the redesign is done.
- Treat the provided long widget sample as a visual reference only. Do not paste it directly; rebuild it as responsive Flutter layouts and localized content.
- Extract the current Korean copy first and make `app_ko.arb` the canonical source of truth and default locale.
- If the current UI uses English chrome labels such as `About`, `Projects`, or `Contact`, rewrite them into Korean first for `app_ko.arb`, then derive `app_en.arb` from that Korean source.
- Test examples should use the Korean locale by default. If an English example is ever needed, it must come from translated Korean localization keys rather than fresh hardcoded English.

### Task 1: Preserve the current app as legacy and install the new entry point

**Files:**
- Create: `lib/old/legacy_portfolio_app.dart`
- Create: `lib/old/views/` (legacy copies of the current section/widgets files copied under this tree)
- Modify: `lib/main.dart`
- Test: `test/widget_test.dart`

**Step 1: Write the failing bootstrap smoke test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/main.dart';

void main() {
  testWidgets('boots redesigned portfolio app', (tester) async {
    await tester.pumpWidget(const PortfolioBootstrap());
    expect(find.byType(Directionality), findsOneWidget);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL because `PortfolioBootstrap` does not exist yet.

**Step 3: Copy the current app into the legacy namespace and create the new bootstrap**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:portfolio_hesu/app/portfolio_app.dart';

void main() => runApp(const PortfolioBootstrap());

class PortfolioBootstrap extends StatelessWidget {
  const PortfolioBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return const PortfolioApp();
  }
}
```

Copy the current `PortfolioClone`, old `CustomAppBar`, old drawer, and the current section implementations under `lib/old/...` so nothing is deleted. Keep the current file paths in place so later redesign tasks can replace those files in situ without recreating the directory structure from scratch.

**Step 4: Run test to verify it passes**

Run: `flutter test test/widget_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/main.dart lib/old test/widget_test.dart
git commit -m "chore: preserve legacy portfolio app"
```

### Task 2: Add localized content and app settings state

**Files:**
- Modify: `pubspec.yaml`
- Create: `l10n.yaml`
- Create: `lib/l10n/app_ko.arb`
- Create: `lib/l10n/app_en.arb`
- Create: `lib/app/app_settings_controller.dart`
- Create: `lib/content/portfolio_content.dart`
- Test: `test/app_settings_controller_test.dart`

**Step 1: Write the failing settings controller test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/app/app_settings_controller.dart';

void main() {
  test('toggles theme mode and locale', () {
    final controller = AppSettingsController();
    expect(controller.themeMode, ThemeMode.dark);
    expect(controller.locale.languageCode, 'ko');

    controller.toggleTheme();
    controller.setLocale(const Locale('en'));

    expect(controller.themeMode, ThemeMode.light);
    expect(controller.locale.languageCode, 'en');
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/app_settings_controller_test.dart`
Expected: FAIL because the controller is not implemented yet.

**Step 3: Add localization/config files and structured content**

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: any

flutter:
  generate: true

# l10n.yaml
arb-dir: lib/l10n
template-arb-file: app_ko.arb
output-localization-file: app_localizations.dart
```

```dart
// lib/app/app_settings_controller.dart
class AppSettingsController extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.dark;
  Locale locale = const Locale('ko');

  void toggleTheme() { ... }
  void setLocale(Locale next) { ... }
}
```

Extract the current Korean strings into `app_ko.arb` first, including any labels that are currently written in English in the UI chrome. Then translate those same keys into `app_en.arb`. Use `lib/content/portfolio_content.dart` for non-string data such as URLs, asset paths, skill levels, project tags, and section IDs. Put every human-readable sentence, title, CTA label, and navigation label in ARB files only.

**Step 4: Run the localized generation and tests**

Run: `flutter gen-l10n`
Expected: generated localization classes appear without errors.

Run: `flutter test test/app_settings_controller_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add pubspec.yaml l10n.yaml lib/l10n lib/app lib/content test/app_settings_controller_test.dart
git commit -m "feat: add app settings and localized content"
```

### Task 3: Build the redesign shell, navigation, responsive header, and shared test harness

**Files:**
- Create: `lib/app/portfolio_app.dart`
- Create: `lib/views/layout/portfolio_shell.dart`
- Create: `lib/views/layout/portfolio_header.dart`
- Create: `lib/views/layout/portfolio_section_scaffold.dart`
- Create: `lib/theme/portfolio_theme.dart`
- Create: `lib/theme/portfolio_tokens.dart`
- Create: `test/helpers/test_portfolio_frame.dart`
- Test: `test/portfolio_shell_test.dart`

**Step 1: Write the failing shell navigation test**

```dart
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/l10n/app_localizations.dart';
import 'package:portfolio_hesu/app/portfolio_app.dart';
import 'helpers/test_portfolio_frame.dart';

void main() {
  testWidgets('헤더, 키보드, 스크롤로 섹션 이동이 동작한다', (tester) async {
    final AppLocalizations l10n = await pumpPortfolioApp(
      tester,
      locale: const Locale('ko'),
    );

    expect(find.text(l10n.navAbout), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();

    expect(find.text(l10n.navProjects), findsWidgets);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/portfolio_shell_test.dart`
Expected: FAIL because the redesigned app shell and test helpers are not present yet.

**Step 3: Implement the responsive shell, test helpers, and theme system**

```dart
// lib/app/portfolio_app.dart
MaterialApp(
  locale: settingsController.locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  theme: buildPortfolioTheme(Brightness.light),
  darkTheme: buildPortfolioTheme(Brightness.dark),
  themeMode: settingsController.themeMode,
  home: const PortfolioShell(),
);

// test/helpers/test_portfolio_frame.dart
Future<AppLocalizations> pumpPortfolioFrame(
  WidgetTester tester, {
  required Widget child,
  Locale locale = const Locale('ko'),
}) async { ... }

Future<AppLocalizations> pumpPortfolioApp(
  WidgetTester tester, {
  Locale locale = const Locale('ko'),
}) async { ... }
```

```dart
// lib/views/layout/portfolio_shell.dart
class PortfolioShell extends StatefulWidget { ... }

// responsibilities
// - PageController for About / Projects / Contact
// - header click navigation
// - keyboard up/down navigation
// - pointer scroll navigation
// - locale/theme controls wired to AppSettingsController
// - default locale is Korean
```

Create a single token-driven theme that exposes light and dark variants for background, card surfaces, borders, accent colors, and typography. Desktop should show a glass-like header bar; mobile should collapse to a compact top bar plus drawer or sheet while preserving the same section targets. The test helper must provide `MaterialApp`, localization delegates, supported locales, default Korean locale, and a configurable viewport so the section tests do not each rebuild their own harness.

**Step 4: Run tests**

Run: `flutter test test/portfolio_shell_test.dart`
Expected: PASS

Run: `flutter analyze`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/app/portfolio_app.dart lib/views/layout lib/theme test/helpers test/portfolio_shell_test.dart
git commit -m "feat: add redesigned shell and responsive navigation"
```

### Task 4: Rebuild the About section in the new visual language

**Files:**
- Modify: `lib/views/sections/about/about.dart`
- Modify: `lib/views/sections/about/about_item.dart`
- Modify: `lib/views/sections/contact/history.dart`
- Test: `test/helpers/test_portfolio_frame.dart`
- Test: `test/about_section_test.dart`

**Step 1: Write the failing About section test**

```dart
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/l10n/app_localizations.dart';
import 'package:portfolio_hesu/views/sections/about/about.dart';
import 'helpers/test_portfolio_frame.dart';

void main() {
  testWidgets('소개 섹션이 핵심 카드와 이력 블록을 렌더링한다', (tester) async {
    final AppLocalizations l10n = await pumpPortfolioFrame(
      tester,
      child: const Aboutme(),
      locale: const Locale('ko'),
    );

    expect(find.text(l10n.aboutSectionTitle), findsOneWidget);
    expect(find.text(l10n.aboutExperienceTitle), findsOneWidget);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/about_section_test.dart`
Expected: FAIL because the new localized structure is not rendered yet.

**Step 3: Implement the About section**

```dart
// target layout
// - hero-style intro block with accent heading
// - summary/profile card using existing about copy
// - experience timeline card using existing job history
// - education/history block adapted from current HistoryList
```

Keep the current content, but restyle it with stronger typography, tinted surfaces, subtle gradients, and responsive card stacking. Do not introduce any literal strings in the widgets.

**Step 4: Run tests**

Run: `flutter test test/about_section_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/views/sections/about/about.dart lib/views/sections/about/about_item.dart lib/views/sections/contact/history.dart test/about_section_test.dart
git commit -m "feat: redesign about section"
```

### Task 5: Rebuild the Projects section with featured and secondary project groups

**Files:**
- Modify: `lib/views/sections/project/project.dart`
- Modify: `lib/views/sections/project/post.dart`
- Modify: `lib/views/widgets/custom_card.dart`
- Test: `test/helpers/test_portfolio_frame.dart`
- Create: `test/projects_section_test.dart`

**Step 1: Write the failing Projects section test**

```dart
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/l10n/app_localizations.dart';
import 'package:portfolio_hesu/views/sections/project/project.dart';
import 'helpers/test_portfolio_frame.dart';

void main() {
  testWidgets('프로젝트 섹션이 대표 작업과 작은 프로젝트 목록을 보여준다', (tester) async {
    final AppLocalizations l10n = await pumpPortfolioFrame(
      tester,
      child: const ProjectTxt(),
      locale: const Locale('ko'),
    );

    expect(find.text(l10n.projectsSectionTitle), findsOneWidget);
    expect(find.text(l10n.projectsSmallListTitle), findsOneWidget);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/projects_section_test.dart`
Expected: FAIL because the new layout and localized labels are missing.

**Step 3: Implement the Projects section**

```dart
// target layout
// - top featured project block inspired by the reference hero/case-study card
// - supporting cards for remaining main projects
// - compact grid/list for small side projects
// - localized buttons for store links / external links / "view more"
```

Use the current project data and links, but convert the layout from plain cards into a more editorial, high-contrast composition. Keep the section scroll-safe on mobile by collapsing wide rows into stacked cards.

**Step 4: Run tests**

Run: `flutter test test/projects_section_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/views/sections/project/project.dart lib/views/sections/project/post.dart lib/views/widgets/custom_card.dart test/projects_section_test.dart
git commit -m "feat: redesign projects section"
```

### Task 6: Rebuild the Contact section, skill matrix, and footer CTA

**Files:**
- Modify: `lib/views/sections/contact/contact_block.dart`
- Modify: `lib/views/sections/contact/skills.dart`
- Modify: `lib/views/sections/project/footer.dart`
- Test: `test/helpers/test_portfolio_frame.dart`
- Create: `test/contact_section_test.dart`

**Step 1: Write the failing Contact section test**

```dart
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/l10n/app_localizations.dart';
import 'package:portfolio_hesu/views/sections/contact/contact_block.dart';
import 'helpers/test_portfolio_frame.dart';

void main() {
  testWidgets('연락처 섹션이 기술 그룹과 연락 수단을 보여준다', (tester) async {
    final AppLocalizations l10n = await pumpPortfolioFrame(
      tester,
      child: const ContactSection(),
      locale: const Locale('ko'),
    );

    expect(find.text(l10n.contactSkillsTitle), findsOneWidget);
    expect(find.text(l10n.contactLocationTitle), findsOneWidget);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/contact_section_test.dart`
Expected: FAIL because the new contact presentation is not implemented yet.

**Step 3: Implement the Contact section**

```dart
// target layout
// - skill categories in redesigned surface cards
// - contact details in compact info blocks
// - footer CTA with localized action labels
// - localized copyright line
```

Preserve the same contact data and skills, but reshape them into a cleaner information hierarchy that matches the new theme system.

**Step 4: Run tests**

Run: `flutter test test/contact_section_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/views/sections/contact/contact_block.dart lib/views/sections/contact/skills.dart lib/views/sections/project/footer.dart test/contact_section_test.dart
git commit -m "feat: redesign contact section"
```

### Task 7: Full verification, responsive QA, and cleanup

**Files:**
- Modify: any touched files from Tasks 1-6
- Test: `test/widget_test.dart`
- Test: `test/app_settings_controller_test.dart`
- Test: `test/portfolio_shell_test.dart`
- Test: `test/about_section_test.dart`
- Test: `test/projects_section_test.dart`
- Test: `test/contact_section_test.dart`

**Step 1: Run formatting**

Run: `dart format lib test`
Expected: all touched files formatted cleanly.

**Step 2: Run static analysis**

Run: `flutter analyze`
Expected: PASS

**Step 3: Run the full automated test suite**

Run: `flutter test`
Expected: PASS

**Step 4: Perform manual checks**

Run: `flutter run -d chrome`
Expected: the app opens and all of the following work:

- desktop header navigation
- mouse wheel section movement
- keyboard up and down section movement
- mobile and tablet responsive layouts
- light and dark mode toggle
- `ko/en` locale toggle
- external links still launch correctly

**Step 5: Commit**

```bash
git add lib test pubspec.yaml l10n.yaml
git commit -m "feat: ship redesigned localized portfolio"
```

Plan complete and saved to `docs/plans/2026-03-20-portfolio-redesign.md`. Two execution options:

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

**Which approach?**
