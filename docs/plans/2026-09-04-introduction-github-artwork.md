# Separate Introduction App And GitHub Artwork Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a separate Microsoft Word-style `자기소개` app on iPhone, iPad, and Mac, preserve the existing Profile/About apps and default Docks, and replace the GitHub launcher artwork with the supplied image.

**Architecture:** Introduce `PortfolioAppId.introduction` as a first-class route backed by a content-neutral `IntroductionApp`. Add it to the desktop and mobile launcher catalogs, but not to either pinned/default Dock list; the Mac Dock may show it dynamically while its window is running, like every other non-pinned app. Keep Profile labelled `프로필` with its Instagram-inspired painter and About labelled `About` with its existing painter, while the shared artwork widget renders the supplied 512×476 RGBA Word asset only for Introduction and the supplied GitHub asset only for GitHub.

**Tech Stack:** Flutter, Dart, widget tests, bundled PNG assets

---

### Task 1: Specify the separate app identity and launcher catalogs

**Files:**
- Modify: `test/portfolio/portfolio_data_test.dart`
- Modify: `test/portfolio/launcher_catalog_test.dart`
- Modify: `test/portfolio/app_content_test.dart`
- Modify: `lib/portfolio/models/portfolio_app_id.dart`
- Modify: `lib/portfolio/widgets/apple_app_icon.dart`

**Step 1: Write the failing identity and catalog tests**

Add expectations that:

- `PortfolioAppId.values` contains `introduction` immediately after `about`.
- `portfolioLauncherAppIds` and `MacDock.launchableApps` contain `introduction` immediately after `about`.
- `portfolioMobileLauncherAppIds` and `AppleHomeGrid.apps` contain `introduction` immediately after `profile`.
- `AppleAppIcon.labelFor(PortfolioAppId.profile)` remains `프로필`.
- `AppleAppIcon.labelFor(PortfolioAppId.about)` remains `About`.
- `AppleAppIcon.labelFor(PortfolioAppId.introduction)` is `자기소개`.
- `MacDock.pinnedApps` remains exactly `[about, projects]`.
- `AppleMobileDock.apps` remains exactly `[profile, projects]`.

Do not change Profile/About keys, routes, labels, or artwork expectations to Introduction expectations.

**Step 2: Run the focused tests to verify they fail**

Run: `flutter test test/portfolio/portfolio_data_test.dart test/portfolio/launcher_catalog_test.dart test/portfolio/app_content_test.dart`

Expected: FAIL because `PortfolioAppId.introduction` and its label/catalog entries do not yet exist.

**Step 3: Add the enum and public launcher entries**

Add `PortfolioAppId.introduction` after `about`. Insert it after `about` in the Mac/desktop launcher catalog and after `profile` in the mobile launcher catalog. If `portfolioDockAppIds` is retained as a compatibility catalog, add Introduction after About there as well; do not use that compatibility list to redefine either default Dock.

Map only `PortfolioAppId.introduction` to `자기소개` in `AppleAppIcon.labelFor`. Restore or retain the independent mappings:

```dart
PortfolioAppId.profile => '프로필',
PortfolioAppId.about => 'About',
PortfolioAppId.introduction => '자기소개',
```

The existing `windowTitleFor` fallback should provide `자기소개` as the new app's window title without special casing it.

**Step 4: Run the focused tests**

Run: `flutter test test/portfolio/portfolio_data_test.dart test/portfolio/launcher_catalog_test.dart test/portfolio/app_content_test.dart`

Expected: tests compile; route-related assertions may still fail until Task 2.

### Task 2: Add a content-neutral Introduction route

**Files:**
- Create: `lib/portfolio/apps/introduction_app.dart`
- Modify: `lib/portfolio/apps/portfolio_app_content.dart`
- Modify: `test/portfolio/app_content_test.dart`
- Modify: `test/portfolio/portfolio_scroll_behavior_test.dart`

**Step 1: Write the failing route and empty-document tests**

Extend the exhaustive root-key map with:

```dart
'introduction': 'introduction-app',
```

Add a focused widget test that pumps `PortfolioAppId.introduction` at a compact size and verifies:

- `introduction-app`, `introduction-scroll`, and `introduction-document` each exist once.
- The visible title is `자기소개`.
- The neutral status copy is `자기소개서 내용을 추가할 예정입니다.`.
- `portfolioData.identity.biography` is not rendered as substitute copy.
- The content is scrollable on a short viewport without overflow.

Add `PortfolioAppId.introduction` with `Key('introduction-scroll')` to the shared adaptive scroll-behavior targets.

**Step 2: Run the focused tests to verify they fail**

Run: `flutter test test/portfolio/app_content_test.dart test/portfolio/portfolio_scroll_behavior_test.dart`

Expected: FAIL because `IntroductionApp` and its route do not exist.

**Step 3: Implement the minimal future-ready screen**

Create a stateless `IntroductionApp` that accepts `compact` and `tablet`, then renders:

- `AppleAppSurface` with `Key('introduction-app')`.
- A `LayoutBuilder` and bouncing `SingleChildScrollView` with `Key('introduction-scroll')`.
- A centered, constrained document surface with `Key('introduction-document')`.
- Only the user-specified title and neutral future-content message.

Keep the document structure responsive and selectable, but do not add an editor, invent biography text, reuse the short About biography, or add a new `PortfolioData` field before actual self-introduction content is supplied.

Import the new file from `portfolio_app_content.dart` and add the exhaustive route:

```dart
PortfolioAppId.introduction => IntroductionApp(
  compact: compact,
  tablet: tablet,
),
```

The existing generic `MobileAppSurface`, `MacWindow`, and `MacWindowState` handling should supply navigation controls, window management, and default sizing without Introduction-specific branches.

**Step 4: Run the focused tests**

Run: `flutter test test/portfolio/app_content_test.dart test/portfolio/portfolio_scroll_behavior_test.dart`

Expected: PASS.

### Task 3: Lock down the exact supplied assets and artwork behavior

**Files:**
- Create or replace: `assets/icons/microsoft-word.png`
- Create or replace: `assets/icons/github.svg`
- Modify: `pubspec.yaml`
- Modify: `test/portfolio/apple_app_artwork_test.dart`
- Modify: `lib/portfolio/widgets/apple_app_artwork.dart`

**Step 1: Write the failing artwork tests**

Add or update tests that verify:

- `assets/icons/microsoft-word.png` decodes to exactly 512×476 and uses an RGBA PNG payload.
- `assets/icons/github.svg` uses a 24×24 viewBox and contains no background rectangle.
- Introduction renders `assets/icons/microsoft-word.png` through `Image.asset` with `BoxFit.contain` and high-quality filtering.
- The Word image has a stable `apple-app-artwork-introduction-image` key.
- Only Introduction receives an inset of `size * 0.06`, exposed by `apple-app-artwork-introduction-inset`.
- `AppleAppArtwork.colorsFor(PortfolioAppId.introduction)` returns a fully transparent palette.
- GitHub renders `assets/icons/github.svg` instead of `Icons.code_rounded`.
- Profile still uses `CustomPaint`, its original Instagram-inspired palette, and no `Image`.
- About still uses `CustomPaint`, its original blue palette, and no `Image`.

Keep the normalized shared launcher frame around Introduction. Render GitHub as a Projects/Trash-style transparent-frame silhouette so the SVG does not receive an opaque tile or square shadow.

**Step 2: Run the focused artwork tests to verify they fail**

Run: `flutter test test/portfolio/apple_app_artwork_test.dart`

Expected: FAIL if Introduction is missing, if Word is still assigned to Profile/About, if the old 8% inset remains, or if the Word asset is not the final 512×476 RGBA image.

**Step 3: Install and register the final assets**

Place the final supplied files at:

- `assets/icons/microsoft-word.png` — 512×476, 8-bit RGBA.
- `assets/icons/github.svg` — supplied 24×24, transparent-background GitHub vector.

Register both exact paths under `flutter.assets` in `pubspec.yaml`. Keep them under `assets/icons`; do not recreate the retired `assets/image` directory.

**Step 4: Implement the renderer split**

Update `AppleAppArtwork` so that:

- `profile` and `about` remain bespoke painter-backed apps.
- `introduction` and `github` are asset-backed apps.
- `thisMac` remains the only Material-glyph utility app.
- `assetPathFor(introduction)` returns the Word path and `assetPathFor(github)` returns the GitHub path.
- Introduction's palette is two transparent colors; Profile/About retain their original palettes.
- `_buildAssetArtwork` applies a 6% inset only to Introduction and does not add an opaque backing behind its RGBA pixels.
- GitHub resolves `currentColor` without adding a background rectangle. Mac desktop and Mac Dock always use an opaque black mark; iPhone and iPad use the same black mark inside their white rounded launcher tile.
- `_AppleAppArtworkPainter.paint` routes Profile to `_drawProfile`, About to `_drawAbout`, and rejects Introduction/GitHub because their images are rendered outside the painter.

If the earlier incorrect implementation removed `_drawProfile` or `_drawAbout`, restore both methods rather than approximating new artwork.

**Step 5: Run the artwork tests**

Run: `flutter test test/portfolio/apple_app_artwork_test.dart test/portfolio/apple_icon_consistency_test.dart`

Expected: PASS, including every desktop, iPhone, iPad, and Mac Dock artwork frame.

### Task 4: Restore Profile/About semantics and exercise Introduction on each shell

**Files:**
- Modify: `test/portfolio/apple_mobile_shell_test.dart`
- Modify: `test/portfolio/mobile_notes_about_test.dart`
- Modify: `test/portfolio/mobile_navigation_bar_test.dart`
- Modify: `test/portfolio/profile_app_test.dart`
- Modify: `test/portfolio/mac_desktop_test.dart`
- Verify: `test/portfolio/mac_dock_lifecycle_test.dart`
- Verify: `test/portfolio/projects_location_navigation_test.dart`

**Step 1: Restore tests changed by the discarded shared-identity approach**

Restore all Profile expectations to `프로필`, including `Open 프로필`, `Close 프로필 window`, and `Back in 프로필`. Restore all About expectations to `About`, including its open/close/minimize/maximize/restore semantics.

Treat `자기소개` as valid only when the test target is `PortfolioAppId.introduction`.

**Step 2: Add the missing shell integration assertions**

On both 390×844 iPhone and 834×1194 iPad layouts:

- Include `introduction` in the complete home-app list.
- Verify `home-app-profile` and `home-app-introduction` both exist as separate launchers.
- Verify `mobile-dock-profile` and `mobile-dock-projects` exist.
- Verify `mobile-dock-introduction` does not exist.
- Tap `home-app-introduction` and verify `introduction-app` opens with `Close 자기소개 window`.
- Close it and verify the mobile home returns.

On Mac:

- Add `PortfolioAppId.introduction: '자기소개'` to the complete desktop label map while keeping `PortfolioAppId.about: 'About'`.
- Verify `desktop-app-introduction` exists.
- Verify `dock-app-introduction` is absent initially.
- Open Introduction and verify `mac-window-introduction`, `introduction-app`, and the dynamic `dock-app-introduction`/running indicator.
- Close it and verify the non-pinned Dock item disappears.

Do not add Introduction to `_pinnedDockApps`, `MacDock.pinnedApps`, or `AppleMobileDock.apps`. Existing full-catalog window/Dock lifecycle loops may provide the Mac dynamic-Dock assertions; avoid duplicating them when they already make the invariant explicit.

**Step 3: Run the shell and navigation tests**

Run: `flutter test test/portfolio/apple_mobile_shell_test.dart test/portfolio/mobile_notes_about_test.dart test/portfolio/mobile_navigation_bar_test.dart test/portfolio/profile_app_test.dart test/portfolio/mac_desktop_test.dart test/portfolio/mac_dock_lifecycle_test.dart test/portfolio/projects_location_navigation_test.dart`

Expected: PASS with Profile, About, and Introduction independently addressable on their intended surfaces.

### Task 5: Preserve GitHub behavior while changing only its artwork

**Files:**
- Verify: `lib/portfolio/apps/portfolio_app_content.dart`
- Verify: `lib/portfolio/apps/system_apps.dart`
- Verify: `test/portfolio/app_content_test.dart`
- Verify: `test/portfolio/apple_mobile_shell_test.dart`
- Verify: `test/portfolio/mac_desktop_test.dart`

**Step 1: Confirm the route is unchanged**

Keep `PortfolioAppId.github` routed to the existing `GitHubApp`. Do not auto-launch the external URL when its launcher icon is opened.

**Step 2: Run existing GitHub behavior tests**

Run: `flutter test test/portfolio/app_content_test.dart test/portfolio/apple_mobile_shell_test.dart test/portfolio/mac_desktop_test.dart`

Expected: PASS; GitHub opens its internal app first and launches `portfolioData.githubUrl` only after the explicit external action.

### Task 6: Verify the complete deliverable

**Files:**
- Verify: `assets/icons/microsoft-word.png`
- Verify: `assets/icons/github.svg`
- Verify: all modified Dart, YAML, and test files

**Step 1: Verify the asset metadata**

Run: `file assets/icons/microsoft-word.png assets/icons/github.svg`

Expected: Word reports `512 x 476` and `RGBA`; GitHub reports an SVG document.

Run: `sips -g pixelWidth -g pixelHeight -g hasAlpha assets/icons/microsoft-word.png`

Expected: Word reports 512×476 with alpha. Separately verify that GitHub's SVG uses `viewBox="0 0 24 24"` and has no background `<rect>`.

**Step 2: Format only the touched Dart files**

Run: `dart format lib/portfolio/apps/introduction_app.dart lib/portfolio/apps/portfolio_app_content.dart lib/portfolio/models/portfolio_app_id.dart lib/portfolio/widgets/apple_app_artwork.dart lib/portfolio/widgets/apple_app_icon.dart test/portfolio/app_content_test.dart test/portfolio/apple_app_artwork_test.dart test/portfolio/apple_mobile_shell_test.dart test/portfolio/launcher_catalog_test.dart test/portfolio/mac_desktop_test.dart test/portfolio/mobile_navigation_bar_test.dart test/portfolio/mobile_notes_about_test.dart test/portfolio/portfolio_data_test.dart test/portfolio/portfolio_scroll_behavior_test.dart test/portfolio/profile_app_test.dart`

Expected: formatter exits successfully without touching unrelated files.

**Step 3: Run static analysis and the full regression suite**

Run: `flutter analyze`

Expected: PASS with no issues.

Run: `flutter test`

Expected: PASS.

**Step 4: Build the production web portfolio**

Run: `dart run tool/build_web.dart`

Expected: successful production build containing the Introduction and GitHub assets.

**Step 5: Review the final diff**

Run: `git status --short`

Run: `git diff --check`

Expected: only the intended Introduction, artwork, Dock, test, asset, and plan changes are present, with no whitespace errors. Do not create a commit unless the user explicitly asks; preserve unrelated in-progress workspace changes.
