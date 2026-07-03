;==============================================================================
; memory.asm
;
; Memory notes for BUILD 008.
;
; This file does not allocate memory. It lives near the top of the include list
; as a reminder of the address contract shared by code, build script, DCMOTO,
; and the K7 wrapper.
;==============================================================================

; The program is assembled for PROGRAM_ORIGIN ($6000). The stack is initialized
; to STACK_TOP ($9FFF), the top of the MO5 user RAM, in main.asm.
; That gives this build a simple layout:
;
;   $0000-$1F3F  MO5 video RAM window, bitmap or color selected by $A7C0
;   $6000-...    game code and read-only data
;   after code    early writable variables owned by their modules
;   $9FFF down   stack
;
; A future milestone will reserve a named game-state block explicitly once the
; movement, collection, enemy, and score variables have settled.
