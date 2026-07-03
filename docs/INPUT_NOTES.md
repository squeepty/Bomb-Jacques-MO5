# Input Notes

This document explains how Bomb Jacques reads controls on the Thomson MO5 and
turns raw hardware bits into game-friendly input state. It is written as a
learning companion for `src/input.asm`.

## Input Goals

The game wants one simple input model, no matter whether the player uses:

- keyboard fallback keys
- the standard MO5 game-extension joystick

The rest of the game should not care where the input came from. It only reads
the normalized state bytes:

- `Dpad_Held`
- `Fire_Held`
- `Dpad_Press`
- `Fire_Press`
- `NameKey_Press`

## Hardware Addresses

The relevant addresses are defined in `src/constants.asm`.

| Symbol | Address | Purpose |
| --- | ---: | --- |
| `KEYBOARD_PORT` | `$A7C1` | System PIA keyboard matrix port. |
| `JOYPAD_DPAD_PORT` | `$A7CC` | Standard game-extension direction port. |
| `JOYPAD_FIRE_PORT` | `$A7CD` | Standard game-extension trigger port. |
| `JOYPAD_CRA` | `$A7CE` | Game-extension PIA control register A. |
| `JOYPAD_CRB` | `$A7CF` | Game-extension PIA control register B. |

The joystick ports are optional hardware. The keyboard fallback is always
available on the MO5.

## Normalized Button Bits

The game stores input with a simple convention:

```text
1 = pressed
0 = not pressed
```

Button masks:

| Symbol | Bit | Meaning |
| --- | ---: | --- |
| `c1_button_up_mask` | `%00000001` | Up direction. Also accepted as jump by some gameplay code. |
| `c1_button_down_mask` | `%00000010` | Down direction. Currently reserved. |
| `c1_button_left_mask` | `%00000100` | Left direction. |
| `c1_button_right_mask` | `%00001000` | Right direction. |
| `c1_button_A_mask` | `%01000000` | Main fire/jump button. |

The `c1_` prefix comes from the joystick engine pattern this code was adapted
from. In this project it effectively means "controller 1".

## Frame State: Read, Held, Press

The input code keeps three versions of each control group:

| State | Meaning |
| --- | --- |
| `Read` | Raw normalized buttons read during this frame. |
| `Held` | Buttons that were down at the end of the previous frame. |
| `Press` | Buttons that became down this frame. |

Variables in `src/input.asm`:

| Variable | Alias | Meaning |
| --- | --- | --- |
| `Joypads_Read` | `Dpad_Read`, `Fire_Read` | Two bytes: current direction byte and current fire byte. |
| `Joypads_Held` | `Dpad_Held`, `Fire_Held` | Two bytes: previous frame's held state. |
| `Joypads_Press` | `Dpad_Press`, `Fire_Press` | Two bytes: newly pressed buttons. |

`Joypads_Read`, `Joypads_Held`, and `Joypads_Press` are two-byte blocks. The
first byte is the D-pad byte; the second byte is the fire byte. That is why the
code can use `LDD` and `STD` to move both bytes at once.

## Why Held And Press Both Exist

Different game actions need different input semantics.

| Action | State used | Reason |
| --- | --- | --- |
| Move left/right | `Dpad_Held` | Holding a direction should keep moving Jacques. |
| Start jump | `Dpad_Press` or `Fire_Press` | One press should start one jump. |
| Slow fall while jump is held | `Dpad_Held` or `Fire_Held` | Holding jump during descent should keep slowing the fall. |
| Title start | `Fire_Press` | Holding fire should not repeatedly restart. |
| Name-entry character confirm | `Fire_Press` or `Dpad_Press` | One press confirms one slot. |

The frame loop reads input once per active frame, then gameplay consumes the
already-normalized bytes.

## Initialization

`InitInput` performs two jobs:

1. Configure the optional joystick PIA as input.
2. Clear all input state bytes.

```asm
InitInput:
        jsr     InitJoypadPia

        ldd     #$0000
        std     Joypads_Read
        std     Joypads_Held
        std     Joypads_Press
        clr     NameKey_Read
        clr     NameKey_Held
        clr     NameKey_Press
        rts
```

The important beginner detail: `STD Joypads_Read` stores both `A` and `B`.
Because `LDD #$0000` set `A = 0` and `B = 0`, `STD` clears two neighboring
bytes at once.

## Joystick PIA Setup

The standard MO5 game extension uses a PIA. Before reading it, the game sets
both joystick ports as inputs.

```asm
        lda     JOYPAD_CRA
        anda    #$FB
        sta     JOYPAD_CRA
        clrb
        stb     JOYPAD_DPAD_PORT
        ora     #$04
        sta     JOYPAD_CRA
```

The same pattern is repeated for `JOYPAD_CRB` and `JOYPAD_FIRE_PORT`.

What is happening:

1. Read the PIA control register.
2. Clear bit 2 with `ANDA #$FB`.
3. With bit 2 clear, the port address selects the data-direction register.
4. Store `$00` to the port, making all bits inputs.
5. Set bit 2 again with `ORA #$04`.
6. The port address now selects the data register for normal reads.

This is a common PIA pattern: temporarily select the direction register, write
the direction mask, then return to data-register access.

## Reading One Gameplay Frame

`ReadInput` is the main gameplay input routine:

```asm
ReadInput:
        ldd     #$0000
        std     Joypads_Read

        jsr     ReadJoypadHardware
        jsr     ReadKeyboardHardware

        ldd     Joypads_Held
        eora    Dpad_Read
        eorb    Fire_Read
        anda    Dpad_Read
        andb    Fire_Read
        std     Joypads_Press

        ldd     Joypads_Read
        std     Joypads_Held
        rts
```

Step by step:

1. Clear `Dpad_Read` and `Fire_Read`.
2. OR in joystick state.
3. OR in keyboard fallback state.
4. Compare the current read state against last frame's held state.
5. Store only newly pressed bits in `Press`.
6. Copy current `Read` to `Held` for the next frame.

The edge-detection formula is:

```text
Press = (Held XOR Read) AND Read
```

That means:

- if a bit was `0` and is now `1`, it appears in `Press`
- if a bit was `1` and is still `1`, it is held but not pressed
- if a bit was `1` and is now `0`, it is released and not pressed

The 6809 version uses `EORA`/`EORB` for XOR and `ANDA`/`ANDB` for the final
mask.

## Joystick Reading

Joystick hardware bits are active-low: a pressed control reads as `0`. The game
wants `1 = pressed`, so it complements the byte with `COMA`.

```asm
ReadJoypadHardware:
        lda     JOYPAD_DPAD_PORT
        coma
        anda    #$0F
        ora     Dpad_Read
        sta     Dpad_Read
```

Step by step:

1. Load the hardware direction byte.
2. `COMA` flips every bit, so active-low pressed bits become `1`.
3. `ANDA #$0F` keeps only the low four direction bits.
4. `ORA Dpad_Read` merges joystick input with any existing input source.
5. Store the normalized result.

The fire button uses the same pattern, but masks with `c1_button_A_mask`.

## Keyboard Gameplay Controls

Keyboard fallback reads the MO5 keyboard matrix through `KEYBOARD_PORT`.

Current gameplay keys:

| Key | Selector | Game bit |
| --- | ---: | --- |
| `Q` | `%01010110` | `c1_button_left_mask` |
| `D` | `%00110110` | `c1_button_right_mask` |
| `Space` | `%01000000` | `c1_button_A_mask` |
| `N` | `%00000000` | Cheat-only next level, read separately |

The keyboard matrix is also active-low. The gameplay scanner writes a selector
byte, reads the port back, then checks bit 7.

```asm
        lda     #KEY_Q_SELECTOR
        sta     KEYBOARD_PORT
        lda     KEYBOARD_PORT
        bita    #$80
        bne     ReadKeyboardD
```

Read this as:

- select the `Q` key position
- read the keyboard port
- test bit 7
- if bit 7 is non-zero, `Q` is not pressed
- if bit 7 is zero, set the left button bit

Because keyboard and joystick inputs are both ORed into the same normalized
state, either device can control Jacques.

## Gameplay Consumers

The game reads the normalized bytes in `src/game.asm`.

| Routine | Input checked | Purpose |
| --- | --- | --- |
| `UpdateHorizontal` | `Dpad_Held` left/right bits | Continuous horizontal movement. |
| `TryJump` | `Dpad_Press` up or `Fire_Press` A | Start one jump. |
| `ShouldDelayFall` | `Dpad_Held` up or `Fire_Held` A | Slow falling while jump remains held. |
| `RunGameFrameTitle` | `Fire_Press` A | Start a new game. |
| `RunGameFrameHallOfFame` | `Fire_Press` A | Return from hall of fame to title. |
| `UpdateNameEntryState` | `NameKey_Press`, `Dpad_Press`, `Fire_Press` | Type, cycle, and confirm name-entry characters. |

This separation is useful when learning game loops: input is sampled once, then
many systems can ask questions of the same stable frame state.

## Name Entry Keyboard Scanner

Name entry needs many more keys than gameplay. Instead of hardcoding one small
scan for `Q`, `D`, and `Space`, it walks a table.

Each table entry is two bytes:

```text
keyboard selector, output character
```

Example entries:

```asm
NameKeyboardTable:
        fcb     $5A,'A'
        fcb     $44,'B'
        ...
        fcb     $68,NAME_KEY_ENTER
        fcb     $52,NAME_KEY_BACKSPACE
```

`ReadNameKeyboardHardware` scans `NAME_KEY_SCAN_COUNT` entries. The first key
that is currently down becomes `NameKey_Read`.

The scanner then compares `NameKey_Read` with `NameKey_Held`:

- if the same key is still held, `NameKey_Press` stays zero
- if this is a new key, `NameKey_Press` receives the ASCII/control code
- if no key is down, `NameKey_Held` is cleared

This gives name entry the same "new press only" behavior as gameplay buttons,
but for ASCII-like key values instead of bit masks.

## Name Entry Controls

Direct keyboard:

| Input | Behavior |
| --- | --- |
| `A-Z` | Type the character and advance one slot. |
| `Enter` | Commit the name immediately. |
| `Backspace` | Erase the previous character. |

Controller fallback:

| Input | Behavior |
| --- | --- |
| Left press | Decrement the current name character. |
| Right press | Increment the current name character. |
| Fire press | Confirm the current character and advance. |
| Up press | Also confirm the current character and advance. |

The controller path lets name entry remain usable even without keyboard typing,
though keyboard input is the friendlier path on an emulator.

## Cheat Input

The `SQUEEPTY` cheat uses the name-key scanner on the title and hall-of-fame
screens.

The cheat logic tracks how many consecutive letters match:

1. If the new key matches the next expected letter, advance the index.
2. If the full word has been typed, set `InfiniteLivesFlag`.
3. If a wrong key is typed, reset the index.
4. If the wrong key is `S`, restart at index 1 so repeated `S` attempts feel
   natural.

When the cheat is active, `N` skips to the next level during gameplay.

`N` is read separately in `TryCheatNextLevel` instead of through the normal
`ReadKeyboardHardware` gameplay scanner. It also has its own `CheatNextLevelHeld`
latch so holding `N` cannot skip multiple levels.

## Adding A New Gameplay Key

To add a new keyboard gameplay action:

1. Add or identify a selector constant in `src/constants.asm`.
2. Extend `ReadKeyboardHardware` to scan that selector.
3. OR the matching normalized bit into `Dpad_Read` or `Fire_Read`.
4. Consume `Held` or `Press` in `src/game.asm`, depending on the intended
   behavior.

Use `Held` for continuous actions and `Press` for one-shot actions.

## Adding A New Name-Entry Key

To add a key to the name-entry scanner:

1. Add a two-byte entry to `NameKeyboardTable`.
2. Increase `NAME_KEY_SCAN_COUNT`.
3. Handle the resulting code in `UpdateNameEntryState` if it is not a normal
   `A-Z` character.

The table order matters: the scanner stops on the first pressed key it finds.

## Current Limitations

- There is no release-state byte. The game tracks current and new presses, not
  "was just released".
- Keyboard gameplay fallback only scans `Q`, `D`, and `Space`; `N` is cheat
  special-case input.
- Name entry records one key at a time. If several keys are held, the first one
  in `NameKeyboardTable` wins.
- Timing is tied to the current frame loop rather than a fixed interrupt, so
  input sampling rate follows frame timing.

## References

- DCMOTO MO5 monitor source:
  [keyboard scan](http://dcmoto.free.fr/documentation/moniteur-mo5-getch/moniteur-mo5-getch_src.txt),
  [joystick primitive](http://dcmoto.free.fr/documentation/moniteur-mo5-joyst/moniteur-mo5-joyst_src.txt),
  and [equates](http://dcmoto.free.fr/documentation/moniteur-mo5-eqmon/moniteur-mo5-eqmon_src.txt).
- Wide Dot Thomson TO8 game engine:
  [`ReadJoypads.asm`](https://github.com/wide-dot/thomson-to8-game-engine/blob/main/engine/joypad/ReadJoypads.asm)
  and
  [`ReadKeyboard.asm`](https://github.com/wide-dot/thomson-to8-game-engine/blob/main/engine/keyboard/ReadKeyboard.asm).
