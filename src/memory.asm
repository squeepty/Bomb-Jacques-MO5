;==============================================================================
; memory.asm
;
; Memory notes for BUILD 001.
;==============================================================================

; BUILD 001 has no writable game variables yet.
;
; The program is assembled for PROGRAM_ORIGIN ($6000). The stack is initialized
; to STACK_TOP ($9FFF), the top of the MO5 user RAM, in main.asm.
; That gives early builds a simple layout:
;
;   $0000-$1F3F  MO5 video RAM window, bitmap or color selected by $A7C0
;   $6000-...    game code and read-only data
;   $9FFF down   stack
;
; Future milestones will reserve a small game state block explicitly instead of
; scattering variables through code modules.
