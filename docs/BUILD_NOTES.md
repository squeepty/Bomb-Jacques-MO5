# Build Notes

## Toolchain

The project uses LWTOOLS for Motorola 6809 assembly.

```sh
brew install lwtools
```

The assembler command is wrapped by:

```sh
tools/build.sh
```

## BUILD 007

Added:

- Lives state starting at 3 lives.
- Visible `LIVES` HUD counter.
- Death state after touching either enemy.
- Short input-freezing death pause.
- Respawn at the starting position while lives remain.
- `GAME OVER` state and message when lives reach 0.
- PNG-spec sprite tuning for platforms, the 2x2 player, 2x2 bombs, and 2x2
  enemies.
- Left/middle/right platform tiles with rounded slab ends.
- Direction-specific left/right enemy sprite data.
- Stopped player sprite preserves the last left/right facing direction.
- Platform landing holds the straight jump sprite until a new movement or jump.
- Released jump now ends the upward rise instead of continuing until blocked.
- Enemy 1 now spawns from varied top columns, falls, walks on platforms, and
  transforms into phase 2 after reaching the bottom floor.
- Enemy 1 spawn is preceded by a one-second two-frame spawn effect.
- Enemy 1 phase-2 transition reuses the same one-second two-frame effect.
- Enemy 1 phase 2 uses new left/right sprites and flies with the same attraction
  model as enemy 2.
- Enemy 1 phase 2 and enemy 2 now use an 80% attraction rate toward Jacques and
  20% wandering movement.
- Font glyphs needed by `BUILD 007`, `LIVES`, and `GAME OVER`.
- BUILD 007 labels and load notes.

Expected:

The MO5 screen clears and displays an arena headed by:

```text
BOMB JACQUES BUILD 007
LIVES 3      SCORE 0000
```

Enemy 1 shows a one-second two-frame spawn effect at varied columns near the top
of the arena, then falls and walks when supported by a platform. After reaching
the bottom floor, it plays the same one-second two-frame effect, then transforms
into phase 2 and flies with the same attraction movement as enemy 2. Enemy 2
flies horizontally and vertically; 80% of movement ticks step toward Jacques and
20% wander. Touching either enemy flashes `HIT`, subtracts one life, pauses
briefly, and respawns Jacques at the starting position while lives remain. After
the last life is lost, `GAME OVER` appears and gameplay stops. Bomb collection
and bonus scoring continue to work.

Observed:

The source assembles successfully with LWTOOLS.

Status:

Ready for DCMOTO testing.

## BUILD 006

Added:

- Second enemy state and fixed vertical patrol.
- Distinct second-enemy sprite and color.
- Player collision checks against both enemies.
- BUILD 006 labels and load notes.

Expected:

The MO5 screen clears and displays an arena headed by:

```text
BOMB JACQUES BUILD 006
SCORE 00
```

One enemy patrols along the floor and a second enemy patrols vertically above
the right platform. Touching either enemy flashes `HIT` in the HUD and returns
Jacques to the starting position. Bomb collection and bonus scoring continue to
work.

Observed:

The source assembles successfully with LWTOOLS.

Status:

Ready for DCMOTO testing.

## BUILD 005

Added:

- First enemy state and fixed horizontal patrol.
- 2x2 enemy drawing with a separate color attribute.
- Player/enemy footprint collision against Jacques' 2x3 sprite.
- Temporary `HIT` HUD flash after touching the enemy.
- Player reset to the starting position after an enemy hit.
- Font glyphs needed by `BUILD 005` and `HIT`.

Expected:

The MO5 screen clears and displays an arena headed by:

```text
BOMB JACQUES BUILD 005
SCORE 00
```

One enemy patrols along the floor. Touching the enemy flashes `HIT` in
the HUD and returns Jacques to the starting position. Bomb collection and bonus
scoring continue to work.

Observed:

The source assembles successfully with LWTOOLS.

Status:

Ready for DCMOTO testing.

## BUILD 004

Added:

- Highlighted bonus-bomb state.
- Lit-bomb cell pattern with a separate color attribute.
- Bonus scoring: 200 points for the highlighted bomb, 50 points for any other
  bomb.
- Highlight advancement to the next active bomb after a bonus collection.
- Four-digit score text.
- Short `BONUS` HUD flash when the highlighted bomb is collected.
- Font glyphs needed by `BUILD 004`, four-digit scoring, and `BONUS`.

Expected:

The MO5 screen clears and displays an arena headed by:

```text
BOMB JACQUES BUILD 004
SCORE 00
```

One active bomb is visually highlighted. Collecting that bomb removes it,
increments the score by 200, flashes `BONUS`, and highlights the next remaining
active bomb. Collecting any other active bomb removes it and increments the
score by 50.

Observed:

The source assembles successfully with LWTOOLS.

Status:

Ready for DCMOTO testing.

## BUILD 003

Added:

- Bomb active/inactive state.
- Cell-overlap collision between Jacques and bombs.
- Bomb score increase when a bomb is collected.
- HUD score text and dynamic score digit.
- Rise-until-blocked jumping with slow falling while jump is held.
- Font glyphs needed by `BUILD 003` and `SCORE`.

Expected:

The MO5 screen clears and displays an arena headed by:

```text
BOMB JACQUES BUILD 003
SCORE 0
```

Jacques can collect bombs. Each collected bomb disappears and the visible score
increases according to the current scoring model.

Observed:

The source assembles successfully with LWTOOLS.

Status:

Ready for DCMOTO testing.

## BUILD 002

Added:

- A static one-screen arena drawn from 8x8 bitmap cells.
- Player, platform, bomb, and empty-cell sprite patterns.
- Frame input state with `Held` and `Press` bytes.
- Direct MO5 keyboard fallback for `Q`, `D`, and `Space`.
- Standard game-extension joystick reads at `$A7CC-$A7CF`.
- Cell-based player movement with jump, gravity, and landing.

Expected:

The MO5 screen clears and displays an arena headed by:

```text
BOMB JACQUES BUILD 002
```

Jacques can move left/right, jump, fall, and land on the floor and platforms.

Observed:

The source assembles successfully with LWTOOLS. DCMOTO verification confirmed
the arena, bombs, player, left/right movement, and jump work.

Status:

Verified in DCMOTO.

## BUILD 001

Added:

- A documented 6809 entry point at `$6000`.
- Direct bitmap/color RAM clearing.
- A small 8x8 title font.
- A raw DCMOTO binary output and address sheet.
- A DCMOTO `.k7` cassette image.

Expected:

The MO5 screen clears and displays:

```text
Bomb Jacques

BUILD 001
```

Observed:

The source assembles successfully with LWTOOLS.

The DCMOTO binary loader file is:

```text
build/bomb-jacques.bin
```

The DCMOTO cassette image is:

```text
build/bomb-jacques.k7
```

Use the address range written to:

```text
build/DCMOTO_LOAD.txt
```

Status:

Ready for DCMOTO testing.
