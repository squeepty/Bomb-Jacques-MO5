;==============================================================================
; memory.asm
;
; Memory notes for BUILD 001.
;==============================================================================

; BUILD 001 has no writable game variables yet.
;
; The program is assembled for PROGRAM_ORIGIN ($6000). The stack is initialized
; to STACK_TOP ($BFFF) in main.asm. That gives early builds a simple layout:
;
;   $0000-$1F3F  bitmap video RAM
;   $2000-$3F3F  color video RAM
;   $6000-...    game code and read-only data
;   $BFFF down   stack
;
; Future milestones will reserve a small game state block explicitly instead of
; scattering variables through code modules.
