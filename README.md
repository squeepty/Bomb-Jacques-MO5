# Bomb Jacques

Bomb Jacques is a one-screen arcade game for the Thomson MO5, written in
Motorola 6809 assembly.

The project begins with a strict educational goal: each milestone must build,
run, and explain the MO5 concepts it introduces.

## Current State

BUILD 008 is the game feature-complete milestone, captured at
`milestone-game-feature-complete`:

```text
BOMB JACQUES BUILD 008
LIVES 3      SCORE 0000
```

The game now has a title screen, hall of fame, ten handcrafted levels, a static
arena with right-panel pixel art, platforms, bombs, and 2x2-cell Jacques
sprites. Jacques can move left and right, jump, fall under gravity, land on
platforms, collect bombs, float slowly while jump is held during a fall, and
increase the score.

One bomb is highlighted as the current bonus target. Normal bombs award 50
points, lit bombs award 200 points, bonus balls award 500 points, and frozen
enemies award 100 points. The bonus, power, and energy balls spawn
sequentially: the bonus ball uses its timer, the power ball appears 20 seconds
after the bonus ball is caught, and the energy ball appears 20 seconds after
the power ball is caught. The energy ball awards one life if Jacques has fewer
than 3 lives.

Enemy 1 spawns from varied top columns, falls, walks on platforms when
supported, then transforms into faster flying hunter phases after reaching the
bottom floor. Enemy 2 flies horizontally and vertically with 80% chase movement
toward Jacques and 20% wandering. The power ball freezes active enemies for
about 6 seconds; frozen sprites replace the normal enemy sprites and blink for
the final 2 seconds.

Jacques starts with 3 lives. Touching either enemy makes Jacques fly straight
up offscreen at one-third normal speed while rotating jump poses, subtracts one
life, then respawns him at the starting position. Movement resumes after a
2-second hold, with a blinking grace period. When no lives remain, the game
shows `GAME OVER`; high-score name entry and hall-of-fame display follow when
the score qualifies.

The `SQUEEPTY` cheat can be entered on the title or hall-of-fame screens. When
active, lives are not decremented and `N` skips to the next level during
gameplay.

The local sprite editor at `tools/sprite-editor.mjs` edits gameplay sprites and
the right-panel `SidebarArtBitmap`, saving back to assembly and rebuilding.

Controls:

- `Q`: move left
- `D`: move right
- `Space`: jump
- `N`: next level while the `SQUEEPTY` cheat is active

The standard MO5 game-extension joystick is also read when present.

## Build

Install LWTOOLS, then run:

```sh
tools/build.sh
```

The script writes:

- `build/bomb-jacques.bin`: raw DCMOTO binary bytes assembled at `$6000`
- `build/bomb-jacques.raw`: same raw bytes, kept as an explicit raw copy
- `build/bomb-jacques.k7`: DCMOTO cassette image
- `build/DCMOTO_LOAD.txt`: exact DCMOTO load addresses
- `build/bomb-jacques.lst`: annotated assembler listing
- `build/bomb-jacques.map`: symbol map

## DCMOTO

For cassette loading, use `Supports amovibles > Cassette > Charger` and select
`build/bomb-jacques.k7`. At the MO5 BASIC prompt, type:

```text
LOADM"",,R
```

For debugger loading, open the debugger with `F9`, set the binary loader range
shown in `build/DCMOTO_LOAD.txt`, then use `F6` to load
`build/bomb-jacques.bin`. Set the program counter to `$6000` and run.

## Project Map

- `src/`: 6809 assembly source
- `docs/`: design notes and technical explanations
- `tools/`: local build tooling
- `build/`: generated files, ignored by git
