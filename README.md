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

- `build/bomb-jacques.raw`: raw bytes assembled at `$6000`
- `build/bomb-jacques.bin`: binary block output with load and exec metadata
- `build/bomb-jacques.lst`: annotated assembler listing
- `build/bomb-jacques.map`: symbol map

## Project Map

- `src/`: 6809 assembly source
- `docs/`: design notes and technical explanations
- `tools/`: local build tooling
- `build/`: generated files, ignored by git
