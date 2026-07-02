# CPU Notes

The Thomson MO5 uses a Motorola 6809E running at roughly 1 MHz.

This project starts with only a few 6809 ideas:

- `ORG` tells the assembler where the program will live in memory.
- `LDS` initializes the stack pointer.
- `JSR` calls a routine.
- `RTS` returns from a routine.
- `BRA` branches forever at the end of the BUILD 008 frame loop.
- `LBNE` is used when a conditional branch must reach beyond the 8-bit branch
  offset range.
- `X`, `Y`, and `U` are 16-bit index registers, useful for walking through
  screen memory and string data.

Every routine documents its inputs, outputs, modified registers, and algorithm.
