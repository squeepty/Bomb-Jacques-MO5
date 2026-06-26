# Bomb Jacques

Bomb Jacques is a one-screen arcade game for the Thomson MO5, written in
Motorola 6809 assembly.

The project begins with a strict educational goal: each milestone must build,
run, and explain the MO5 concepts it introduces.

## Current Milestone

BUILD 001 implements the first boot screen:

```text
Bomb Jacques

BUILD 001
```

The display is drawn directly into MO5 video RAM. No BASIC or ROM text routines
are used by the game code.

## Build

Install LWTOOLS, then run:

```sh
tools/build.sh
```

The script writes:

- `build/bomb-jacques.bin`: raw DCMOTO binary bytes assembled at `$6000`
- `build/bomb-jacques.raw`: same raw bytes, kept as an explicit raw copy
- `build/DCMOTO_LOAD.txt`: exact DCMOTO load addresses
- `build/bomb-jacques.lst`: annotated assembler listing
- `build/bomb-jacques.map`: symbol map

## DCMOTO

Open the debugger with `F9`, set the binary loader range shown in
`build/DCMOTO_LOAD.txt`, then use `F6` to load `build/bomb-jacques.bin`.
Set the program counter to `$6000` and run.

## Project Map

- `src/`: 6809 assembly source
- `docs/`: design notes and technical explanations
- `tools/`: local build tooling
- `build/`: generated files, ignored by git
