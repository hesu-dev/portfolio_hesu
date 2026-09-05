# Dock Polish and App Label Localization Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Unify Finder dock hover/selection styling, correct desktop Dock vertical geometry, verify mobile artwork opacity reuse, and localize launcher labels.

**Architecture:** Keep shared app artwork behavior centralized in `AppleAppArtworkFrame`, scope hover removal to Finder destination buttons, and preserve the existing animated indicator as the sole Finder dock selection surface. Keep the Terminal window title special case in English while localizing launcher labels through `AppleAppIcon.labelFor`.

**Tech Stack:** Flutter, Dart, Material widget tests, golden-free geometry assertions.

---

### Task 1: Refine the inner Finder dock

**Files:**
- Modify: `test/portfolio/apple_finder_mobile_navigation_bar_test.dart`
- Modify: `lib/portfolio/widgets/apple_finder_scaffold.dart`

1. Add failing tests for a transparent hover overlay, neutral-gray selected pill, brighter white border, and an overshooting pulse in both directions on phone and tablet.
2. Run the focused widget test and confirm it fails for the intended reasons.
3. Remove the per-button gray hover overlay, keep selected icon blue, change the indicator to theme-aware gray, strengthen the border, and tune the movement/scale curves.
4. Re-run the focused test until it passes.

### Task 2: Equalize outer Dock vertical spacing

**Files:**
- Modify: `test/portfolio/mac_dock_lifecycle_test.dart`
- Modify: `test/portfolio/apple_mobile_shell_test.dart`
- Modify: `lib/portfolio/macos/mac_dock.dart`
- Modify: `lib/portfolio/widgets/apple_app_icon.dart`

1. Add failing geometry tests comparing icon and separator top/bottom gaps inside the macOS Dock and artwork top/bottom gaps inside the iPhone/iPad Dock.
2. Center the macOS Dock row vertically and center resting/hovered artwork while preserving the running indicator.
3. Omit the unused running-indicator slot for unlabeled, non-running mobile Dock icons so their artwork centers naturally.
4. Re-run Dock lifecycle and responsive shell regression tests.

### Task 3: Localize launcher labels and prove artwork reuse

**Files:**
- Modify: `lib/portfolio/widgets/apple_app_icon.dart`
- Modify: affected tests under `test/portfolio/`

1. Update label expectations first for `배경음`, `이메일`, `스킬`, `터미널`, `git`, plus the remaining English launcher labels `프로필` and `휴지통`.
2. Run the focused test to confirm the centralized mapping is still English.
3. Update `AppleAppIcon.labelFor`, keeping `Terminal - Portfolio zsh` unchanged as the Terminal window title.
4. Add or retain an explicit assertion that the mobile Dock Projects icon uses `AppleAppArtworkFrame` with the same mobile 0.5-alpha tile as the home screen.

### Task 4: Verify and commit

1. Format changed Dart files.
2. Run focused widget tests, the full portfolio test suite, static analysis, and the web build.
3. Review the final diff for unrelated files and regressions.
4. Commit only task-owned files using an Angular-style conventional commit message.
5. Hot-restart the existing local server and visually verify the affected responsive states.
