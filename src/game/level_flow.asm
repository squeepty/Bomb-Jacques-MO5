;==============================================================================
; game/level_flow.asm
;
; Lit-bomb selection, bomb score popups, and level transition states.
;
; This file sits between gameplay rules and rendering. It does not draw the
; entire arena itself, but it starts/clears popup timers and changes GameState
; when the player finishes a level or waits for the next one.
;==============================================================================

;------------------------------------------------------------------------------
; SelectNextLitBomb
;
; Purpose:
;   Points the bonus highlight at the first remaining active bomb.
;
; Modified:
;   A, B, X, Y, U
;------------------------------------------------------------------------------
SelectNextLitBomb:
        ; BombLitIndex is 1-based so it can be compared directly with the
        ; player-facing bomb number passed to AwardBombScore.
        lda     #1
        sta     BombScanIndex
        ldb     #BOMB_COUNT
        ldx     #BombActiveFlags

SelectNextLitBombLoop:
        ; Find the first active bomb. If none remain, clear BombLitIndex.
        lda     ,x+
        bne     SelectNextLitBombFound
        inc     BombScanIndex
        decb
        bne     SelectNextLitBombLoop
        clr     BombLitIndex
        rts

SelectNextLitBombFound:
        lda     BombScanIndex
        sta     BombLitIndex
        jmp     DrawCurrentLitBomb

;------------------------------------------------------------------------------
; UpdateBombScorePopup
;
; Purpose:
;   Keeps the 200 score sprite visible briefly after collecting the lit bomb.
;
; Modified:
;   A, B, X, Y, U
;------------------------------------------------------------------------------
UpdateBombScorePopup:
        ; Popup timers are parallel to bomb coordinates. When a timer reaches
        ; zero, erase the popup cells and mark the arena for static redraw.
        lda     #BOMB_COUNT
        sta     BombScanRemaining
        ldx     #BombScorePopupTimers
        ldu     CurrentBombPositions

UpdateBombScorePopupLoop:
        lda     ,x
        beq     UpdateBombScorePopupNext

        deca
        sta     ,x
        bne     UpdateBombScorePopupNext

        lda     ,u
        ldb     1,u
        pshs    x,u
        jsr     EraseBombAtAB
        jsr     MarkStaticRedraw
        puls    x,u

UpdateBombScorePopupNext:
        leax    1,x
        leau    2,u
        dec     BombScanRemaining
        bne     UpdateBombScorePopupLoop

UpdateBombScorePopupDone:
        rts

StartBombScorePopup:
        ; Convert 1-based BombScanIndex to a zero-based timer offset by
        ; decrementing B before ABX.
        pshs    a,b
        ldb     BombScanIndex
        decb
        ldx     #BombScorePopupTimers
        abx
        lda     #BOMB_SCORE_POPUP_FRAMES
        sta     ,x
        puls    a,b
        jmp     DrawBombScorePopupAtAB

ClearBombScorePopup:
        ; Death clears all active popups so respawn/game-over rendering does not
        ; leave floating score cells behind.
        lda     #BOMB_COUNT
        sta     BombScanRemaining
        ldx     #BombScorePopupTimers
        ldu     CurrentBombPositions

ClearBombScorePopupLoop:
        lda     ,x
        beq     ClearBombScorePopupNext

        clr     ,x
        lda     ,u
        ldb     1,u
        pshs    x,u
        jsr     EraseBombAtAB
        jsr     MarkStaticRedraw
        puls    x,u

ClearBombScorePopupNext:
        leax    1,x
        leau    2,u
        dec     BombScanRemaining
        bne     ClearBombScorePopupLoop

ClearBombScorePopupDone:
        rts

;------------------------------------------------------------------------------
; Level transition state
;------------------------------------------------------------------------------
EnterLevelClear:
        ; Entering level-clear is idempotent: only the PLAYING state can start
        ; it, so duplicate calls after all bombs are gone do nothing.
        lda     GameState
        cmpa    #GAME_STATE_PLAYING
        bne     EnterLevelClearDone

        lda     #GAME_STATE_LEVEL_CLEAR
        sta     GameState
        lda     #LEVEL_CLEAR_FRAMES
        sta     LevelTransitionTimer
        clr     LevelMessageColorIndex
        lda     #LEVEL_MESSAGE_COLOR_FRAMES
        sta     LevelMessageColorCounter
        jsr     DrawWellDoneText

EnterLevelClearDone:
        rts

UpdateLevelClearState:
        ; The timer counts down while WELL DONE is color-cycled. On expiry the
        ; next level is reset and the GET READY state begins.
        lda     LevelTransitionTimer
        beq     StartNextLevelGetReady
        dec     LevelTransitionTimer
        beq     StartNextLevelGetReady
        jmp     UpdateWellDoneColor

UpdateWellDoneColor:
        ; LevelMessageColorCounter divides the frame loop so the text color
        ; changes slower than every frame.
        dec     LevelMessageColorCounter
        bne     UpdateWellDoneColorDone

        lda     #LEVEL_MESSAGE_COLOR_FRAMES
        sta     LevelMessageColorCounter
        lda     LevelMessageColorIndex
        inca
        cmpa    #LEVEL_MESSAGE_COLOR_COUNT
        blo     UpdateWellDoneColorStore
        clra

UpdateWellDoneColorStore:
        sta     LevelMessageColorIndex
        jsr     DrawWellDoneText

UpdateWellDoneColorDone:
        rts

StartNextLevelGetReady:
        ; Rebuild only the active game area for the new level. Chrome/sidebar
        ; remain in place, reducing flicker during level changes.
        jsr     AdvanceCurrentLevel
        jsr     StartCurrentLevel
        jsr     ClearGameArea
        jsr     DrawLevelLabel
        jsr     DrawStaticArena
        jsr     DrawPlayer
        jmp     EnterGetReadyState

EnterGetReadyState:
        ; GET READY uses the same transition timer/color cycling machinery as
        ; WELL DONE, but ends by entering active play.
        lda     #GAME_STATE_GET_READY
        sta     GameState
        lda     #GET_READY_FRAMES
        sta     LevelTransitionTimer
        clr     LevelMessageColorIndex
        lda     #LEVEL_MESSAGE_COLOR_FRAMES
        sta     LevelMessageColorCounter
        jmp     DrawGetReadyText

AdvanceCurrentLevel:
        ; Levels wrap after LEVEL_COUNT, keeping the game running indefinitely.
        lda     CurrentLevel
        inca
        cmpa    #LEVEL_COUNT
        blo     AdvanceCurrentLevelStore
        clra

AdvanceCurrentLevelStore:
        sta     CurrentLevel
        rts

UpdateGetReadyState:
        lda     LevelTransitionTimer
        beq     BeginLevelPlay
        dec     LevelTransitionTimer
        beq     BeginLevelPlay
        jmp     UpdateGetReadyColor

UpdateGetReadyColor:
        dec     LevelMessageColorCounter
        bne     UpdateGetReadyColorDone

        lda     #LEVEL_MESSAGE_COLOR_FRAMES
        sta     LevelMessageColorCounter
        lda     LevelMessageColorIndex
        inca
        cmpa    #LEVEL_MESSAGE_COLOR_COUNT
        blo     UpdateGetReadyColorStore
        clra

UpdateGetReadyColorStore:
        sta     LevelMessageColorIndex
        jsr     DrawGetReadyText

UpdateGetReadyColorDone:
        rts

BeginLevelPlay:
        ; Once the message is erased, draw all static/dynamic actors in their
        ; initial positions and return GameState to PLAYING (0).
        jsr     EraseLevelMessage
        jsr     DrawStaticArena
        jsr     DrawEnemy1All
        jsr     DrawEnemy2
        jsr     DrawPlayer
        clr     GameState
        rts

;------------------------------------------------------------------------------
