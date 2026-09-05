# Career Pixel Runner Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the empty career Reels media surface with a responsive pixel-art city runner while removing Reels wording and leaving Education unchanged.

**Architecture:** Add a career-only stateful media widget backed by one deterministic `AnimationController` and one `CustomPainter`. The painter draws all scenery, character frames, jump/coin/level-up events, and effects from normalized timeline progress so the animation remains asset-free, responsive, and testable. The existing overlay actions and reply thread stay in place.

**Tech Stack:** Flutter widgets, `AnimationController`, `CustomPainter`, widget tests, golden-free pixel sampling.

---

### Task 1: Define the career-only UI contract

**Files:**
- Modify: `test/portfolio/profile_app_test.dart`

**Step 1: Write the failing test**

- Open the career detail and assert that `Reels` is absent.
- Assert a keyed runner fills `profile-reel-media-slot` and exposes one descriptive image semantic.
- Return to the feed, open Education, and assert that the runner is absent.
- Assert the iPad sidebar entry is named `경력 보기`, not `릴스 보기`.

**Step 2: Run test to verify it fails**

Run: `flutter test test/portfolio/profile_app_test.dart --plain-name '경력 상세는 Reels 문구 대신 도심 픽셀 러너를 미디어 슬롯에 채운다'`

Expected: FAIL because the runner key is missing and `Reels` is still visible.

### Task 2: Add deterministic motion contracts

**Files:**
- Modify: `test/portfolio/profile_app_test.dart`
- Create: `lib/portfolio/widgets/career_pixel_runner.dart`

**Step 1: Write the failing tests**

- Verify timeline samples cover grounded running, a jump arc, coin collection, and the level-up window.
- Verify reduced-motion mode exposes the same scene without an endlessly scheduled frame.

**Step 2: Run tests to verify they fail**

Run: `flutter test test/portfolio/profile_app_test.dart --plain-name '경력 픽셀 러너'`

Expected: FAIL because the timeline and widget do not exist.

**Step 3: Implement the minimal timeline and widget shell**

- Add a normalized deterministic timeline.
- Add `CareerPixelRunner` with a `RepaintBoundary`, one image semantic, and reduced-motion handling.
- Keep animation painting isolated from layout rebuilds.

**Step 4: Run focused tests**

Run: `flutter test test/portfolio/profile_app_test.dart --plain-name '경력 픽셀 러너'`

Expected: PASS.

### Task 3: Paint the city runner scene

**Files:**
- Modify: `lib/portfolio/widgets/career_pixel_runner.dart`

**Step 1: Implement the painter**

- Snap geometry to a virtual pixel grid and disable antialiasing.
- Draw a bright pixel sky, looping clouds, layered buildings, AT CENTER, 판교역, and a recurring convenience store.
- Draw a two-head-tall fair-skinned woman with brown ponytail, glasses, and a dark business suit.
- Animate alternating run poses, ponytail/jacket motion, occasional jump arcs, gold coins, spark bursts, speed lines, and a `LV UP` event.
- Add foreground scrims only where existing white overlay controls need contrast.

**Step 2: Verify animation frames differ**

Run the focused widget test with bounded `pump` durations and compare the painter timeline/frame state rather than waiting for settlement.

Expected: PASS with deterministic frame changes.

### Task 4: Integrate and regress

**Files:**
- Modify: `lib/portfolio/apps/profile_app.dart`
- Modify: `test/portfolio/profile_app_test.dart`

**Step 1: Wire the runner into career detail only**

- Pass the history kind into `_ProfileReelOverlay`.
- Replace the career media `ColoredBox` child with `CareerPixelRunner`.
- Remove the visible `Reels` heading and rename the sidebar semantic to `경력 보기`.
- Preserve all action keys, detail geometry, likes, comments, sharing, and reply behavior.

**Step 2: Update obsolete assertions**

- Remove the old contract that required visible `Reels` text and forbade all `CustomPaint` in the media slot.
- Keep the Education empty-media contract and all layout/accessibility coverage.

**Step 3: Format and run verification**

Run: `dart format lib/portfolio/apps/profile_app.dart lib/portfolio/widgets/career_pixel_runner.dart test/portfolio/profile_app_test.dart`

Run: `flutter test test/portfolio/profile_app_test.dart`

Run: `flutter test`

Run: `flutter analyze`

Expected: all tests pass and analysis reports no issues.
