;==============================================================================
; input.asm
;
; BUILD 008 input routines.
;==============================================================================

;------------------------------------------------------------------------------
; InitInput
;
; Purpose:
;   Initializes the optional joystick PIA and clears per-frame input state.
;
; Modified:
;   A, B, D
;------------------------------------------------------------------------------
InitInput:
        jsr     InitJoypadPia

        ldd     #$0000
        std     Joypads_Read
        std     Joypads_Held
        std     Joypads_Press
        clr     NameKey_Read
        clr     NameKey_Held
        clr     NameKey_Press
        rts

;------------------------------------------------------------------------------
; InitJoypadPia
;
; Purpose:
;   Configures the MO5 game-extension PIA as inputs.
;
; Notes:
;   This mirrors the Wide Dot TO8 engine pattern, adapted from $E7CC-$E7CF to
;   the MO5 game PIA at $A7CC-$A7CF.
;
; Modified:
;   A, B
;------------------------------------------------------------------------------
InitJoypadPia:
        lda     JOYPAD_CRA
        anda    #$FB
        sta     JOYPAD_CRA
        clrb
        stb     JOYPAD_DPAD_PORT
        ora     #$04
        sta     JOYPAD_CRA

        lda     JOYPAD_CRB
        anda    #$FB
        sta     JOYPAD_CRB
        clrb
        stb     JOYPAD_FIRE_PORT
        ora     #$04
        sta     JOYPAD_CRB
        rts

;------------------------------------------------------------------------------
; ReadInput
;
; Purpose:
;   Reads joystick and keyboard state for the current frame.
;
; Output:
;   Dpad_Held / Fire_Held contain buttons currently down.
;   Dpad_Press / Fire_Press contain buttons newly pressed this frame.
;
; Modified:
;   A, B, D
;------------------------------------------------------------------------------
ReadInput:
        ldd     #$0000
        std     Joypads_Read

        jsr     ReadJoypadHardware
        jsr     ReadKeyboardHardware

        ldd     Joypads_Held
        eora    Dpad_Read
        eorb    Fire_Read
        anda    Dpad_Read
        andb    Fire_Read
        std     Joypads_Press

        ldd     Joypads_Read
        std     Joypads_Held
        rts

;------------------------------------------------------------------------------
; ReadJoypadHardware
;
; Purpose:
;   Adds standard MO5 joystick state to Joypads_Read.
;
; Modified:
;   A, B
;------------------------------------------------------------------------------
ReadJoypadHardware:
        lda     JOYPAD_DPAD_PORT
        coma
        anda    #$0F
        ora     Dpad_Read
        sta     Dpad_Read

        lda     JOYPAD_FIRE_PORT
        coma
        anda    #c1_button_A_mask
        ora     Fire_Read
        sta     Fire_Read
        rts

;------------------------------------------------------------------------------
; ReadKeyboardHardware
;
; Purpose:
;   Adds keyboard fallback controls to Joypads_Read.
;
; Controls:
;   Q = left, D = right, Space = jump.
;
; Modified:
;   A
;------------------------------------------------------------------------------
ReadKeyboardHardware:
        lda     #KEY_Q_SELECTOR
        sta     KEYBOARD_PORT
        lda     KEYBOARD_PORT
        bita    #$80
        bne     ReadKeyboardD
        lda     Dpad_Read
        ora     #c1_button_left_mask
        sta     Dpad_Read

ReadKeyboardD:
        lda     #KEY_D_SELECTOR
        sta     KEYBOARD_PORT
        lda     KEYBOARD_PORT
        bita    #$80
        bne     ReadKeyboardSpace
        lda     Dpad_Read
        ora     #c1_button_right_mask
        sta     Dpad_Read

ReadKeyboardSpace:
        lda     #KEY_SPACE_SELECTOR
        sta     KEYBOARD_PORT
        lda     KEYBOARD_PORT
        bita    #$80
        bne     ReadKeyboardDone
        lda     Fire_Read
        ora     #c1_button_A_mask
        sta     Fire_Read

ReadKeyboardDone:
        rts

;------------------------------------------------------------------------------
; ReadNameKeyboardHardware
;
; Purpose:
;   Reads a single newly pressed A-Z, Enter, or Backspace key for name entry.
;
; Output:
;   NameKey_Press contains the ASCII code of the newly pressed key, or 0.
;
; Modified:
;   A, B, X
;------------------------------------------------------------------------------
ReadNameKeyboardHardware:
        clr     NameKey_Read
        clr     NameKey_Press
        ldx     #NameKeyboardTable
        ldb     #NAME_KEY_SCAN_COUNT
        stb     NameKeyScanRemaining

ReadNameKeyboardLoop:
        lda     ,x+
        sta     KEYBOARD_PORT
        lda     KEYBOARD_PORT
        bita    #$80
        bne     ReadNameKeyboardNext

        lda     ,x
        sta     NameKey_Read
        bra     ReadNameKeyboardCompare

ReadNameKeyboardNext:
        leax    1,x
        dec     NameKeyScanRemaining
        bne     ReadNameKeyboardLoop

ReadNameKeyboardCompare:
        lda     NameKey_Read
        beq     ReadNameKeyboardNoKey
        cmpa    NameKey_Held
        beq     ReadNameKeyboardHold
        sta     NameKey_Press

ReadNameKeyboardHold:
        sta     NameKey_Held
        rts

ReadNameKeyboardNoKey:
        clr     NameKey_Held
        rts

Joypads_Read:
Dpad_Read:
        fcb     $00
Fire_Read:
        fcb     $00

Joypads_Held:
Dpad_Held:
        fcb     $00
Fire_Held:
        fcb     $00

Joypads_Press:
Dpad_Press:
        fcb     $00
Fire_Press:
        fcb     $00

NameKey_Read:
        fcb     $00
NameKey_Held:
        fcb     $00
NameKey_Press:
        fcb     $00
NameKeyScanRemaining:
        fcb     $00

; Selector bytes come from the MO5 monitor TABASC key order.
NameKeyboardTable:
        fcb     $5A,'A'
        fcb     $44,'B'
        fcb     $64,'C'
        fcb     $36,'D'
        fcb     $3A,'E'
        fcb     $26,'F'
        fcb     $16,'G'
        fcb     $06,'H'
        fcb     $18,'I'
        fcb     $04,'J'
        fcb     $14,'K'
        fcb     $24,'L'
        fcb     $34,'M'
        fcb     $00,'N'
        fcb     $28,'O'
        fcb     $38,'P'
        fcb     $56,'Q'
        fcb     $2A,'R'
        fcb     $46,'S'
        fcb     $1A,'T'
        fcb     $08,'U'
        fcb     $54,'V'
        fcb     $60,'W'
        fcb     $50,'X'
        fcb     $0A,'Y'
        fcb     $4A,'Z'
        fcb     $68,NAME_KEY_ENTER
        fcb     $52,NAME_KEY_BACKSPACE
