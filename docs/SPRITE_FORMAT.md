# Sprite Format

BUILD 007 uses 8x8 monochrome bitmap cells for early gameplay art.

Each cell row is one byte:

- bit `1`: foreground pixel
- bit `0`: background pixel

The current gameplay cells are:

- empty
- platform left cap, middle, and right cap
- 2 2x2 enemies
- 2-frame 2x2 enemy 1 spawn effect
- enemy 1 phase-2 left/right sprites
- 2x2 bomb
- 2x2 lit bonus bomb
- 9 player poses built from 2x2 cells: straight up, straight down, up-left,
  up-right, down-left, down-right, immobile, walking right, walking left

The current platform, bomb, enemy, and player gameplay sprites are converted
from the PNG sprite specs used during BUILD 007 tuning.

Color is separate from the bitmap. The renderer writes the 8 bitmap bytes into
the shape plane, then writes one color attribute byte on each matching row in the
color plane.

The lit bonus bomb uses both a different bitmap pattern and a different color
attribute so it remains distinguishable on displays where either shape or color
is less obvious.

The font still uses the same one-byte-per-row representation. BUILD 007 extends
the temporary glyph set to cover four-digit scores, the lives counter,
`GAME OVER`, and the `BONUS` / `HIT` HUD flashes.
