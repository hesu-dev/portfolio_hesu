# Music timeline and reliable repeat implementation plan

**Goal:** Keep repeat-one playing reliably, provide iPhone-style seeking above transport and volume, and replace native Flutter launcher icons with the existing portfolio artwork.

**Architecture:** Preserve the app-owned MusicController and audio_service Now Playing handler. Replace audioplayers' completion/release race with just_audio's native loop mode. Expose duration/position/seek through the existing playback boundary; UI drag previews commit one seek at release.

**Tech stack:** Flutter, Cupertino controls, just_audio, audio_service/audio_session, existing flutter_svg artwork.

1. Reproduce the old completion ordering from the installed Darwin source. Add playback tests for native repeat, time events, seeking, and app/system control consistency.
2. Replace the player adapter, preserve serialized controller commands and lazy playback, publish actual position/duration/state, and configure repeat before starting playback and when mode changes. Update the four playback fakes.
3. Add elapsed/remaining time and seek control, then transport, then volume with iPhone-style controls. Verify seeking does not change volume; preserve accessibility, keyboard/swipe, themes and responsive layouts.
4. Rasterize the exact portfolio SVG to native launcher icon sizes, checking dimensions and iOS opacity. Keep existing web branding.
5. Run targeted music/mobile/content tests, static analysis, web build where affected, and signed iPhone release. Inspect the built background mode and signature; confirm actual device repeat with the user if screen/audio verification requires their phone.

No commit or unrelated cleanup is required. Preserve existing uncommitted changes and the signing-cache symlinks.
