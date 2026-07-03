# Memory Map

This document explains how Bomb Jacques uses the MO5 address space. It is a
learning companion for `src/constants.asm`, `src/memory.asm`, and the generated
`build/DCMOTO_LOAD.txt`.

## Big Picture

The game is assembled to run at `$6000`:

```asm
PROGRAM_ORIGIN      equ     $6000
STACK_TOP           equ     $9FFF
```

At startup, `main.asm` does:

```asm
        org     PROGRAM_ORIGIN
        ...
        lds     #STACK_TOP
```

`ORG` tells the assembler that the first byte of the program will live at
`$6000`. `LDS` moves the hardware stack pointer near the top of available user
RAM.

## Current Address Summary

| Address range | Size | Purpose |
| --- | ---: | --- |
| `$0000-$1F3F` | 8000 bytes | Banked MO5 video RAM window. The selected bank is either bitmap bytes or color bytes. |
| `$6000` | 1 byte address | Program origin and execution address. |
| `$6000-$9B09` | 15114 bytes | Current assembled game binary range. |
| `$9B0A-$9FFF` | 1270 bytes | Current gap above the binary, used as stack headroom. |
| `$9FFF` downward | variable | Runtime stack. |
| `$A7C0-$A7C3` | hardware | System PIA area used for video-plane selection and keyboard matrix access. |
| `$A7CC-$A7CF` | hardware | Standard MO5 game-extension joystick PIA when present. |

The current end address comes from `tools/build.sh`, which computes:

```text
end = $6000 + size(build/bomb-jacques.bin) - 1
```

For the current feature-complete build:

```text
$6000 + 15114 - 1 = $9B09
```

## Video RAM Window

The MO5 display data appears through a window at `$0000-$1F3F`. The game does
not move this window; it switches which video plane is visible there.

Relevant constants:

```asm
VIDEO_BITMAP_BASE   equ     $0000
VIDEO_COLOR_BASE    equ     VIDEO_BITMAP_BASE
VIDEO_BANK_SELECT   equ     $A7C0
VIDEO_BYTES_PER_ROW equ     40
VIDEO_ROWS          equ     200
VIDEO_BITMAP_BYTES  equ     8000
VIDEO_COLOR_BYTES   equ     VIDEO_BITMAP_BYTES
```

The bitmap plane and color plane use the same offsets. The difference is which
plane has been selected through `$A7C0`.

Example:

- bitmap plane selected, write `$0000`: changes the first 8 pixels of the
  bitmap
- color plane selected, write `$0000`: changes the color attribute for that
  same 8-pixel group

This is why drawing routines usually:

1. Select bitmap plane.
2. Write bitmap bytes.
3. Select color plane.
4. Write color bytes at the same offsets.
5. Return to bitmap plane.

## Hardware I/O Addresses

The game uses memory-mapped I/O. A load or store to one of these addresses talks
to hardware rather than normal RAM.

| Symbol | Address | Used by |
| --- | ---: | --- |
| `VIDEO_BANK_SELECT` | `$A7C0` | `SelectBitmapPlane`, `SelectColorPlane`. |
| `KEYBOARD_PORT` | `$A7C1` | Keyboard matrix scan in `src/input.asm`. |
| `JOYPAD_DPAD_PORT` | `$A7CC` | Joystick direction reads. |
| `JOYPAD_FIRE_PORT` | `$A7CD` | Joystick trigger reads. |
| `JOYPAD_CRA` | `$A7CE` | Joystick PIA control register A. |
| `JOYPAD_CRB` | `$A7CF` | Joystick PIA control register B. |

For example:

```asm
        lda     VIDEO_BANK_SELECT
        ora     #$01
        sta     VIDEO_BANK_SELECT
```

This reads the current hardware control byte, sets bit 0, then writes it back.
That is enough to select the bitmap plane for this project.

## Program Binary Layout

`src/main.asm` is assembled as one continuous unit. It includes the neighboring
source files:

```asm
        include "constants.asm"
        include "memory.asm"
        ...
        include "video.asm"
        include "input.asm"
        include "game.asm"
```

Because these files are included into one assembly stream, the final binary
contains:

1. code
2. read-only tables
3. strings
4. sprite data
5. writable state bytes

There is not yet a separate linker script or fixed RAM block for all variables.
The labels near the end of `src/input.asm` and `src/game.asm` allocate writable
bytes with `FCB`/`FDB`.

## Writable State

Current writable variables include:

| Area | Examples | Purpose |
| --- | --- | --- |
| Input state | `Dpad_Read`, `Dpad_Held`, `Fire_Press`, `NameKey_Press` | Per-frame input values. |
| Player state | `PlayerCol`, `PlayerRow`, `PlayerDY`, `PlayerSprite` | Position, movement, and rendered pose. |
| Enemy state | `Enemy1Col`, `Enemy1State`, `Enemy2Active`, slot variables | Enemy positions, phases, and movement counters. |
| Item state | `PowerActive`, `BonusItemActive`, `EnergyItemSpawnTimer` | Bonus/power/energy item lifecycle. |
| Level state | `CurrentLevel`, `CurrentBombPositions`, `BombActiveFlags` | Current arena and collected bombs. |
| UI state | `ScoreDigitsText`, `LivesValue`, `LevelTransitionTimer` | Score, lives, get-ready, and level-clear messages. |
| Hall of fame | `HallEntry1` through `HallEntry5`, `PlayerNameText` | Name entry and high-score table. |
| Render scratch | `DrawRunCol`, `DrawObjectRow`, `FrameStaticDirty` | Temporary draw coordinates and dirty flags. |

These labels are ordinary RAM addresses after the program has loaded. They are
initialized by the bytes in the binary, then mutated by gameplay.

## Stack

The stack starts at `$9FFF` and grows downward.

The code uses the stack for:

- return addresses from `JSR`
- saved registers with `PSHS`
- temporary values, such as saving `A` while computing a cell address

Example:

```asm
        pshs    x,u
        jsr     DrawBombAtAB
        puls    x,u
```

The current binary ends at `$9B09`, leaving `$9B0A-$9FFF` as stack headroom.
That is 1270 bytes. This is enough for the current shallow call patterns, but
it is still a finite resource: every `JSR` and `PSHS` consumes stack space until
the matching `RTS` or `PULS`.

## Load Files And Addressing

`tools/build.sh` produces several build artifacts:

| File | Address behavior |
| --- | --- |
| `build/bomb-jacques.bin` | Raw bytes only. The emulator must be told to load them at `$6000`. |
| `build/bomb-jacques.loadm` | DECB/`LOADM` file containing load address `$6000` and execution address `$6000`. |
| `build/bomb-jacques.k7` | Cassette wrapper around the `LOADM` file. |
| `build/DCMOTO_LOAD.txt` | Human-readable current load range. |

Raw binary loading is fast in the debugger, but it relies on manually entering
the correct address range. Cassette loading is slower but carries the `LOADM`
metadata inside the file.

## Things To Watch When Editing

- If the binary grows too close to `$9FFF`, the stack can collide with code or
  variables.
- If `PROGRAM_ORIGIN` changes, `tools/build.sh`, DCMOTO loading notes, and K7
  examples must change with it.
- Any hardcoded address in docs should be checked against
  `build/DCMOTO_LOAD.txt` after a build.
- Video writes must select the intended plane first; bitmap and color data share
  the same `$0000-$1F3F` window.

## Future Cleanup Ideas

The current layout favors educational simplicity. A later polish pass could:

- reserve a named game-state block
- group variables by subsystem more explicitly
- add a memory budget table generated from the map file
- add stack-depth notes for the deepest rendering paths
