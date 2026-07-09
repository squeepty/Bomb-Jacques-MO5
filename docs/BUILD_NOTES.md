# Build Notes

This file explains how to assemble and load Bomb Jacques. Historical per-build
feature notes live in `docs/CHANGE_LOG.md`.

## Toolchain

The project uses LWTOOLS for Motorola 6809 assembly.

On macOS:

```sh
brew install lwtools
```

The build also uses Node.js to create the DCMOTO cassette image:

```sh
node --version
```

## One-Command Build

Run from the project root:

```sh
tools/build.sh
```

The script assembles `src/main.asm` twice:

- once as a raw binary for debugger loading
- once as a DECB `LOADM` binary, which is then wrapped into a `.k7` cassette
  image by `tools/make-k7.mjs`

`src/main.asm` is the only file passed directly to the assembler. It pulls in
the rest of the source tree with `include` directives.

## Generated Files

The build writes all generated files into `build/`.

| File | Purpose |
| --- | --- |
| `build/bomb-jacques.bin` | Raw bytes assembled for address `$4000`; useful for DCMOTO debugger loading. |
| `build/bomb-jacques.raw` | Copy of the raw binary, kept as an explicit raw artifact. |
| `build/bomb-jacques.loadm` | DECB/`LOADM` binary produced by LWTOOLS. |
| `build/bomb-jacques.k7` | DCMOTO cassette image generated from the `LOADM` binary. |
| `build/DCMOTO_LOAD.txt` | Current load range and emulator loading notes. |
| `build/bomb-jacques.lst` | Assembler listing with addresses and source lines. |
| `build/bomb-jacques.map` | Symbol map. Useful for finding routine and data addresses. |

`build/DCMOTO_LOAD.txt` is the authoritative current address sheet. The current
final v2 candidate loads at `$4000` and currently ends at `$8CF3`.

## Cassette Loading In DCMOTO

Use this path when testing the game as a cassette image:

1. Open DCMOTO.
2. Use `Supports amovibles > Cassette > Charger`.
3. Select `build/bomb-jacques.k7`.
4. At the MO5 BASIC prompt, type:

```text
LOADM"",,R
```

The `R` asks BASIC to run the loaded program after loading finishes.

## Debugger Binary Loading In DCMOTO

Use this path when you want the fastest edit/build/test loop:

1. Press `F9` in DCMOTO to open the debugger.
2. Set the binary load range shown in `build/DCMOTO_LOAD.txt`.
3. Press `F6`, or use `File > Charger fichier binaire...`.
4. Choose `build/bomb-jacques.bin`.
5. Set `PC` to `$4000`.
6. Run.

For the current final v2 candidate, the binary loader range is:

```text
$4000-$8CF3
```

## Source Layout During Assembly

The assembler starts at `src/main.asm`.

Important includes:

| File | Role |
| --- | --- |
| `src/constants.asm` | Shared addresses, colors, gameplay constants, and layout constants. |
| `src/memory.asm` | Memory-layout comments and project memory assumptions. |
| `src/video.asm` | MO5 bitmap/color-plane selection, cell drawing, font drawing, and screen clearing. |
| `src/input.asm` | Keyboard and joystick input scanning. |
| `src/sound.asm` | One-bit MO5 buzzer initialization and short blocking gameplay effects. |
| `src/game.asm` | Gameplay include manifest that preserves assembler order. |
| `src/game/*.asm` | Split gameplay modules for flow, setup, items, enemies, movement, collision/death, scoring/name entry, level flow, rendering, tables, sprites, backgrounds, and mutable state. |
| `src/levels.asm` | Platform and bomb tables for the ten levels. |
| `src/sidebar_art.asm` | Right-panel bitmap art. |

Because the code is included into one assembly unit, labels can refer to each
other across files after inclusion. This keeps the current educational build
simple, but it also means global label names should stay descriptive.

The `src/game/` split is intentionally conservative. `src/game.asm` includes
the smaller gameplay files in the same order the old monolithic file used, so a
successful split should rebuild to the same bytes. After the initial split,
`build/bomb-jacques.k7` was verified byte-identical to
`downloads/bomb-jacques.k7`.

## Reading Build Output

After a successful build, `tools/build.sh` prints the generated artifact paths.
It also rewrites `build/DCMOTO_LOAD.txt` with the current end address, computed
from the assembled binary size.

The list and map files are useful when learning the code:

- Use `build/bomb-jacques.lst` to see which source line produced each address.
- Use `build/bomb-jacques.map` to find the assembled address of a label.

Example:

```sh
rg "Symbol: RunGameFrame" build/bomb-jacques.map
rg "RunGameFrame:" build/bomb-jacques.lst
```

## Common Build Problems

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `error: lwasm not found` | LWTOOLS is not installed or not on `PATH`. | Install LWTOOLS and open a new shell. |
| `node: command not found` | Node.js is missing. | Install Node.js; it is only needed for the `.k7` generator. |
| DCMOTO loads but starts at the wrong place | The program counter was not set to the origin. | Set `PC` to the exec address in `build/DCMOTO_LOAD.txt`, or use cassette `LOADM"",,R`. |
| DCMOTO binary load truncates or overruns | The debugger load range is stale. | Rebuild and copy the range from `build/DCMOTO_LOAD.txt`. |
| The game shows old behavior | DCMOTO is still using an old artifact. | Re-run `tools/build.sh` and reload `build/bomb-jacques.bin` or `.k7`. |

## Build Hygiene

Generated files under `build/` are ignored by git. Source, docs, and tooling are
the files that should be committed.

Before making a milestone or sharing a build:

```sh
tools/build.sh
git status --short
```

The build should pass, and `git status --short` should only show intentional
source or documentation changes.
