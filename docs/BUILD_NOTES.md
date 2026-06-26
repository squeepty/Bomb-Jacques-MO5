# Build Notes

## Toolchain

The project uses LWTOOLS for Motorola 6809 assembly.

```sh
brew install lwtools
```

The assembler command is wrapped by:

```sh
tools/build.sh
```

## BUILD 001

Added:

- A documented 6809 entry point at `$6000`.
- Direct bitmap/color RAM clearing.
- A small 8x8 title font.
- A binary-block output intended for LOADM-style workflows.

Expected:

The MO5 screen clears and displays:

```text
Bomb Jacques

BUILD 001
```

Observed:

The source assembles successfully with LWTOOLS.

Status:

Ready for DCMOTO testing.
