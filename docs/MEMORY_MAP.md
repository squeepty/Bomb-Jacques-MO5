# Memory Map

This map is intentionally small and will be refined as the project is tested on
DCMOTO and real MO5 references.

## BUILD 008 Addresses

| Address | Purpose |
| --- | --- |
| `$0000-$1F3F` | MO5 video RAM window, bitmap or color plane selected by `$A7C0` |
| `$6000` | Bomb Jacques program origin |
| `$6000-$9ADE` | Current assembled game binary range |
| `$9FFF` | Temporary stack top |
| `$A7C0-$A7C3` | System PIA, including video plane select and keyboard matrix port |
| `$A7CC-$A7CF` | Standard MO5 game-extension PIA when present |

## Notes

The MO5 has 16 KB of video RAM and 32 KB of user RAM. BUILD 008 loads the
program at `$6000`, leaving room below for BASIC/system workspace and a small
stack gap above the current `$9ADE` binary end.

Early writable variables are currently assembled after the routines that own
them. A later milestone should reserve a named game-state block once the state
layout stabilizes.
