;==============================================================================
; Bomb Jacques
; BUILD 008
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
;   Program entry point for BUILD 008.
;
; Input:
;   None. The program is expected to be loaded and executed at $6000.
;
; Output:
;   The MO5 screen shows a static arena, movable player, bombs, score,
;   highlighted bonus bomb, two patrolling enemies, lives, death/respawn, and
;   game over.
;
; Modified:
;   All registers may be modified during initialization.
;
; Algorithm:
;   1. Disable interrupts while BUILD 008 owns the machine.
;   2. Initialize the stack pointer.
;   3. Initialize input and game state.
;   4. Run the milestone 8 gameplay loop.
;------------------------------------------------------------------------------
Start:
        orcc    #$50
        lds     #STACK_TOP

        jsr     InitInput
        jsr     InitGame

MainLoop:
        jsr     RunGameFrame
        bra     MainLoop

        include "video.asm"
        include "input.asm"
        include "game.asm"

        end     Start
