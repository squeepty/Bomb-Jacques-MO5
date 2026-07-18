;==============================================================================
; memory.asm
;
; Memory notes for the Bomb Jacques V2 release.
;
; This file does not allocate memory. It lives near the top of the include list
; as a reminder of the address contract shared by code, build script, DCMOTO,
; and the K7 wrapper.
;==============================================================================

; The program is assembled for PROGRAM_ORIGIN. The stack is initialized
; to STACK_TOP ($9FFF), the top of the MO5 user RAM, in main.asm.
; That gives this build a simple layout:
;
;   $0000-$1F3F  MO5 video RAM window, bitmap or color selected by $A7C0
;   PROGRAM_ORIGIN-... game code and read-only data
;   after code    early writable variables owned by their modules
;   $9FFF down   stack
;
; Writable state remains grouped by subsystem in input.asm and game/state.asm.
; The release keeps one continuous assembly unit rather than adding a linker or
; a separately reserved state segment.
