# Video Notes

The Thomson MO5 display is a 320x200 bitmap with a color attribute byte for each
group of 8 horizontal pixels.

BUILD 007 treats the screen as a 40x25 grid of 8x8 cells:

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

The gameplay renderer uses `DrawCellPattern` for platforms, Jacques, normal
bombs, the highlighted bonus bomb, and two enemies. The HUD uses
`DrawString` for the build label, lives counter, four-digit score, temporary
`BONUS` / `HIT` feedback text, and the `GAME OVER` message.

The current color bytes are provisional and will continue to be tuned visually
in DCMOTO.
