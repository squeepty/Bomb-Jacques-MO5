# Bomb Jacques

Bomb Jacques is a one-screen arcade game for the Thomson MO5, written in
Motorola 6809 assembly.

The project has two goals:

1. Build a fun, plausible 1985-style MO5 arcade game.
2. Serve as a highly documented learning project for MO5 assembly development.

The codebase is intentionally organized like a teaching project. Source files
favor readable labels, small routines, explicit constants, and companion
documentation over clever compression. The long-term idea is that someone can
learn how an MO5 game is assembled, loaded, rendered, controlled, and evolved by
reading both the assembly and the docs side by side.

## Current Milestone

The current game milestone is:

```text
BOMB JACQUES BUILD 008
milestone-game-feature-complete
```

BUILD 008 is feature-complete for the current gameplay target. It includes:

- title screen and hall-of-fame attract flow
- high-score name entry
- ten handcrafted levels
- level-clear and get-ready transitions
- score, lives, death, respawn, and game-over flow
- bonus, power, and energy item progression
- enemy freeze and frozen-enemy scoring
- score popups
- editable right-panel bitmap art
- browser sprite editor for gameplay sprites and sidebar art
- cassette image output for DCMOTO

Sound effects are still deferred. Final DCMOTO play-through verification and
small visual polish remain appropriate before treating the build as a release
candidate.

## Game Concept

Bomb Jacques is inspired by the gameplay spirit of Bomb Jack, but it is not an
arcade conversion. The design question is:

```text
What if this kind of single-screen bomb-collection game had been made
specifically for the Thomson MO5?
```

Jacques starts in a fixed arena with platforms, bombs, enemies, and a right-side
status panel. The objective is to collect every bomb while avoiding enemies.
One bomb is highlighted as the current lit-bomb target; collecting that bomb is
worth more points and advances the highlighted target to another remaining bomb.

The game is built around MO5-friendly constraints:

- 320x200 display
- 40x25 grid of 8x8 gameplay cells
- simple 2x2-cell moving sprites
- separate bitmap and color planes
- conservative redraw strategy to reduce flicker
- 6809 assembly code assembled as one educational unit

## Gameplay Summary

Each level follows this loop:

1. `GET READY` is shown.
2. Jacques begins active play.
3. Enemies and timed items appear while Jacques collects bombs.
4. Collecting all bombs shows `WELL DONE!`.
5. The next arena loads.

After level 10, level progression wraps back to level 1.

## Controls

Keyboard fallback controls:

| Input | Action |
| --- | --- |
| `Q` | Move left. |
| `D` | Move right. |
| `Space` | Jump. Holding jump while falling slows descent. |
| `N` | Skip to the next level only when the `SQUEEPTY` cheat is active. |

The standard MO5 game-extension joystick is also read when present.

Name-entry controls:

| Input | Action |
| --- | --- |
| `A-Z` | Type a high-score name character. |
| `Enter` | Commit the name. |
| `Backspace` | Erase the previous character. |
| Joystick/keyboard left or right | Cycle the current name character. |
| Fire or up | Confirm the current name character. |

Cheat:

```text
SQUEEPTY
```

Enter the cheat on the title or hall-of-fame screen. When active, enemy hits do
not decrement lives and `N` advances to the next level during gameplay.

## Scoring And Lives

Jacques starts with 3 lives.

| Event | Score |
| --- | ---: |
| Normal bomb | 50 |
| Lit bomb | 200 |
| Bonus Ball | 500 |
| Frozen enemy | 100 |

The Energy Ball restores one life only when Jacques has fewer than 3 lives.

Touching an active enemy starts the death sequence unless Jacques is in respawn
grace or the enemy is frozen and collectable. During death, gameplay movement
freezes and Jacques flies straight up offscreen while cycling jump poses. If
lives remain, he respawns after a short hold and gets a blinking grace period.
If no lives remain, the score is checked for hall-of-fame entry.

## Enemies And Items

Enemy behavior:

| Sprite | Count | Appears | Chase | Movement |
| --- | ---: | --- | --- | --- |
| Enemy 2 flyer | 1 | At start | 80% | Horizontal and vertical |
| Enemy 1 walker | 4 | One every 5 seconds | None | Falls, then walks left/right |
| Enemy 1 phase 2 hunter | 3 | When a walker reaches ground | 70%/80%/50% by slot | Horizontal and vertical |
| Enemy 1 phase 3 hunter | 1 | When the phase-3 slot reaches ground | 80% | Horizontal and vertical, faster |

Item behavior:

| Item | Appears | Effect |
| --- | --- | --- |
| Bonus Ball | After 20 seconds of active play | Awards 500 points. |
| Power Ball | 20 seconds after the Bonus Ball is caught | Freezes active enemies. |
| Energy Ball | 20 seconds after the Power Ball is caught | Restores one life when below 3. |

The Power Ball freezes active enemies for about 6 seconds. Frozen enemies use a
replacement frozen sprite and blink during the final 2 seconds. Frozen Enemy 1
slots return through their normal spawn cadence when collected; Enemy 2 is
reactivated when the freeze period ends if it was collected while frozen.

## Timing Model

Active-play timing currently uses:

```asm
PLAY_TICKS_PER_SECOND equ   17
```

This is a game-loop timing scale, not yet a 50 Hz interrupt-driven clock.
Timers count only while the game is actively playing. Title, hall of fame, name
entry, get-ready, level-clear, and death/respawn waits do not consume spawn
time.

Current design counters:

| Event | Target | Counter |
| --- | ---: | ---: |
| Enemy 1 walker spawn interval | 5 seconds | 85 active-play ticks |
| Bonus Ball spawn | 20 seconds | 340 active-play ticks |
| Power Ball after Bonus Ball caught | 20 seconds | 340 active-play ticks |
| Energy Ball after Power Ball caught | 20 seconds | 340 active-play ticks |

Movement remains 8x8-cell based. Some enemy frame counters are staggered so
fewer enemies step on the same frame, which smooths perceived motion without
changing collision or rendering to half-cell movement.

## Quick Start

From the repository root:

```sh
brew install lwtools
node --version
tools/build.sh
```

`node --version` is a quick check that Node.js is available for the K7 cassette
generator and browser sprite editor.

After a successful build, use either the generated cassette image or the raw
binary loader path in DCMOTO.

## Downloadable K7 Image

A current built cassette image is committed for download/reference here:

```text
downloads/bomb-jacques.k7
```

Direct project link:

[`downloads/bomb-jacques.k7`](downloads/bomb-jacques.k7)

Current file details:

| Field | Value |
| --- | --- |
| Format | Thomson MO5 / DCMOTO K7 cassette image |
| Size | 16440 bytes |
| Build | `BOMB JACQUES BUILD 008` |
| Load address | `$6000` |
| SHA-256 | `767114b73b45c30f6c466a595cbfef49acb850e4d4c5ae27b607bef02aed0cf8` |

This file is copied from `build/bomb-jacques.k7` after running
`tools/build.sh`. The `build/` directory remains ignored because it contains
generated working artifacts; `downloads/bomb-jacques.k7` is the stable file to
link from a project page or release note.

## Build Outputs

The build writes generated files to `build/`, which is ignored by git.

| File | Purpose |
| --- | --- |
| `build/bomb-jacques.bin` | Raw binary assembled for address `$6000`; fastest for debugger loading. |
| `build/bomb-jacques.raw` | Explicit copy of the raw binary. |
| `build/bomb-jacques.loadm` | DECB/`LOADM` stream produced by LWTOOLS. |
| `build/bomb-jacques.k7` | DCMOTO cassette image wrapping the `LOADM` stream. |
| `build/DCMOTO_LOAD.txt` | Current load range and emulator instructions. |
| `build/bomb-jacques.lst` | Assembler listing with addresses and source lines. |
| `build/bomb-jacques.map` | Symbol map for routines, tables, and variables. |

For the current feature-complete build, the program loads at `$6000` and the
generated binary currently ends at `$9B09`:

```text
Start address: $6000
End address:   $9B09
Exec address:  $6000
```

If the source grows, rebuild and trust `build/DCMOTO_LOAD.txt` over hardcoded
notes.

## Loading In DCMOTO

### Cassette Path

Use this path to test the same `.k7` cassette image a user would load:

1. Open DCMOTO.
2. Use `Supports amovibles > Cassette > Charger`.
3. Select `build/bomb-jacques.k7`.
4. At the MO5 BASIC prompt, type:

```text
LOADM"",,R
```

The `R` asks BASIC to run the program after loading.

### Debugger Binary Path

Use this path for a faster edit/build/test loop:

1. Press `F9` in DCMOTO to open the debugger.
2. Set the binary load range from `build/DCMOTO_LOAD.txt`.
3. Press `F6`, or use `File > Charger fichier binaire...`.
4. Choose `build/bomb-jacques.bin`.
5. Set `PC` to `$6000`.
6. Run.

For the current build, the debugger range is:

```text
$6000-$9B09
```

## Source Layout

The assembler entry point is `src/main.asm`. It sets the origin, initializes the
stack, and includes the rest of the assembly files.

| File | Role |
| --- | --- |
| `src/main.asm` | Program entry, include order, interrupt setup assumptions, and main loop entry. |
| `src/constants.asm` | Hardware addresses, colors, layout constants, gameplay constants, state values, timing values, and input masks. |
| `src/memory.asm` | Memory-layout comments and assumptions. |
| `src/video.asm` | MO5 video-plane selection, screen clearing, cell drawing, font drawing, text positioning, and sidebar art drawing. |
| `src/input.asm` | Keyboard matrix scanning, optional joystick PIA setup, held/press input state, and name-entry scanning. |
| `src/game.asm` | Gameplay include manifest. Keeps the original assembler order while delegating implementation to `src/game/*.asm`. |
| `src/game/flow.asm` | Game initialization, attract/title/hall flow, main frame dispatch, and render-state snapshots. |
| `src/game/level_setup.asm` | Level reset, platform/bomb table selection, player/enemy/item reset, and bomb reset. |
| `src/game/items.asm` | Bonus, power, energy item movement, collection, freeze timing, and item seeds. |
| `src/game/enemies.asm` | Enemy 1 slot scheduling, enemy phases, enemy 2 flight, chase/wander logic, and enemy seeds. |
| `src/game/player_movement.asm` | Player horizontal movement, jump/fall logic, platform checks, and footprint blocking helpers. |
| `src/game/collection_death.asm` | Bomb collection, frozen enemy collection, enemy collision, death, respawn, and game-over entry. |
| `src/game/scoring_hall.asm` | Score addition, hall-of-fame defaults, score comparison, name entry, and score insertion. |
| `src/game/level_flow.asm` | Lit-bomb selection, score popup timers, level clear, get-ready, and next-level transitions. |
| `src/game/rendering.asm` | Title, HUD, sidebar, arena, enemies, items, bombs, player, text, and erase/redraw helpers. |
| `src/game/tables.asm` | Wait loop, spawn tables, text strings, hall entries, color tables, and included level/sidebar data. |
| `src/game/sprites.asm` | 8x8 cell art, 2x2 gameplay sprites, player sprite table, item art, and enemy art. |
| `src/game/state.asm` | Mutable gameplay variables allocated with `FCB`/`FDB`. |
| `src/levels.asm` | Platform and bomb data for the ten handcrafted levels. |
| `src/sidebar_art.asm` | 56x128 right-panel bitmap art. |

The project currently assembles as one continuous unit. There is no separate
linker script. This makes labels easy to follow while learning, but it also
means shared label names should stay explicit and descriptive.

The `src/game/` split was done as a conservative source-organization pass:
`src/game.asm` preserves the old assembler order, and the rebuilt K7 was
verified byte-identical to the tracked downloadable cassette image.

## Memory And Video Model

Key addresses:

| Address or range | Meaning |
| --- | --- |
| `$6000` | Program origin and execution address. |
| `$6000-$9B09` | Current assembled game binary range. |
| `$9FFF` | Stack starts here and grows downward. |
| `$0000-$1F3F` | MO5 banked video RAM window. |
| `$A7C0` | Video bank select and system PIA area. |
| `$A7C1` | Keyboard matrix port. |
| `$A7CC-$A7CF` | Standard MO5 game-extension joystick PIA. |

The MO5 display path used here is a 320x200 bitmap with a separate color
attribute plane. The game treats most drawing as a 40x25 grid of 8x8 cells:

```text
320 pixels / 8 pixels per byte = 40 bytes per row
200 pixels / 8 pixel rows per cell = 25 cell rows
```

Bitmap and color data share the same `$0000-$1F3F` offsets; the selected plane
is controlled through `$A7C0`. Drawing routines typically select the bitmap
plane, write shape bytes, select the color plane, write color attributes at the
same offsets, and return to the bitmap plane.

## Graphics And Sprite Format

Most art is stored as 8x8 monochrome cells:

- 8 bytes per cell
- one byte per pixel row
- bit 7 is the leftmost pixel
- bit 0 is the rightmost pixel
- color is stored separately in the MO5 color plane

Moving objects are usually 2x2 cells, or 16x16 pixels. A contiguous 2x2 sprite
uses four 8-byte cells:

```text
top-left
top-right
bottom-left
bottom-right
```

That is 32 bytes per 2x2 sprite. Bombs use separately labeled quadrants, while
many player and enemy sprites are stored contiguously and selected through
tables.

## Sprite Editor

The local browser sprite editor edits:

- 2x2 gameplay sprites in `src/game/sprites.asm`
- the 56x128 right-panel `SidebarArtBitmap` in `src/sidebar_art.asm`

Run it with:

```sh
node tools/sprite-editor.mjs
```

By default it serves:

```text
http://127.0.0.1:5177/
```

You can request another port:

```sh
node tools/sprite-editor.mjs 5180
```

The editor saves changed sprite data back into assembly and runs the build
script after saves.

## Documentation Map

The documentation is part of the project, not an afterthought.

| Document | Use it for |
| --- | --- |
| [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md) | Current gameplay rules, scoring, enemies, items, timing, cheat, and sprite-editor role. |
| [`docs/BUILD_NOTES.md`](docs/BUILD_NOTES.md) | Toolchain setup, build output, DCMOTO loading, common build problems, and build hygiene. |
| [`docs/CHANGE_LOG.md`](docs/CHANGE_LOG.md) | Build-by-build history from BUILD 001 through BUILD 008. |
| [`docs/KNOWN_BUGS.md`](docs/KNOWN_BUGS.md) | Current known issues, verification notes, and historical milestone caveats. |
| [`docs/CPU_NOTES.md`](docs/CPU_NOTES.md) | 6809 mnemonic and addressing-mode explanations using project examples. |
| [`docs/MEMORY_MAP.md`](docs/MEMORY_MAP.md) | Program origin, stack, video RAM window, hardware I/O, writable state, and load artifacts. |
| [`docs/VIDEO_NOTES.md`](docs/VIDEO_NOTES.md) | MO5 display model, bitmap/color planes, cell addressing, drawing routines, text rendering, and redraw strategy. |
| [`docs/INPUT_NOTES.md`](docs/INPUT_NOTES.md) | Keyboard scanning, joystick PIA setup, held vs pressed state, gameplay controls, name-entry controls, and cheat input. |
| [`docs/SPRITE_FORMAT.md`](docs/SPRITE_FORMAT.md) | 8x8 cell encoding, 2x2 sprite layout, masked drawing, player/enemy/item sprites, font glyphs, and sidebar bitmap format. |
| [`docs/K7_FORMAT.md`](docs/K7_FORMAT.md) | Thomson K7 cassette block format, `LOADM` nesting, checksums, parser notes, and current artifact math. |

## Suggested Learning Path

If you are using this repository to learn MO5 assembly development:

1. Build the project once with `tools/build.sh`.
2. Load the cassette in DCMOTO with `LOADM"",,R`.
3. Read `docs/BUILD_NOTES.md` to understand the generated files.
4. Read `src/main.asm` and follow the include order.
5. Read `docs/CPU_NOTES.md` alongside small routines in `src/video.asm`.
6. Read `docs/VIDEO_NOTES.md`, then inspect `DrawCellPattern` and
   `DrawCellPatternMasked`.
7. Read `docs/INPUT_NOTES.md`, then inspect `ReadInput` in `src/input.asm`.
8. Read `docs/SPRITE_FORMAT.md`, then edit a small sprite with the browser
   editor.
9. Read `docs/MEMORY_MAP.md` and compare it with `build/DCMOTO_LOAD.txt`.
10. Read `docs/K7_FORMAT.md` to understand why the cassette image is larger
    than the raw assembled binary.

The most useful mental model is that the game is a set of simple layers:

```text
6809 code and data
loaded at $6000
draws 8x8 cells into MO5 video planes
uses normalized input state
runs a small game-state machine
exports raw, LOADM, and K7 build artifacts
```

## Development Workflow

A normal edit loop looks like this:

```sh
tools/build.sh
```

Then reload either `build/bomb-jacques.bin` or `build/bomb-jacques.k7` in
DCMOTO.

Useful files while debugging:

- `build/bomb-jacques.lst` shows source lines and generated addresses.
- `build/bomb-jacques.map` shows symbol addresses.
- `build/DCMOTO_LOAD.txt` shows the current binary load range.

Useful searches:

```sh
rg "RunGameFrame" src
rg "PlayerSpriteTable" src/game/sprites.asm
rg "VIDEO_BANK_SELECT" src docs
rg "POWER_FREEZE_FRAMES" src docs
```

Before creating a milestone or sharing a build:

```sh
tools/build.sh
git status --short
```

The build should pass, and git status should show only intentional source,
tooling, or documentation changes.

## Current Limitations

Known current limitations:

- timing still uses a temporary game-loop scale rather than an MO5 50 Hz
  interrupt
- sound effects are not implemented
- final all-level DCMOTO play-through verification is still recommended
- visual polish may still happen around title, hall of fame, sprite editor, and
  right-panel art

See [`docs/KNOWN_BUGS.md`](docs/KNOWN_BUGS.md) for the current issue and
verification list.

## Repository Hygiene

Generated build files are intentionally ignored:

```text
build/
*.log
.DS_Store
```

Commit source, documentation, and tools. Rebuild generated artifacts locally as
needed.
