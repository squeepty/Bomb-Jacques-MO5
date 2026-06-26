# Video Notes

The Thomson MO5 display is a 320x200 bitmap with a color attribute byte for each
group of 8 horizontal pixels.

BUILD 001 treats the screen as a 40x25 grid of 8x8 cells:

- 40 bytes per bitmap row
- 8 bitmap rows per text cell
- 25 text rows

For each bitmap byte at `$0000 + offset`, the matching color byte is at
`$2000 + offset`.

The current color byte for title text is `$07`, intended as white foreground on
black background. This will be verified visually in DCMOTO.
