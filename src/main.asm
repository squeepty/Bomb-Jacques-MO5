;==============================================================================
; Bomb Jacques
; BUILD 001
;
; A Thomson MO5 assembly game.
;==============================================================================

        include "constants.asm"
        include "memory.asm"

        org     PROGRAM_ORIGIN

;------------------------------------------------------------------------------
; Start
;
; Purpose:
;   Program entry point for BUILD 001.
;
; Input:
;   None. The program is expected to be loaded and executed at $6000.
;
; Output:
;   The MO5 screen shows the project title and build number.
;
; Modified:
;   All registers may be modified during initialization.
;
; Algorithm:
;   1. Initialize the stack pointer.
;   2. Clear bitmap and color video RAM.
;   3. Draw the title screen.
;   4. Stay in an infinite loop so the screen remains visible.
;------------------------------------------------------------------------------
Start:
        lds     #STACK_TOP

        jsr     ClearScreen
        jsr     DrawTitleScreen

MainLoop:
        bra     MainLoop

        include "video.asm"
        include "title.asm"

        end     Start
