;==============================================================================
; game/scoring_hall.asm
;
; Score arithmetic, hall-of-fame comparison/insertion, and name entry.
;
; The score is stored as four ASCII digit bytes because the game draws it often
; and only adds fixed values. That avoids binary-to-decimal conversion during
; rendering. Hall entries are fixed-size zero-terminated strings, which makes
; shifting and copying rows simple byte loops.
;==============================================================================

; AwardBombScore
;
; Purpose:
;   Awards normal or bonus points for a collected bomb.
;
; Input:
;   A = number of the bomb just collected, 1-BOMB_COUNT.
;
; Modified:
;   A, B, X, Y, U
;------------------------------------------------------------------------------
AwardBombScore:
        ; BombScanIndex is 1-based, matching BombLitIndex. The lit bomb awards
        ; bonus points and then moves the highlight to the next active bomb.
        cmpa    BombLitIndex
        beq     AwardBombScoreBonus

        jmp     AddScore50

AwardBombScoreBonus:
        jsr     AddScore200
        jsr     SelectNextLitBomb
        rts

;------------------------------------------------------------------------------
; Score add helpers
;
; Purpose:
;   Adds the fixed game scoring values to the four-digit ASCII score. The score
;   caps at 9999.
;
; Modified:
;   A, X, Y, U
;------------------------------------------------------------------------------
AddScore50:
        ; Adding 50 only touches the tens digit, with carry into the hundreds.
        lda     ScoreTensText
        adda    #5
        cmpa    #'9'
        bls     AddScore50Store
        suba    #10
        sta     ScoreTensText
        jsr     AddScore100Raw
        jmp     DrawScore

AddScore50Store:
        sta     ScoreTensText
        jmp     DrawScore

AddScore100:
        jsr     AddScore100Raw
        jmp     DrawScore

AddScore200:
        jsr     AddScore100Raw
        jsr     AddScore100Raw
        jmp     DrawScore

AddScore500:
        jsr     AddScore100Raw
        jsr     AddScore100Raw
        jsr     AddScore100Raw
        jsr     AddScore100Raw
        jsr     AddScore100Raw
        jmp     DrawScore

AddScore100Raw:
        ; Raw helpers update the ASCII digits but do not redraw. This lets
        ; AddScore200/AddScore500 batch repeated +100 operations before DrawScore.
        lda     ScoreHundredsText
        cmpa    #'9'
        bhs     AddScore100CarryThousands
        inca
        sta     ScoreHundredsText
        rts

AddScore100CarryThousands:
        lda     #'0'
        sta     ScoreHundredsText
        lda     ScoreThousandsText
        cmpa    #'9'
        bhs     SetScoreMaxed
        inca
        sta     ScoreThousandsText
        rts

SetScoreMaxed:
        ; The display is four digits, so saturation is simpler and clearer than
        ; wrapping past 9999.
        lda     #'9'
        sta     ScoreThousandsText
        sta     ScoreHundredsText
        sta     ScoreTensText
        sta     ScoreOnesText
        rts

;------------------------------------------------------------------------------
; Hall of Fame
;------------------------------------------------------------------------------
InitHallOfFameDefaults:
        ; Runtime hall entries live in writable memory. Copy defaults into that
        ; memory at startup so insertion can mutate the live table.
        ldd     #HallDefaultEntry1
        std     HallCopySrc
        ldd     #HallEntry1
        std     HallCopyDest
        lda     #HALL_ENTRY_COUNT
        sta     HallShiftIndex

InitHallOfFameDefaultsLoop:
        ; Source and destination both advance by one fixed-size entry.
        jsr     CopyHallEntry
        ldd     HallCopySrc
        addd    #HALL_ENTRY_SIZE
        std     HallCopySrc
        ldd     HallCopyDest
        addd    #HALL_ENTRY_SIZE
        std     HallCopyDest
        dec     HallShiftIndex
        bne     InitHallOfFameDefaultsLoop
        rts

BuildPlayerHallEntryFields:
        ; Snapshot score and level into the temporary player-entry fields before
        ; comparing or inserting into the hall table.
        lda     ScoreThousandsText
        sta     PlayerScoreText
        lda     ScoreHundredsText
        sta     PlayerScoreText+1
        lda     ScoreTensText
        sta     PlayerScoreText+2
        lda     ScoreOnesText
        sta     PlayerScoreText+3

        lda     CurrentLevel
        inca
        cmpa    #10
        blo     BuildPlayerLevelOneDigit
        lda     #'1'
        sta     PlayerLevelText
        lda     #'0'
        sta     PlayerLevelText+1
        rts

BuildPlayerLevelOneDigit:
        adda    #'0'
        sta     PlayerLevelText+1
        lda     #'0'
        sta     PlayerLevelText
        rts

IsHallOfFameScore:
        ldx     #HallEntry5
        jmp     ComparePlayerScoreToEntryAtX

ComparePlayerScoreToEntryAtX:
        ; Lexicographic comparison works because both scores are four ASCII
        ; digits with leading zeroes.
        lda     PlayerScoreText
        cmpa    HALL_SCORE_OFFSET,x
        bhi     ComparePlayerScoreGreater
        blo     ComparePlayerScoreNotGreater
        lda     PlayerScoreText+1
        cmpa    HALL_SCORE_OFFSET+1,x
        bhi     ComparePlayerScoreGreater
        blo     ComparePlayerScoreNotGreater
        lda     PlayerScoreText+2
        cmpa    HALL_SCORE_OFFSET+2,x
        bhi     ComparePlayerScoreGreater
        blo     ComparePlayerScoreNotGreater
        lda     PlayerScoreText+3
        cmpa    HALL_SCORE_OFFSET+3,x
        bhi     ComparePlayerScoreGreater

ComparePlayerScoreNotGreater:
        clra
        rts

ComparePlayerScoreGreater:
        lda     #1
        rts

EnterNameEntry:
        ; Name entry is a separate state so the frame loop can read the full
        ; name keyboard table while redrawing only the text field.
        jsr     ClearPlayerName
        jsr     DrawNameEntryScreen
        lda     #GAME_STATE_NAME_ENTRY
        sta     GameState
        rts

ClearPlayerName:
        ; Fill the editable name with spaces, then seed the first character with
        ; A so joystick-only entry has a useful starting point.
        ldx     #PlayerNameText
        ldb     #HALL_NAME_LEN
        lda     #' '

ClearPlayerNameLoop:
        sta     ,x+
        decb
        bne     ClearPlayerNameLoop

        clr     ,x
        ldx     #PlayerNameText
        lda     #'A'
        sta     ,x
        clr     NameEntryIndex
        rts

UpdateNameEntryState:
        ; Physical keyboard input wins when a letter/control key was pressed.
        ; Otherwise dpad/fire can edit one character at a time.
        lda     NameKey_Press
        beq     UpdateNameEntryDpad
        cmpa    #NAME_KEY_ENTER
        lbeq    CommitNameEntry
        cmpa    #NAME_KEY_BACKSPACE
        beq     BackspaceNameEntryChar
        cmpa    #'A'
        blo     UpdateNameEntryDpad
        cmpa    #'Z'
        bhi     UpdateNameEntryDpad
        jsr     TypeNameEntryChar
        rts

UpdateNameEntryDpad:
        lda     Dpad_Press
        bita    #c1_button_left_mask
        beq     UpdateNameEntryRight
        jsr     DecrementNameEntryChar

UpdateNameEntryRight:
        lda     Dpad_Press
        bita    #c1_button_right_mask
        beq     UpdateNameEntryConfirm
        jsr     IncrementNameEntryChar

UpdateNameEntryConfirm:
        lda     Fire_Press
        bita    #c1_button_A_mask
        bne     ConfirmNameEntryChar
        lda     Dpad_Press
        bita    #c1_button_up_mask
        beq     UpdateNameEntryDone

ConfirmNameEntryChar:
        ; Confirming a blank cell stores A, matching the initial visual cursor.
        jsr     StoreDefaultNameEntryChar

AdvanceNameEntryIndex:
        inc     NameEntryIndex
        lda     NameEntryIndex
        cmpa    #HALL_NAME_LEN
        bhs     CommitNameEntry
        jsr     DrawPlayerNameEntry
        rts

CommitNameEntry:
        jsr     InsertHallOfFameEntry
        jmp     EnterHallOfFameScreenNoChrome

UpdateNameEntryDone:
        rts

StoreDefaultNameEntryChar:
        ; Calculate PlayerNameText + NameEntryIndex using D as the 16-bit offset.
        clra
        ldb     NameEntryIndex
        ldx     #PlayerNameText
        leax    d,x
        lda     ,x
        cmpa    #' '
        bne     StoreDefaultNameEntryCharDone
        lda     #'A'
        sta     ,x

StoreDefaultNameEntryCharDone:
        rts

TypeNameEntryChar:
        ; Preserve the typed ASCII value across the helper call, which returns
        ; the destination pointer in X.
        pshs    a
        jsr     LoadCurrentNameEntryPointer
        puls    a
        sta     ,x
        jmp     AdvanceNameEntryIndex

BackspaceNameEntryChar:
        lda     NameEntryIndex
        beq     BackspaceNameEntryAtCurrent
        dec     NameEntryIndex

BackspaceNameEntryAtCurrent:
        jsr     LoadCurrentNameEntryPointer
        lda     #' '
        sta     ,x
        jmp     DrawPlayerNameEntry

DecrementNameEntryChar:
        ; Joystick editing wraps A backward to Z.
        jsr     StoreDefaultNameEntryChar
        jsr     LoadCurrentNameEntryPointer
        lda     ,x
        cmpa    #'A'
        bhi     DecrementNameEntryStore
        lda     #'Z'+1

DecrementNameEntryStore:
        deca
        sta     ,x
        jmp     DrawPlayerNameEntry

IncrementNameEntryChar:
        ; Joystick editing wraps Z forward to A.
        jsr     StoreDefaultNameEntryChar
        jsr     LoadCurrentNameEntryPointer
        lda     ,x
        cmpa    #'Z'
        blo     IncrementNameEntryStore
        lda     #'A'-1

IncrementNameEntryStore:
        inca
        sta     ,x
        jmp     DrawPlayerNameEntry

LoadCurrentNameEntryPointer:
        clra
        ldb     NameEntryIndex
        ldx     #PlayerNameText
        leax    d,x
        rts

InsertHallOfFameEntry:
        ; FindHallInsertIndex returns A=0 when the score does not enter the
        ; table. Otherwise HallInsertIndex marks the row to overwrite.
        jsr     FindHallInsertIndex
        beq     InsertHallOfFameDone

        lda     #HALL_ENTRY_COUNT-1
        sta     HallShiftIndex

InsertHallOfFameShiftLoop:
        ; Shift entries downward from the bottom so data is not overwritten
        ; before it has been copied.
        lda     HallShiftIndex
        cmpa    HallInsertIndex
        bls     InsertHallOfFameWrite
        ldb     HallShiftIndex
        jsr     LoadHallEntryPointer
        stx     HallCopyDest
        ldb     HallShiftIndex
        decb
        jsr     LoadHallEntryPointer
        stx     HallCopySrc
        jsr     CopyHallEntry
        dec     HallShiftIndex
        bra     InsertHallOfFameShiftLoop

InsertHallOfFameWrite:
        ldb     HallInsertIndex
        jsr     LoadHallEntryPointer
        stx     HallCopyDest
        jsr     WritePlayerHallEntry

InsertHallOfFameDone:
        rts

FindHallInsertIndex:
        clr     HallInsertIndex
        ldx     #HallEntry1

FindHallInsertIndexLoop:
        jsr     ComparePlayerScoreToEntryAtX
        bne     FindHallInsertIndexFound
        leax    HALL_ENTRY_SIZE,x
        inc     HallInsertIndex
        lda     HallInsertIndex
        cmpa    #HALL_ENTRY_COUNT
        blo     FindHallInsertIndexLoop
        clra
        rts

FindHallInsertIndexFound:
        lda     #1
        rts

LoadHallEntryPointer:
        ; HallEntryPointers is a table of 16-bit addresses, so B is doubled
        ; before loading the pointer into X.
        clra
        lslb
        ldx     #HallEntryPointers
        ldx     d,x
        rts

CopyHallEntry:
        ; Generic fixed-size byte copy used for both startup defaults and
        ; insertion shifting.
        ldx     HallCopySrc
        ldu     HallCopyDest
        ldb     #HALL_ENTRY_SIZE

CopyHallEntryLoop:
        lda     ,x+
        sta     ,u+
        decb
        bne     CopyHallEntryLoop
        rts

WritePlayerHallEntry:
        ; The entry layout is:
        ;   two level digits, space, ten name chars, space, four score digits, 0.
        ldx     HallCopyDest
        lda     PlayerLevelText
        sta     ,x
        lda     PlayerLevelText+1
        sta     1,x
        lda     #' '
        sta     2,x

        leax    HALL_NAME_OFFSET,x
        ldu     #PlayerNameText
        ldb     #HALL_NAME_LEN

WritePlayerHallNameLoop:
        lda     ,u+
        sta     ,x+
        decb
        bne     WritePlayerHallNameLoop

        ldx     HallCopyDest
        lda     #' '
        sta     13,x
        lda     PlayerScoreText
        sta     HALL_SCORE_OFFSET,x
        lda     PlayerScoreText+1
        sta     HALL_SCORE_OFFSET+1,x
        lda     PlayerScoreText+2
        sta     HALL_SCORE_OFFSET+2,x
        lda     PlayerScoreText+3
        sta     HALL_SCORE_OFFSET+3,x
        clr     HALL_ENTRY_SIZE-1,x
        rts
