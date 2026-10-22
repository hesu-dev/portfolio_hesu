# Music assets

The bundled playlist contains one track: **Always**, at `01-always.mp3`.
It is copied unchanged from the supplied `Yogurting BGM - Always.mp3` file.
Replace `01-always.mp3` to update this soundtrack, then rebuild the app.

On iOS, audio continues in the background and publishes the track, duration,
position, and playback state to the lock screen and Control Center. System
play/pause, previous/next, and seeking control the same player as the app.
Calls and disconnected headphones pause playback; resuming is an explicit
user action. Background audio is declared in `ios/Runner/Info.plist` and
the music session uses `audio_service` with `audio_session`. Playback and native
repeat-one use `just_audio`; repeat does not release/recreate the player at
each loop. The app shows elapsed/remaining time and commits seeking when the
time-slider drag ends, separately from volume.

Device check: play Always, go Home or lock the phone, then open Control Center.
Check that Always remains audible and displayed, pause/resume and seek there,
and reopen Music to confirm the same state. Check track completion/repeat
while the phone is locked as well.

Place portfolio music files in this directory. Supported filenames
use `.mp3`, `.m4a`, `.ogg`, `.wav`, `.aac`, or `.flac`; tracks are discovered
from Flutter's asset manifest and played in filename order.

Use numeric prefixes such as `01-night-drive.mp3` to control the list order.
The web build starts paused until the visitor presses Play. After that gesture,
list mode advances through every track and wraps, while repeat-one mode loops
the current track. The selected track, mode, and volume live only in the
browser tab's session storage; the playing state is never restored automatically.

Run a new Flutter/Firebase build after adding or renaming audio so the generated
asset manifest includes the files.
