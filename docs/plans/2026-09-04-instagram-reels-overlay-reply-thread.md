# Instagram Reels Overlay and Reply Thread Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the static career/education detail card with an image-ready Instagram Reels overlay whose like and comment controls work, and render the real career and education data as a continuous reply thread below it.

**Architecture:** Represent history with two category posts—career and education—instead of one post per individual item or one combined post. Each detail is one vertical `CustomScrollView`: an image-free media slot contains the Reels top bar, right action rail, and bottom account/caption overlay; only the selected category's items are mapped to accessible reply rows below it. Like state is stored independently per category, and the comment action scrolls the same detail controller to that category's reply thread. The redundant feed-level GitHub and email actions are omitted. No generated image, comment composer, fake account, or copied social metric is introduced.

**Tech Stack:** Flutter, Dart, Material widgets, `flutter_test`

---

### Task 1: Lock the corrected detail contract with failing widget tests

**Files:**
- Modify: `test/portfolio/profile_app_test.dart`

**Step 1: Write the failing overlay test**

Assert that `profile-reel-overlay` owns the top bar, action rail, and information overlay; the right rail sits to the right of the information; and the old generated artwork/image widgets are absent.

Also assert that career and education each produce one square category post, the post statistic matches the number of non-empty categories, and no per-item feed cards exist. The visible statistics use `게시물 N개`, `경력 N년`, and `교육 N번`, with no feed-level GitHub or email actions.

**Step 2: Write the failing like test**

Tap `profile-reel-like-action` twice and assert outline → filled red → outline, with `좋아요`/`좋아요 취소` semantics and no invented count.

**Step 3: Write the failing reply-thread test**

Assert that the detail contains one continuous `profile-reel-reply-thread`, renders experiences before education with the injected organization/institution, period, and full description, and contains no `TextField` or comment composer.

**Step 4: Write the failing comment-navigation test**

On a short viewport, tap `profile-reel-comment-action` and assert the detail scroll offset increases until the reply-thread heading is visible.

**Step 5: Run the focused tests and confirm RED**

Run: `flutter test test/portfolio/profile_app_test.dart --reporter expanded`

Expected: FAIL because the overlay/action/thread keys and interactions do not exist and the current detail is a static sibling layout.

### Task 2: Implement the image-ready Reels overlay

**Files:**
- Modify: `lib/portfolio/apps/profile_app.dart`

**Step 1: Add category-post navigation and like state**

Store the selected history category and a liked-category set in `_ProfileAppState`. Preserve each category's like state while navigating back to the feed, without binding a post to an arbitrary individual item.

**Step 2: Replace the static visual with a neutral media slot and overlay stack**

Build `profile-reel-overlay` without `Image`, `RawImage`, `DecorationImage`, or generated artwork. Overlay `Reels` and camera at the top, a heart/comment/share rail at the right, and the real account plus the selected career or education caption at the bottom. Individual item metadata belongs only in the reply rows.

**Step 3: Wire the actions**

The heart toggles its icon, color, semantics, and feedback. The comment button animates the detail scroll controller to the reply thread. Share stays a real accessible control with visible tap feedback but performs no external mutation.

**Step 4: Run the focused overlay and like tests and confirm GREEN**

Run: `flutter test test/portfolio/profile_app_test.dart --reporter expanded`

Expected: overlay and like interaction assertions pass; reply tests remain the only failures until Task 3.

### Task 3: Render career and education as a continuous reply narrative

**Files:**
- Modify: `lib/portfolio/apps/profile_app.dart`
- Modify: `test/portfolio/profile_app_test.dart`

**Step 1: Map existing data without a new comment model**

For the career post, render every experience in source order in `profile-reel-reply-thread`. For the education post, render every education item in source order. Each item is an owner comment; its organization/institution, period, full description, and optional education link appear as indented replies. Never mix the opposite category into the selected post.

**Step 2: Preserve exact data and links**

Do not synthesize usernames or comments. Keep the existing `ExternalLauncher` behavior for education links and place the button inside the relevant education reply.

**Step 3: Make the thread responsive and accessible**

Use semantic comment/reply labels, minimum 44px actions, unclipped multiline text, and a single vertical detail scrollable for touch and mouse at iPhone/iPad sizes and 200% text.

**Step 4: Run the profile suite and confirm GREEN**

Run: `flutter test test/portfolio/profile_app_test.dart --reporter expanded`

Expected: all profile tests pass.

### Task 4: Regression and visual verification

**Files:**
- Modify only if a verified regression requires it.

**Step 1: Format and analyze**

Run: `dart format lib/portfolio/apps/profile_app.dart test/portfolio/profile_app_test.dart`

Run: `flutter analyze`

Expected: no issues.

**Step 2: Run regression tests**

Run: `flutter test test/portfolio/profile_app_test.dart test/portfolio/apple_mobile_shell_test.dart test/portfolio/portfolio_scroll_behavior_test.dart`

Run: `flutter test`

Expected: all tests pass.

**Step 3: Inspect the running mobile surface**

Verify light/dark iPhone and iPad layouts: empty media slot, overlay placement, reversible heart state, comment-to-thread navigation, continuous replies, and no overflow.
