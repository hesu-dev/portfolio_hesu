# Profile Reel Reply and Desktop About Revision Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Simplify profile reel metadata and replies across supported sizes, then localize and trim the desktop About page.

**Architecture:** Keep the existing profile data models and responsive containers. Narrow `_ProfileReelOverlay` to account plus section title, normalize both history types through the existing `_ProfileReplyItem`, and remove the desktop About contact tail at its source.

**Tech Stack:** Flutter, Dart, widget tests, Flutter web build.

---

### Task 1: Lock the simplified reel overlay contract

**Files:**
- Modify: `test/portfolio/profile_app_test.dart`
- Modify: `lib/portfolio/apps/profile_app.dart`

1. Update the career and education detail tests so the overlay must contain the account identity and exactly one section title while excluding the identity headline and `경력 N개` or `교육 N개`.
2. Run the focused tests and confirm RED because both extra lines still render.
3. Remove `itemCount`, `organization`, and `metadata` from the detail-to-overlay API and delete their two text widgets.
4. Run the focused tests and confirm GREEN without changing the feed headline, history-card counts, media, or action rail.
5. Commit as `fix(profile): simplify reel overlay metadata`.

### Task 2: Promote history item titles in the shared reply component

**Files:**
- Modify: `test/portfolio/profile_app_test.dart`
- Modify: `lib/portfolio/apps/profile_app.dart`

1. Change reply-contract tests so career author slots contain `organization` and bodies contain only `period` plus `description`; education author slots contain `institution` and bodies contain `period`, `program`, and any link.
2. Add responsive cases for iPhone, iPad, and a wide standalone Profile surface, including large text, with no horizontal overflow or clipping.
3. Run the focused tests and confirm RED because the current author is the profile identity and the old body duplicates titles and renders roles.
4. Remove `identityName` from `_ProfileReplyItem`, derive the shared title from the current history item, and reduce each body to its new ordered fields.
5. Run the focused and full profile tests, format, and commit as `refactor(profile): promote reply item titles`.

### Task 3: Localize and trim the desktop About page

**Files:**
- Modify: `test/portfolio/about_app_test.dart`
- Modify: `test/portfolio/app_content_test.dart`
- Modify: `test/portfolio/mobile_notes_about_test.dart`
- Modify: `lib/portfolio/apps/about_app.dart`

1. Add or update tests for both wide and narrow desktop content surfaces: require `경력` and `교육`; reject English headings, Contact title/subtitle, email, GitHub URL, and an orphan divider after the last education entry.
2. Run the focused About tests and confirm RED against the current English headings and Contact tail.
3. Rename the two section titles, remove the complete Contact tail and preceding divider, then delete unused Contact-only widgets.
4. Run the focused About and app-content tests and confirm GREEN.
5. Format and commit as `feat(about): localize sections and remove contact`.

### Task 4: Integration and local preview

**Files:**
- Verify: `lib/portfolio/apps/profile_app.dart`
- Verify: `lib/portfolio/apps/about_app.dart`
- Verify: related test files

1. Run `flutter test test/portfolio/profile_app_test.dart`, the focused About suites, `flutter test`, `flutter analyze`, `git diff --check`, and `dart run tool/build_web.dart`.
2. Inspect the Profile Career and Education details at phone/tablet-compatible widths, then inspect desktop About at wide and narrow window sizes.
3. Reuse or restart the static local server and leave `http://127.0.0.1:4174/` open on an updated screen.
4. Request a final spec-compliance and code-quality review, fix any material findings, and re-run affected verification.
