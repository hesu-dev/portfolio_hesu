# Music assets

Place portfolio background-music files in this directory. Supported filenames
use `.mp3`, `.m4a`, `.ogg`, `.wav`, `.aac`, or `.flac`; tracks are discovered
from Flutter's asset manifest and played in filename order.

Use numeric prefixes such as `01-night-drive.mp3` to control the list order.
The web build starts paused until the visitor presses Play. After that gesture,
list mode advances through every track and wraps, while repeat-one mode loops
the current track. The selected track, mode, and volume live only in the
browser tab's session storage; the playing state is never restored automatically.

Run a new Flutter/Firebase build after adding or renaming audio so the generated
asset manifest includes the files.
