# Sprite Format

This document explains how Bomb Jacques stores and draws sprite art. It is a
learning companion for the `Cell...` labels in `src/game.asm`, the glyph labels
in `src/video.asm`, and the sidebar bitmap in `src/sidebar_art.asm`.

## The Basic 8x8 Cell

Most art is built from 8x8 monochrome bitmap cells.

One cell is 8 bytes:

```asm
CellEmpty:
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
```

Each byte is one horizontal row:

- bit 7 is the leftmost pixel
- bit 0 is the rightmost pixel
- `1` means foreground pixel
- `0` means transparent/background pixel, depending on the draw routine

Example:

```text
%00111111
  ||||||
  six foreground pixels on the right side of the cell
```

The MO5 bitmap also stores 8 horizontal pixels per byte, so an 8x8 cell maps
very naturally to eight bytes in video RAM.

## Color Is Separate From Shape

Sprite shape bytes do not contain color. Color is written to the MO5 color plane
with a separate attribute byte.

Common color constants:

| Symbol | Used for |
| --- | --- |
| `COLOR_PLATFORM` | Platform cells. |
| `COLOR_PLAYER` | Jacques. |
| `COLOR_BOMB` | Normal bombs. |
| `COLOR_BOMB_LIT` | Lit bomb and score popup. |
| `COLOR_ENEMY` | Enemy 1. |
| `COLOR_ENEMY2` | Enemy 2. |
| `COLOR_POWER` | Power ball. |
| `COLOR_BONUS_ITEM` | Bonus ball. |
| `COLOR_ENERGY_ITEM` | Energy ball. |
| `COLOR_FROZEN` | Frozen enemy replacement sprite. |
| `COLOR_SIDEBAR_ART` | Right-panel bitmap. |

The same bitmap pattern can therefore be drawn with different colors, and the
same color can be used for many shapes.

## Full Cell Draws Versus Masked Draws

There are two important cell draw routines:

| Routine | Behavior |
| --- | --- |
| `DrawCellPattern` | Copies all 8 bitmap rows and writes all 8 color rows. Best for background, platforms, text backing cells, and erasing. |
| `DrawCellPatternMasked` | ORs non-zero sprite bits into the bitmap and writes color only on rows that contain sprite pixels. Best for moving sprites. |

`DrawCellPatternMasked` treats zero bits as transparent because it uses `ORA`
with the destination byte:

```asm
        lda     ,u+
        beq     DrawCellMaskedBitmapNext
        ora     ,x
        sta     ,x
```

This means a sprite can be layered over the arena without first destroying all
background pixels in that byte. When an object moves, the old 2x2 footprint is
erased back to empty cells and the static arena is redrawn if needed.

## 2x2 Sprite Layout

Most moving objects are 2x2 cells, or 16x16 pixels.

A contiguous 2x2 sprite is stored as four 8-byte cells, in this order:

```text
top-left cell      top-right cell
bottom-left cell   bottom-right cell
```

In memory:

```text
8 bytes top-left
8 bytes top-right
8 bytes bottom-left
8 bytes bottom-right
= 32 bytes total
```

Many draw routines set `U` once, then call `DrawCellPatternMasked` four times.
Each call consumes one 8-byte cell, so `U` advances through the 32-byte sprite.

## Separately Labeled 2x2 Sprites

Bombs use separate labels for each quadrant:

```asm
CellBombTopLeft:
CellBombTopRight:
CellBombBottomLeft:
CellBombBottomRight:
```

`DrawBombAtAB` explicitly loads each label before drawing each cell. This style
is more verbose, but it makes individual quadrants easy to find and edit.

The lit bomb follows the same pattern:

```asm
CellLitBombTopLeft:
CellLitBombTopRight:
CellLitBombBottomLeft:
CellLitBombBottomRight:
```

The lit bomb changes both shape and color so it remains distinguishable even if
one display characteristic is weak.

## Player Sprite Table

Jacques uses a table of 16-bit pointers:

```asm
PlayerSpriteTable:
        fdb     CellPlayerUp
        fdb     CellPlayerDown
        fdb     CellPlayerUpLeft
        fdb     CellPlayerUpRight
        fdb     CellPlayerDownLeft
        fdb     CellPlayerDownRight
        fdb     CellPlayerWalkRight
        fdb     CellPlayerWalkLeft
        fdb     CellPlayerFront
```

The current `PlayerSprite` byte is an index into this table. `DrawPlayerAtAB`
multiplies the index by two because each table entry is a 16-bit address:

```asm
        clra
        ldb     PlayerSprite
        lslb
        ldx     #PlayerSpriteTable
        ldu     d,x
```

Then it draws four 8-byte cells from the selected sprite.

Player sprite constants:

| Constant | Sprite |
| --- | --- |
| `PLAYER_SPRITE_UP` | Straight upward pose. |
| `PLAYER_SPRITE_DOWN` | Straight downward pose. |
| `PLAYER_SPRITE_UP_LEFT` | Rising or death-rotation left pose. |
| `PLAYER_SPRITE_UP_RIGHT` | Rising or death-rotation right pose. |
| `PLAYER_SPRITE_DOWN_LEFT` | Falling left pose. |
| `PLAYER_SPRITE_DOWN_RIGHT` | Falling right pose. |
| `PLAYER_SPRITE_WALK_RIGHT` | Walking right pose. |
| `PLAYER_SPRITE_WALK_LEFT` | Walking left pose. |
| `PLAYER_SPRITE_FRONT` | Spawn and landing/front-facing pose. |

## Enemy Sprites

Enemy 1 has several shapes:

| Label | Purpose |
| --- | --- |
| `CellEnemy1Left` | Walking enemy facing left. |
| `CellEnemy1Right` | Walking enemy facing right. |
| `CellEnemy1SpawnA` | Spawn/transform animation frame A. |
| `CellEnemy1SpawnB` | Spawn/transform animation frame B. |
| `CellEnemy1Phase2Left` | Flying hunter phase facing left. |
| `CellEnemy1Phase2Right` | Flying hunter phase facing right. |
| `CellEnemy1Phase3` | Faster final hunter form. |

Enemy 2 has:

| Label | Purpose |
| --- | --- |
| `CellEnemy2Left` | Flyer facing left. |
| `CellEnemy2Right` | Flyer facing right. |

During power freeze, normal enemy sprites are replaced by:

```asm
CellEnemyFrozen
```

The frozen sprite is not an overlay. It is a replacement shape drawn while the
freeze timer is active and the blink phase says it should be visible.

## Item And Popup Sprites

| Label | Meaning |
| --- | --- |
| `CellPower` | Power ball; starts enemy freeze. |
| `CellBonusItem` | Bonus ball; awards 500 points. |
| `CellEnergyItem` | Energy ball; restores one life when below 3. |
| `CellScore200TopLeft` etc. | Temporary 2x2 score popup for lit-bomb collection. |

Power, bonus, and energy items are all 2x2 masked sprites. They share movement
logic, but each uses its own color constant and bitmap label.

## Platform Cells

Platforms are made from one-cell tiles:

| Label | Use |
| --- | --- |
| `CellPlatformLeft` | Left end cap. |
| `CellPlatformMiddle` | Middle section. |
| `CellPlatformRight` | Right end cap. |

`DrawPlatformRun` draws a row of platform cells by placing one left cap, zero or
more middle cells, and one right cap.

## Font Glyphs

Font glyphs in `src/video.asm` use the same 8-byte cell format:

```asm
GlyphA:
        fcb     %00111100
        ...
```

The text renderer draws one glyph per 8x8 text cell. `DrawString` writes bitmap
rows only; callers usually prepare colored backing cells first with
`DrawTextCells` or another cell-fill helper.

Supported glyph labels currently include:

- space, punctuation used by the game (`!`, quote, `#`, comma, dash, colon)
- digits `0-9`
- uppercase letters `A-Z`

Lowercase input is converted to uppercase before lookup.

## Shifted Text

Two helper paths adjust glyph placement:

| Routine | Purpose |
| --- | --- |
| `DrawStringShiftRight4` | Draws text shifted 4 pixels right by splitting each glyph across two bytes. |
| `DrawStringDown4` | Draws text shifted 4 pixels down by advancing the destination by four scanlines. |

These are used for visual centering where whole 8x8 cells look too coarse.

## Sidebar Bitmap

`src/sidebar_art.asm` stores the right-panel image:

```asm
SidebarArtBitmap:
        fcb ...
```

Dimensions:

| Constant | Value | Meaning |
| --- | ---: | --- |
| `SIDEBAR_ART_PIXEL_ROWS` | 128 | Height in bitmap rows. |
| `SIDEBAR_ART_BYTES_PER_ROW` | 7 | Width in bytes. |
| Width | 56 pixels | `7 bytes * 8 pixels`. |

Total bitmap data size:

```text
128 rows * 7 bytes = 896 bytes
```

`DrawSidebarArt` copies those bytes directly into the bitmap plane, then writes
`COLOR_SIDEBAR_ART` to the same footprint in the color plane.

## Editing Sprites Safely

When editing by hand:

- keep each 8x8 cell exactly 8 bytes
- keep contiguous 2x2 sprites exactly 32 bytes
- keep `PlayerSpriteTable` order synchronized with the `PLAYER_SPRITE_*`
  constants
- remember that bit 7 is leftmost and bit 0 is rightmost
- use zeros for transparent pixels in masked moving sprites
- rebuild after editing so assembler errors catch missing or extra bytes around
  labels

The browser sprite editor can edit both:

- gameplay 2x2 sprites in `src/game.asm`
- the right-panel bitmap in `src/sidebar_art.asm`
