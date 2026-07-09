;==============================================================================
; sound.asm
;
; Tiny 1-bit sound effects for the MO5 internal buzzer.
;
; The MO5 system PIA port B is already used for keyboard matrix selectors at
; $A7C1. Bit 0 of the same writes feeds the 1-bit DAC, so the effects below
; pulse only that bit and finish by writing zero. The next input scan writes its
; own selector byte again, so there is no persistent keyboard state to restore.
;==============================================================================

;------------------------------------------------------------------------------
; InitSound
;
; Purpose:
;   Leaves the internal buzzer in a silent state at startup.
;
; Modified:
;   None.
;------------------------------------------------------------------------------
InitSound:
        pshs    a
        clra
        sta     SOUND_BUZZER_PORT
        puls    a
        rts

;------------------------------------------------------------------------------
; Public sound effect entry points
;
; Notes:
;   These are short blocking phrases. They are intentionally compact because the
;   current game loop is busy-wait based rather than interrupt-driven.
;------------------------------------------------------------------------------
SoundBombPickup:
        pshs    a,b,x
        lda     #42
        ldb     #18
        jsr     SoundTone
        jsr     SoundOff
        puls    a,b,x
        rts

SoundLitBomb:
        pshs    a,b,x
        lda     #33
        ldb     #18
        jsr     SoundTone
        jsr     SoundOff
        puls    a,b,x
        rts

SoundJump:
        pshs    a,b,x
        lda     #16
        ldb     #64
        jsr     SoundTone
        jsr     SoundOff
        puls    a,b,x
        rts

SoundEnemyHit:
        pshs    a,b,x
        lda     #18
        ldb     #20
        jsr     SoundTone
        lda     #28
        ldb     #18
        jsr     SoundTone
        lda     #42
        ldb     #18
        jsr     SoundTone
        lda     #62
        ldb     #16
        jsr     SoundTone
        lda     #88
        ldb     #16
        jsr     SoundTone
        lda     #118
        ldb     #14
        jsr     SoundTone
        jsr     SoundOff
        puls    a,b,x
        rts

SoundLevelClear:
        jmp     SoundRewardChirp

SoundRewardChirp:
        pshs    a,b,x
        lda     #82
        ldb     #16
        jsr     SoundTone
        jsr     SoundShortPause
        lda     #66
        ldb     #16
        jsr     SoundTone
        jsr     SoundShortPause
        lda     #52
        ldb     #18
        jsr     SoundTone
        jsr     SoundShortPause
        lda     #40
        ldb     #18
        jsr     SoundTone
        jsr     SoundShortPause
        lda     #30
        ldb     #20
        jsr     SoundTone
        jsr     SoundShortPause
        lda     #22
        ldb     #42
        jsr     SoundTone
        jsr     SoundOff
        puls    a,b,x
        rts

SoundGameOver:
        pshs    a,b,x
        lda     #18
        ldb     #28
        jsr     SoundTone
        jsr     SoundShortPause
        lda     #26
        ldb     #26
        jsr     SoundTone
        jsr     SoundShortPause
        lda     #36
        ldb     #24
        jsr     SoundTone
        jsr     SoundShortPause
        lda     #50
        ldb     #22
        jsr     SoundTone
        jsr     SoundShortPause
        lda     #68
        ldb     #20
        jsr     SoundTone
        jsr     SoundShortPause
        lda     #90
        ldb     #18
        jsr     SoundTone
        jsr     SoundShortPause
        lda     #116
        ldb     #16
        jsr     SoundTone
        jsr     SoundShortPause
        lda     #148
        ldb     #28
        jsr     SoundTone
        jsr     SoundOff
        puls    a,b,x
        rts

;------------------------------------------------------------------------------
; SoundTone
;
; Purpose:
;   Plays one square-wave tone.
;
; Input:
;   A = half-period delay count. Higher values produce lower tones.
;   B = number of full high/low cycles to emit.
;
; Modified:
;   A, B.
;------------------------------------------------------------------------------
SoundTone:
        sta     SoundToneDelayCount
        stb     SoundToneCycleCount

SoundToneLoop:
        lda     #SOUND_BUZZER_BIT
        sta     SOUND_BUZZER_PORT
        ldb     SoundToneDelayCount

SoundToneHighDelay:
        decb
        bne     SoundToneHighDelay

        clra
        sta     SOUND_BUZZER_PORT
        ldb     SoundToneDelayCount

SoundToneLowDelay:
        decb
        bne     SoundToneLowDelay

        dec     SoundToneCycleCount
        bne     SoundToneLoop
        rts

SoundShortPause:
        ldx     #220

SoundShortPauseLoop:
        leax    -1,x
        bne     SoundShortPauseLoop
        rts

SoundOff:
        clra
        sta     SOUND_BUZZER_PORT
        rts

SoundToneDelayCount:
        fcb     $00
SoundToneCycleCount:
        fcb     $00
