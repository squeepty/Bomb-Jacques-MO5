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

if ! command -v lwasm >/dev/null 2>&1; then
    echo "error: lwasm not found. Install LWTOOLS first." >&2
    exit 1
fi

mkdir -p "$BUILD_DIR"

lwasm \
    --6809 \
    --format=raw \
    --includedir="$SRC_DIR" \
    --output="$RAW_OUT" \
    --list="$LIST_OUT" \
    --symbols \
    --map="$MAP_OUT" \
    "$MAIN"

lwasm \
    --6809 \
    --format=decb \
    --includedir="$SRC_DIR" \
    --output="$BIN_OUT" \
    "$MAIN"

echo "BUILD 001 assembled"
echo "  raw:  $RAW_OUT"
echo "  bin:  $BIN_OUT"
echo "  list: $LIST_OUT"
echo "  map:  $MAP_OUT"
