# Responsive Default Dock Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Show a bottom Dock on every responsive form factor, with Profile and Projects pinned on iPhone/iPad and About and Projects pinned on Mac instead of Trash.

**Architecture:** Reuse the dormant `AppleMobileDock` as a home-screen overlay inside `AppleMobileShell`, and reserve matching space in `AppleHomeGrid` so scrollable launchers remain reachable. Refactor `MacDock` into pinned items plus ordered running items, deduplicating pinned apps and allowing Trash to appear only while it is running.

**Tech Stack:** Flutter, Dart, `flutter_test`

---

### Task 1: Define the responsive Dock contract in tests

**Files:**
- Modify: `test/portfolio/apple_mobile_shell_test.dart`
- Modify: `test/portfolio/mac_dock_lifecycle_test.dart`
- Modify: `test/portfolio/mac_desktop_test.dart`
- Modify: `test/portfolio/launcher_catalog_test.dart`

**Step 1: Write the failing tests**

- Assert that iPhone, iPad, and wide mobile-platform layouts render `mobile-dock`.
- Assert that each mobile Dock contains exactly `profile` and `projects`, never `about` or `trash`, and that both entries open the correct app.
- Assert that small/high-text-scale home grids remain scrollable and unobscured by the Dock.
- Assert that an idle Mac Dock contains exactly `about` and `projects`, never `trash`.
- Assert that pinned Mac apps remain after closing, do not duplicate while running, and Trash appears dynamically only while open/minimized.

**Step 2: Run tests to verify they fail**

Run: `flutter test test/portfolio/apple_mobile_shell_test.dart test/portfolio/mac_dock_lifecycle_test.dart test/portfolio/mac_desktop_test.dart test/portfolio/launcher_catalog_test.dart`

Expected: FAIL because the mobile shell does not mount its Dock and the Mac Dock still pins Trash.

### Task 2: Restore the mobile Dock

**Files:**
- Modify: `lib/portfolio/mobile/apple_mobile_dock.dart`
- Modify: `lib/portfolio/mobile/apple_mobile_shell.dart`
- Modify: `lib/portfolio/mobile/apple_home_grid.dart`
- Test: `test/portfolio/apple_mobile_shell_test.dart`

**Step 1: Implement the minimal mobile behavior**

- Use one ordered mobile Dock catalog: `PortfolioAppId.profile`, then `PortfolioAppId.projects`.
- Import and place `AppleMobileDock` at the bottom of the mobile home `Stack` for both phone and tablet layouts.
- Reserve `92` logical pixels on phone and `100` on tablet below the home grid, matching the rendered Dock footprint and offset.

**Step 2: Run the focused mobile tests**

Run: `flutter test test/portfolio/apple_mobile_shell_test.dart`

Expected: PASS with no overflow exceptions at compact sizes or 200% text scale.

### Task 3: Replace the default Mac Trash item with pinned portfolio entries

**Files:**
- Modify: `lib/portfolio/macos/mac_dock.dart`
- Test: `test/portfolio/mac_dock_lifecycle_test.dart`
- Test: `test/portfolio/mac_desktop_test.dart`
- Test: `test/portfolio/launcher_catalog_test.dart`

**Step 1: Implement the minimal desktop behavior**

- Pin `PortfolioAppId.about` and `PortfolioAppId.projects` in that order.
- Build the dynamic list from running desktop launcher apps excluding the pinned IDs, preserving canonical launcher order.
- Render a separator only when dynamic running items exist.
- Keep running indicators on pinned apps and allow Trash to appear dynamically while its window exists.

**Step 2: Run the focused desktop tests**

Run: `flutter test test/portfolio/mac_dock_lifecycle_test.dart test/portfolio/mac_desktop_test.dart test/portfolio/launcher_catalog_test.dart`

Expected: PASS with one instance per Dock item and no overflow at the minimum Mac breakpoint.

### Task 4: Format and verify the complete change

**Files:**
- Verify all modified Dart files.

**Step 1: Format**

Run: `dart format lib/portfolio/mobile/apple_mobile_dock.dart lib/portfolio/mobile/apple_mobile_shell.dart lib/portfolio/mobile/apple_home_grid.dart lib/portfolio/macos/mac_dock.dart test/portfolio/apple_mobile_shell_test.dart test/portfolio/mac_dock_lifecycle_test.dart test/portfolio/mac_desktop_test.dart test/portfolio/launcher_catalog_test.dart`

Expected: Formatter exits successfully.

**Step 2: Analyze**

Run: `flutter analyze`

Expected: No issues found.

**Step 3: Run the full test suite**

Run: `flutter test`

Expected: All tests pass.
