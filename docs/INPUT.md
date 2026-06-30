# Input Notes

BUILD 007 keeps input state in the same shape used by many 8-bit game loops:

- `Held`: the control is down now.
- `Press`: the control became down this frame.

Left and right movement use `Dpad_Held`, so holding the direction keeps moving
Jacques. Jump uses `Dpad_Press` or `Fire_Press`, so one press creates one jump.

## Keyboard

Keyboard fallback reads the MO5 keyboard matrix through the system PIA port at
`$A7C1`.

Current keys:

- `Q`: left
- `D`: right
- `Space`: jump

Name entry accepts direct keyboard input:

- `A-Z`: type the next character and advance one slot
- `Enter`: finish the name immediately
- `Backspace`: erase the previous character

The key selectors come from the MO5 monitor keyboard scan order.

## Joystick

When the standard MO5 game extension is present, BUILD 007 reads:

- `$A7CC`: joystick directions
- `$A7CD`: joystick trigger
- `$A7CE`: PIA control register A
- `$A7CF`: PIA control register B

The game initializes both PIA ports as inputs before the main loop. Direction
bits are active-low in hardware, then inverted into the game state so `1` means
pressed.

## References

- DCMOTO MO5 monitor source:
  [keyboard scan](http://dcmoto.free.fr/documentation/moniteur-mo5-getch/moniteur-mo5-getch_src.txt),
  [joystick primitive](http://dcmoto.free.fr/documentation/moniteur-mo5-joyst/moniteur-mo5-joyst_src.txt),
  and [equates](http://dcmoto.free.fr/documentation/moniteur-mo5-eqmon/moniteur-mo5-eqmon_src.txt).
- Wide Dot Thomson TO8 game engine:
  [`ReadJoypads.asm`](https://github.com/wide-dot/thomson-to8-game-engine/blob/main/engine/joypad/ReadJoypads.asm)
  and
  [`ReadKeyboard.asm`](https://github.com/wide-dot/thomson-to8-game-engine/blob/main/engine/keyboard/ReadKeyboard.asm).
