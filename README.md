# Bomb Jacques

Bomb Jacques is a one-screen arcade game for the Thomson MO5, written in
Motorola 6809 assembly.

The project begins with a strict educational goal: each milestone must build,
run, and explain the MO5 concepts it introduces.

## Current Milestone

BUILD 007 implements lives, death, respawn, and game over:

```text
BOMB JACQUES BUILD 007
LIVES 3      SCORE 0000
```

The game draws a static arena with platforms, bombs, and 2x2-cell Jacques
sprites. The player can move left and right, jump, fall under gravity, land on
platforms, collect bombs, float slowly while jump is held during a fall, and
increase the score. One bomb is highlighted as the current bonus target;
collecting it awards 200 points, advances the highlight to the next active
bomb, and flashes `BONUS` in the HUD. Normal bombs award 50 points, bonus balls
award 500 points, and frozen enemies award 100 points.
One 2x2 enemy spawns from varied top columns, falls, walks on platforms when
supported, then transforms into a flying phase 2 after reaching the bottom
floor. A one-second two-frame effect plays before it becomes active and again
before phase 2 activates. A second 2x2 enemy flies horizontally and vertically,
with 80% chase movement toward Jacques and 20% wandering.

Jacques starts with 3 lives. Touching either enemy makes Jacques fly straight
up offscreen while rotating jump poses, subtracts one life, then respawns him at
the starting position. Movement resumes after a short hold, with a blinking
grace period. When no lives remain, the game shows `GAME OVER` and stops
gameplay.

Controls:

- `Q`: move left
- `D`: move right
- `Space`: jump

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
