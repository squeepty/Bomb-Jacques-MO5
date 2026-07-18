# Thomson K7 Cassette Image Format

This note documents the byte structure of the Thomson `.k7` cassette image used
by DCMOTO and by this project. It is written as a learning reference, so it
separates the cassette container from the machine-code file carried inside it.

The scope is the decoded cassette byte stream. It is not a WAV/audio format and
does not describe pulse timings, motor control, silence gaps, or copy-protected
tapes. Copy-protected commercial tapes can use non-standard physical encodings
that are outside this document.

## Three Layers To Keep Separate

The project cassette has three nested layers:

| Layer | File in this project | What it means |
| --- | --- | --- |
| Raw program bytes | `build/bomb-jacques.bin` | The assembled 6809 machine code and data that will live at `$4000-$8CDC`. |
| `LOADM` stream | `build/bomb-jacques.loadm` | A Thomson/DECB machine-code file: record headers plus the raw program bytes. |
| K7 cassette image | `build/bomb-jacques.k7` | Cassette blocks that carry the `LOADM` stream. |

The K7 layer does not understand 6809 instructions, labels, video memory, or the
program entry point. It only stores a named binary file and splits its bytes into
cassette blocks. The `LOADM` layer is what says "load these bytes at `$4000` and
execute from `$4000`."

For the current build:

| Artifact | Size | Meaning |
| --- | ---: | --- |
| `build/bomb-jacques.bin` | 19677 bytes | V2 program image from `$4000` through `$8CDC`. |
| `build/bomb-jacques.loadm` | 19687 bytes | 5-byte data-record header + 19677 program bytes + 5-byte end record. |
| `build/bomb-jacques.k7` | 21381 bytes | Header block + 78 data blocks + end block. |

## File Structure

A `.k7` file is a concatenation of cassette blocks:

```text
file header block
data block 0
data block 1
...
data block n
end block
```

The file header block gives the cassette file a Thomson name, extension, and
type. The data blocks carry the file bytes. For Bomb Jacques, those file bytes
are exactly the contents of `build/bomb-jacques.loadm`.

## Block Structure

Every block emitted by `tools/make-k7.mjs` has this layout:

| Relative offset | Size | Value or meaning |
| --- | ---: | --- |
| `$00` | 16 | Leader/synchronization bytes |
| `$10` | 1 | Block marker byte 1: `$3C` |
| `$11` | 1 | Block marker byte 2: `$5A` |
| `$12` | 1 | Block type |
| `$13` | 1 | Stored length byte |
| `$14` | n | Block payload |
| `$14+n` | 1 | Payload checksum |

Total block size is:

```text
16 leader bytes
+ 2 marker bytes
+ 1 type byte
+ 1 stored-length byte
+ n payload bytes
+ 1 checksum byte
= 21 + n bytes
```

The block framing is the same for header, data, and end blocks. Only the type
and payload change.

## Leader

This project's writer emits this 16-byte leader before every block:

```text
dc 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01
```

Some standard `.k7` producers emit sixteen `$01` bytes instead:

```text
01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01
```

For project-local files, expect the first form. For general-purpose tooling,
treat the leader as synchronization padding and avoid depending on the first
byte being only `$DC` or only `$01`.

## Marker

The two marker bytes are always:

```text
3c 5a
```

They mark the start of the structured part of the block after the leader.

If you are writing a parser, it is useful to think of the 16 leader bytes as
"skip/tolerate" and the `$3C $5A` bytes as "now the block really starts."

## Block Type

The block types used by this project are:

| Type | Meaning | Payload size |
| --- | --- | ---: |
| `$00` | File header block | 14 bytes |
| `$01` | Data block | 0 to 254 bytes |
| `$FF` | End block | 0 bytes |

The order is always:

```text
$00 header
$01 data
$01 data
...
$01 data
$FF end
```

`tools/make-k7.mjs` only writes these three types.

## Stored Length

The stored length is not the payload length. It is:

```text
stored_length = (payload_length + 2) & $FF
```

To decode a block written in this style:

```text
payload_length = (stored_length - 2) & $FF
```

This creates one important wraparound case:

| Payload length | Stored length |
| ---: | ---: |
| 0 | `$02` |
| 14 | `$10` |
| 37 | `$27` |
| 138 | `$8C` |
| 253 | `$FF` |
| 254 | `$00` |

A full 254-byte data block therefore has stored length `$00`, not `$FE`. This
is the most common off-by-two surprise when hand-decoding a K7 file.

`tools/make-k7.mjs` limits payloads to 254 bytes. It never emits a 255-byte
payload, so stored length `$01` should be treated as invalid for files generated
by this project.

## Checksum

The checksum is the two's complement of the 8-bit sum of the payload bytes:

```text
sum = 0
for each payload byte:
    sum = (sum + byte) & $FF

checksum = (-sum) & $FF
```

Equivalently, this must be true:

```text
(sum(payload_bytes) + checksum) & $FF == 0
```

The checksum covers only the payload. It does not include:

- leader bytes
- `$3C $5A` marker bytes
- block type
- stored length byte

That narrow checksum scope is another common debugging trap. If a checksum only
matches after you include the type or length byte, the parser is checking the
wrong range.

## File Header Payload

A type `$00` file header block has a 14-byte payload:

| Payload offset | Size | Meaning |
| --- | ---: | --- |
| `$00` | 8 | File name, uppercase ASCII, space padded |
| `$08` | 3 | Extension, uppercase ASCII, space padded |
| `$0B` | 1 | Thomson file type |
| `$0C` | 2 | File-type attributes |

The file name and extension do not include a dot. Short fields are padded with
ASCII spaces (`$20`).

Known Thomson file type values:

| Value | Meaning |
| --- | --- |
| `$00` | BASIC program |
| `$01` | Data file |
| `$02` | Machine-code binary, loaded with `LOADM`/`CLOADM` |

For this project, `tools/make-k7.mjs` writes a machine-code header:

```text
42 4f 4d 42 4a 41 43 20 42 49 4e 02 00 00
```

Decoded:

| Bytes | Meaning |
| --- | --- |
| `42 4f 4d 42 4a 41 43 20` | Name: `BOMBJAC ` |
| `42 49 4e` | Extension: `BIN` |
| `02` | Machine-code binary |
| `00 00` | Attributes used by this project |

The header payload sum is `$E9`, so the checksum is `$17`:

```text
($E9 + $17) & $FF = $00
```

The complete project header block is:

```text
dc 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01
3c 5a
00
10
42 4f 4d 42 4a 41 43 20 42 49 4e 02 00 00
17
```

Where:

| Byte(s) | Meaning |
| --- | --- |
| `dc 01 ... 01` | 16-byte leader |
| `3c 5a` | Block marker |
| `00` | Header block type |
| `10` | Stored length: `14 + 2` |
| `42 ... 00` | 14-byte header payload |
| `17` | Payload checksum |

Other file types can use different attribute bytes. For example, some BASIC
cassette examples use `ff ff` attributes. For this project's `LOADM` cassette
images, the attributes are always `00 00`.

## Data Blocks

A type `$01` block contains file payload bytes. The `.k7` block layer does not
interpret those bytes; it only chunks them into blocks and adds cassette record
framing.

`tools/make-k7.mjs` writes data blocks in chunks of up to 254 bytes:

```text
for offset in 0, 254, 508, ...
    write type $01 block containing payload[offset..offset+253]
```

A full 254-byte data block uses stored length `$00`:

```text
dc 01 ... 01
3c 5a
01
00
254 payload bytes
checksum
```

The first data block in this project begins with the first bytes of the inner
`LOADM` stream:

```text
00 4c dd 40 00 ...
```

Those five bytes are not K7 metadata. They are the `LOADM` data-record marker,
data length, and load address. The K7 data block simply carries them.

The final data block is shorter when the carried file size is not a multiple of
254. In the V2 release, the final data block carries 129 bytes, so its stored
length is:

```text
129 + 2 = 131 = $83
```

## End Block

The end block has type `$FF`, an empty payload, stored length `$02`, and
checksum `$00`:

```text
dc 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01
3c 5a
ff
02
00
```

Because the payload is empty, the checksum is also zero:

```text
(0 + $00) & $FF = $00
```

The K7 end block marks the end of the cassette file. It is separate from the
inner `LOADM` end record described below.

## Inner `LOADM` Payload Used Here

The `.k7` data blocks for Bomb Jacques contain the bytes produced by:

```sh
lwasm --format=decb
```

That stream is the `build/bomb-jacques.loadm` file. It is not part of the K7
container itself, but it matters because it is what the MO5 `LOADM`/`CLOADM`
loader consumes after the cassette layer has delivered the bytes.

The `decb`/`LOADM` stream has two records in the current build:

```text
data record
end record
```

### Data Record

| Relative offset | Size | Meaning |
| --- | ---: | --- |
| `$00` | 1 | Record marker `$00` |
| `$01` | 2 | Data length, big-endian |
| `$03` | 2 | Load address, big-endian |
| `$05` | n | Machine-code bytes |

For the current build, the first and only data record begins:

```text
00 4c dd 40 00 ...
```

Decoded:

| Bytes | Meaning |
| --- | --- |
| `00` | Data record marker |
| `4c dd` | `$4CDD` bytes, 19677 decimal |
| `40 00` | Load address `$4000` |

The program bytes occupy `$4CDD` bytes. Because they load at `$4000`, the last
loaded byte is:

```text
$4000 + $4CDD - 1 = $8CDC
```

That value should match the memory-map documentation and the assembler listing.
If it does not, either the binary changed or one of the docs is stale.

### End Record

| Relative offset | Size | Meaning |
| --- | ---: | --- |
| `$00` | 1 | Record marker `$FF` |
| `$01` | 2 | Zero field: `$0000` |
| `$03` | 2 | Execution address, big-endian |

For the current build:

```text
ff 00 00 40 00
```

Decoded:

| Bytes | Meaning |
| --- | --- |
| `ff` | End record marker |
| `00 00` | Zero field |
| `40 00` | Execution address `$4000` |

The inner `LOADM` end record is five bytes long. It tells the loader where to
start execution after loading.

The K7 data block boundaries do not have to match `LOADM` record boundaries.
The cassette layer simply streams the `LOADM` bytes in order.

## Current Project Example

After running `tools/build.sh`, the V2 `build/bomb-jacques.k7` is 21381
bytes and contains 80 blocks:

| Block category | Count |
| --- | ---: |
| Header block | 1 |
| Full 254-byte data blocks | 77 |
| Final partial data block | 1 |
| End block | 1 |
| Total blocks | 80 |

The first, last, and boundary blocks are:

| K7 offsets | Type | Payload length | Stored length | Checksum |
| --- | --- | ---: | ---: | ---: |
| `$0000-$0022` | Header `$00` | 14 | `$10` | `$17` |
| `$0023-$0135` | Data `$01` | 254 | `$00` | `$07` |
| `$0136-$0248` | Data `$01` | 254 | `$00` | `$52` |
| `...` | 74 more full data blocks | 254 | `$00` | varies |
| `$51C7-$52D9` | Data `$01` | 254 | `$00` | `$0B` |
| `$52DA-$536F` | Data `$01` | 129 | `$83` | `$66` |
| `$5370-$5384` | End `$FF` | 0 | `$02` | `$00` |

The carried `LOADM` stream is 19687 bytes:

```text
5-byte data-record header
+ 19677-byte program image
+ 5-byte end record
= 19687 bytes
```

The K7 data payload is split like this:

```text
77 full 254-byte blocks + 1 partial 129-byte block
= (77 * 254) + 129
= 19558 + 129
= 19687 bytes
```

The total K7 size follows from the block sizes:

```text
header: 21 + 14 = 35
data:   77 * (21 + 254) = 21175
data:   21 + 129 = 150
end:    21 + 0 = 21
total:  35 + 21175 + 150 + 21 = 21381 bytes
```

The final byte offset is `$5384` because offsets are zero-based:

```text
21381 decimal = $5385 bytes
last offset = $5385 - 1 = $5384
```

## Writer Walkthrough

The project writer is `tools/make-k7.mjs`. Its structure mirrors the format:

| Function or step | Format role |
| --- | --- |
| `asciiPadded(text, length)` | Uppercases and space-pads the 8-byte name and 3-byte extension fields. |
| `leader()` | Emits `$DC` followed by fifteen `$01` bytes. |
| `checksum(body)` | Computes the two's-complement checksum over payload bytes only. |
| `block(type, body)` | Emits one framed K7 block: leader, marker, type, stored length, payload, checksum. |
| `block(0x00, ...)` | Writes the 14-byte file header block. |
| `for (... offset += 254)` | Splits the inner file into 254-byte data blocks. |
| `block(0xff, [])` | Writes the empty K7 end block. |

The writer receives `build/bomb-jacques.loadm` as its input payload, not
`build/bomb-jacques.bin`. This distinction matters:

```text
bin  = raw bytes that go into memory
loadm = loader records around those bytes
k7 = cassette blocks around the loadm stream
```

If the writer used the raw `.bin` directly, the cassette would not carry the
`LOADM` load address and execution address records.

## Parser Checklist

For a project-generated `.k7` parser:

1. Read 16 leader bytes.
2. Require marker bytes `$3C $5A`.
3. Read block type.
4. Read stored length.
5. Compute `payload_length = (stored_length - 2) & $FF`.
6. Reject payload length 255.
7. Read `payload_length` payload bytes.
8. Read checksum.
9. Verify `(sum(payload) + checksum) & $FF == 0`.
10. Interpret block type `$00`, `$01`, or `$FF`.
11. Append payload bytes from `$01` data blocks to reconstruct the carried file.
12. Stop after the `$FF` end block.

For general Thomson `.k7` tooling, be more tolerant of the leader bytes and more
careful around files that may not be standard, especially protected commercial
cassettes.

## Teaching Decoder Pseudocode

This pseudocode focuses on the project-generated format:

```text
offset = 0
payload_file = []

while offset < k7_size:
    leader = read 16 bytes
    marker = read 2 bytes
    require marker == [ $3C, $5A ]

    type = read byte
    stored_length = read byte
    payload_length = (stored_length - 2) & $FF
    require payload_length != 255

    payload = read payload_length bytes
    checksum = read byte
    require (sum(payload) + checksum) & $FF == 0

    if type == $00:
        decode file name, extension, and file type
    else if type == $01:
        append payload to payload_file
    else if type == $FF:
        stop
    else:
        error
```

After this loop, `payload_file` should equal `build/bomb-jacques.loadm`.

## Common Mistakes

| Symptom | Likely cause |
| --- | --- |
| Full data blocks appear to have zero bytes | Stored length `$00` means 254 payload bytes because the length wraps. |
| Checksums are consistently wrong | The checksum is being calculated over type/length/marker bytes instead of payload only. |
| The first data block looks like metadata | It is the inner `LOADM` record header: `00 4c dd 40 00`. |
| The cassette seems to end twice | There is a `LOADM` end record inside the data payload and a K7 end block outside it. |
| A parser reads one byte too few or too many | Remember that block size is `21 + payload_length`. |
| Offsets look one byte past the documented end | File sizes are counts; offsets are zero-based. |

## Useful Consistency Checks

These checks are quick ways to prove the three layers still agree:

```text
raw binary size:
    $4CDD = 19677 bytes

loaded address range:
    $4000 through $8CDC

LOADM size:
    5 + 19677 + 5 = 19687 bytes

K7 data split:
    77 * 254 + 129 = 19687 bytes

K7 total size:
    35 + 21175 + 150 + 21 = 21381 bytes
```

If a code change grows the assembled binary, update the numbers here only after
checking the generated artifacts. The format rules stay the same, but the
program length, final partial block length, checksums, offsets, and total K7
size can change.

## Sources

- `tools/make-k7.mjs`, the writer used by this project.
- `tools/build.sh`, which wraps an LWTOOLS `decb`/`LOADM` payload into K7.
- DCMOTO emulator utilities page:
  `http://dcmoto.free.fr/emulateur/index.html`
- DCMOTO `DCTXT2K7` package and sample `HELLO.K7`, used as a second standard
  cassette example:
  `http://dcmoto.free.fr/emulateur/dos/mo_dctxt2k7.zip`
