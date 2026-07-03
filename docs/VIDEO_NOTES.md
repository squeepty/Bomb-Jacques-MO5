# Video Notes

This document explains how Bomb Jacques draws to the Thomson MO5 display. It is
a learning companion for `src/video.asm`, the drawing helpers in
`src/game/rendering.asm`, and the video constants in `src/constants.asm`.

## Display Model

The MO5 display used here is a 320x200 bitmap with a separate color attribute
plane.

Project constants:

```asm
VIDEO_BYTES_PER_ROW equ     40
VIDEO_ROWS          equ     200
TEXT_CELL_HEIGHT    equ     8
TEXT_COLUMNS        equ     40
TEXT_ROWS           equ     25
```

Why those values:

```text
320 pixels / 8 pixels per byte = 40 bytes per bitmap row
200 pixel rows / 8 pixels per text cell = 25 text rows
```

The game treats the display as a 40x25 grid of 8x8 cells for most gameplay.
That gives simple column/row coordinates while still writing real bitmap bytes.

## Bitmap Plane And Color Plane

The MO5 exposes video memory through a banked window at `$0000-$1F3F`.

The same address offset can mean either:

- bitmap byte
- color attribute byte

The selected plane is controlled through `$A7C0`:

```asm
VIDEO_BITMAP_BASE   equ     $0000
VIDEO_COLOR_BASE    equ     VIDEO_BITMAP_BASE
VIDEO_BANK_SELECT   equ     $A7C0
```

Plane select routines:

```asm
SelectBitmapPlane:
        lda     VIDEO_BANK_SELECT
        ora     #$01
        sta     VIDEO_BANK_SELECT
        rts

SelectColorPlane:
        lda     VIDEO_BANK_SELECT
        anda    #$FE
        sta     VIDEO_BANK_SELECT
        rts
```

This project treats bit 0 of `$A7C0` as the bitmap/color selector:

- bit 0 set: bitmap plane
- bit 0 clear: color plane

Most routines return with the bitmap plane selected. That convention reduces
surprise because most drawing starts by writing bitmap bytes.

## Cell Coordinates To Video Addresses

Gameplay routines usually pass cell coordinates:

- `A` = column, 0 to 39
- `B` = row, 0 to 24

`CellAddress` converts that to a video offset.

Formula:

```text
offset = row * 8 pixel rows * 40 bytes per pixel row + column
offset = row * 320 + column
```

Example:

```text
cell col 5, row 3
offset = 3 * 320 + 5
offset = 965 = $03C5
```

`CellAddress` uses a lookup table instead of multiplying at runtime:

```asm
TextRowOffsets:
        fdb     0
        fdb     320
        fdb     640
        ...
        fdb     7680
```

The routine loads `row * 320`, adds the column, and returns the address in both
`X` and `Y`. `Y` mirrors `X` because bitmap and color planes share offsets.

## Clearing The Whole Screen

`ClearScreen` does a full video reset:

1. Select bitmap plane.
2. Write 8000 zero bytes.
3. Select color plane.
4. Write 8000 `COLOR_BACKGROUND` bytes.
5. Return to bitmap plane.

Bitmap clearing uses 16-bit stores for speed:

```asm
        ldx     #VIDEO_BITMAP_BASE
        ldd     #$0000
        ldy     #VIDEO_BITMAP_WORDS

ClearBitmapLoop:
        std     ,x++
        leay    -1,y
        bne     ClearBitmapLoop
```

`VIDEO_BITMAP_WORDS` is 4000 because the bitmap plane is 8000 bytes and each
`STD` writes two bytes.

Full-screen clearing is useful at boot, but gameplay transitions avoid it where
possible so the persistent chrome/sidebar does not flicker.

## Drawing One Full Cell

`DrawCellPattern` draws an 8x8 cell and its color:

Inputs:

| Register / variable | Meaning |
| --- | --- |
| `U` | Address of 8-byte cell bitmap. |
| `A` | Text column. |
| `B` | Text row. |
| `DrawCellColor` | Color attribute byte to write. |

Bitmap loop:

```asm
        ldb     #TEXT_CELL_HEIGHT

DrawCellBitmapRow:
        lda     ,u+
        sta     ,x
        leax    VIDEO_BYTES_PER_ROW,x
        decb
        bne     DrawCellBitmapRow
```

It writes one byte, then advances by 40 bytes to reach the next pixel row in
the same cell column.

Color loop:

```asm
        lda     DrawCellColor
        ldb     #TEXT_CELL_HEIGHT

DrawCellColorRow:
        sta     ,x
        leax    VIDEO_BYTES_PER_ROW,x
        decb
        bne     DrawCellColorRow
```

One color byte is written for each of the 8 rows covered by the cell.

## Drawing A Masked Cell

`DrawCellPatternMasked` is used for moving sprites.

Instead of replacing each destination byte, it ORs sprite bits into the existing
bitmap byte:

```asm
        lda     ,u+
        beq     DrawCellMaskedBitmapNext
        ora     ,x
        sta     ,x
```

Effects:

- sprite `1` bits become visible
- sprite `0` bits leave existing pixels alone
- completely empty rows skip both bitmap write and color write

The color plane is updated only for rows where the sprite row has at least one
foreground bit. This keeps empty transparent rows from repainting color
attributes unnecessarily.

## Text Rendering

Text uses the same 8x8 byte-per-row shape as sprites.

`DrawString`:

- expects `U` to point to a zero-terminated string
- expects `A`/`B` to hold the starting cell column/row
- draws one 8x8 glyph per character
- stops at byte `0`

`DrawString` writes bitmap glyphs only. Callers prepare colored empty cells
first when they need text with a known color/background. For example, title and
hall-of-fame code calls `DrawTextCells`, then `DrawString`.

Special text helpers:

| Routine | Effect |
| --- | --- |
| `DrawStringShiftRight4` | Draws glyphs shifted right by 4 pixels by splitting each row across two bytes. |
| `DrawStringDown4` | Draws glyphs 4 pixels lower by advancing the destination address by four scanlines. |

These helpers make labels such as `GET READY` and the level indicator feel less
rigid than pure 8x8-cell placement.

## Screen Areas

The screen is divided by constants:

| Area | Constants |
| --- | --- |
| Play arena | `ARENA_LEFT_COL` through `ARENA_RIGHT_COL`, `ARENA_TOP_ROW` through above `FLOOR_ROW`. |
| Top/left/bottom border | Drawn by `DrawTopBorder`, `DrawLeftBorder`, `DrawBottomBorder`. |
| Sidebar | Starts at `SIDEBAR_START_COL`. |
| Right margin | `SIDEBAR_RIGHT_MARGIN_COL`. |
| Sidebar art | `SIDEBAR_ART_COL`, `SIDEBAR_ART_ROW`, 56x128 pixels. |

`DrawScreenChrome` draws border, sidebar background, and right margin. It is
used for attract screens and initial setup. During play transitions, the game
now prefers `ClearGameArea` plus narrow status redraws to avoid flickering the
out-of-game area.

## Gameplay Rendering Strategy

The renderer separates static and moving content.

Static content:

- borders and sidebar chrome
- platforms
- active bombs
- title/hall-of-fame/name-entry backing cells

Moving or transient content:

- Jacques
- enemies
- power/bonus/energy items
- score popups
- blinking frozen enemy sprites
- `GET READY` and `WELL DONE!` messages

Normal play frame shape:

1. Save current render positions.
2. Update gameplay state.
3. Erase old moving-object footprints if anything changed.
4. Mark static redraw when erasing may have damaged background.
5. Redraw static arena if dirty.
6. Draw changed moving objects.
7. Draw score popup if active.

`FrameStaticDirty` is the one-byte flag that tells the frame whether static
arena cells need to be restored.

## Erasing And Restoring

Moving sprites are 2x2 cells. Erasing a sprite usually draws four empty cells at
its previous footprint.

For enemies and items:

```asm
EraseEnemyAtAB:
        jsr     DrawEmptyAtAB
        ...
```

For the player, erase is slightly smarter:

```asm
RestorePlayerCellAtAB:
        cmpb    #ARENA_TOP_ROW
        blo     RestorePlayerCellBorder
        ...
        jmp     DrawEmptyAtAB
```

If Jacques exits into the border during the death animation, the erased cell is
restored as border color rather than arena background.

After an erase, static content such as platforms and bombs may need to be
redrawn. That is why erase routines call `MarkStaticRedraw`.

## Sidebar Art

The right-panel art is a 56x128 bitmap:

```text
7 bytes per row * 8 pixels per byte = 56 pixels
128 rows high
```

`DrawSidebarArt` copies the bitmap bytes directly:

```asm
        ldx     #VIDEO_BITMAP_BASE+SIDEBAR_ART_BASE_OFFSET
        ldu     #SidebarArtBitmap
        ldy     #SIDEBAR_ART_PIXEL_ROWS
```

Then it selects the color plane and fills the same footprint with
`COLOR_SIDEBAR_ART`.

## Life Icons And Score

Life icons are drawn manually into the sidebar rather than through the general
2x2 sprite path. `DrawLifeIconAtAB` copies four cells from `CellPlayerUpRight`
into a compact sidebar position and writes `COLOR_LIFE`.

Score digits use text drawing:

1. Clear four score cells with `COLOR_SCORE`.
2. Draw the zero-terminated `ScoreDigitsText` string.

The score text bytes are mutable:

```asm
ScoreDigitsText:
ScoreThousandsText:
        fcb     '0'
ScoreHundredsText:
        fcb     '0'
ScoreTensText:
        fcb     '0'
ScoreOnesText:
        fcb     '0'
        fcb     0
```

Updating the score changes these bytes, then calls `DrawScore`.

## Color Constants

The color bytes live in `src/constants.asm`.

This project treats them as named attributes rather than documenting every MO5
foreground/background bit. When learning the renderer, the important fact is
that shape and color are separate writes.

Examples:

```asm
COLOR_BACKGROUND    equ     $06
COLOR_BOMB_LIT      equ     $56
COLOR_LIFE          equ     $30
COLOR_LEVEL         equ     $70
COLOR_BORDER        equ     $00
COLOR_SIDEBAR       equ     $70
```

Changing a color constant changes later draws using that color, not the bitmap
shape data.

## Practical Debugging Tips

- If shapes look correct but colors are wrong, inspect plane selection and
  `DrawCellColor`.
- If colors look correct but shapes are missing, inspect bitmap-plane writes and
  sprite pointers in `U`.
- If sprites leave trails, check erase paths and whether `FrameStaticDirty` is
  set after erasing.
- If the sidebar flickers, look for accidental `ClearScreen` or
  `DrawScreenChrome` calls during gameplay transitions.
- If text appears with stale color, make sure backing cells were drawn before
  `DrawString`.
