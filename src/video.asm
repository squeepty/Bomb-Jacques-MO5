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
        jsr     CellAddress
        bsr     SelectBitmapPlane

        ; Move the destination to row 3 so seven of the eight row offsets fit in
        ; the 6809's fast 8-bit indexed form.
        leax    120,x
        pulu    d
        sta     -120,x
        stb     -80,x
        pulu    d
        sta     -40,x
        stb     ,x
        pulu    d
        sta     40,x
        stb     80,x
        pulu    d
        sta     120,x
        stb     160,x

        ; SelectColorPlane would preserve unrelated $A7C0 bits too, but we have
        ; just forced bitmap mode, so bit 0 can be toggled directly here.
        dec     VIDEO_BANK_SELECT
        lda     DrawCellColor
        sta     -120,x
        sta     -80,x
        sta     -40,x
        sta     ,x
        sta     40,x
        sta     80,x
        sta     120,x
        sta     160,x

        inc     VIDEO_BANK_SELECT
        rts

DrawOpaqueCellBitmapAtX:
        pshs    x
        leax    120,x
        pulu    d
        sta     -120,x
        stb     -80,x
        pulu    d
        sta     -40,x
        stb     ,x
        pulu    d
        sta     40,x
        stb     80,x
        pulu    d
        sta     120,x
        stb     160,x
        puls    x
        rts

DrawOpaqueCellColorAtX:
        pshs    x
        leax    120,x
        sta     -120,x
        sta     -80,x
        sta     -40,x
        sta     ,x
        sta     40,x
        sta     80,x
        sta     120,x
        sta     160,x
        puls    x
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
        jsr     CellAddress
        jsr     SelectBitmapPlane

        pshs    x,u
        jsr     DrawMaskedCellBitmapAtX
        puls    x,u
        dec     VIDEO_BANK_SELECT
        ldb     DrawCellColor
        jsr     DrawMaskedCellColorAtX
        inc     VIDEO_BANK_SELECT
        rts

DrawSprite2x2Masked:
        jsr     CellAddress
        jsr     SelectBitmapPlane

        pshs    x,u
        jsr     DrawMaskedCellBitmapAtX
        leax    1,x
        jsr     DrawMaskedCellBitmapAtX
        leax    319,x
        jsr     DrawMaskedCellBitmapAtX
        leax    1,x
        jsr     DrawMaskedCellBitmapAtX
        puls    x,u

        dec     VIDEO_BANK_SELECT
        ldb     DrawCellColor
        jsr     DrawMaskedCellColorAtX
        leax    1,x
        jsr     DrawMaskedCellColorAtX
        leax    319,x
        jsr     DrawMaskedCellColorAtX
        leax    1,x
        jsr     DrawMaskedCellColorAtX
        inc     VIDEO_BANK_SELECT
        rts

DrawSprite2x2Opaque:
        jsr     CellAddress
        jsr     SelectBitmapPlane

        pshs    x,u
        jsr     DrawOpaqueCellBitmapAtX
        leax    1,x
        jsr     DrawOpaqueCellBitmapAtX
        leax    319,x
        jsr     DrawOpaqueCellBitmapAtX
        leax    1,x
        jsr     DrawOpaqueCellBitmapAtX
        puls    x,u

        dec     VIDEO_BANK_SELECT
        lda     DrawCellColor
        jsr     DrawOpaqueCellColorAtX
        leax    1,x
        jsr     DrawOpaqueCellColorAtX
        leax    319,x
        jsr     DrawOpaqueCellColorAtX
        leax    1,x
        jsr     DrawOpaqueCellColorAtX
        inc     VIDEO_BANK_SELECT
        rts

DrawMaskedCellBitmapAtX:
        pshs    x
        leax    120,x
        lda     ,u+
        beq     DrawMaskedCellBitmapRow1
        ora     -120,x
        sta     -120,x
DrawMaskedCellBitmapRow1:
        lda     ,u+
        beq     DrawMaskedCellBitmapRow2
        ora     -80,x
        sta     -80,x
DrawMaskedCellBitmapRow2:
        lda     ,u+
        beq     DrawMaskedCellBitmapRow3
        ora     -40,x
        sta     -40,x
DrawMaskedCellBitmapRow3:
        lda     ,u+
        beq     DrawMaskedCellBitmapRow4
        ora     ,x
        sta     ,x
DrawMaskedCellBitmapRow4:
        lda     ,u+
        beq     DrawMaskedCellBitmapRow5
        ora     40,x
        sta     40,x
DrawMaskedCellBitmapRow5:
        lda     ,u+
        beq     DrawMaskedCellBitmapRow6
        ora     80,x
        sta     80,x
DrawMaskedCellBitmapRow6:
        lda     ,u+
        beq     DrawMaskedCellBitmapRow7
        ora     120,x
        sta     120,x
DrawMaskedCellBitmapRow7:
        lda     ,u+
        beq     DrawMaskedCellBitmapDone
        ora     160,x
        sta     160,x
DrawMaskedCellBitmapDone:
        puls    x
        rts

DrawMaskedCellColorAtX:
        pshs    x
        leax    120,x
        lda     ,u+
        beq     DrawMaskedCellColorRow1
        stb     -120,x
DrawMaskedCellColorRow1:
        lda     ,u+
        beq     DrawMaskedCellColorRow2
        stb     -80,x
DrawMaskedCellColorRow2:
        lda     ,u+
        beq     DrawMaskedCellColorRow3
        stb     -40,x
DrawMaskedCellColorRow3:
        lda     ,u+
        beq     DrawMaskedCellColorRow4
        stb     ,x
DrawMaskedCellColorRow4:
        lda     ,u+
        beq     DrawMaskedCellColorRow5
        stb     40,x
DrawMaskedCellColorRow5:
        lda     ,u+
        beq     DrawMaskedCellColorRow6
        stb     80,x
DrawMaskedCellColorRow6:
        lda     ,u+
        beq     DrawMaskedCellColorRow7
        stb     120,x
DrawMaskedCellColorRow7:
        lda     ,u+
        beq     DrawMaskedCellColorDone
        stb     160,x
DrawMaskedCellColorDone:
        puls    x
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
        ; The program runs from RAM, so the column byte is patched directly into
        ; the ADDD immediate operand. This avoids a row-offset table lookup.
        sta     CellAddressColumn
        lda     #4*VIDEO_BYTES_PER_ROW
        mul
        lslb
        rola
CellAddressAddColumn:
        addd    #VIDEO_BITMAP_BASE
CellAddressColumn equ *-1
        tfr     d,x
        leay    ,x
        rts

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
;   1. Convert most lowercase letters to uppercase.
;   2. Select the matching temporary glyph.
;   3. Copy 8 glyph bytes, one per bitmap row.
;------------------------------------------------------------------------------
DrawGlyphAtCell:
        ; The main glyph table stores uppercase shapes. The version stamp uses a
        ; few lowercase forms; other lowercase ASCII falls back to uppercase.
        cmpa    #'a'
        lbeq    DrawGlyphUseLowerA
        cmpa    #'m'
        lbeq    DrawGlyphUseLowerM
        cmpa    #'s'
        lbeq    DrawGlyphUseLowerS
        cmpa    #'v'
        lbeq    DrawGlyphUseLowerV
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
        cmpa    #'('
        lbeq    DrawGlyphUseParenLeft
        cmpa    #')'
        lbeq    DrawGlyphUseParenRight
        cmpa    #','
        lbeq    DrawGlyphUseComma
        cmpa    #'.'
        lbeq    DrawGlyphUseDot
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
DrawGlyphUseParenLeft:
        ldu     #GlyphParenLeft
        lbra    DrawGlyphCopy
DrawGlyphUseParenRight:
        ldu     #GlyphParenRight
        lbra    DrawGlyphCopy
DrawGlyphUseComma:
        ldu     #GlyphComma
        lbra    DrawGlyphCopy
DrawGlyphUseDot:
        ldu     #GlyphDot
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
        lbra    DrawGlyphCopy
DrawGlyphUseLowerA:
        ldu     #GlyphLowerA
        lbra    DrawGlyphCopy
DrawGlyphUseLowerM:
        ldu     #GlyphLowerM
        lbra    DrawGlyphCopy
DrawGlyphUseLowerS:
        ldu     #GlyphLowerS
        lbra    DrawGlyphCopy
DrawGlyphUseLowerV:
        ldu     #GlyphLowerV

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

GlyphParenLeft:
        fcb     %00001100
        fcb     %00011000
        fcb     %00110000
        fcb     %00110000
        fcb     %00110000
        fcb     %00011000
        fcb     %00001100
        fcb     %00000000

GlyphParenRight:
        fcb     %00110000
        fcb     %00011000
        fcb     %00001100
        fcb     %00001100
        fcb     %00001100
        fcb     %00011000
        fcb     %00110000
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

GlyphDot:
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00011000
        fcb     %00000000

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

GlyphLowerA:
        fcb     %00000000
        fcb     %00000000
        fcb     %00111100
        fcb     %00000110
        fcb     %00111110
        fcb     %01100110
        fcb     %00111110
        fcb     %00000000

GlyphLowerM:
        fcb     %00000000
        fcb     %00000000
        fcb     %01101100
        fcb     %01111110
        fcb     %01111110
        fcb     %01101010
        fcb     %01100010
        fcb     %00000000

GlyphLowerS:
        fcb     %00000000
        fcb     %00000000
        fcb     %00111110
        fcb     %01100000
        fcb     %00111100
        fcb     %00000110
        fcb     %01111100
        fcb     %00000000

GlyphLowerV:
        fcb     %00000000
        fcb     %00000000
        fcb     %01100110
        fcb     %01100110
        fcb     %01100110
        fcb     %00111100
        fcb     %00011000
        fcb     %00000000

DrawCellColor:
        fcb     COLOR_TEXT
GlyphShiftMode:
        fcb     0
