#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SRC_DIR="$ROOT_DIR/src"
BUILD_DIR="$ROOT_DIR/build"
MAIN="$SRC_DIR/main.asm"

RAW_OUT="$BUILD_DIR/bomb-jacques.raw"
BIN_OUT="$BUILD_DIR/bomb-jacques.bin"
LIST_OUT="$BUILD_DIR/bomb-jacques.lst"
MAP_OUT="$BUILD_DIR/bomb-jacques.map"
LOAD_OUT="$BUILD_DIR/DCMOTO_LOAD.txt"

if ! command -v lwasm >/dev/null 2>&1; then
    echo "error: lwasm not found. Install LWTOOLS first." >&2
    exit 1
fi

mkdir -p "$BUILD_DIR"

lwasm \
    --6809 \
    --format=raw \
    --includedir="$SRC_DIR" \
    --output="$BIN_OUT" \
    --list="$LIST_OUT" \
    --symbols \
    --map="$MAP_OUT" \
    "$MAIN"

cp "$BIN_OUT" "$RAW_OUT"

BIN_SIZE=$(wc -c < "$BIN_OUT" | tr -d ' ')
LOAD_START_HEX=6000
LOAD_END_DEC=$((0x6000 + BIN_SIZE - 1))
LOAD_END_HEX=$(printf "%04X" "$LOAD_END_DEC")

{
    printf "Bomb Jacques BUILD 001\n"
    printf "\n"
    printf "DCMOTO binary loader settings:\n"
    printf "\n"
    printf "File: %s\n" "$BIN_OUT"
    printf "Start address: $%s\n" "$LOAD_START_HEX"
    printf "End address:   $%s\n" "$LOAD_END_HEX"
    printf "Exec address:  $%s\n" "$LOAD_START_HEX"
    printf "\n"
    printf "In DCMOTO:\n"
    printf "1. Press F9 to open the debugger.\n"
    printf "2. Set the binary load range to $%s-$%s.\n" "$LOAD_START_HEX" "$LOAD_END_HEX"
    printf "3. Press F6 or use File > Charger fichier binaire... and choose bomb-jacques.bin.\n"
    printf "4. Set PC to $%s and run.\n" "$LOAD_START_HEX"
} > "$LOAD_OUT"

echo "BUILD 001 assembled"
echo "  dcmoto bin: $BIN_OUT"
echo "  raw copy:   $RAW_OUT"
echo "  load notes: $LOAD_OUT"
echo "  list:       $LIST_OUT"
echo "  map:        $MAP_OUT"
