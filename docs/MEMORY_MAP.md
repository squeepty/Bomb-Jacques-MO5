# Memory Map

This first map is intentionally small and will be refined as the project is
tested on DCMOTO and real MO5 references.

## BUILD 001 Addresses

| Address | Purpose |
| --- | --- |
| `$0000-$1F3F` | MO5 bitmap/video shape RAM, 8000 bytes |
| `$2000-$3F3F` | MO5 color attribute RAM, 8000 bytes |
| `$6000` | Bomb Jacques program origin |
| `$BFFF` | Temporary stack top |

## Notes

The MO5 has 16 KB of video RAM and 32 KB of user RAM. BUILD 001 loads the
program at `$6000`, leaving room below for BASIC/system workspace and above for
the stack while the project is still tiny.
