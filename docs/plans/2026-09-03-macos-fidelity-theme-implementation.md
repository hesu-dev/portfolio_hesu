# macOS Fidelity and Theme Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the adaptive portfolio default to Light mode and add a settings-driven Dark mode while refining the desktop into a faithful modern Mac experience with an original code-native wallpaper, a display notch, recognizable app artwork, dynamic Dock behavior, Notes-style About content, and Slack-inspired Skills content.

**Architecture:** `PortfolioApp` owns a two-value theme controller and passes it through the adaptive shell to a shared Settings app. Existing portfolio data remains the content source. macOS presentation uses shared vector artwork and traffic controls, while the Dock derives its pinned and dynamic sections from window-manager state. iPad and iPhone reuse the artwork, settings, About, and Skills components without gaining desktop floating windows.

**Tech Stack:** Flutter/Dart, widget tests, CustomPainter/code-native vector shapes, locally extracted WebP frames from installed macOS Sonoma movies.

---

### Task 1: Global Light and Dark preference

**Files:**
- Create: `lib/portfolio/theme/portfolio_theme_controller.dart`
- Modify: `lib/portfolio/portfolio_app.dart`
- Modify: `lib/portfolio/widgets/adaptive_portfolio_shell.dart`
- Test: `test/portfolio/theme_controller_test.dart`
- Test: `test/widget_test.dart`

**Step 1: Write the failing tests**

Test that the controller exposes exactly Light and Dark, defaults to Light regardless of platform brightness, notifies once for a real change, and does not notify for an identical selection. Pump `PortfolioApp` under a dark host/platform and assert that its initial `MaterialApp.themeMode` is `ThemeMode.light`, title remains data-derived, and color remains `#121316`.

**Step 2: Run tests to verify RED**

Run: `flutter test test/portfolio/theme_controller_test.dart test/widget_test.dart`

Expected: FAIL because the controller does not exist and the app still uses a fixed or system-driven theme mode.

**Step 3: Implement the controller and root ownership**

Define:

```dart
enum PortfolioThemePreference { light, dark }

class PortfolioThemeController extends ChangeNotifier {
  PortfolioThemeController({
    PortfolioThemePreference initial = PortfolioThemePreference.light,
  }) : _preference = initial;

  PortfolioThemePreference get preference => _preference;
  ThemeMode get themeMode => _preference == PortfolioThemePreference.light
      ? ThemeMode.light
      : ThemeMode.dark;

  void select(PortfolioThemePreference value) { /* notify on change only */ }
}
```

Make `PortfolioApp` stateful, own or accept an injected controller, dispose only an internally owned controller, and rebuild `MaterialApp` through `AnimatedBuilder`. Pass the same controller through the adaptive shell without recreating shell or application keys.

**Step 4: Run GREEN verification**

Run: `flutter test test/portfolio/theme_controller_test.dart test/widget_test.dart`

Expected: PASS.

**Step 5: Commit in small units**

```bash
git commit -m "test(theme): 화면 모드 전환 계약 검증"
git commit -m "feat(theme): 라이트 기본 전역 테마 제어 추가"
```

### Task 2: Settings application and app ID wiring

**Files:**
- Modify: `lib/portfolio/models/portfolio_app_id.dart`
- Modify: `lib/portfolio/widgets/apple_app_icon.dart`
- Modify: `lib/portfolio/apps/portfolio_app_content.dart`
- Create: `lib/portfolio/apps/settings_app.dart`
- Modify: `lib/portfolio/macos/mac_desktop.dart`
- Modify: `lib/portfolio/mobile/apple_mobile_shell.dart`
- Modify: `lib/portfolio/mobile/apple_home_grid.dart`
- Test: `test/portfolio/settings_app_test.dart`
- Test: `test/portfolio/apple_mobile_shell_test.dart`
- Test: `test/portfolio/mac_desktop_test.dart`

**Step 1: Write failing behavior tests**

Require `PortfolioAppId.settings`, stable keys `settings-app`, `theme-light`, and `theme-dark`, no text or control named Automatic/System/자동, and explicit Light/Dark selection. Verify Mac, iPad, and iPhone all open Settings, changing a preference immediately changes theme brightness, and open-window/app state survives.

**Step 2: Run RED**

Run: `flutter test test/portfolio/settings_app_test.dart test/portfolio/apple_mobile_shell_test.dart test/portfolio/mac_desktop_test.dart`

Expected: FAIL because Settings is missing.

**Step 3: Implement Settings**

Add a Settings app with one navigation item, `화면 모드`. Wide layouts use a sidebar and preview-card detail; compact layouts stack the same choices. Use semantic radio/selected states, 44-pixel targets, Enter/Space activation, visible focus, and theme-derived AA colors. Pass the shared controller through `PortfolioAppContent` rather than looking it up globally.

**Step 4: Run GREEN and commit**

```bash
flutter test test/portfolio/settings_app_test.dart test/portfolio/apple_mobile_shell_test.dart test/portfolio/mac_desktop_test.dart
git commit -m "test(settings): 화면 모드 설정 동작 명세"
git commit -m "feat(settings): 라이트와 다크 설정 앱 추가"
git commit -m "feat(responsive): 모든 기기에 설정 앱 연결"
```

### Task 3: Original Mac-inspired wallpaper and display notch

**Files:**
- Modify: `lib/portfolio/macos/mac_wallpaper.dart`
- Modify: `lib/portfolio/macos/mac_menu_bar.dart`
- Test: `test/portfolio/mac_visual_fidelity_test.dart`

**Step 1: Define the two deterministic compositions**

Define original Light and Dark palettes, gradient stops, and bezier-like flowing layers in Flutter. Do not copy or derive pixels from Apple wallpaper, application, or ICNS resources.

**Step 2: Write RED tests**

Require Light/Dark theme-dependent painter variants, no wallpaper binary assets, a centered `mac-display-notch`, and menu regions that do not intersect the notch at 1024×700 and 200% text.

**Step 3: Implement the wallpaper and notch**

Render the selected original composition with a custom painter. Add a black 170–180px notch with rounded lower corners. Split menu content around a reserved center region and reduce secondary labels at constrained widths.

**Step 4: Verify and commit**

```bash
flutter test test/portfolio/mac_visual_fidelity_test.dart
git commit -m "test(mac): 배경과 디스플레이 노치 검증"
git commit -m "feat(mac): 오리지널 배경과 상단 노치 적용"
```

### Task 4: Shared application artwork

**Files:**
- Create: `lib/portfolio/widgets/apple_app_artwork.dart`
- Modify: `lib/portfolio/widgets/apple_app_icon.dart`
- Test: `test/portfolio/apple_app_artwork_test.dart`

**Step 1: Write RED tests**

Test deterministic artwork kinds for About/Finder, Skills/Slack, Projects/folder, Terminal, Mail, and Settings. Verify each tile has the correct stable artwork key, no generic Material icon for these six apps, usable semantics inherited from `AppleAppIcon`, and no remote or ICNS asset.

**Step 2: Implement code-native artwork**

Build each icon from Flutter containers, paths, and small painters. Keep artwork excluded from semantics so the parent button owns the accessible label. Scale from the supplied tile size so desktop and mobile remain consistent.

**Step 3: Verify and commit**

```bash
flutter test test/portfolio/apple_app_artwork_test.dart test/portfolio/app_content_test.dart
git commit -m "test(icon): macOS 앱 아트워크 매핑 검증"
git commit -m "feat(icon): Finder와 시스템 앱 아트워크 구현"
```

### Task 5: Shared traffic controls and dynamic Dock

**Files:**
- Create: `lib/portfolio/macos/mac_traffic_controls.dart`
- Modify: `lib/portfolio/macos/mac_window.dart`
- Modify: `lib/portfolio/macos/mac_dock.dart`
- Modify: `lib/portfolio/macos/mac_desktop.dart`
- Test: `test/portfolio/mac_desktop_test.dart`
- Test: `test/portfolio/mac_visual_fidelity_test.dart`

**Step 1: Write RED tests**

Require a single `MacTrafficControls` instance per open window, color-only circles with no descendant `Icon`, preserved stable action keys, and at least 28-pixel targets. Test the Dock decoration has no outer border and uses a near-white translucent fill. Verify Settings/This Mac/GitHub appears only while running, remains while minimized, restores/focuses on activation, and disappears on close; pinned launchers remain and only lose their running indicator.

**Step 2: Implement controls and Dock sections**

Extract the existing private traffic-light code into the public shared component. Derive Dock children from pinned IDs, window-manager running IDs, and fixed utilities; never duplicate an app ID. Keep running app order stable by first-open order and preserve existing single-window/z-order behavior.

**Step 3: Verify and commit**

```bash
flutter test test/portfolio/mac_desktop_test.dart test/portfolio/mac_visual_fidelity_test.dart
git commit -m "refactor(window): 창 제어 버튼을 공용 컴포넌트로 분리"
git commit -m "style(window): 트래픽 라이트 내부 아이콘 제거"
git commit -m "style(dock): 무테 유백색 Dock 적용"
git commit -m "feat(dock): 실행 중 앱 동적 영역 추가"
```

### Task 6: Notes-style About card

**Files:**
- Modify: `lib/portfolio/apps/about_app.dart`
- Test: `test/portfolio/app_content_test.dart`

**Step 1: Write RED tests**

Require `about-notes-card`, `about-notes-header`, and `about-notes-body`; assert all identity strings come from injected `PortfolioData`, the header says `메모`, and the card scrolls without exception at 320×480/200% and 390×844/200%.

**Step 2: Implement the card**

Merge identity and introduction into a yellow-header Notes card with a code-native white folder outline, dotted separator, and readable theme-aware paper body. Leave career, education, and contact below it and keep link behavior intact.

**Step 3: Verify and commit**

```bash
flutter test test/portfolio/app_content_test.dart test/portfolio/apple_mobile_shell_test.dart test/portfolio/mac_desktop_test.dart
git commit -m "test(about): 메모 카드 소개 화면 명세"
git commit -m "feat(about): 소개 정보를 메모 카드로 구성"
```

### Task 7: Slack-inspired Skills application

**Files:**
- Modify: `lib/portfolio/apps/skills_app.dart`
- Test: `test/portfolio/app_content_test.dart`
- Test: `test/portfolio/apple_mobile_shell_test.dart`

**Step 1: Write RED tests**

Require wide keys `skills-workspace-rail`, `skills-channel-sidebar`, and `skills-channel-detail`; preserve `skills-category-*`, `skills-list`, and `skill-item-*`. Test injected groups, selection state, Tab/Enter/Space, 44-pixel targets, visible focus, Light/Dark AA colors, and compact scrolling at 320×480/200%.

**Step 2: Implement Slack-inspired information architecture**

Use a deep-purple workspace rail and channel sidebar in wide mode, with portfolio-derived workspace/channel names and message-like skill rows. Use a compact horizontal channel strip and vertical rows below the wide breakpoint. Do not copy any organization, text, avatar, or channel from the screenshot.

**Step 3: Verify and commit**

```bash
flutter test test/portfolio/app_content_test.dart test/portfolio/apple_mobile_shell_test.dart
git commit -m "test(skills): Slack형 기술 화면 동작 명세"
git commit -m "feat(skills): 기술 목록을 Slack형 화면으로 재구성"
```

### Task 8: Integration, documentation, and visual QA

**Files:**
- Modify: `README.md`
- Modify: `test/widget_test.dart`
- Modify: `test/portfolio/web_metadata_test.dart` if an asset contract is needed

**Step 1: Add integration assertions**

Test all exact responsive boundaries, theme changes on each shell, state preservation while switching theme, no forbidden identity, code-native wallpaper variants, and absence of automatic/system theme choices.

**Step 2: Document attribution and non-affiliation**

Document that the interface is an independent portfolio inspired by familiar desktop/mobile patterns, uses independently drawn wallpaper and application artwork, and is not affiliated with Apple or Slack.

**Step 3: Run full verification**

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release --base-href /portfolio_hesu/ --pwa-strategy=none
flutter build web --release --base-href / --pwa-strategy=none
git diff --check
```

Serve the root build and inspect 1440×900, 1024×700, 834×1194, 600×400, 390×844, and 320×480. Exercise every desktop icon, traffic control, Dock restore/focus, theme switch, About card, Skills channel selection, Projects scrolling, and Terminal input. Confirm no console errors and no stale owner identity.

**Step 4: Commit**

```bash
git commit -m "test(responsive): Apple 화면 전체 회귀 검증"
git commit -m "docs(readme): macOS 자산과 비제휴 안내 추가"
```
