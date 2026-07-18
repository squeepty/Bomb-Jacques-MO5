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

`CellAddress` uses the 6809 `MUL` instruction and a 16-bit shift:

```asm
        sta     CellAddressColumn
        lda     #4*VIDEO_BYTES_PER_ROW
        mul
        lslb
        rola
        addd    #VIDEO_BITMAP_BASE
CellAddressColumn equ *-1
        tfr     d,x
        leay    ,x
```

`MUL` first produces `row * 160`; `LSLB`/`ROLA` double that 16-bit result to
`row * 320`. Because the game executes from writable RAM, the column is patched
into the low byte of the `ADDD` immediate operand. This avoids the former
row-offset table. The final address is returned in both `X` and `Y`; the planes
share offsets even though only one is visible at a time.

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

The hot path is unrolled. `PULU D` fetches two source rows at once, and fixed
offset stores write all eight bitmap rows without a loop branch:

```asm
        leax    120,x
        pulu    d
        sta     -120,x
        stb     -80,x
        pulu    d
        sta     -40,x
        stb     ,x
        pulu    d
        sta     40,x
        stb     80,x
        pulu    d
        sta     120,x
        stb     160,x
```

Seven offsets fit the 6809's fast 8-bit indexed form after moving `X` to bitmap
row 3; only the final `160,x` store needs the wider offset form. The color path
is unrolled in the same shape:

```asm
        lda     DrawCellColor
        sta     -120,x
        sta     -80,x
        sta     -40,x
        sta     ,x
        sta     40,x
        sta     80,x
        sta     120,x
        sta     160,x
```

One color byte is still written for each of the eight rows covered by the cell;
the unrolling only removes loop and source-load overhead.

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
| Gameplay background | 240x176 pixels, drawn by `DrawArenaBackground`. |

`DrawScreenChrome` draws border, sidebar background, and right margin. It is
used for attract screens and initial setup. During play transitions, the game
now prefers `DrawArenaBackground` plus narrow status redraws to avoid flickering
the out-of-game area.

`DrawVersionLabel` is intentionally not part of chrome anymore. It draws the
small `(v2)` label in the lower-left play area only after title and hall-of-fame
screen content has been cleared and redrawn.

## Gameplay Background

V2 includes a 240x176 two-color Egypt background behind gameplay and the
high-score name-entry screen. The source image exactly matches the active game
area: 30 bytes per pixel row by 176 rows.

The upper part of the image is empty cyan. To save program space, the generated
`src/game/backgrounds.asm` stores only the lower cell-aligned slice:

```text
source rows 56-175
30 bytes per row * 120 rows = 3600 bytes
```

`DrawArenaBackground` clears the whole arena bitmap footprint to zero, fills the
same color-plane footprint with `COLOR_BACKGROUND`, then streams the stored
lower bitmap rows into video RAM. Title and hall screens remain plain; gameplay
and name entry get the pyramid/sphinx art.

The finalized resident bitmap includes a graduated dither beneath the sphinx
head. Only the original solid-shadow interior differs from the source art, so
the pyramid, face, outline, and ground remain unchanged.

## Gameplay Rendering Strategy

The renderer separates static and moving content.

Static content:

- borders and sidebar chrome
- gameplay background
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
4. Each erase restores the exact static cell underneath: background image,
   platform, bomb, popup, or border.
5. Mark dynamic overlays dirty when an erase may have crossed another moving
   object.
6. Draw changed moving objects.
7. Draw score popup if active.

`FrameStaticDirty` is now a one-byte "moving overlays may need redraw" flag. It
no longer triggers a full static-arena repaint during ordinary frames.

## Erasing And Restoring

Moving sprites are 2x2 cells. Erasing a sprite restores four cells at its
previous footprint.

For enemies and items:

```asm
EraseEnemyAtAB:
        jmp     RestoreStatic2x2AtAB
```

For a single arena cell, the restore path first checks bounds, then restores the
right static layer:

```asm
RestoreStaticCellAtAB:
        cmpb    #ARENA_TOP_ROW
        blo     RestoreStaticCellBorder
        ...
        jsr     RestoreStaticBaseCell
        jsr     RestoreScorePopupCell
        jsr     RestoreBombCell
```

If no platform, popup, or bomb owns the cell, `RestoreStaticBaseCell` calls
`DrawArenaBackgroundCellAtAB`. That routine either draws a plain cyan cell for
the empty top area or copies the matching 8x8 slice from `EgyptBackgroundBitmap`.

If Jacques exits into the border during the death animation, the erased cell is
restored as border color rather than arena background.

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
COLOR_VERSION_LABEL equ     $06
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
