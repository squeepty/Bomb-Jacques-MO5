# Thomson K7 Cassette Image Format

This note documents the byte structure of a standard Thomson `.k7` cassette
image as used by DCMOTO and by this project.

The scope is the decoded cassette byte stream. It is not a WAV/audio format and
does not describe pulse timings, motor control, silence gaps, or copy-protected
tapes. Copy-protected commercial tapes can use non-standard physical encodings
that are outside this document.

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

Each block carries a small Thomson cassette record. The data blocks contain the
file bytes exactly as the Thomson loader should see them. For this project those
file bytes are an LWTOOLS `decb`/`LOADM` stream, described later.

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
16 leader bytes + 2 marker bytes + 1 type byte + 1 length byte + n payload bytes + 1 checksum byte
= 21 + n bytes
```

### Leader

This project's writer emits this 16-byte leader before every block:

```text
dc 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01
```

Some other standard `.k7` producers emit sixteen `$01` bytes instead:

```text
01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01
```

For project-local files, expect the first form. For general-purpose tooling,
treat the leader as synchronization padding and do not depend on the first byte
being only `$DC` or only `$01`.

### Marker

The two marker bytes are always:

```text
3c 5a
```

They mark the start of the structured part of the block after the leader.

### Block Type

The standard block types used here are:

| Type | Meaning | Payload size |
| --- | --- | ---: |
| `$00` | File header block | 14 bytes |
| `$01` | Data block | 0 to 254 bytes |
| `$FF` | End block | 0 bytes |

The file header block comes first. Data blocks follow until the whole file
payload has been written. The end block terminates the file.

### Stored Length

The stored length is not just the payload length. It is:

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
| 253 | `$FF` |
| 254 | `$00` |

`tools/make-k7.mjs` limits payloads to 254 bytes. It never emits a 255-byte
payload, so stored length `$01` should be treated as invalid for files generated
by this project.

### Checksum

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

The checksum covers only the payload. It does not include the leader bytes, the
`$3C $5A` marker, the block type, or the stored length byte.

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

Other file types can use different attribute bytes. For example, the public
DCMOTO `DCTXT2K7` BASIC example emits `ff ff` for an ASCII BASIC file. For this
project's `LOADM` cassette images, the attributes are always `00 00`.

The complete project header block is:

```text
dc 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01
3c 5a
00
10
42 4f 4d 42 4a 41 43 20 42 49 4e 02 00 00
17
```

Here `$10` is the stored length (`14 + 2`) and `$17` is the payload checksum.

## Data Blocks

A type `$01` block contains file payload bytes. The `.k7` block layer does not
interpret those bytes; it only chunks them into blocks and adds the cassette
record framing.

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

A shorter final data block uses `payload_length + 2`. For example, a 37-byte
final data block uses stored length `$27`.

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

Because the payload is empty, the checksum is also zero.

## Inner `LOADM` Payload Used Here

The `.k7` data blocks for Bomb Jacques contain the bytes produced by:

```sh
lwasm --format=decb
```

That stream is the `build/bomb-jacques.loadm` file. It is not part of the K7
container itself, but it matters because it is what the MO5 `LOADM`/`CLOADM`
loader consumes after the cassette layer has delivered the bytes.

The `decb`/`LOADM` stream has records like this:

### Data Record

| Relative offset | Size | Meaning |
| --- | ---: | --- |
| `$00` | 1 | Record marker `$00` |
| `$01` | 2 | Data length, big-endian |
| `$03` | 2 | Load address, big-endian |
| `$05` | n | Machine-code bytes |

For the current build, the first and only data record begins:

```text
00 02 17 60 00 ...
```

Decoded:

| Bytes | Meaning |
| --- | --- |
| `00` | Data record |
| `02 17` | `$0217` bytes, 535 decimal |
| `60 00` | Load address `$6000` |

### End Record

| Relative offset | Size | Meaning |
| --- | ---: | --- |
| `$00` | 1 | Record marker `$FF` |
| `$01` | 2 | Zero field: `$0000` |
| `$03` | 2 | Execution address, big-endian |

For the current build:

```text
ff 00 00 60 00
```

Decoded:

| Bytes | Meaning |
| --- | --- |
| `ff` | End record |
| `00 00` | Zero field |
| `60 00` | Execution address `$6000` |

The K7 data block boundaries do not have to match `LOADM` record boundaries.
The cassette layer simply streams the `LOADM` bytes in order.

## Current Project Example

After running `tools/build.sh`, the current `build/bomb-jacques.k7` is 664
bytes and contains these blocks:

| K7 offsets | Type | Payload length | Stored length | Checksum |
| --- | --- | ---: | ---: | ---: |
| `$0000-$0022` | Header `$00` | 14 | `$10` | `$17` |
| `$0023-$0135` | Data `$01` | 254 | `$00` | `$A8` |
| `$0136-$0248` | Data `$01` | 254 | `$00` | `$60` |
| `$0249-$0282` | Data `$01` | 37 | `$27` | `$01` |
| `$0283-$0297` | End `$FF` | 0 | `$02` | `$00` |

The carried `LOADM` stream is 545 bytes:

```text
535-byte data record + 5-byte end record = 545 bytes
```

The K7 data payload is split like this:

```text
254 + 254 + 37 = 545 bytes
```

The total K7 size follows from the block sizes:

```text
header: 21 + 14 = 35
data:   21 + 254 = 275
data:   21 + 254 = 275
data:   21 + 37 = 58
end:    21 + 0 = 21
total:  35 + 275 + 275 + 58 + 21 = 664 bytes
```

## Parser Checklist

For a project-generated `.k7` parser:

1. Read 16 leader bytes.
2. Require marker bytes `$3C $5A`.
3. Read block type.
4. Read stored length.
5. Compute `payload_length = (stored_length - 2) & $FF`.
6. Reject payload length 255.
7. Read payload bytes.
8. Read checksum.
9. Verify `(sum(payload) + checksum) & $FF == 0`.
10. Interpret block type `$00`, `$01`, or `$FF`.
11. Stop after the `$FF` end block.

For general Thomson `.k7` tooling, be more tolerant of the leader bytes and more
careful around files that may not be standard, especially protected commercial
cassettes.

## Sources

- `tools/make-k7.mjs`, the writer used by this project.
- `tools/build.sh`, which wraps an LWTOOLS `decb`/`LOADM` payload into K7.
- DCMOTO emulator utilities page:
  `http://dcmoto.free.fr/emulateur/index.html`
- DCMOTO `DCTXT2K7` package and sample `HELLO.K7`, used as a second standard
  cassette example:
  `http://dcmoto.free.fr/emulateur/dos/mo_dctxt2k7.zip`
