# Education Side Workstation Revision Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Preserve the existing Education pixel scene while making its foreground workstation side-facing, diversifying skyline lights, and centering all boxed status labels.

**Architecture:** Keep the existing sprite sheet, timeline, room painter, background workstations, reel integration, and media dimensions. Add one shared pure pixel-text placement helper used by the Career and Education painters, then revise only Education's skyline-light generator and foreground workstation geometry.

**Tech Stack:** Flutter, Dart, `CustomPainter`, widget tests with raw RGBA inspection.

---

### Task 1: Center the three boxed status labels

**Files:**
- Create: `lib/portfolio/widgets/pixel_text_layout.dart`
- Modify: `lib/portfolio/widgets/career_pixel_runner.dart`
- Modify: `lib/portfolio/widgets/education_pixel_study.dart`
- Test: `test/portfolio/profile_app_test.dart`

1. Add failing tests for the final labels `LEARNING`, `LV + UP!`, and `SESSION COMPLETE`; assert `21C` is absent.
2. Add failing pure-layout tests proving the combined foreground and 1px shadow bounds center within 0.5 logical pixels of representative boxes, including both Career pulse sizes.
3. Run the focused tests and confirm they fail against the current top-left offsets.
4. Implement a shared centered-origin function and centered paint helpers in both painters. Keep stat labels and inline `+1` unchanged.
5. Run focused and full profile tests, format, analyze, and commit as `fix(profile): center pixel status labels`.

### Task 2: Diversify skyline building lights

**Files:**
- Modify: `lib/portfolio/widgets/education_pixel_study.dart`
- Test: `test/portfolio/profile_app_test.dart`

1. Add a failing rendered-pixel test at six progress values for both themes. Require multiple vertical light rows, at least four distinct point masks, a non-empty steady-light intersection, and a substantially larger light-position union than the current one-light-per-building implementation.
2. Confirm RED because the current global parity pattern produces only two masks and one light per building.
3. Implement deterministic multi-row/multi-column window slots with steady, unlit, and independently phased blinking modes. Clip every light to the window sky rectangle.
4. Run focused tests and inspect two captured light/dark frames for stable positions without random shimmer.
5. Run profile tests, format, analyze, and commit as `feat(profile): vary library skyline lights`.

### Task 3: Replace the foreground monitor with a side-view workstation

**Files:**
- Modify: `lib/portfolio/widgets/education_pixel_study.dart`
- Test: `test/portfolio/profile_app_test.dart`

1. Add failing rendered-pixel tests at `progress ~= 0.16` and `0.52` for both 320×258 and 714×288. Require a side laptop screen and base, chair silhouette, typing-hand contact, notebook page above the work surface, and no old wide front-facing monitor in the foreground region.
2. Confirm RED against the current front-facing primary monitor.
3. Keep the character baseline, scale, crop data, eight-pose timeline, background workstations, HUD, and scrims unchanged. Replace only the immediate chair/desk/primary-monitor drawing with the approved side geometry and layer order.
4. Run focused tests and produce temporary before/after motion captures. Iterate until the laptop reads in profile and the action rail stays clear at both sizes; remove temporary capture code.
5. Run profile tests, format, analyze, and commit as `fix(profile): use side-view study workstation`.

### Task 4: Integration and visual verification

**Files:**
- Verify: `lib/portfolio/apps/profile_app.dart`
- Verify: `lib/portfolio/widgets/career_pixel_runner.dart`
- Verify: `lib/portfolio/widgets/education_pixel_study.dart`
- Verify: `test/portfolio/profile_app_test.dart`

1. Capture Education at iPhone 390×844 and iPad 834×1194 in light and dark themes.
2. Capture Education typing, notebook, and session-complete states plus Career level-up.
3. Verify unchanged Career/Education media rectangles, overlay contrast, replies, reduced motion, and accessibility semantics.
4. Run `flutter test test/portfolio/profile_app_test.dart`, `flutter test`, `flutter analyze`, `dart run tool/build_web.dart`, and `git diff --check`.
5. Rebuild the local site and leave `http://127.0.0.1:4174/` open on the Education detail view.
