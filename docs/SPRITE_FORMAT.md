# Sprite Format

No gameplay sprites exist yet.

BUILD 001 introduces only an 8x8 monochrome font used for the title screen. Each
glyph row is one byte:

- bit `1`: foreground pixel
- bit `0`: background pixel

This is close to the representation we will use for early 8-pixel-wide sprites.
