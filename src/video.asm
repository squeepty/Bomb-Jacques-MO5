;==============================================================================
; video.asm
;
; BUILD 001 video routines for the Thomson MO5 bitmap display.
;==============================================================================

;------------------------------------------------------------------------------
; ClearScreen
;
; Purpose:
;   Clears the bitmap plane and initializes the color plane.
;
; Input:
;   None.
;
; Output:
;   Bitmap RAM is zeroed. Color RAM is filled with COLOR_TITLE.
;
; Modified:
;   A, B, D, X, Y
;
; Algorithm:
;   1. Write 8000 zero bytes to bitmap RAM using 16-bit stores.
;   2. Write 8000 color bytes to color RAM using 8-bit stores.
;------------------------------------------------------------------------------
ClearScreen:
        ldx     #VIDEO_BITMAP_BASE
        ldd     #$0000
        ldy     #VIDEO_BITMAP_WORDS

ClearBitmapLoop:
        std     ,x++
        leay    -1,y
        bne     ClearBitmapLoop

        ldx     #VIDEO_COLOR_BASE
        ldb     #COLOR_TITLE
        ldy     #VIDEO_COLOR_BYTES

ClearColorLoop:
        stb     ,x+
        leay    -1,y
        bne     ClearColorLoop

        rts

;------------------------------------------------------------------------------
; DrawString
;
; Purpose:
;   Draws a zero-terminated ASCII string on an 8x8 text-cell grid.
;
; Input:
;   U = address of zero-terminated string
;   A = text column, 0-39
;   B = text row, 0-24
;
; Output:
;   String is drawn to bitmap and color RAM.
;
; Modified:
;   A, B, D, X, Y, U
;
; Algorithm:
;   1. Convert the text-cell coordinate into bitmap and color addresses.
;   2. Read one character from the string.
;   3. Draw its 8x8 glyph.
;   4. Advance one screen byte to the next cell and repeat until zero.
;------------------------------------------------------------------------------
DrawString:
        jsr     CellAddress

DrawStringNext:
        lda     ,u+
        beq     DrawStringDone

        pshs    x,y,u
        jsr     DrawGlyphAtCell
        puls    x,y,u

        leax    1,x
        leay    1,y
        bra     DrawStringNext

DrawStringDone:
        rts

;------------------------------------------------------------------------------
; CellAddress
;
; Purpose:
;   Converts a text-cell coordinate into bitmap and color addresses.
;
; Input:
;   A = text column, 0-39
;   B = text row, 0-24
;
; Output:
;   X = bitmap address for the top-left byte of the cell
;   Y = color address for the top-left byte of the cell
;
; Modified:
;   A, B, D, X, Y
;
; Algorithm:
;   A text row is 8 bitmap rows. Each bitmap row is 40 bytes.
;   Therefore one text row is 8 * 40 = 320 bytes.
;   A lookup table keeps this easy to read and avoids early arithmetic tricks.
;------------------------------------------------------------------------------
CellAddress:
        pshs    a
        lslb
        clra
        ldx     #TextRowOffsets
        ldd     d,x
        addb    ,s+
        adca    #0
        addd    #VIDEO_BITMAP_BASE
        tfr     d,x
        addd    #VIDEO_COLOR_BASE - VIDEO_BITMAP_BASE
        tfr     d,y
        rts

TextRowOffsets:
        fdb     0
        fdb     320
        fdb     640
        fdb     960
        fdb     1280
        fdb     1600
        fdb     1920
        fdb     2240
        fdb     2560
        fdb     2880
        fdb     3200
        fdb     3520
        fdb     3840
        fdb     4160
        fdb     4480
        fdb     4800
        fdb     5120
        fdb     5440
        fdb     5760
        fdb     6080
        fdb     6400
        fdb     6720
        fdb     7040
        fdb     7360
        fdb     7680

;------------------------------------------------------------------------------
; DrawGlyphAtCell
;
; Purpose:
;   Draws one 8x8 font glyph at the current bitmap/color addresses.
;
; Input:
;   A = ASCII character to draw
;   X = bitmap address for top glyph row
;   Y = color address for top glyph row
;
; Output:
;   One glyph is drawn.
;
; Modified:
;   A, B, X, Y, U
;
; Algorithm:
;   1. Convert lowercase letters to uppercase.
;   2. Select the matching temporary BUILD 001 glyph.
;   3. Copy 8 glyph bytes, one per bitmap row.
;   4. Write the matching color byte for each row.
;------------------------------------------------------------------------------
DrawGlyphAtCell:
        cmpa    #'a'
        blo     DrawGlyphFind
        cmpa    #'z'
        bhi     DrawGlyphFind
        suba    #32

DrawGlyphFind:
        ldu     #GlyphSpace

        cmpa    #' '
        lbeq    DrawGlyphCopy
        cmpa    #'0'
        lbeq    DrawGlyphUse0
        cmpa    #'1'
        lbeq    DrawGlyphUse1
        cmpa    #'A'
        lbeq    DrawGlyphUseA
        cmpa    #'B'
        lbeq    DrawGlyphUseB
        cmpa    #'C'
        lbeq    DrawGlyphUseC
        cmpa    #'D'
        lbeq    DrawGlyphUseD
        cmpa    #'E'
        lbeq    DrawGlyphUseE
        cmpa    #'I'
        lbeq    DrawGlyphUseI
        cmpa    #'J'
        lbeq    DrawGlyphUseJ
        cmpa    #'L'
        lbeq    DrawGlyphUseL
        cmpa    #'M'
        lbeq    DrawGlyphUseM
        cmpa    #'O'
        lbeq    DrawGlyphUseO
        cmpa    #'Q'
        lbeq    DrawGlyphUseQ
        cmpa    #'S'
        lbeq    DrawGlyphUseS
        cmpa    #'U'
        lbeq    DrawGlyphUseU
        lbra    DrawGlyphCopy

DrawGlyphUse0:
        ldu     #Glyph0
        bra     DrawGlyphCopy
DrawGlyphUse1:
        ldu     #Glyph1
        bra     DrawGlyphCopy
DrawGlyphUseA:
        ldu     #GlyphA
        bra     DrawGlyphCopy
DrawGlyphUseB:
        ldu     #GlyphB
        bra     DrawGlyphCopy
DrawGlyphUseC:
        ldu     #GlyphC
        bra     DrawGlyphCopy
DrawGlyphUseD:
        ldu     #GlyphD
        bra     DrawGlyphCopy
DrawGlyphUseE:
        ldu     #GlyphE
        bra     DrawGlyphCopy
DrawGlyphUseI:
        ldu     #GlyphI
        bra     DrawGlyphCopy
DrawGlyphUseJ:
        ldu     #GlyphJ
        bra     DrawGlyphCopy
DrawGlyphUseL:
        ldu     #GlyphL
        bra     DrawGlyphCopy
DrawGlyphUseM:
        ldu     #GlyphM
        bra     DrawGlyphCopy
DrawGlyphUseO:
        ldu     #GlyphO
        bra     DrawGlyphCopy
DrawGlyphUseQ:
        ldu     #GlyphQ
        bra     DrawGlyphCopy
DrawGlyphUseS:
        ldu     #GlyphS
        bra     DrawGlyphCopy
DrawGlyphUseU:
        ldu     #GlyphU

DrawGlyphCopy:
        ldb     #TEXT_CELL_HEIGHT

DrawGlyphRow:
        lda     ,u+
        sta     ,x
        lda     #COLOR_TITLE
        sta     ,y
        leax    VIDEO_BYTES_PER_ROW,x
        leay    VIDEO_BYTES_PER_ROW,y
        decb
        bne     DrawGlyphRow

        rts

; Temporary 8x8 glyph set for BUILD 001.
; Each byte is one row. Bit 7 is the leftmost pixel.

GlyphSpace:
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000

Glyph0:
        fcb     %00111100
        fcb     %01100110
        fcb     %01101110
        fcb     %01110110
        fcb     %01100110
        fcb     %01100110
        fcb     %00111100
        fcb     %00000000

Glyph1:
        fcb     %00011000
        fcb     %00111000
        fcb     %00011000
        fcb     %00011000
        fcb     %00011000
        fcb     %00011000
        fcb     %01111110
        fcb     %00000000

GlyphA:
        fcb     %00011000
        fcb     %00111100
        fcb     %01100110
        fcb     %01100110
        fcb     %01111110
        fcb     %01100110
        fcb     %01100110
        fcb     %00000000

GlyphB:
        fcb     %01111100
        fcb     %01100110
        fcb     %01100110
        fcb     %01111100
        fcb     %01100110
        fcb     %01100110
        fcb     %01111100
        fcb     %00000000

GlyphC:
        fcb     %00111100
        fcb     %01100110
        fcb     %01100000
        fcb     %01100000
        fcb     %01100000
        fcb     %01100110
        fcb     %00111100
        fcb     %00000000

GlyphD:
        fcb     %01111000
        fcb     %01101100
        fcb     %01100110
        fcb     %01100110
        fcb     %01100110
        fcb     %01101100
        fcb     %01111000
        fcb     %00000000

GlyphE:
        fcb     %01111110
        fcb     %01100000
        fcb     %01100000
        fcb     %01111100
        fcb     %01100000
        fcb     %01100000
        fcb     %01111110
        fcb     %00000000

GlyphI:
        fcb     %01111110
        fcb     %00011000
        fcb     %00011000
        fcb     %00011000
        fcb     %00011000
        fcb     %00011000
        fcb     %01111110
        fcb     %00000000

GlyphJ:
        fcb     %00011110
        fcb     %00001100
        fcb     %00001100
        fcb     %00001100
        fcb     %01101100
        fcb     %01101100
        fcb     %00111000
        fcb     %00000000

GlyphL:
        fcb     %01100000
        fcb     %01100000
        fcb     %01100000
        fcb     %01100000
        fcb     %01100000
        fcb     %01100000
        fcb     %01111110
        fcb     %00000000

GlyphM:
        fcb     %01100011
        fcb     %01110111
        fcb     %01111111
        fcb     %01101011
        fcb     %01100011
        fcb     %01100011
        fcb     %01100011
        fcb     %00000000

GlyphO:
        fcb     %00111100
        fcb     %01100110
        fcb     %01100110
        fcb     %01100110
        fcb     %01100110
        fcb     %01100110
        fcb     %00111100
        fcb     %00000000

GlyphQ:
        fcb     %00111100
        fcb     %01100110
        fcb     %01100110
        fcb     %01100110
        fcb     %01101110
        fcb     %00111100
        fcb     %00000110
        fcb     %00000000

GlyphS:
        fcb     %00111100
        fcb     %01100110
        fcb     %01100000
        fcb     %00111100
        fcb     %00000110
        fcb     %01100110
        fcb     %00111100
        fcb     %00000000

GlyphU:
        fcb     %01100110
        fcb     %01100110
        fcb     %01100110
        fcb     %01100110
        fcb     %01100110
        fcb     %01100110
        fcb     %00111100
        fcb     %00000000
