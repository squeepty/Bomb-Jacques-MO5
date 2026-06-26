;==============================================================================
; constants.asm
;
; Shared constants for Bomb Jacques.
;==============================================================================

PROGRAM_ORIGIN      equ     $6000
STACK_TOP           equ     $9FFF

VIDEO_BITMAP_BASE   equ     $0000
VIDEO_COLOR_BASE    equ     VIDEO_BITMAP_BASE
VIDEO_BANK_SELECT   equ     $A7C0
VIDEO_BYTES_PER_ROW equ     40
VIDEO_ROWS          equ     200
VIDEO_BITMAP_BYTES  equ     8000
VIDEO_BITMAP_WORDS  equ     4000
VIDEO_COLOR_BYTES   equ     VIDEO_BITMAP_BYTES

TEXT_CELL_HEIGHT    equ     8
TEXT_COLUMNS        equ     40
TEXT_ROWS           equ     25

COLOR_TITLE         equ     $70

TITLE_TEXT_COL      equ     14
TITLE_TEXT_ROW      equ     10
BUILD_TEXT_COL      equ     15
BUILD_TEXT_ROW      equ     12
