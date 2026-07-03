# CPU Notes

The Thomson MO5 uses a Motorola 6809E running at roughly 1 MHz.

This document is a learning map for the 6809 assembly actually used by Bomb
Jacques. It is not a full 6809 manual. Instead, it explains every CPU mnemonic
and assembler directive currently present in `src/*.asm`, with the project
idioms that make those instructions useful.

## Registers

| Register | Size | Role in this project |
| --- | ---: | --- |
| `A` | 8-bit | General byte work: counters, flags, columns, rows, colors, character bytes. |
| `B` | 8-bit | Another byte register. Often paired with `A` as `D`, or used as a loop counter. |
| `D` | 16-bit | The combined `A:B` register. Used for 16-bit timers, addresses, and table offsets. |
| `X` | 16-bit | Main index pointer for tables, video memory, variables, and loops. |
| `Y` | 16-bit | Secondary index pointer or 16-bit loop counter. |
| `U` | 16-bit | Extra index pointer, commonly used for sprite, string, and level-data pointers. |
| `S` | 16-bit | Hardware stack pointer. `JSR`, `RTS`, `PSHS`, and `PULS` all use it. |
| `PC` | 16-bit | Program counter. Branches, jumps, calls, and returns change it. |
| `CC` | 8-bit | Condition-code flags. Branches test these flags. |

The 6809's `D` register is not separate storage. It is `A` followed by `B`.
If `A = $12` and `B = $34`, then `D = $1234`.

## Condition Codes

The condition-code register contains flags set by arithmetic, comparisons,
loads, tests, shifts, and some other instructions.

| Flag | Meaning | Why it matters here |
| --- | --- | --- |
| `Z` | Zero | `BEQ`, `BNE`, `LBEQ`, and `LBNE` test whether a result was zero or equal. |
| `N` | Negative | `BMI` tests bit 7 of an 8-bit result or bit 15 of a 16-bit result. |
| `C` | Carry or borrow | Unsigned comparisons use it through `BCC`, `BHS`, `BLO`, and related branches. |
| `V` | Signed overflow | Updated by arithmetic. The current code rarely branches on it directly. |
| `H` | Half carry | Useful for BCD arithmetic. The current code does not use it directly. |
| `I` | IRQ mask | `ORCC #$50` sets interrupt-mask bits during startup. |
| `F` | FIRQ mask | Also set by `ORCC #$50` during startup. |
| `E` | Entire state | Used by interrupt stacking. The game does not manipulate it directly. |

Most game values are unsigned bytes: columns, rows, timers, counters, and
states. That is why the code uses branches such as `BLO`, `BLS`, `BHI`, and
`BHS` after `CMPA` or `CMPB`.

## Addressing Patterns Used

The same mnemonic can read or write data through several addressing modes. These
are the patterns used in the codebase.

| Pattern | Example | Meaning |
| --- | --- | --- |
| Immediate | `lda #START_LIVES` | Use the literal value after `#`. |
| Direct or extended label | `sta LivesValue` | Read or write the memory at a label. The assembler chooses the needed encoding. |
| Memory-mapped I/O | `sta VIDEO_BANK_SELECT` | Same syntax as a label, but the address is MO5 hardware. |
| Indexed | `lda ,u` | Read through a pointer register. |
| Indexed with offset | `ldb 1,u` | Read at pointer plus a small offset. |
| Indexed with `D` offset | `ldu d,x` | Use the 16-bit value in `D` as an offset from `X`. |
| Post-increment | `lda ,u+` | Read through `U`, then increment `U` by one. |
| Double post-increment | `std ,x++` | Store two bytes through `X`, then increment `X` by two. |
| Stack list | `pshs x,u` | Push named registers on the hardware stack. |

Two project idioms are worth recognizing:

```asm
        clra
        ldb     CurrentLevel
        lslb
        ldx     #LevelBombTable
        ldu     d,x
```

This builds a 16-bit offset in `D`. `CurrentLevel` is one byte, so `CLRA` clears
the high byte. `LSLB` multiplies by two because the table stores 16-bit
pointers. `LDU D,X` then loads the pointer for the current level.

```asm
        ldu     #CellEmpty
        lda     DrawRunCol
        ldb     DrawRunRow
        jsr     DrawCellPattern
```

This is the normal draw-call shape: `U` points at bitmap data, `A` holds a text
column, `B` holds a text row, and `JSR` calls a drawing routine.

## Assembler Directives And Data Pseudo-Ops

These are not CPU instructions. They are commands to LWASM, the assembler.

| Directive | Meaning in this project |
| --- | --- |
| `ORG` | Sets the address where assembled code will live. `main.asm` uses `org PROGRAM_ORIGIN`, currently `$6000`. |
| `INCLUDE` | Inserts another source file at assembly time. `main.asm` includes constants, memory notes, video, input, and game code. |
| `END` | Marks the end of assembly and names the program entry point with `end Start`. |
| `EQU` | Defines a constant. Labels such as `VIDEO_BYTES_PER_ROW equ 40` do not allocate memory. |
| `FCB` | Form constant byte. Used for sprite bytes, state variables, color tables, and byte data. |
| `FCC` | Form constant characters. Used for zero-terminated strings such as `BOMB JACQUES`. |
| `FDB` | Form double byte. Used for 16-bit pointers, offsets, and word-sized data. |

## CPU Mnemonics Used

### Loading, Storing, And Moving Data

| Mnemonic | Meaning | Notes for Bomb Jacques |
| --- | --- | --- |
| `LDA` | Load byte into `A`. | The most common instruction in the game. Used for state bytes, constants, flags, rows, columns, colors, and characters. |
| `LDB` | Load byte into `B`. | Often used for rows, loop counts, or the low byte of `D`. |
| `LDD` | Load 16-bit value into `D`. | Used for 16-bit timers and pointer math. Since `D` is `A:B`, this changes both registers. |
| `LDX` | Load 16-bit value into `X`. | Often sets `X` to a table, variable block, or video address. |
| `LDY` | Load 16-bit value into `Y`. | Used for 16-bit loop counts and secondary pointers. |
| `LDU` | Load 16-bit value into `U`. | Commonly points to strings, sprite cell data, and level tables. |
| `LDS` | Load the stack pointer `S`. | Startup uses `lds #STACK_TOP` before any calls rely on the stack. |
| `STA` | Store `A` to memory. | Used for variables and hardware registers. Example: selecting keyboard/video ports. |
| `STB` | Store `B` to memory. | Used for byte variables, counters, and hardware ports. |
| `STD` | Store 16-bit `D` to memory. | Used for 16-bit timers and two-byte state. |
| `STX` | Store 16-bit `X` to memory. | Used when preserving pointers. |
| `STU` | Store 16-bit `U` to memory. | Used for the current level bomb-position pointer. |
| `TFR` | Transfer register to register. | Copies values between compatible registers, such as `tfr d,y` for a loop counter. |

Loads usually update `N` and `Z`, and stores also update condition flags on the
6809. The game usually branches on explicit compares or tests instead of store
side effects.

### Arithmetic

| Mnemonic | Meaning | Notes for Bomb Jacques |
| --- | --- | --- |
| `ABX` | Add unsigned `B` to `X`. | Handy for indexing byte tables, such as advancing `X` by a small runtime offset. |
| `ADCA` | Add memory or immediate value plus carry to `A`. | Used when carrying low-byte addition into a high byte during address math. |
| `ADDA` | Add byte to `A`. | Used for counters, positions, ASCII digit math, and bounds calculations. |
| `ADDB` | Add byte to `B`. | Used sparingly for byte arithmetic. |
| `ADDD` | Add 16-bit value to `D`. | Used for pointer and word-sized value adjustment. |
| `SUBA` | Subtract byte from `A`. | Used for character conversion and small arithmetic. |
| `SUBD` | Subtract 16-bit value from `D`. | Used to decrement 16-bit timers. |
| `INC` | Increment a byte in memory. | Used for timers, indexes, and state bytes. |
| `INCA` | Increment `A`. | Used after loading a value into `A`. |
| `INCB` | Increment `B`. | Used for row/column or small counter adjustment. |
| `DEC` | Decrement a byte in memory. | Common loop and timer operation. |
| `DECA` | Decrement `A`. | Used when a value is already in `A`. |
| `DECB` | Decrement `B`. | Very common for countdown loops. |

Arithmetic instructions set flags. After addition or subtraction, unsigned code
usually cares about `C` and equality code usually cares about `Z`.

### Logic, Bit Tests, And Bit Manipulation

| Mnemonic | Meaning | Notes for Bomb Jacques |
| --- | --- | --- |
| `ANDA` | Bitwise AND into `A`. | Masks hardware input bits, random seed bits, and color/control bits. |
| `ANDB` | Bitwise AND into `B`. | Same idea for `B`, used less often. |
| `ORA` | Bitwise OR into `A`. | Sets bits in input state or hardware control values. |
| `EORA` | Bitwise exclusive OR into `A`. | Mixes pseudo-random seeds and detects changed input bits. |
| `EORB` | Bitwise exclusive OR into `B`. | Used in input edge detection. |
| `BITA` | Test bits in `A` without changing `A`. | Used heavily for keyboard/joystick masks and blink masks. |
| `COMA` | Complement all bits in `A`. | Used for active-low hardware input: pressed bits arrive as zero, then `COMA` flips them. |
| `ORCC` | OR bits into the condition-code register. | Startup uses `orcc #$50` to mask IRQ and FIRQ while the game owns the machine. |

`BITA` behaves like an `ANDA` for flags, but it does not store the result back
into `A`. That makes it ideal for questions like "is this button bit set?"

### Shifts

| Mnemonic | Meaning | Notes for Bomb Jacques |
| --- | --- | --- |
| `ASLA` | Arithmetic shift left `A` by one bit. | Multiplies an unsigned byte by two when the top bit is not important. |
| `LSLB` | Logical shift left `B` by one bit. | Used to turn an index into a word-table offset. |
| `LSRA` | Logical shift right `A` by one bit. | Used by pseudo-random seed updates. The old bit 0 moves into carry. |

The shift instructions update carry with the bit that was shifted out. The seed
generators use that carry with `BCC` to choose whether to apply feedback.

### Clear, Test, And Compare

| Mnemonic | Meaning | Notes for Bomb Jacques |
| --- | --- | --- |
| `CLR` | Clear a byte in memory to zero. | Used for state reset, flags, timers, and counters. |
| `CLRA` | Clear `A` to zero. | Often prepares the high byte of `D` before loading a byte into `B`. |
| `CLRB` | Clear `B` to zero. | Used when a zero byte is needed in `B`. |
| `TSTA` | Test `A` and set flags. | Used when code wants to branch on whether `A` is zero or negative without changing it. |
| `TSTB` | Test `B` and set flags. | Same idea for `B`. |
| `CMPA` | Compare `A` against another byte. | The most common compare, used for states, bounds, timers, and ASCII digits. |
| `CMPB` | Compare `B` against another byte. | Used for row/counter comparisons. |
| `CMPD` | Compare 16-bit `D` against another word. | Used for 16-bit timers. |

`CMPA`, `CMPB`, and `CMPD` subtract internally but do not store the result. The
next branch reads the flags from that hidden subtraction.

Example:

```asm
        lda     PlayerCol
        cmpa    #ARENA_LEFT_COL
        bls     UpdateHorizontalDone
```

This reads as: if the player's column is lower than or equal to the left arena
limit, do not move farther left.

### Branches And Jumps

Short branches such as `BNE` use an 8-bit relative offset and are compact, but
they can only reach nearby labels. Long branches such as `LBNE` use a 16-bit
relative offset and can reach much farther. The project uses long branches when
large routines outgrow short-branch range.

| Mnemonic | Meaning | Typical use |
| --- | --- | --- |
| `BRA` | Branch always, short range. | Small unconditional jumps inside routines and loops. |
| `LBRA` | Branch always, long range. | Unconditional jumps to farther labels. |
| `BEQ` | Branch if equal or zero, short range. | Tests `Z = 1` after compare/test. |
| `LBEQ` | Branch if equal or zero, long range. | Same condition as `BEQ`, farther reach. |
| `BNE` | Branch if not equal or not zero, short range. | Tests `Z = 0`, often for loops. |
| `LBNE` | Branch if not equal or not zero, long range. | Same condition as `BNE`, farther reach. |
| `BCC` | Branch if carry clear, short range. | Used by random seed update after `LSRA`. Same carry condition as `BHS`. |
| `BHS` | Branch if higher or same, short range. | Unsigned `>=` after compare. Carry clear. |
| `LBHS` | Long branch if higher or same. | Same condition as `BHS`, farther reach. |
| `BLO` | Branch if lower, short range. | Unsigned `<` after compare. Carry set. Same condition as `BCS`. |
| `LBLO` | Long branch if lower. | Same condition as `BLO`, farther reach. |
| `BLS` | Branch if lower or same, short range. | Unsigned `<=` after compare. Carry set or zero set. |
| `LBLS` | Long branch if lower or same. | Same condition as `BLS`, farther reach. |
| `BHI` | Branch if higher, short range. | Unsigned `>` after compare. Carry clear and zero clear. |
| `BMI` | Branch if minus, short range. | Tests `N = 1`. Used for direction bytes such as `$FF` meaning left/up. |
| `JMP` | Jump to an address with no return. | Tail-calls and state transitions. |
| `JSR` | Jump to subroutine. | Calls another routine and pushes the return address on `S`. |
| `RTS` | Return from subroutine. | Pops the return address from `S`. |

Unsigned compare cheat sheet:

| After `CMPA value` | Branch | Meaning |
| --- | --- | --- |
| `BLO label` | Lower | `A < value` |
| `BLS label` | Lower or same | `A <= value` |
| `BHI label` | Higher | `A > value` |
| `BHS label` | Higher or same | `A >= value` |
| `BEQ label` | Equal | `A == value` |
| `BNE label` | Not equal | `A != value` |

### Stack Operations

| Mnemonic | Meaning | Notes for Bomb Jacques |
| --- | --- | --- |
| `PSHS` | Push registers onto the hardware stack `S`. | Used to preserve registers around nested drawing or table-walking calls. |
| `PULS` | Pull registers from the hardware stack `S`. | Restores registers previously saved with `PSHS`. |

Keep stack operations balanced. If a routine does `pshs x,u`, it must later do
the matching `puls x,u` on every path before `RTS`, unless it intentionally
returns by pulling `PC` (this project does not use that style).

The game commonly uses:

```asm
        pshs    x,u
        jsr     DrawBombAtAB
        puls    x,u
```

That lets a drawing routine freely modify `X` and `U` without breaking the
outer scan loop.

### Effective Address Instructions

| Mnemonic | Meaning | Notes for Bomb Jacques |
| --- | --- | --- |
| `LEAX` | Load effective address into `X`. | Pointer arithmetic such as `leax 1,x` or `leax VIDEO_BYTES_PER_ROW,x`. |
| `LEAY` | Load effective address into `Y`. | Used for pointer or loop-counter arithmetic, including `leay -1,y`. |
| `LEAU` | Load effective address into `U`. | Used to advance data pointers. |

`LEA` instructions compute addresses; they do not read memory. In this project
they are also used as convenient 16-bit add/subtract instructions for index
registers.

### Program Startup And Control

| Mnemonic | Meaning | Notes for Bomb Jacques |
| --- | --- | --- |
| `ORCC` | Set bits in condition code. | `orcc #$50` masks IRQ and FIRQ at startup. |
| `LDS` | Load stack pointer. | `lds #STACK_TOP` must happen before the main call chain. |
| `JSR` | Call subroutine. | Used immediately after startup to call `InitInput` and `InitGame`. |
| `BRA` | Branch always. | The main loop uses `bra MainLoop` to run forever. |

## Common Project Idioms

### Countdown Loop

```asm
        ldb     #TEXT_CELL_HEIGHT

DrawCellBitmapRow:
        lda     ,u+
        sta     ,x
        leax    VIDEO_BYTES_PER_ROW,x
        decb
        bne     DrawCellBitmapRow
```

This says: repeat eight times, copying one byte per bitmap row, then move the
destination pointer down one MO5 scanline.

### Active-Low Keyboard Bits

```asm
        lda     KEYBOARD_PORT
        bita    #$80
        bne     ReadKeyboardDone
```

Some MO5 input bits read as zero when pressed. Here `BITA` sets flags from the
masked bit. If the bit is non-zero, the key is not pressed, so `BNE` skips the
button update.

### State Dispatch

```asm
        lda     GameState
        cmpa    #GAME_STATE_PLAYING
        lbeq    RunGameFramePlaying
```

The game loop loads a state byte, compares it to constants, and long-branches
to the matching handler.

### Dirty Rendering

```asm
        lda     PlayerCol
        cmpa    PlayerPrevCol
        bne     ErasePlayerChanged
```

The renderer compares current and previous state. If something changed, it
erases the old sprite footprint, redraws the restored static cells, and draws
the new sprite. This is why compare and branch instructions are everywhere in
`game.asm`.

Every routine documents its inputs, outputs, modified registers, and algorithm.
