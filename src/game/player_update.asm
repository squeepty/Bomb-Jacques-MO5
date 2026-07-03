;==============================================================================
; game/player_update.asm
;
; High-level Jacques update pipeline.
;
; This small module exists so the frame loop can say "update player" without
; knowing the details. The actual work is in player_movement.asm.
;==============================================================================

;------------------------------------------------------------------------------
; UpdatePlayer
;
; Purpose:
;   Applies left/right movement, jump, gravity, and landing.
;
; Modified:
;   A, B
;------------------------------------------------------------------------------
UpdatePlayer:
        ; Order matters:
        ;   horizontal movement affects collision footprint,
        ;   ground refresh decides whether jumping is legal,
        ;   vertical movement may land on a platform,
        ;   sprite selection reflects the final movement state.
        jsr     UpdateHorizontal
        jsr     RefreshGroundState
        jsr     TryJump
        jsr     ApplyVertical
        jsr     UpdatePlayerSprite
        rts

UpdatePlayerGraceTimer:
        ; Grace is a simple countdown used by collision and blink rendering.
        lda     PlayerGraceTimer
        beq     UpdatePlayerGraceTimerDone
        dec     PlayerGraceTimer

UpdatePlayerGraceTimerDone:
        rts
