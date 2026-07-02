# Video Notes

The Thomson MO5 display is a 320x200 bitmap with a color attribute byte for each
group of 8 horizontal pixels.

BUILD 008 treats most gameplay as a 40x25 grid of 8x8 cells:

- 40 bytes per bitmap row
- 8 bitmap rows per text cell
- 25 text rows

The MO5 exposes video RAM through a banked window at `$0000-$1F3F`. The game
selects the bitmap or color plane through the system PIA at `$A7C0`, writes the
same offset in the selected plane, then returns to the bitmap plane.

Current drawing routines:

- `ClearScreen` clears the bitmap plane and fills the color plane.
- `DrawString` draws 8x8 font glyphs on the bitmap plane.
- `DrawCellPattern` draws one 8x8 gameplay cell and its matching color rows.
- `DrawCellPatternMasked` merges dynamic sprites over the arena while leaving
  transparent pixels untouched.
- `DrawSidebarArt` copies the 56x128 right-panel bitmap and color rows.

The gameplay renderer uses static redraws for platforms, bombs, and sidebar
chrome, then masked draws for Jacques, enemies, score popups, and moving bonus,
power, and energy items. During power freeze, frozen enemy sprites replace the
normal enemy sprites. The HUD uses `DrawString` for lives, score, level labels,
title/hall-of-fame text, name entry, `GET READY`, `WELL DONE`, and
`GAME OVER`.

The current color bytes are tuned for the milestone but remain easy to adjust
from `src/constants.asm`.
