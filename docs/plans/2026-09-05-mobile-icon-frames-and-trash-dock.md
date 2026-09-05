# Mobile Icon Frames And Trash Dock Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add white rounded launcher tiles to the iPhone/iPad Projects, GitHub, and Trash icons; move Trash to the far-right Mac Dock utility area; remove launcher artwork drop shadows; and keep desktop GitHub black in every theme.

**Architecture:** Keep artwork data shared, but make the launcher surface explicit at each call site. Mobile launchers opt into a white rounded backing, while Mac desktop and Dock retain transparent silhouettes. Mac Dock owns an always-present Trash utility item after one separator, and the Mac desktop catalog excludes Trash.

**Tech Stack:** Flutter, Dart, `flutter_svg`, Flutter widget tests.

---

### Task 1: Define the mobile white launcher surface

**Files:**
- Modify: `lib/portfolio/widgets/apple_app_artwork.dart`
- Modify: `lib/portfolio/widgets/apple_app_icon.dart`
- Modify: `lib/portfolio/mobile/apple_home_grid.dart`
- Modify: `lib/portfolio/mobile/apple_mobile_dock.dart`
- Test: `test/portfolio/apple_app_artwork_test.dart`
- Test: `test/portfolio/apple_mobile_shell_test.dart`

**Step 1: Write the failing tests**

Assert that Projects, GitHub, and Trash render inside white rounded tiles on both iPhone and iPad home surfaces, while their Mac frames remain transparent.

**Step 2: Run tests to verify RED**

Run: `flutter test test/portfolio/apple_app_artwork_test.dart test/portfolio/apple_mobile_shell_test.dart --reporter failures-only`

Expected: FAIL because transparent artwork currently has no mobile backing.

**Step 3: Implement the minimal surface override**

Add an explicit mobile white-tile option to `AppleAppIcon` and `AppleAppArtworkFrame`. Apply it from `AppleHomeGrid` and `AppleMobileDock`; keep Mac call sites on the transparent default.

**Step 4: Run tests to verify GREEN**

Run the focused command from Step 2 and expect all tests to pass.

### Task 2: Move Trash into the Mac Dock utility area

**Files:**
- Modify: `lib/portfolio/macos/mac_desktop.dart`
- Modify: `lib/portfolio/macos/mac_dock.dart`
- Test: `test/portfolio/mac_desktop_test.dart`
- Test: `test/portfolio/mac_dock_lifecycle_test.dart`

**Step 1: Write the failing tests**

Assert that Trash is absent from the Mac desktop grid, always present at the Dock's far-right edge, and preceded by exactly one separator. Verify that opening, minimizing, restoring, and closing Trash preserves the fixed Dock item while its running indicator follows window state.

**Step 2: Run tests to verify RED**

Run: `flutter test test/portfolio/mac_desktop_test.dart test/portfolio/mac_dock_lifecycle_test.dart --reporter failures-only`

Expected: FAIL because Trash is currently a desktop launcher and only appears in the Dock while running.

**Step 3: Implement the fixed utility item**

Exclude Trash from the Mac desktop catalog, exclude it from the dynamic-running list, render the ordinary Dock group first, then one separator, then Trash.

**Step 4: Run tests to verify GREEN**

Run the focused command from Step 2 and expect all tests to pass.

### Task 3: Remove artwork shadows and pin desktop GitHub to black

**Files:**
- Modify: `lib/portfolio/widgets/apple_app_artwork.dart`
- Modify: `lib/portfolio/macos/mac_desktop.dart`
- Modify: `lib/portfolio/macos/mac_dock.dart`
- Test: `test/portfolio/apple_app_artwork_test.dart`
- Test: `test/portfolio/mac_dock_lifecycle_test.dart`

**Step 1: Write the failing tests**

Assert that every `AppleAppArtworkFrame` has no default box shadow. Assert that GitHub uses opaque black in both Light and Dark Mac desktop/Dock surfaces and inside the mobile white tile.

**Step 2: Run tests to verify RED**

Run: `flutter test test/portfolio/apple_app_artwork_test.dart test/portfolio/mac_dock_lifecycle_test.dart --reporter failures-only`

Expected: FAIL because framed artwork has a drop shadow and Mac GitHub is currently white/theme-derived.

**Step 3: Implement the minimal visual changes**

Remove the default artwork-frame `boxShadow`. Pass `Colors.black` for GitHub from Mac desktop and Dock call sites only.

**Step 4: Run tests to verify GREEN**

Run the focused command from Step 2 and expect all tests to pass.

### Task 4: Verify the complete result

**Files:**
- Verify all modified Dart, test, and plan files.

**Step 1: Format and analyze**

Run: `dart format <touched Dart files>`

Run: `flutter analyze lib/portfolio test/portfolio`

Expected: no issues.

**Step 2: Run affected test suites**

Run the artwork, mobile shell, Mac desktop, Dock lifecycle, launcher catalog, and icon consistency suites.

Expected: all affected tests pass.

**Step 3: Verify the live app**

Reload `http://127.0.0.1:8765/` from the existing no-CDN local server and inspect representative iPhone, iPad, and Mac layouts.

### Task 5: Align Finder folders and expose Profile replies

- Align the constrained project grid and every wrapped folder row to the leading edge.
- End the Profile reel media surface just below the share icon so the first reply is visible without an initial scroll.
- Replace the prior centered/full-viewport test contracts with responsive leading-edge and reply-visibility tests.

### Task 6: Build GitHub, Photos, and Mail application surfaces

- Model three verified public repositories (`portfolio_hesu`, `chrome_extension`, and `code_study`) and open each repository card through the shared external launcher.
- Replace the Photos placeholder with a responsive library, 12 code-native thumbnails, filterable albums, and an accessible single-photo detail view that returns to the preserved gallery state.
- Replace the Mail profile card with recipient, subject, body, and a send action that constructs a safely encoded `mailto:` URI.

### Task 7: Add session-only Trash behavior

- Keep Trash state in the adaptive shell so it survives Mac/iPad/iPhone breakpoint changes.
- Show a deterministic temporary-item list and an Empty action.
- Require `Y` in the confirmation dialog before switching to the empty state; do not delete files or persist data.
- Propagate the state through desktop Dock, mobile home, app content, and the Trash painter so filled/empty artwork stays synchronized.
