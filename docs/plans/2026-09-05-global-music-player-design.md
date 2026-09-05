# Global Music Player Design

## Goal

Add one Music launcher and a web-first global BGM player that reads bundled
audio from `assets/music/`, starts only after an explicit user gesture, and
keeps playing while the user navigates between portfolio apps.

## Playback model

`PortfolioApp` owns a single `MusicController` for the lifetime of the page.
Opening or closing the Music window changes only the view; it does not recreate
the player. The initial state is paused so Chrome and Safari never receive an
audible autoplay request before interaction. Once the user presses Play, the
default queue mode advances through the sorted asset list and wraps from the
last track to the first. The alternate `repeat one` mode loops only the active
track. Browser tab mute remains a browser-level control and requires no custom
override.

The controller talks to a small `MusicPlayback` interface rather than directly to a
plugin. The web/runtime adapter lazily creates an `audioplayers` player on the
first playback gesture, while tests use a deterministic fake. This boundary is
also the future replacement point for native background playback and lock
screen controls.

The project pins the compatible `audioplayers` 6.7 line because its current
Flutter 3.38 toolchain does not satisfy the Flutter 3.44 minimum required by
`audioplayers` 6.8. Upgrading Flutter can unlock the newer plugin line later.

## Assets and session state

`MusicAssetLibrary` loads Flutter's `AssetManifest`, filters supported files
under `assets/music/`, and sorts them by file name. A name such as
`01-night-drive.mp3` therefore controls both order and the human-readable title.
Adding files requires a new Flutter/Firebase build because the manifest is
generated at build time. With no audio files, the Music view shows an empty
state and disables playback controls.

The selected track, queue mode, and volume are stored in web `sessionStorage`.
They survive refreshes in the same tab but do not require an account or server.
The restored track remains paused until a new user gesture; the playing flag is
never persisted. Non-web builds use an in-memory implementation until native
persistence is introduced.

## Interaction and animation

The Music screen presents the current track as a large card, the full asset
list, Play/Pause, Previous, Next, volume, and queue-mode controls. Previous and
Next wrap in both directions. Horizontal swipes invoke the same commands as the
buttons. Every navigation increments a revision, even with a one-track list,
so an `AnimatedSwitcher` always runs a perspective Y-axis card flip. Incoming
and outgoing halves swap at 90 degrees to prevent mirrored labels. Completion
uses the same transition: advance in queue mode, restart in repeat-one mode.

Errors from blocked playback or unsupported media restore the paused state and
show an accessible message without losing the selected track.

## Verification

Tests cover asset filtering and ordering, session restoration without autoplay,
play/pause, wraparound navigation, automatic queue advance, repeat-one,
per-navigation animation revisions, rapid command safety, empty/error states,
responsive layout, launcher routing, and global state survival. Final checks
include static analysis, all portfolio feature tests, a release web build, and
manual Chrome rendering. Real decoder playback is verified after an actual
audio file is placed in `assets/music/`.
