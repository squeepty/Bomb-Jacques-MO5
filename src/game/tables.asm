;==============================================================================
; game/tables.asm
;
; Small shared data tables and display strings.
;
; Code above this file references many labels below. Because LWASM processes all
; includes as one continuous source, forward references are fine: the assembler
; resolves them after reading the full program.
;==============================================================================

;------------------------------------------------------------------------------
; WaitFrame
;
; Purpose:
;   Provides a simple fixed delay until milestone timing uses the 50 Hz IRQ.
;
; Modified:
;   X, Y
;------------------------------------------------------------------------------
WaitFrame:
        ; Busy-wait timing burns CPU cycles in two nested loops. It is simple and
        ; deterministic enough for this milestone, but will eventually give way
        ; to interrupt-driven 50 Hz timing.
        ldx     #FRAME_DELAY_OUTER

WaitFrameOuter:
        ldy     #FRAME_DELAY_INNER

WaitFrameInner:
        ; LEAY/LEAX subtract one from a 16-bit index register and set condition
        ; codes, letting BNE loop until the register becomes zero.
        leay    -1,y
        bne     WaitFrameInner
        leax    -1,x
        bne     WaitFrameOuter
        rts

PowerSpawnCols:
        ; Spawn tables are parallel arrays. A masked seed chooses index 0-7,
        ; then the same index reads a column and row.
        fcb     3
        fcb     28
        fcb     8
        fcb     26
        fcb     13
        fcb     22
        fcb     5
        fcb     21

PowerSpawnRows:
        fcb     5
        fcb     7
        fcb     12
        fcb     9
        fcb     18
        fcb     15
        fcb     6
        fcb     21

        ; Level data is included here so gameplay tables, sprite data, and state
        ; remain grouped after executable code in the final binary.
        include "levels.asm"

TitleText:
        ; Text strings are zero-terminated for DrawString.
        fcc     "BOMB JACQUES"
        fcb     0

TitleBombName:
        fcc     "BOMB"
        fcb     0

TitleBombScoreText:
        fcc     "0050"
        fcb     0

TitleLitBombName:
        fcc     "LIT BOMB"
        fcb     0

TitleLitBombScoreText:
        fcc     "0200"
        fcb     0

TitleBonusName:
        fcc     "BONUS"
        fcb     0

TitleBonusScoreText:
        fcc     "0500"
        fcb     0

TitleFrozenName:
        fcc     "FROZEN ENEMY"
        fcb     0

TitleFrozenScoreText:
        fcc     "0100"
        fcb     0

TitleInstructionsText:
        fcc     "Q:LEFT, D:RIGHT, SPACE:JUMP"
        fcb     0

TitleStartText:
        fcc     "PRESS SPACE TO START"
        fcb     0

CheatSqueeptyText:
        ; Cheat text is length-controlled by CHEAT_SQUEEPTY_LEN, so it does not
        ; need a zero terminator.
        fcc     "SQUEEPTY"

HudText:
        fcc     "BOMB JACQUES BUILD 008"
        fcb     0

VersionLabelText:
        fcc     "(v2)"
        fcb     0

Player1Text:
        fcc     "PLAYER1"
        fcb     0

LevelLabelText:
        fcc     "LEVEL 01"
        fcb     0

ScoreText:
        fcc     "SCORE "
        fcb     0

ScoreDigitsText:
        ; The label ScoreDigitsText points at the first mutable digit. The four
        ; digit labels let score code update individual columns directly.
ScoreThousandsText:
        fcb     '0'
ScoreHundredsText:
        fcb     '0'
ScoreTensText:
        fcb     '0'
ScoreOnesText:
        fcb     '0'
        fcb     0

GameOverText:
        fcc     "GAME OVER"
        fcb     0

WellDoneText:
        fcc     "WELL DONE!"
        fcb     0

GetReadyText:
        fcc     "GET READY"
        fcb     0

HallOfFameTitle:
        fcc     "HALL OF FAME"
        fcb     0

HallHeaderText:
        fcc     "# LV NAME      SCORE"
        fcb     0

NameEntryTitle:
        fcc     "ENTER NAME"
        fcb     0

HallEntryPointers:
        ; Pointer table used to address hall rows by numeric index.
        fdb     HallEntry1
        fdb     HallEntry2
        fdb     HallEntry3
        fdb     HallEntry4
        fdb     HallEntry5

HallDefaultEntry1:
        ; Defaults are copied into the live HallEntry rows during InitGame.
        fcc     "10 SQUEEPTY   6000"
        fcb     0
HallDefaultEntry2:
        fcc     "08 PROUDLY    5000"
        fcb     0
HallDefaultEntry3:
        fcc     "06 PRESENTS   4000"
        fcb     0
HallDefaultEntry4:
        fcc     "04 BOMB       3000"
        fcb     0
HallDefaultEntry5:
        fcc     "02 JACQUES    1000"
        fcb     0

HallEntry1:
        fcc     "10 SQUEEPTY   6000"
        fcb     0
HallEntry2:
        fcc     "08 PROUDLY    5000"
        fcb     0
HallEntry3:
        fcc     "06 PRESENTS   4000"
        fcb     0
HallEntry4:
        fcc     "04 BOMB       3000"
        fcb     0
HallEntry5:
        fcc     "02 JACQUES    1000"
        fcb     0

HallRankText:
        fcb     '1'
        fcb     0

HallLineColors:
        ; Color rows for hall/title-style screens: title, header, then entries.
        fcb     COLOR_HALL_HEADER
        fcb     COLOR_HALL_HEADER
        fcb     COLOR_HALL_TEXT
        fcb     COLOR_HALL_TEXT
        fcb     COLOR_HALL_TEXT
        fcb     COLOR_HALL_TEXT
        fcb     COLOR_HALL_TEXT

LevelMessageColors:
        ; WELL DONE and GET READY cycle through these color attributes.
        fcb     $16
        fcb     $26
        fcb     $36
        fcb     $46
        fcb     $56
        fcb     $76

        ; Sidebar art is data-only and is consumed by DrawSidebarArt.
        include "sidebar_art.asm"
