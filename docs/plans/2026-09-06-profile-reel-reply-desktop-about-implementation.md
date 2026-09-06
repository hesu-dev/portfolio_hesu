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

### Task 5: Align desktop history entry hierarchy

**Files:**
- Modify: `test/portfolio/about_app_test.dart`
- Modify: `test/portfolio/app_content_test.dart`
- Modify: `test/portfolio/mobile_notes_about_test.dart`
- Modify: `lib/portfolio/apps/about_app.dart`

1. Add a widget test requiring career `organization + period` above an indented `description`, rejecting `role`; require education `institution + period` above an indented `program` while retaining the optional link.
2. Run the focused About tests and confirm RED against the existing role-first and program-first layouts.
3. Add one private shared history-entry presentation widget and map each data type into its title, period, body, and optional footer slots.
4. Run the focused About tests and compact 200% text case and confirm GREEN.

### Task 6: Remove traffic-light tooltips and identify maximize

**Files:**
- Modify: `test/portfolio/mac_desktop_test.dart`
- Modify: `lib/portfolio/macos/mac_traffic_controls.dart`

1. Change the traffic-light widget test to reject descendant `Tooltip` widgets and require maximize/restore glyphs while retaining accessible labels, pointer sizes, focus, and callbacks.
2. Run the focused test and confirm RED because tooltips exist and the green control has no glyph.
3. Remove only the visual Tooltip wrapper, preserving outer Semantics, and supply state-aware maximize/restore glyphs plus the decorative maximize glyph.
4. Run the traffic-light tests and confirm GREEN.

### Task 7: Rename the desktop system-menu profile action

**Files:**
- Modify: `test/portfolio/mac_desktop_test.dart`
- Modify: `lib/portfolio/macos/mac_menu_bar.dart`

1. Update the system-menu test to require `민희수 프로필 보기` and reject `About This Portfolio`, while still asserting that activation opens the About window.
2. Run the focused test and confirm RED on the old label.
3. Replace the menu-item label without changing its key, icon, callback, focus, or dismissal behavior.
4. Run the focused menu-bar tests and confirm GREEN.

### Task 8: Rebuild, review, and reconnect the preview

**Files:**
- Verify: all files changed in Tasks 5-7

1. Run the focused suites, full test suite, analyzer, formatter check, and `git diff --check`.
2. Build the Flutter web output, keep the static server on port 4174 available, and open a cache-busted local URL.
3. Inspect the desktop About history hierarchy, traffic-light glyphs without hover tooltips, and renamed system-menu action in the browser.
4. Request final spec and code-quality review, address material findings, commit with an Angular-style message, and leave the verified local page open.
