# Sprite Format

BUILD 008 uses 8x8 monochrome bitmap cells for gameplay art and a wider
monochrome bitmap for the right-panel decoration.

Each cell row is one byte:

- bit `1`: foreground pixel
- bit `0`: background pixel

The current gameplay cells include:

- empty
- platform left cap, middle, and right cap
- 2 2x2 enemies plus enemy 1 spawn/phase variants
- 2-frame 2x2 enemy 1 spawn effect
- enemy 1 phase-2 left/right sprites
- frozen enemy sprite used as a replacement during power freeze
- 2x2 bomb
- 2x2 lit bonus bomb
- 2x2 score popup
- 2x2 bonus, power, and energy items
- player poses built from 2x2 cells: straight up, straight down, up-left,
  up-right, down-left, down-right, walking right, walking left, and front-facing

The current platform, bomb, enemy, and player gameplay sprites were tuned from
the PNG/spec references used during the BUILD 007 and BUILD 008 art passes.

Color is separate from the bitmap. The renderer writes the 8 bitmap bytes into
the shape plane, then writes one color attribute byte on each matching row in the
color plane.

The lit bonus bomb uses both a different bitmap pattern and a different color
attribute so it remains distinguishable on displays where either shape or color
is less obvious.

The font still uses the same one-byte-per-row representation. BUILD 008 covers
the title screen, hall of fame, name entry, score, lives, level labels,
`GAME OVER`, `GET READY`, and level-clear messages.

`src/sidebar_art.asm` stores the right-panel bitmap as 128 rows of 7 bytes
each, for a 56x128 monochrome image. The browser sprite editor can edit both
2x2 gameplay sprites and this right-panel bitmap.
