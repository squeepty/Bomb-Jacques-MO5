;==============================================================================
; video.asm
;
; BUILD 008 video routines for the Thomson MO5 bitmap display.
;
; The MO5 display used here has two conceptual planes at the same address
; window: bitmap bits and color attributes. Most routines follow the pattern:
; select bitmap plane, write shape bytes, select color plane, write matching
; color bytes, then return to bitmap plane for the next caller.
;==============================================================================

;------------------------------------------------------------------------------
; SelectBitmapPlane / SelectColorPlane
;
; Purpose:
;   Selects which MO5 video plane is visible at $0000-$1F3F.
;
; Modified:
;   A
;------------------------------------------------------------------------------
SelectBitmapPlane:
        ; Preserve all $A7C0 bits except bit 0. Other hardware state may share
        ; this PIA byte, so the code reads-modifies-writes instead of storing a
        ; literal value.
        lda     VIDEO_BANK_SELECT
        ora     #$01
        sta     VIDEO_BANK_SELECT
        rts

SelectColorPlane:
        lda     VIDEO_BANK_SELECT
        anda    #$FE
        sta     VIDEO_BANK_SELECT
        rts

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
;   Bitmap RAM is zeroed. Color RAM is filled with COLOR_BACKGROUND.
;
; Modified:
;   A, B, D, X, Y
;
; Algorithm:
;   1. Select the bitmap plane and write 8000 zero bytes.
;   2. Select the color plane and write 8000 color bytes.
;   3. Restore bitmap plane selection before returning.
;------------------------------------------------------------------------------
ClearScreen:
        jsr     SelectBitmapPlane

        ldx     #VIDEO_BITMAP_BASE
        ldd     #$0000
        ldy     #VIDEO_BITMAP_WORDS

ClearBitmapLoop:
        ; STD writes two bytes at a time. 4000 word stores clear 8000 bitmap
        ; bytes faster than 8000 single-byte stores.
        std     ,x++
        leay    -1,y
        bne     ClearBitmapLoop

        jsr     SelectColorPlane

        ldx     #VIDEO_COLOR_BASE
        ldb     #COLOR_BACKGROUND
        ldy     #VIDEO_COLOR_BYTES

ClearColorLoop:
        stb     ,x+
        leay    -1,y
        bne     ClearColorLoop

        jsr     SelectBitmapPlane
        rts

;------------------------------------------------------------------------------
; DrawCellPattern
;
; Purpose:
;   Draws one 8x8 bitmap cell and its matching color attributes.
;
; Input:
;   U = address of 8-byte cell bitmap
;   A = text column, 0-39
;   B = text row, 0-24
;   DrawCellColor = color attribute byte
;
; Output:
;   One 8x8 cell is drawn. Bitmap plane is selected before return.
;
; Modified:
;   A, B, X, Y, U
;------------------------------------------------------------------------------
DrawCellPattern:
        ; CellAddress returns the same offset in X and Y. Because the MO5 planes
        ; are banked, the address is the same; only the selected plane changes.
        jsr     CellAddress

        pshs    x,u
        jsr     SelectBitmapPlane
        puls    x,u

        pshs    x
        ldb     #TEXT_CELL_HEIGHT

DrawCellBitmapRow:
        ; One 8x8 cell consumes one byte per scanline. Add 40 bytes to move from
        ; one pixel row to the next row in the same cell column.
        lda     ,u+
        sta     ,x
        leax    VIDEO_BYTES_PER_ROW,x
        decb
        bne     DrawCellBitmapRow

        puls    x
        jsr     SelectColorPlane

        lda     DrawCellColor
        ldb     #TEXT_CELL_HEIGHT

DrawCellColorRow:
        sta     ,x
        leax    VIDEO_BYTES_PER_ROW,x
        decb
        bne     DrawCellColorRow

        jsr     SelectBitmapPlane
        rts

;------------------------------------------------------------------------------
; DrawCellPatternMasked
;
; Purpose:
;   Draws one 8x8 bitmap cell while leaving zero sprite pixels untouched.
;
; Input:
;   U = address of 8-byte cell bitmap
;   A = text column, 0-39
;   B = text row, 0-24
;   DrawCellColor = color attribute byte
;
; Output:
;   Non-zero bitmap pixels are merged into the destination cell. Color
;   attributes are written only on rows that contain sprite pixels. Bitmap plane
;   is selected before return.
;
; Modified:
;   A, B, X, U
;------------------------------------------------------------------------------
DrawCellPatternMasked:
        ; Masked draws are for moving objects. Zero source rows leave both
        ; bitmap and color alone, so sprites can sit over the arena without
        ; repainting their transparent rows.
        jsr     CellAddress

        pshs    x,u
        jsr     SelectBitmapPlane
        puls    x,u

        pshs    x,u
        ldb     #TEXT_CELL_HEIGHT

DrawCellMaskedBitmapRow:
        lda     ,u+
        beq     DrawCellMaskedBitmapNext
        ; OR merges foreground bits into the existing byte. Erase/redraw code
        ; restores the background later when a sprite moves away.
        ora     ,x
        sta     ,x

DrawCellMaskedBitmapNext:
        leax    VIDEO_BYTES_PER_ROW,x
        decb
        bne     DrawCellMaskedBitmapRow

        puls    x,u
        jsr     SelectColorPlane

        ldb     #TEXT_CELL_HEIGHT

DrawCellMaskedColorRow:
        lda     ,u+
        beq     DrawCellMaskedColorNext
        lda     DrawCellColor
        sta     ,x

DrawCellMaskedColorNext:
        leax    VIDEO_BYTES_PER_ROW,x
        decb
        bne     DrawCellMaskedColorRow

        jsr     SelectBitmapPlane
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
;   String is drawn to bitmap RAM. Color RAM is initialized by ClearScreen.
;
; Modified:
;   A, B, D, X, Y, U
;
; Algorithm:
;   1. Convert the text-cell coordinate into a bitmap address.
;   2. Read one character from the string.
;   3. Draw its 8x8 glyph.
;   4. Advance one screen byte to the next cell and repeat until zero.
;------------------------------------------------------------------------------
DrawString:
        ; DrawString assumes callers have already prepared color attributes for
        ; the text area when they need non-default colors.
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

DrawStringShiftRight4:
        jsr     CellAddress

DrawStringShiftRight4Next:
        lda     ,u+
        beq     DrawStringShiftRight4Done

        pshs    x,y,u
        jsr     DrawGlyphAtCellShiftRight4
        puls    x,y,u

        leax    1,x
        leay    1,y
        bra     DrawStringShiftRight4Next

DrawStringShiftRight4Done:
        rts

DrawStringDown4:
        jsr     CellAddress
        leax    4*VIDEO_BYTES_PER_ROW,x
        leay    4*VIDEO_BYTES_PER_ROW,y

DrawStringDown4Next:
        lda     ,u+
        beq     DrawStringDown4Done

        pshs    x,y,u
        jsr     DrawGlyphAtCell
        puls    x,y,u

        leax    1,x
        leay    1,y
        bra     DrawStringDown4Next

DrawStringDown4Done:
        rts

;------------------------------------------------------------------------------
; CellAddress
;
; Purpose:
;   Converts a text-cell coordinate into bitmap/color-plane addresses.
;
; Input:
;   A = text column, 0-39
;   B = text row, 0-24
;
; Output:
;   X = bitmap address for the top-left byte of the cell
;   Y = same address in the alternate color plane
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
        ; Save the column while B is transformed into a word-table offset.
        ; Pushing A is smaller and clearer here than reserving a scratch byte.
        pshs    a
        lslb
        clra
        ldx     #TextRowOffsets
        ldd     d,x
        addb    ,s+
        adca    #0
        addd    #VIDEO_BITMAP_BASE
        tfr     d,x
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
;   Y = color-plane address for top glyph row, currently unused
;
; Output:
;   One glyph is drawn.
;
; Modified:
;   A, B, X, Y, U
;
; Algorithm:
;   1. Convert lowercase letters to uppercase.
;   2. Select the matching temporary glyph.
;   3. Copy 8 glyph bytes, one per bitmap row.
;------------------------------------------------------------------------------
DrawGlyphAtCell:
        ; The glyph table stores uppercase shapes only. Lowercase ASCII is
        ; converted by subtracting 32 before the lookup chain.
        cmpa    #'a'
        blo     DrawGlyphFind
        cmpa    #'z'
        bhi     DrawGlyphFind
        suba    #32

DrawGlyphFind:
        ldu     #GlyphSpace

        cmpa    #' '
        lbeq    DrawGlyphCopy
        cmpa    #'!'
        lbeq    DrawGlyphUseBang
        cmpa    #$22
        lbeq    DrawGlyphUseQuote
        cmpa    #'#'
        lbeq    DrawGlyphUseHash
        cmpa    #','
        lbeq    DrawGlyphUseComma
        cmpa    #'-'
        lbeq    DrawGlyphUseDash
        cmpa    #':'
        lbeq    DrawGlyphUseColon
        cmpa    #'0'
        lbeq    DrawGlyphUse0
        cmpa    #'1'
        lbeq    DrawGlyphUse1
        cmpa    #'2'
        lbeq    DrawGlyphUse2
        cmpa    #'3'
        lbeq    DrawGlyphUse3
        cmpa    #'4'
        lbeq    DrawGlyphUse4
        cmpa    #'5'
        lbeq    DrawGlyphUse5
        cmpa    #'6'
        lbeq    DrawGlyphUse6
        cmpa    #'7'
        lbeq    DrawGlyphUse7
        cmpa    #'8'
        lbeq    DrawGlyphUse8
        cmpa    #'9'
        lbeq    DrawGlyphUse9
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
        cmpa    #'F'
        lbeq    DrawGlyphUseF
        cmpa    #'G'
        lbeq    DrawGlyphUseG
        cmpa    #'H'
        lbeq    DrawGlyphUseH
        cmpa    #'I'
        lbeq    DrawGlyphUseI
        cmpa    #'J'
        lbeq    DrawGlyphUseJ
        cmpa    #'K'
        lbeq    DrawGlyphUseK
        cmpa    #'L'
        lbeq    DrawGlyphUseL
        cmpa    #'M'
        lbeq    DrawGlyphUseM
        cmpa    #'N'
        lbeq    DrawGlyphUseN
        cmpa    #'O'
        lbeq    DrawGlyphUseO
        cmpa    #'P'
        lbeq    DrawGlyphUseP
        cmpa    #'Q'
        lbeq    DrawGlyphUseQ
        cmpa    #'R'
        lbeq    DrawGlyphUseR
        cmpa    #'S'
        lbeq    DrawGlyphUseS
        cmpa    #'T'
        lbeq    DrawGlyphUseT
        cmpa    #'U'
        lbeq    DrawGlyphUseU
        cmpa    #'V'
        lbeq    DrawGlyphUseV
        cmpa    #'W'
        lbeq    DrawGlyphUseW
        cmpa    #'X'
        lbeq    DrawGlyphUseX
        cmpa    #'Y'
        lbeq    DrawGlyphUseY
        cmpa    #'Z'
        lbeq    DrawGlyphUseZ
        lbra    DrawGlyphCopy

DrawGlyphUseBang:
        ldu     #GlyphBang
        lbra    DrawGlyphCopy
DrawGlyphUseQuote:
        ldu     #GlyphQuote
        lbra    DrawGlyphCopy
DrawGlyphUseHash:
        ldu     #GlyphHash
        lbra    DrawGlyphCopy
DrawGlyphUseComma:
        ldu     #GlyphComma
        lbra    DrawGlyphCopy
DrawGlyphUseDash:
        ldu     #GlyphDash
        lbra    DrawGlyphCopy
DrawGlyphUseColon:
        ldu     #GlyphColon
        lbra    DrawGlyphCopy
DrawGlyphUse0:
        ldu     #Glyph0
        lbra    DrawGlyphCopy
DrawGlyphUse1:
        ldu     #Glyph1
        lbra    DrawGlyphCopy
DrawGlyphUse2:
        ldu     #Glyph2
        lbra    DrawGlyphCopy
DrawGlyphUse3:
        ldu     #Glyph3
        lbra    DrawGlyphCopy
DrawGlyphUse4:
        ldu     #Glyph4
        lbra    DrawGlyphCopy
DrawGlyphUse5:
        ldu     #Glyph5
        lbra    DrawGlyphCopy
DrawGlyphUse6:
        ldu     #Glyph6
        lbra    DrawGlyphCopy
DrawGlyphUse7:
        ldu     #Glyph7
        lbra    DrawGlyphCopy
DrawGlyphUse8:
        ldu     #Glyph8
        lbra    DrawGlyphCopy
DrawGlyphUse9:
        ldu     #Glyph9
        lbra    DrawGlyphCopy
DrawGlyphUseA:
        ldu     #GlyphA
        lbra    DrawGlyphCopy
DrawGlyphUseB:
        ldu     #GlyphB
        lbra    DrawGlyphCopy
DrawGlyphUseC:
        ldu     #GlyphC
        lbra    DrawGlyphCopy
DrawGlyphUseD:
        ldu     #GlyphD
        lbra    DrawGlyphCopy
DrawGlyphUseE:
        ldu     #GlyphE
        lbra    DrawGlyphCopy
DrawGlyphUseF:
        ldu     #GlyphF
        lbra    DrawGlyphCopy
DrawGlyphUseG:
        ldu     #GlyphG
        lbra    DrawGlyphCopy
DrawGlyphUseH:
        ldu     #GlyphH
        lbra    DrawGlyphCopy
DrawGlyphUseI:
        ldu     #GlyphI
        lbra    DrawGlyphCopy
DrawGlyphUseJ:
        ldu     #GlyphJ
        lbra    DrawGlyphCopy
DrawGlyphUseK:
        ldu     #GlyphK
        lbra    DrawGlyphCopy
DrawGlyphUseL:
        ldu     #GlyphL
        lbra    DrawGlyphCopy
DrawGlyphUseM:
        ldu     #GlyphM
        lbra    DrawGlyphCopy
DrawGlyphUseN:
        ldu     #GlyphN
        lbra    DrawGlyphCopy
DrawGlyphUseO:
        ldu     #GlyphO
        lbra    DrawGlyphCopy
DrawGlyphUseP:
        ldu     #GlyphP
        lbra    DrawGlyphCopy
DrawGlyphUseQ:
        ldu     #GlyphQ
        lbra    DrawGlyphCopy
DrawGlyphUseR:
        ldu     #GlyphR
        lbra    DrawGlyphCopy
DrawGlyphUseS:
        ldu     #GlyphS
        lbra    DrawGlyphCopy
DrawGlyphUseT:
        ldu     #GlyphT
        lbra    DrawGlyphCopy
DrawGlyphUseU:
        ldu     #GlyphU
        lbra    DrawGlyphCopy
DrawGlyphUseV:
        ldu     #GlyphV
        lbra    DrawGlyphCopy
DrawGlyphUseW:
        ldu     #GlyphW
        lbra    DrawGlyphCopy
DrawGlyphUseX:
        ldu     #GlyphX
        lbra    DrawGlyphCopy
DrawGlyphUseY:
        ldu     #GlyphY
        lbra    DrawGlyphCopy
DrawGlyphUseZ:
        ldu     #GlyphZ

DrawGlyphCopy:
        lda     GlyphShiftMode
        bne     DrawGlyphCopyShiftRight4
        ldb     #TEXT_CELL_HEIGHT

DrawGlyphRow:
        lda     ,u+
        sta     ,x
        leax    VIDEO_BYTES_PER_ROW,x
        decb
        bne     DrawGlyphRow

        rts

DrawGlyphAtCellShiftRight4:
        pshs    a
        lda     #1
        sta     GlyphShiftMode
        puls    a
        jsr     DrawGlyphAtCell
        clr     GlyphShiftMode
        rts

DrawGlyphCopyShiftRight4:
        ldb     #TEXT_CELL_HEIGHT

DrawGlyphShiftRight4Row:
        lda     ,u+
        pshs    a
        ; Shifted text splits one 8-pixel glyph row across two neighboring video
        ; bytes: upper nibble into the current byte, lower nibble into the next.
        lsra
        lsra
        lsra
        lsra
        ora     ,x
        sta     ,x
        puls    a
        asla
        asla
        asla
        asla
        ora     1,x
        sta     1,x
        leax    VIDEO_BYTES_PER_ROW,x
        decb
        bne     DrawGlyphShiftRight4Row

        rts

; Temporary 8x8 glyph set.
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

GlyphBang:
        fcb     %00011000
        fcb     %00011000
        fcb     %00011000
        fcb     %00011000
        fcb     %00011000
        fcb     %00000000
        fcb     %00011000
        fcb     %00000000

GlyphQuote:
        fcb     %01100110
        fcb     %01100110
        fcb     %00100100
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000

GlyphHash:
        fcb     %00100100
        fcb     %00100100
        fcb     %01111110
        fcb     %00100100
        fcb     %01111110
        fcb     %00100100
        fcb     %00100100
        fcb     %00000000

GlyphComma:
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00011000
        fcb     %00011000
        fcb     %00110000

GlyphDash:
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %01111110
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000

GlyphColon:
        fcb     %00000000
        fcb     %00011000
        fcb     %00011000
        fcb     %00000000
        fcb     %00000000
        fcb     %00011000
        fcb     %00011000
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

Glyph2:
        fcb     %00111100
        fcb     %01100110
        fcb     %00000110
        fcb     %00001100
        fcb     %00110000
        fcb     %01100000
        fcb     %01111110
        fcb     %00000000

Glyph3:
        fcb     %00111100
        fcb     %01100110
        fcb     %00000110
        fcb     %00011100
        fcb     %00000110
        fcb     %01100110
        fcb     %00111100
        fcb     %00000000

Glyph4:
        fcb     %00001100
        fcb     %00011100
        fcb     %00111100
        fcb     %01101100
        fcb     %01111110
        fcb     %00001100
        fcb     %00001100
        fcb     %00000000

Glyph5:
        fcb     %01111110
        fcb     %01100000
        fcb     %01111100
        fcb     %00000110
        fcb     %00000110
        fcb     %01100110
        fcb     %00111100
        fcb     %00000000

Glyph6:
        fcb     %00111100
        fcb     %01100110
        fcb     %01100000
        fcb     %01111100
        fcb     %01100110
        fcb     %01100110
        fcb     %00111100
        fcb     %00000000

Glyph7:
        fcb     %01111110
        fcb     %00000110
        fcb     %00001100
        fcb     %00011000
        fcb     %00110000
        fcb     %00110000
        fcb     %00110000
        fcb     %00000000

Glyph8:
        fcb     %00111100
        fcb     %01100110
        fcb     %01100110
        fcb     %00111100
        fcb     %01100110
        fcb     %01100110
        fcb     %00111100
        fcb     %00000000

Glyph9:
        fcb     %00111100
        fcb     %01100110
        fcb     %01100110
        fcb     %00111110
        fcb     %00000110
        fcb     %01100110
        fcb     %00111100
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

GlyphF:
        fcb     %01111110
        fcb     %01100000
        fcb     %01100000
        fcb     %01111100
        fcb     %01100000
        fcb     %01100000
        fcb     %01100000
        fcb     %00000000

GlyphG:
        fcb     %00111100
        fcb     %01100110
        fcb     %01100000
        fcb     %01101110
        fcb     %01100110
        fcb     %01100110
        fcb     %00111100
        fcb     %00000000

GlyphH:
        fcb     %01100110
        fcb     %01100110
        fcb     %01100110
        fcb     %01111110
        fcb     %01100110
        fcb     %01100110
        fcb     %01100110
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

GlyphK:
        fcb     %01100110
        fcb     %01101100
        fcb     %01111000
        fcb     %01110000
        fcb     %01111000
        fcb     %01101100
        fcb     %01100110
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

GlyphN:
        fcb     %01100110
        fcb     %01110110
        fcb     %01111110
        fcb     %01111110
        fcb     %01101110
        fcb     %01100110
        fcb     %01100110
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

GlyphP:
        fcb     %01111100
        fcb     %01100110
        fcb     %01100110
        fcb     %01111100
        fcb     %01100000
        fcb     %01100000
        fcb     %01100000
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

GlyphR:
        fcb     %01111100
        fcb     %01100110
        fcb     %01100110
        fcb     %01111100
        fcb     %01111000
        fcb     %01101100
        fcb     %01100110
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

GlyphT:
        fcb     %01111110
        fcb     %00011000
        fcb     %00011000
        fcb     %00011000
        fcb     %00011000
        fcb     %00011000
        fcb     %00011000
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

GlyphV:
        fcb     %01100110
        fcb     %01100110
        fcb     %01100110
        fcb     %01100110
        fcb     %01100110
        fcb     %00111100
        fcb     %00011000
        fcb     %00000000

GlyphW:
        fcb     %01100011
        fcb     %01100011
        fcb     %01100011
        fcb     %01101011
        fcb     %01111111
        fcb     %01110111
        fcb     %01100011
        fcb     %00000000

GlyphX:
        fcb     %01100110
        fcb     %01100110
        fcb     %00111100
        fcb     %00011000
        fcb     %00111100
        fcb     %01100110
        fcb     %01100110
        fcb     %00000000

GlyphY:
        fcb     %01100110
        fcb     %01100110
        fcb     %00111100
        fcb     %00011000
        fcb     %00011000
        fcb     %00011000
        fcb     %00011000
        fcb     %00000000

GlyphZ:
        fcb     %01111110
        fcb     %00000110
        fcb     %00001100
        fcb     %00011000
        fcb     %00110000
        fcb     %01100000
        fcb     %01111110
        fcb     %00000000

DrawCellColor:
        fcb     COLOR_TEXT
GlyphShiftMode:
        fcb     0
