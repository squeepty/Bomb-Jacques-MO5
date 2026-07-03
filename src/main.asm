;==============================================================================
; Bomb Jacques
; BUILD 008
;
; A Thomson MO5 assembly game.
;
; This file is intentionally small. It is the "book cover" for the program:
; choose the assembly origin, include the project modules, initialize hardware
; state once, then stay forever in the frame loop.
;==============================================================================

; LWASM processes includes as if their text had been pasted here. Constants and
; memory notes must be seen before ORG because PROGRAM_ORIGIN is used below.
        include "constants.asm"
        include "memory.asm"

; ORG does not write bytes. It tells the assembler "the next byte I emit will
; live at this address when the program is loaded." The build script and K7
; wrapper both agree that the program is loaded at $6000.
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
        ; Disable IRQ and FIRQ while the game owns the machine. The current
        ; timing model is a busy-wait loop, so there is no interrupt handler to
        ; preserve yet.
        orcc    #$50

        ; The 6809 stack grows downward. Starting at $9FFF leaves space between
        ; the loaded program image and the stack for return addresses, PSHS
        ; saves, and temporary values.
        lds     #STACK_TOP

        ; Subsystems are initialized before the first frame. InitGame enters the
        ; title/attract state; it does not start active play immediately.
        jsr     InitInput
        jsr     InitGame

MainLoop:
        ; The game is a cooperative state machine. Every pass through this loop
        ; reads input, updates the current state, draws only what changed, waits
        ; briefly, and returns here.
        jsr     RunGameFrame
        bra     MainLoop

        ; Code is kept in separate files for learning, but the assembler still
        ; sees one continuous program. Order matters: labels and data appear in
        ; memory exactly in this include order.
        include "video.asm"
        include "input.asm"
        include "game.asm"

        end     Start
