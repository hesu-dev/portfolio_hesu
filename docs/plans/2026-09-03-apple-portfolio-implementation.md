# Apple-Style Portfolio Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the served Flutter portfolio with a shared-data macOS desktop, iPadOS tablet, and iPhone mobile experience for Min He-su.

**Architecture:** A pure Dart content model and terminal engine feed three responsive Flutter presentation shells. The macOS shell owns multi-window state; iPad and iPhone shells share a single-active-app navigation model with form-factor-specific layout. External navigation is injected and validated so tests never launch real links.

**Tech Stack:** Flutter 3 / Dart 3.8, Material and Cupertino widgets, `url_launcher`, Flutter widget/unit tests, GitHub Pages release build.

> **2026-09-04 변경:** 아래의 GitHub Pages 유지·배포 절차는 후속 요구사항으로 폐기됐다. 최종 배포 기준은 Vercel 루트(`/`) 빌드이며, 기존 Pages 설정과 `gh-pages` 브랜치는 제거한다.

---

### Task 1: Shared portfolio data and app identifiers

**Files:**
- Create: `lib/portfolio/data/portfolio_data.dart`
- Create: `lib/portfolio/models/portfolio_app_id.dart`
- Create: `test/portfolio/portfolio_data_test.dart`

**Step 1: Write the failing tests**

Add tests that expect the canonical identity and safe link set:

```dart
test('contains only Min He-su identity and links', () {
  expect(portfolioData.name, '민희수');
  expect(portfolioData.email, 'hs0647@naver.com');
  expect(portfolioData.githubUrl, 'https://github.com/hesu-dev/');
  expect(portfolioData.allSearchableText, isNot(contains('천주아')));
  expect(portfolioData.allUrls, everyElement(isNot(contains('juah'))));
});

test('omits blank and malformed project actions', () {
  expect(portfolioData.projects.expand((p) => p.links),
      everyElement(predicate((link) => link.uri.hasScheme))));
});
```

**Step 2: Run the tests and verify RED**

Run: `flutter test test/portfolio/portfolio_data_test.dart`

Expected: FAIL because the data model does not exist.

**Step 3: Implement the minimal immutable model**

Create const value types for identity, experience, education, skill groups, projects, and project links. Populate them from the existing repository content. Add computed `allSearchableText` and `allUrls` fields used by the safety test.

Create this shared identifier:

```dart
enum PortfolioAppId {
  about,
  skills,
  projects,
  terminal,
  thisMac,
  trash,
  github,
  mail,
}
```

**Step 4: Run the tests and verify GREEN**

Run: `flutter test test/portfolio/portfolio_data_test.dart`

Expected: PASS.

**Step 5: Commit**

```bash
git add lib/portfolio/data lib/portfolio/models test/portfolio/portfolio_data_test.dart
git commit -m "feat: add shared portfolio data"
```

### Task 2: Terminal command engine

**Files:**
- Create: `lib/portfolio/terminal/terminal_engine.dart`
- Create: `test/portfolio/terminal_engine_test.dart`

**Step 1: Write the failing tests**

Cover `help`, `whoami`, `ls`, `cat skills.md`, `git status`, `git log`, `clear`, whitespace, and unknown commands:

```dart
test('whoami returns Min He-su identity', () {
  final result = TerminalEngine(portfolioData).execute('whoami');
  expect(result.lines.join('\n'), contains('민희수'));
  expect(result.lines.join('\n'), contains('hesu-dev'));
});

test('unknown commands are handled without throwing', () {
  final result = TerminalEngine(portfolioData).execute('oops');
  expect(result.lines.single, contains('command not found'));
});

test('clear marks the transcript for clearing', () {
  expect(TerminalEngine(portfolioData).execute('clear').clear, isTrue);
});
```

**Step 2: Run and verify RED**

Run: `flutter test test/portfolio/terminal_engine_test.dart`

Expected: FAIL because `TerminalEngine` is missing.

**Step 3: Implement the engine**

Use a normalized `switch` with a `TerminalResult(lines:, clear:)` return type. Keep output deterministic and derive identity, project names, and skill names from `PortfolioData`.

**Step 4: Run and verify GREEN**

Run: `flutter test test/portfolio/terminal_engine_test.dart`

Expected: PASS.

**Step 5: Commit**

```bash
git add lib/portfolio/terminal test/portfolio/terminal_engine_test.dart
git commit -m "feat: add portfolio terminal commands"
```

### Task 3: Responsive entry point and external-link boundary

**Files:**
- Create: `lib/portfolio/portfolio_app.dart`
- Create: `lib/portfolio/services/external_launcher.dart`
- Create: `lib/portfolio/widgets/adaptive_portfolio_shell.dart`
- Modify: `lib/main.dart`
- Replace: `test/widget_test.dart`

**Step 1: Write the failing widget tests**

Pump fixed widths and require the correct semantic shell:

```dart
testWidgets('selects iPhone, iPad, and Mac shells by width', (tester) async {
  await pumpAtWidth(tester, 390);
  expect(find.byKey(const Key('iphone-shell')), findsOneWidget);
  await pumpAtWidth(tester, 834);
  expect(find.byKey(const Key('ipad-shell')), findsOneWidget);
  await pumpAtWidth(tester, 1440);
  expect(find.byKey(const Key('mac-shell')), findsOneWidget);
});
```

Add exact boundary cases for 599/600 and 1023/1024.

**Step 2: Run and verify RED**

Run: `flutter test test/widget_test.dart`

Expected: FAIL because the adaptive shell is missing.

**Step 3: Implement the minimal selector and app root**

`AdaptivePortfolioShell` uses `LayoutBuilder` and selects:

```dart
if (width >= 1024) return MacDesktop(key: const Key('mac-shell'));
if (width >= 600) return AppleMobileShell.tablet(key: const Key('ipad-shell'));
return AppleMobileShell.phone(key: const Key('iphone-shell'));
```

Define `ExternalLauncher` with a production `UrlLauncherExternalLauncher` and allow `PortfolioApp` to receive a fake in tests. Update `main.dart` to run the new app only.

**Step 4: Run and verify GREEN**

Run: `flutter test test/widget_test.dart`

Expected: PASS with placeholder shells.

**Step 5: Commit**

```bash
git add lib/main.dart lib/portfolio/portfolio_app.dart lib/portfolio/services lib/portfolio/widgets test/widget_test.dart
git commit -m "feat: add adaptive Apple portfolio shell"
```

### Task 4: Shared app icons and content surfaces

**Files:**
- Create: `lib/portfolio/theme/apple_theme.dart`
- Create: `lib/portfolio/widgets/apple_app_icon.dart`
- Create: `lib/portfolio/apps/about_app.dart`
- Create: `lib/portfolio/apps/skills_app.dart`
- Create: `lib/portfolio/apps/projects_app.dart`
- Create: `lib/portfolio/apps/terminal_app.dart`
- Create: `lib/portfolio/apps/system_apps.dart`
- Create: `lib/portfolio/apps/portfolio_app_content.dart`
- Create: `test/portfolio/app_content_test.dart`

**Step 1: Write failing content tests**

Require each app to render the user's canonical data and no reference-site identity. Select a second project and assert its title and actions update. Enter a terminal command through the real text field and assert the transcript changes.

**Step 2: Run and verify RED**

Run: `flutter test test/portfolio/app_content_test.dart`

Expected: FAIL because the app surfaces are missing.

**Step 3: Implement minimal shared surfaces**

Create `PortfolioAppContent(appId:, compact:, tablet:)` to route to the appropriate content. Use one shared set of content widgets with adaptive padding and master-detail behavior. Use `CupertinoIcons`/Material symbols and gradient containers instead of downloaded reference assets.

**Step 4: Run and verify GREEN**

Run: `flutter test test/portfolio/app_content_test.dart`

Expected: PASS.

**Step 5: Commit**

```bash
git add lib/portfolio/theme lib/portfolio/widgets/apple_app_icon.dart lib/portfolio/apps test/portfolio/app_content_test.dart
git commit -m "feat: build shared portfolio apps"
```

### Task 5: macOS desktop and window manager

**Files:**
- Create: `lib/portfolio/macos/mac_desktop.dart`
- Create: `lib/portfolio/macos/mac_menu_bar.dart`
- Create: `lib/portfolio/macos/mac_dock.dart`
- Create: `lib/portfolio/macos/mac_window.dart`
- Create: `lib/portfolio/macos/mac_window_state.dart`
- Create: `lib/portfolio/macos/mac_wallpaper.dart`
- Create: `test/portfolio/mac_desktop_test.dart`

**Step 1: Write failing window behavior tests**

Test double-click/Enter opening, duplicate-open focus behavior, close, minimize, Dock restore, maximize/restore, and active-window layering through stable keys such as `desktop-app-about`, `mac-window-about`, `window-close-about`, and `dock-app-about`.

**Step 2: Run and verify RED**

Run: `flutter test test/portfolio/mac_desktop_test.dart`

Expected: FAIL because macOS shell widgets are missing.

**Step 3: Implement the window manager and shell**

Use a `Stack` below a 30-pixel menu bar and above a 94-pixel Dock. Keep a map of `MacWindowState` plus an ordered active-id list. Clamp title-bar drag updates to the visible work area. Render rounded Mica-style windows using `ClipRRect`, `BackdropFilter`, translucent fills, subtle borders, and shadows. Implement menu/Control Center/notification overlays and close them on background tap.

**Step 4: Run and verify GREEN**

Run: `flutter test test/portfolio/mac_desktop_test.dart`

Expected: PASS.

**Step 5: Commit**

```bash
git add lib/portfolio/macos test/portfolio/mac_desktop_test.dart
git commit -m "feat: build interactive macOS desktop"
```

### Task 6: iPadOS and iPhone shells

**Files:**
- Create: `lib/portfolio/mobile/apple_mobile_shell.dart`
- Create: `lib/portfolio/mobile/apple_status_bar.dart`
- Create: `lib/portfolio/mobile/apple_home_grid.dart`
- Create: `lib/portfolio/mobile/apple_mobile_dock.dart`
- Create: `lib/portfolio/mobile/mobile_app_surface.dart`
- Create: `test/portfolio/apple_mobile_shell_test.dart`

**Step 1: Write failing mobile behavior tests**

Require a six-column tablet grid and four-column phone grid, Dock labels, app open/close navigation, safe-area structure, iPad profile widget, and scrollable project details.

**Step 2: Run and verify RED**

Run: `flutter test test/portfolio/apple_mobile_shell_test.dart`

Expected: FAIL because mobile shell widgets are missing.

**Step 3: Implement both form factors**

Share the navigation state and app definitions but vary dimensions, grid count, home widget, typography, and content layout. Use `AnimatedSwitcher` for home/app transitions and never render desktop floating windows below 1024 pixels.

**Step 4: Run and verify GREEN**

Run: `flutter test test/portfolio/apple_mobile_shell_test.dart`

Expected: PASS.

**Step 5: Commit**

```bash
git add lib/portfolio/mobile test/portfolio/apple_mobile_shell_test.dart
git commit -m "feat: add iPadOS and iPhone portfolio shells"
```

### Task 7: Web metadata and deployment readiness

**Files:**
- Modify: `web/index.html`
- Modify: `web/manifest.json`
- Modify: `README.md`
- Test: `test/portfolio/portfolio_data_test.dart`

**Step 1: Add a failing metadata test/check**

Add a small test that reads the source metadata files and expects `민희수`, the new description, and no stale Flutter starter title/reference identity.

**Step 2: Run and verify RED**

Run: `flutter test test/portfolio/portfolio_data_test.dart`

Expected: FAIL on current metadata.

**Step 3: Update metadata and documentation**

Set the title, description, theme color, and manifest names. Document local run, GitHub Pages build with `/portfolio_hesu/`, and future Vercel/root build with `/`. Do not deploy, delete the remote `gh-pages` branch, or change external service settings.

**Step 4: Run and verify GREEN**

Run: `flutter test test/portfolio/portfolio_data_test.dart`

Expected: PASS.

**Step 5: Commit**

```bash
git add web/index.html web/manifest.json README.md test/portfolio/portfolio_data_test.dart
git commit -m "docs: refresh portfolio web metadata"
```

### Task 8: Full verification and visual QA

**Files:**
- Modify as required by verified defects only.

**Step 1: Format**

Run: `dart format lib/portfolio lib/main.dart test`

Expected: exit 0.

**Step 2: Analyze**

Run: `flutter analyze`

Expected: no issues.

**Step 3: Test**

Run: `flutter test`

Expected: all tests pass.

**Step 4: Build both deployment paths**

Run: `flutter build web --release --base-href /portfolio_hesu/ --pwa-strategy=none`

Expected: exit 0 and `build/web/index.html` references `/portfolio_hesu/`.

Run: `flutter build web --release --base-href / --pwa-strategy=none`

Expected: exit 0 for a future Vercel-root artifact.

**Step 5: Browser QA**

Serve the build locally and inspect at 1440×900, 834×1194, and 390×844. Verify shell selection, icon launches, Mac window controls, iPad/iPhone app navigation, project scrolling, terminal commands, responsive orientation, and absence of console errors. Confirm only Min He-su links are present before clicking any external action.

**Step 6: Request code review**

Dispatch a reviewer with the design document and this plan. Fix every critical or important issue, then rerun Steps 1–5.

**Step 7: Integrate safely**

Fast-forward the implementation branch into `main`, verify the merged tree, disable and remove GitHub Pages, then create `dev` from the finalized `main`. Vercel deployment itself remains a later operation.
