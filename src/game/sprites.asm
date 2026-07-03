;==============================================================================
; game/sprites.asm
;
; Monochrome 8x8 cell and 2x2 sprite bitmap data.
;
; One `fcb %xxxxxxxx` row is one 8-pixel scanline. Bit 7 is the leftmost pixel
; of the cell and bit 0 is the rightmost pixel. A single 8x8 cell therefore uses
; 8 bytes. Most actors are 2x2 cells and use 32 bytes in this order:
;
;   top-left cell, top-right cell, bottom-left cell, bottom-right cell
;
; Color is not stored here. Rendering code writes these shape bits to the bitmap
; plane and writes a separate color byte to the color plane.
;
; Note for tooling: tools/sprite-editor.mjs reads and rewrites sprite labels in
; this file. Keep sprite labels stable and keep bitmap rows as `fcb` directives.
;==============================================================================

;------------------------------------------------------------------------------
; Basic 8x8 cells
;------------------------------------------------------------------------------
CellEmpty:
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000

CellPlatformLeft:
        fcb     %00111111
        fcb     %01100000
        fcb     %11011111
        fcb     %11011111
        fcb     %11111111
        fcb     %11111111
        fcb     %01111111
        fcb     %00111111

CellPlatformMiddle:
        fcb     %11111111
        fcb     %00000000
        fcb     %11111111
        fcb     %11111111
        fcb     %11111111
        fcb     %11111111
        fcb     %11111111
        fcb     %11111111

CellPlatformRight:
        fcb     %11111100
        fcb     %00000110
        fcb     %11111111
        fcb     %11111111
        fcb     %11111111
        fcb     %11111111
        fcb     %11111110
        fcb     %11111100

;------------------------------------------------------------------------------
; Enemy 1 and enemy 2 phase-1 art
;
; These are full 2x2 sprites. Directional variants are chosen by Enemy1Dir and
; Enemy2Dir during rendering.
;------------------------------------------------------------------------------
CellEnemy1Left:
        fcb     %00000000
        fcb     %00000111
        fcb     %00000111
        fcb     %00001010
        fcb     %00001010
        fcb     %00001010
        fcb     %00000111
        fcb     %00000111

        fcb     %00000000
        fcb     %11100000
        fcb     %11110000
        fcb     %11111000
        fcb     %01111000
        fcb     %01111000
        fcb     %11111000
        fcb     %11110000

        fcb     %00011111
        fcb     %00111100
        fcb     %00111011
        fcb     %00001000
        fcb     %00001111
        fcb     %00001111
        fcb     %00001111
        fcb     %00000110

        fcb     %11110000
        fcb     %11111000
        fcb     %11111000
        fcb     %00111000
        fcb     %11111000
        fcb     %11111000
        fcb     %11111000
        fcb     %00110000

CellEnemy1Right:
        fcb     %00000000
        fcb     %00000111
        fcb     %00001111
        fcb     %00011111
        fcb     %00011110
        fcb     %00011110
        fcb     %00011111
        fcb     %00001111

        fcb     %00000000
        fcb     %11100000
        fcb     %11100000
        fcb     %01010000
        fcb     %01010000
        fcb     %01010000
        fcb     %11100000
        fcb     %11100000

        fcb     %00001111
        fcb     %00011111
        fcb     %00011111
        fcb     %00011100
        fcb     %00011111
        fcb     %00011111
        fcb     %00011111
        fcb     %00001100

        fcb     %11111000
        fcb     %00111100
        fcb     %11011100
        fcb     %00010000
        fcb     %11110000
        fcb     %11110000
        fcb     %11110000
        fcb     %01100000

CellEnemy2Left:
        fcb     %00000000
        fcb     %00000000
        fcb     %00000001
        fcb     %00000111
        fcb     %01111111
        fcb     %01001110
        fcb     %01010111
        fcb     %01100011

        fcb     %00000000
        fcb     %01111110
        fcb     %11111110
        fcb     %11101100
        fcb     %10111110
        fcb     %00011110
        fcb     %11111110
        fcb     %11111110

        fcb     %01100000
        fcb     %01000000
        fcb     %01000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000

        fcb     %00000110
        fcb     %00000110
        fcb     %00000110
        fcb     %00000100
        fcb     %00000100
        fcb     %00000100
        fcb     %00000000
        fcb     %00000000

CellEnemy2Right:
        fcb     %00000000
        fcb     %00111110
        fcb     %01111111
        fcb     %00010111
        fcb     %01110111
        fcb     %01111100
        fcb     %01111111
        fcb     %01101111

        fcb     %00000000
        fcb     %00000000
        fcb     %10000000
        fcb     %11100000
        fcb     %11111010
        fcb     %11110010
        fcb     %11101010
        fcb     %11000110

        fcb     %01100000
        fcb     %01100000
        fcb     %01100000
        fcb     %00100000
        fcb     %00100000
        fcb     %00100000
        fcb     %00000000
        fcb     %00000000

        fcb     %00000110
        fcb     %00000010
        fcb     %00000010
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000

;------------------------------------------------------------------------------
; Bomb and lit-bomb quadrants
;
; Bombs are kept as four explicit labels because rendering sometimes refers to
; individual quadrants rather than one contiguous 32-byte block.
;------------------------------------------------------------------------------
CellBombTopLeft:
        fcb     %00000000
        fcb     %00000000
        fcb     %00000001
        fcb     %00000001
        fcb     %00000011
        fcb     %00001111
        fcb     %00011000
        fcb     %00011001

CellBombTopRight:
        fcb     %00000000
        fcb     %10000000
        fcb     %00000000
        fcb     %00000000
        fcb     %10000000
        fcb     %11100000
        fcb     %11110000
        fcb     %11110000

CellBombBottomLeft:
        fcb     %00110011
        fcb     %00110111
        fcb     %00110111
        fcb     %00011111
        fcb     %00011111
        fcb     %00001111
        fcb     %00000011
        fcb     %00000000

CellBombBottomRight:
        fcb     %11111000
        fcb     %11111000
        fcb     %11111000
        fcb     %11110000
        fcb     %11110000
        fcb     %11100000
        fcb     %10000000
        fcb     %00000000

CellLitBombTopLeft:
        fcb     %00000000
        fcb     %00000101
        fcb     %00000011
        fcb     %00000101
        fcb     %00000011
        fcb     %00001111
        fcb     %00011000
        fcb     %00011001

CellLitBombTopRight:
        fcb     %00000000
        fcb     %01000000
        fcb     %10000000
        fcb     %01000000
        fcb     %10000000
        fcb     %11100000
        fcb     %11110000
        fcb     %11110000

CellLitBombBottomLeft:
        fcb     %00110011
        fcb     %00110111
        fcb     %00110111
        fcb     %00011111
        fcb     %00011111
        fcb     %00001111
        fcb     %00000011
        fcb     %00000000

CellLitBombBottomRight:
        fcb     %11111000
        fcb     %11111000
        fcb     %11111000
        fcb     %11110000
        fcb     %11110000
        fcb     %11100000
        fcb     %10000000
        fcb     %00000000

CellScore200TopLeft:
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00111011
        fcb     %00001010
        fcb     %00001010
        fcb     %00111010

CellScore200TopRight:
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %10111000
        fcb     %10101000
        fcb     %10101000
        fcb     %10101000

CellScore200BottomLeft:
        fcb     %00100010
        fcb     %00100010
        fcb     %00111011
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000

CellScore200BottomRight:
        fcb     %10101000
        fcb     %10101000
        fcb     %10111000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000

;------------------------------------------------------------------------------
; Player sprite pointer table
;
; PlayerSprite is a numeric state. Rendering doubles it and indexes this table
; to get the 16-bit address of the selected 2x2 sprite.
;------------------------------------------------------------------------------
PlayerSpriteTable:
        fdb     CellPlayerUp
        fdb     CellPlayerDown
        fdb     CellPlayerUpLeft
        fdb     CellPlayerUpRight
        fdb     CellPlayerDownLeft
        fdb     CellPlayerDownRight
        fdb     CellPlayerWalkRight
        fdb     CellPlayerWalkLeft
        fdb     CellPlayerFront

;------------------------------------------------------------------------------
; Jacques 2x2 animation poses
;------------------------------------------------------------------------------
CellPlayerUp:
        fcb     %00000000
        fcb     %00000011
        fcb     %00011111
        fcb     %00011111
        fcb     %00001101
        fcb     %00000101
        fcb     %00000100
        fcb     %00000010

        fcb     %00000000
        fcb     %11000000
        fcb     %11111000
        fcb     %11111000
        fcb     %10110000
        fcb     %10100000
        fcb     %00100000
        fcb     %01000000

        fcb     %00000111
        fcb     %00001111
        fcb     %00001111
        fcb     %00011111
        fcb     %00010011
        fcb     %00010011
        fcb     %00001111
        fcb     %00000110

        fcb     %11100000
        fcb     %11110000
        fcb     %11110000
        fcb     %11111000
        fcb     %11001000
        fcb     %11001000
        fcb     %11110000
        fcb     %01100000

CellPlayerFront:
        fcb     %00000000
        fcb     %00000011
        fcb     %00011111
        fcb     %00011111
        fcb     %00001101
        fcb     %00000101
        fcb     %00000100
        fcb     %00000010

        fcb     %00000000
        fcb     %11000000
        fcb     %11111000
        fcb     %11111000
        fcb     %10110000
        fcb     %10100000
        fcb     %00100000
        fcb     %01000000

        fcb     %00000111
        fcb     %00001111
        fcb     %00001111
        fcb     %00011111
        fcb     %00010011
        fcb     %00010011
        fcb     %00001111
        fcb     %00000110

        fcb     %11100000
        fcb     %11110000
        fcb     %11110000
        fcb     %11111000
        fcb     %11001000
        fcb     %11001000
        fcb     %11110000
        fcb     %01100000

CellPlayerDown:
        fcb     %00000000
        fcb     %00111111
        fcb     %01011111
        fcb     %01011111
        fcb     %01001001
        fcb     %00101010
        fcb     %00111000
        fcb     %00011100

        fcb     %00000000
        fcb     %11111000
        fcb     %11110100
        fcb     %11110100
        fcb     %00100100
        fcb     %10101000
        fcb     %00111000
        fcb     %01110000

        fcb     %00001111
        fcb     %00001111
        fcb     %00001111
        fcb     %00001111
        fcb     %00000111
        fcb     %00000111
        fcb     %00000110
        fcb     %00001110

        fcb     %11100000
        fcb     %11100000
        fcb     %11100000
        fcb     %11100000
        fcb     %11000000
        fcb     %11000000
        fcb     %11000000
        fcb     %11100000

CellPlayerUpLeft:
        fcb     %00000000
        fcb     %00000011
        fcb     %00001111
        fcb     %00001111
        fcb     %01101111
        fcb     %01111101
        fcb     %00011100
        fcb     %00001100

        fcb     %00000000
        fcb     %00000000
        fcb     %11100000
        fcb     %11100000
        fcb     %11100000
        fcb     %01100000
        fcb     %01010000
        fcb     %11001000

        fcb     %00000111
        fcb     %00000111
        fcb     %00000011
        fcb     %00000001
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000

        fcb     %11110100
        fcb     %10110100
        fcb     %11010100
        fcb     %11110100
        fcb     %11110100
        fcb     %01110100
        fcb     %00111000
        fcb     %00011000

CellPlayerUpRight:
        fcb     %00000000
        fcb     %00000001
        fcb     %00001111
        fcb     %00001111
        fcb     %00001111
        fcb     %00001101
        fcb     %00010100
        fcb     %00100110

        fcb     %00000000
        fcb     %10000000
        fcb     %11100000
        fcb     %11100000
        fcb     %11101100
        fcb     %01111100
        fcb     %01110000
        fcb     %01100000

        fcb     %01011111
        fcb     %01011011
        fcb     %01010111
        fcb     %01011111
        fcb     %01011110
        fcb     %01011100
        fcb     %00111000
        fcb     %00110000

        fcb     %11000000
        fcb     %11000000
        fcb     %10000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000

CellPlayerDownLeft:
        fcb     %00000000
        fcb     %00000111
        fcb     %00011111
        fcb     %00011111
        fcb     %00001111
        fcb     %00001110
        fcb     %00001000
        fcb     %00000001

        fcb     %00000000
        fcb     %11111000
        fcb     %11100100
        fcb     %11100100
        fcb     %11000100
        fcb     %11001000
        fcb     %11000000
        fcb     %10100000

        fcb     %00011111
        fcb     %00111111
        fcb     %00100111
        fcb     %00001111
        fcb     %00011111
        fcb     %00011110
        fcb     %00111000
        fcb     %00110000

        fcb     %11000000
        fcb     %11100000
        fcb     %01100000
        fcb     %10100000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000

CellPlayerDownRight:
        fcb     %00000000
        fcb     %00011111
        fcb     %00100111
        fcb     %00100111
        fcb     %00100011
        fcb     %00010011
        fcb     %00000011
        fcb     %00000101

        fcb     %00000000
        fcb     %11100000
        fcb     %11111000
        fcb     %11111000
        fcb     %11110000
        fcb     %01110000
        fcb     %00010000
        fcb     %10000000

        fcb     %00000011
        fcb     %00000111
        fcb     %00000110
        fcb     %00000101
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000

        fcb     %11111000
        fcb     %11111100
        fcb     %11100100
        fcb     %11110000
        fcb     %11111000
        fcb     %01111000
        fcb     %00011100
        fcb     %00001100

CellPlayerWalkRight:
        fcb     %00000000
        fcb     %00110111
        fcb     %00111111
        fcb     %00111111
        fcb     %00111111
        fcb     %00011111
        fcb     %00001111
        fcb     %00010011

        fcb     %00000000
        fcb     %11000000
        fcb     %01100000
        fcb     %00000000
        fcb     %00100000
        fcb     %10000000
        fcb     %11100000
        fcb     %10000000

        fcb     %00100111
        fcb     %00101111
        fcb     %01001111
        fcb     %01001111
        fcb     %01000111
        fcb     %01000111
        fcb     %10000111
        fcb     %10000111

        fcb     %11100000
        fcb     %11110000
        fcb     %11111000
        fcb     %11111000
        fcb     %01010000
        fcb     %11100000
        fcb     %11100000
        fcb     %01100000

CellPlayerWalkLeft:
        fcb     %00000000
        fcb     %00000011
        fcb     %00000110
        fcb     %00000000
        fcb     %00000100
        fcb     %00000001
        fcb     %00000111
        fcb     %00000001

        fcb     %00000000
        fcb     %11101100
        fcb     %11111100
        fcb     %11111100
        fcb     %11111100
        fcb     %11111000
        fcb     %11110000
        fcb     %11001000

        fcb     %00000111
        fcb     %00001111
        fcb     %00011111
        fcb     %00011111
        fcb     %00001010
        fcb     %00000111
        fcb     %00000111
        fcb     %00000110

        fcb     %11100100
        fcb     %11110100
        fcb     %11110010
        fcb     %11110010
        fcb     %11100010
        fcb     %11100010
        fcb     %11100001
        fcb     %11100001

;------------------------------------------------------------------------------
; Enemy spawn positions and later-phase art
;------------------------------------------------------------------------------
Enemy1SpawnCols:
        ; StartEnemy1SpawnEffect masks its seed to 0-7 and indexes this table.
        fcb     2
        fcb     6
        fcb     10
        fcb     14
        fcb     18
        fcb     22
        fcb     26
        fcb     29

CellEnemy1SpawnA:
        fcb     %01100000
        fcb     %00111000
        fcb     %00011110
        fcb     %00001111
        fcb     %00000111
        fcb     %00111111
        fcb     %11111111
        fcb     %00011111
        fcb     %01000010
        fcb     %11000110
        fcb     %11001100
        fcb     %11011100
        fcb     %11111000
        fcb     %11111000
        fcb     %11110000
        fcb     %11110000
        fcb     %00001111
        fcb     %00001111
        fcb     %00011111
        fcb     %00111111
        fcb     %00111101
        fcb     %01111000
        fcb     %01100000
        fcb     %10000000
        fcb     %11111000
        fcb     %11111000
        fcb     %11111000
        fcb     %11111100
        fcb     %11111100
        fcb     %11101110
        fcb     %01100110
        fcb     %00100011

CellEnemy1SpawnB:
        fcb     %00100000
        fcb     %00111000
        fcb     %00011110
        fcb     %00001111
        fcb     %00000111
        fcb     %00111111
        fcb     %01111111
        fcb     %00011111

        fcb     %00000000
        fcb     %11000110
        fcb     %11001100
        fcb     %11011100
        fcb     %11111000
        fcb     %11111000
        fcb     %11110000
        fcb     %11100000

        fcb     %00001111
        fcb     %00001111
        fcb     %00011111
        fcb     %00111111
        fcb     %00111100
        fcb     %01111000
        fcb     %01100000
        fcb     %00000000

        fcb     %11111000
        fcb     %11111000
        fcb     %11111000
        fcb     %11111000
        fcb     %11111100
        fcb     %11001110
        fcb     %01000110
        fcb     %00000010

CellEnemy1Phase2Left:
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000011
        fcb     %00001111
        fcb     %00110111
        fcb     %01001011
        fcb     %00000011
        fcb     %00001111
        fcb     %00110010
        fcb     %11111110
        fcb     %01111100
        fcb     %10011100
        fcb     %11101000
        fcb     %11111000
        fcb     %01110100
        fcb     %11111011
        fcb     %11111100
        fcb     %10111011
        fcb     %10011011
        fcb     %11110000
        fcb     %01001111
        fcb     %00111111
        fcb     %11110000
        fcb     %01110000
        fcb     %10100000
        fcb     %00100000
        fcb     %11110001
        fcb     %00011011
        fcb     %11101110
        fcb     %11000100

CellEnemy1Phase2Right:
        fcb     %11000000
        fcb     %11110000
        fcb     %01001100
        fcb     %01111111
        fcb     %00111110
        fcb     %00111001
        fcb     %00010111
        fcb     %00011111
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %11000000
        fcb     %11110000
        fcb     %11101100
        fcb     %11010010
        fcb     %00001111
        fcb     %00001110
        fcb     %00000101
        fcb     %00000100
        fcb     %10001111
        fcb     %11011000
        fcb     %01110111
        fcb     %00100011
        fcb     %00101110
        fcb     %11011111
        fcb     %00111111
        fcb     %11011101
        fcb     %11011001
        fcb     %00001111
        fcb     %11110010
        fcb     %11111100

CellEnemy1Phase3:
        fcb     %00000111
        fcb     %00011000
        fcb     %00110111
        fcb     %00111111
        fcb     %11100010
        fcb     %11111111
        fcb     %11111111
        fcb     %10000000
        fcb     %11100000
        fcb     %11111000
        fcb     %11111100
        fcb     %11111100
        fcb     %00100011
        fcb     %11111111
        fcb     %11111111
        fcb     %00000001
        fcb     %11111111
        fcb     %01111010
        fcb     %00110001
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %11111111
        fcb     %01011110
        fcb     %10001100
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000
        fcb     %00000000

;------------------------------------------------------------------------------
; Moving item and frozen-enemy art
;
; Power, bonus, and energy share movement/collision code but use distinct color
; and bitmap data. CellEnemyFrozen is used as a temporary replacement sprite
; while PowerFreezeTimer is active.
;------------------------------------------------------------------------------
CellPower:
        fcb     %00000111
        fcb     %00011111
        fcb     %00110000
        fcb     %01100000
        fcb     %01100011
        fcb     %11000111
        fcb     %11000110
        fcb     %11000110

        fcb     %11100000
        fcb     %11111000
        fcb     %00001100
        fcb     %00000110
        fcb     %11000110
        fcb     %11100011
        fcb     %01100011
        fcb     %01100011

        fcb     %11000111
        fcb     %11000111
        fcb     %11000110
        fcb     %11000110
        fcb     %01100000
        fcb     %00110000
        fcb     %00011111
        fcb     %00000111

        fcb     %11100011
        fcb     %11000011
        fcb     %00000011
        fcb     %00000011
        fcb     %00000110
        fcb     %00001100
        fcb     %11111000
        fcb     %11100000

CellBonusItem:
        fcb     %00000111
        fcb     %00011111
        fcb     %00110000
        fcb     %01100000
        fcb     %01100111
        fcb     %11000110
        fcb     %11000110
        fcb     %11000111

        fcb     %11100000
        fcb     %11111000
        fcb     %00001100
        fcb     %00000110
        fcb     %11000110
        fcb     %01100011
        fcb     %01100011
        fcb     %11000011

        fcb     %11000111
        fcb     %11000110
        fcb     %11000110
        fcb     %11000111
        fcb     %01100000
        fcb     %00110000
        fcb     %00011111
        fcb     %00000111

        fcb     %11000011
        fcb     %01100011
        fcb     %01100011
        fcb     %11000011
        fcb     %00000110
        fcb     %00001100
        fcb     %11111000
        fcb     %11100000

CellEnergyItem:
        fcb     %00000111
        fcb     %00011111
        fcb     %00110000
        fcb     %01100000
        fcb     %01100111
        fcb     %11000111
        fcb     %11000110
        fcb     %11000111

        fcb     %11100000
        fcb     %11111000
        fcb     %00001100
        fcb     %00000110
        fcb     %11100110
        fcb     %11100011
        fcb     %00000011
        fcb     %11000011

        fcb     %11000111
        fcb     %11000110
        fcb     %11000111
        fcb     %11000111
        fcb     %01100000
        fcb     %00110000
        fcb     %00011111
        fcb     %00000111

        fcb     %11000011
        fcb     %00000011
        fcb     %11100011
        fcb     %11100011
        fcb     %00000110
        fcb     %00001100
        fcb     %11111000
        fcb     %11100000

CellEnemyFrozen:
        fcb     %00000000
        fcb     %00001111
        fcb     %00111111
        fcb     %01110000
        fcb     %01100111
        fcb     %11001111
        fcb     %11001100
        fcb     %11001101

        fcb     %00000000
        fcb     %11110000
        fcb     %11111100
        fcb     %00001110
        fcb     %11100110
        fcb     %11110011
        fcb     %00110011
        fcb     %10110011

        fcb     %11001101
        fcb     %11001100
        fcb     %11001111
        fcb     %01100111
        fcb     %01110000
        fcb     %00111111
        fcb     %00001111
        fcb     %00000000

        fcb     %10110011
        fcb     %00110011
        fcb     %11110011
        fcb     %11100110
        fcb     %00001110
        fcb     %11111100
        fcb     %11110000
        fcb     %00000000
