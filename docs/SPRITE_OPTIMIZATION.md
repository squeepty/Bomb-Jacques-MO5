# Sprite Rendering Optimization

This note documents the sprite-rendering optimization pass introduced after
`milestone-pre-sprites-optimization`. The goal was to reduce MO5 video writes,
remove gameplay flicker, and make the 2x2 sprite path cheaper without changing
gameplay behavior.

## Starting Point

Profiling and review pointed at the video path as the main cost center:

- `DrawCellPattern`
- `DrawCellPatternMasked`
- `CellAddress`
- full static-arena redraws after sprite erases

Most gameplay objects are 2x2 cells: Jacques, enemies, bombs, items, and score
popups. Before the optimization, many call sites drew those four cells as four
separate high-level cell calls. Each cell call recomputed its address, switched
video planes, and looped over eight rows.

The old dirty-render model also erased moving objects to flat background and
then used a broad static redraw to repair any platforms or bombs underneath.
That was simple, but expensive: it regularly repainted more of the arena than
the player could see changing, which caused visible flicker.

## Optimization 1: Unrolled Cell Drawing

`DrawCellPattern` now writes the eight bitmap rows with an unrolled sequence
instead of a loop. It uses `PULU D` to fetch two source rows at a time, then
stores them at fixed video-row offsets.

The same shape is used for color writes: one loaded color byte is stored into
the eight matching color-plane rows.

Why this helps:

- removes the row loop branch overhead
- reduces repeated loads from the source pattern
- keeps the hot path predictable for the 6809
- still returns with the bitmap plane selected, preserving caller assumptions

The masked path uses unrolled helpers too. Empty sprite rows still skip bitmap
and color writes, so transparent sprite rows do not repaint the background.

## Optimization 2: 2x2 Sprite Helpers

The pass added shared 2x2 routines:

- `DrawSprite2x2Masked`
- `DrawSprite2x2Opaque`
- low-level bitmap/color helpers for masked and opaque cells

These routines calculate the top-left cell address once, then draw the four
quadrants by moving the video pointer:

```text
top-left
top-right:    +1 byte
bottom-left:  +319 bytes from top-right
bottom-right: +1 byte
```

That matches the MO5 screen layout:

```text
40 bytes per pixel row * 8 pixel rows = 320 bytes per cell row
```

Why this helps:

- one `CellAddress` call for a full 2x2 object instead of four
- one bitmap-plane pass and one color-plane pass for the object
- less duplicated code in object-specific draw routines
- fewer plane-selection writes to `$A7C0`

Object draw routines such as bombs, enemies, items, and player now mostly
choose color and sprite data, then tail-call the shared 2x2 helper.

## Optimization 3: Faster CellAddress

`CellAddress` converts an 8x8 text-cell coordinate into a byte address inside
the MO5 video window.

The old version used a row-offset table. The optimized version uses `MUL`:

```asm
        sta     CellAddressColumn
        lda     #4*VIDEO_BYTES_PER_ROW
        mul
        lslb
        rola
        addd    #VIDEO_BITMAP_BASE
CellAddressColumn equ *-1
```

The row is multiplied by 160 and then doubled to reach 320 bytes per text-cell
row. The column byte is patched directly into the immediate operand because the
program runs from RAM.

Why this helps:

- removes the row-offset table lookup
- saves table storage
- keeps the conversion compact and fast

The self-modified byte is safe in this project because the assembled program is
loaded into writable RAM.

## Optimization 4: Footprint Restoration Instead Of Full Static Redraw

This was the biggest visual win.

The old erase model was:

1. erase a moving sprite to flat arena background
2. mark static content dirty
3. later redraw platforms, bombs, and popups broadly

The new model restores the exact cells under the erased sprite footprint:

```asm
EraseEnemyAtAB:
        jmp     RestoreStatic2x2AtAB
```

Each 8x8 cell checks what static content owns that coordinate:

1. border if outside the active arena
2. platform cell if it falls on a platform run
3. active score popup if a popup timer owns the bomb footprint
4. active bomb, including lit-bomb color when appropriate
5. gameplay background cell

In v2, the final fallback is no longer a flat empty cell. It calls
`DrawArenaBackgroundCellAtAB`, which restores either cyan paper or the matching
8x8 slice of the Egypt background image.

Why this helps:

- the renderer repairs only the cells that were actually exposed
- normal frames no longer repaint the whole static arena
- moving objects stop causing broad platform/bomb redraws
- visible flicker is removed because the screen is not repeatedly churned

`FrameStaticDirty` changed meaning during this pass. It now means moving
overlays may need redraw after a footprint restore. It no longer means "redraw
the whole static arena."

## Lit-Bomb Regression And Fix

The full static redraw used to hide one implicit dependency: when the lit-bomb
index advanced, the next active bomb would eventually be repainted by the broad
`DrawBombs` pass.

After the optimization, that broad pass no longer ran during normal play. The
result was that `BombLitIndex` changed in memory, but the newly lit bomb could
remain visually normal.

The fix was intentionally narrow:

- `SelectNextLitBomb` stores the new `BombLitIndex`
- it then tail-calls `DrawCurrentLitBomb`
- `DrawCurrentLitBomb` finds that bomb coordinate and redraws only that 2x2
  lit-bomb sprite

This preserved the optimization instead of reintroducing full arena redraws.

## Background-Aware Restores

The v2 background image made the optimized restore path more important. With a
flat background, restoring an empty cell could simply draw `CellEmpty`. With the
Egypt background, sprite erases must restore the exact image cell underneath.

The background is stored as a cropped bitmap:

```text
source rows 56-175
30 bytes per row * 120 rows = 3600 bytes
```

`DrawArenaBackground` draws the full gameplay background at level start.
`DrawArenaBackgroundCellAtAB` restores one 8x8 cell during sprite erases.

The same resident image now backs the name-entry screen, and the V2 release's
graduated sphinx shadow needs no special runtime path: full draws and cell
restores both read the finalized bitmap bytes. This keeps the anti-flicker
renderer compatible with non-empty scenery.

## Expected Effect

The player-visible effect should be:

- much less flicker during movement
- cleaner restores when enemies, items, bombs, popups, or Jacques overlap
  platforms and background art
- slightly lower per-frame rendering cost
- possible slight gameplay speed change while timing still uses busy-wait
  delays

Because frame pacing is still a software wait loop, render-time reductions can
change perceived speed until timing moves to a hardware/IRQ-based cadence.

## Verification Checklist

After changes in this area, test:

- player movement over platforms and background art
- enemies crossing platforms, bombs, and the background image
- lit-bomb collection and the next lit bomb becoming visibly highlighted
- score popup expiry restoring the bomb/background underneath
- death and respawn near border/background/platform cells
- `GET READY` and `WELL DONE!` erasing back to static content
- name entry retaining the pyramid/sphinx background
- title and hall screens still clearing to plain cyan instead of gameplay art

The key invariant: erasing a moving object should restore exactly what would
have been visible if that object had never been drawn.
