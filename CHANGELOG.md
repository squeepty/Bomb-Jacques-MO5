# Changelog

## BUILD 001

Added:

- Initial project structure.
- LWTOOLS build script.
- Direct MO5 video-memory title screen.
- Baseline documentation for memory, video, build notes, and design.
- DCMOTO raw binary output with load-address notes.
- DCMOTO `.k7` cassette image output.

Expected:

- Program loads at `$6000`.
- Screen clears.
- `Bomb Jacques` appears above `BUILD 001`.

Observed:

- Assembles successfully with `lwasm`.
- Emulator behavior still needs DCMOTO verification.

Status:

- Ready for emulator test.
