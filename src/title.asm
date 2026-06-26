;==============================================================================
; title.asm
;
; BUILD 001 title-screen code and text.
;==============================================================================

;------------------------------------------------------------------------------
; DrawTitleScreen
;
; Purpose:
;   Draws the BUILD 001 title text.
;
; Input:
;   None.
;
; Output:
;   "Bomb Jacques" and "BUILD 001" are visible on the screen.
;
; Modified:
;   A, B, X, Y, U
;
; Algorithm:
;   Each line is passed to DrawString with a fixed text-cell coordinate.
;------------------------------------------------------------------------------
DrawTitleScreen:
        ldu     #TitleText
        lda     #TITLE_TEXT_COL
        ldb     #TITLE_TEXT_ROW
        jsr     DrawString

        ldu     #BuildText
        lda     #BUILD_TEXT_COL
        ldb     #BUILD_TEXT_ROW
        jsr     DrawString

        rts

TitleText:
        fcc     "Bomb Jacques"
        fcb     0

BuildText:
        fcc     "BUILD 001"
        fcb     0
