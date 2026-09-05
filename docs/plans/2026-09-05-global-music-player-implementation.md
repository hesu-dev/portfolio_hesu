# Global Music Player Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add an asset-driven global BGM player with user-initiated web playback, queue and repeat-one modes, session-scoped preferences, and repeatable card-flip navigation.

**Architecture:** A root-owned `MusicController` coordinates an injected playback port, manifest-backed track library, and session store. The Music app observes that controller and owns only presentation; launcher catalogs and shared routing expose the new app on every form factor.

**Tech Stack:** Flutter, Dart, `audioplayers`, `package:web`, Flutter `AssetManifest`, widget/unit tests.

**Compatibility note:** Use `audioplayers: ^6.7.1` with the repository's
Flutter 3.38 toolchain. Version 6.8 requires Flutter 3.44 or newer.

---

### Task 1: Build the music domain and web persistence

**Files:**
- Create: `lib/portfolio/music/music_track.dart`
- Create: `lib/portfolio/music/music_asset_library.dart`
- Create: `lib/portfolio/music/music_playback.dart`
- Create: `lib/portfolio/music/music_controller.dart`
- Create: `lib/portfolio/music/music_session_store.dart`
- Create: `lib/portfolio/music/music_session_store_stub.dart`
- Create: `lib/portfolio/music/music_session_store_web.dart`
- Create: `test/portfolio/music_asset_library_test.dart`
- Create: `test/portfolio/music_controller_test.dart`
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Create: `assets/music/README.md`

**Step 1: Write failing domain tests**

Test supported-extension filtering and stable filename ordering; initial paused
state; restored selection/mode/volume without autoplay; play/pause; previous and
next wraparound; queue completion; repeat-one completion; error recovery; and a
navigation revision that increments on every move.

**Step 2: Run tests and verify RED**

Run: `flutter test test/portfolio/music_asset_library_test.dart test/portfolio/music_controller_test.dart`

Expected: FAIL because the music domain does not exist.

**Step 3: Implement the minimum domain**

Add immutable track and playback-mode models, injected library/store/playback
ports, lazy `audioplayers` adapter, generation-safe controller commands, and
conditional web `sessionStorage` persistence. Declare `assets/music/` and keep a
non-audio README so the empty state can ship before real tracks arrive.

**Step 4: Run tests and verify GREEN**

Run the command from Step 2 and expect all tests to pass.

### Task 2: Build the Music app and repeatable flip interaction

**Files:**
- Create: `lib/portfolio/apps/music_app.dart`
- Create: `test/portfolio/music_app_test.dart`

**Step 1: Write failing widget tests**

Test the empty state, populated list, current-card metadata, initial paused
control, Play/Pause, queue/repeat-one toggle, arrow and swipe wraparound, keyboard
semantics, preserved selection, and a new flip key/revision after every move.

**Step 2: Run tests and verify RED**

Run: `flutter test test/portfolio/music_app_test.dart`

Expected: FAIL because `MusicApp` does not exist.

**Step 3: Implement the responsive player**

Build the current-track card, controls, volume slider, mode control, and asset
list. Route buttons and horizontal drag thresholds through the controller. Use a
perspective Y-axis `AnimatedSwitcher` keyed by track plus revision so each
navigation repeats the two-sided flip without mirrored text.

**Step 4: Run tests and verify GREEN**

Run the command from Step 2 and expect all tests to pass.

### Task 3: Integrate the launcher, icon, and global lifecycle

**Files:**
- Modify: `lib/portfolio/portfolio_app.dart`
- Modify: `lib/portfolio/widgets/adaptive_portfolio_shell.dart`
- Modify: `lib/portfolio/macos/mac_desktop.dart`
- Modify: `lib/portfolio/macos/mac_window.dart`
- Modify: `lib/portfolio/mobile/apple_mobile_shell.dart`
- Modify: `lib/portfolio/mobile/mobile_app_surface.dart`
- Modify: `lib/portfolio/apps/portfolio_app_content.dart`
- Modify: `lib/portfolio/models/portfolio_app_id.dart`
- Modify: `lib/portfolio/widgets/apple_app_artwork.dart`
- Modify: `lib/portfolio/widgets/apple_app_icon.dart`
- Modify: launcher, routing, scroll, and lifecycle tests under `test/portfolio/`

**Step 1: Write failing integration tests**

Assert the Music label and code-native icon, launcher presence on Mac/iPad/iPhone,
content routing, and one controller instance surviving Music-window close and
responsive shell changes while preserving paused/playing selection state.

**Step 2: Run tests and verify RED**

Run the focused catalog, artwork, content, desktop, mobile-shell, and new music
lifecycle tests. Expected: FAIL because Music is not in the shared model/router.

**Step 3: Implement the integration**

Add `PortfolioAppId.music`, a shadow-free red/pink music-note artwork, routing,
controller ownership/injection, and catalog ordering. Do not initialize the real
audio player until a user playback action.

**Step 4: Run tests and verify GREEN**

Run the focused integration suites and expect all tests to pass.

### Task 4: Verify, review, and commit

**Step 1: Format and analyze**

Run: `dart format lib/portfolio test/portfolio`

Run: `flutter analyze lib/portfolio test/portfolio`

Expected: no issues.

**Step 2: Run all functional tests**

Run every `test/portfolio/*_test.dart` except the separate workspace-hygiene
suite. Expected: all functional tests pass.

**Step 3: Build and inspect the web app**

Run: `flutter build web --release --no-web-resources-cdn`

Restart the local server and inspect the Music launcher, empty state, and player
layout in the in-app browser. Actual audible playback requires a user-provided
audio asset.

**Step 4: Review and commit**

Request specification and code-quality reviews, fix all important findings, and
commit only Music-related paths with:

`feat(music): 에셋 기반 전역 BGM 플레이어를 추가`
