;==============================================================================
; game/player_movement.asm
;
; Player movement, gravity, platform tests, and generic footprint collision.
;
; All positions are expressed in 8x8 text-cell coordinates rather than pixels.
; Jacques and enemies are 2x2 cells, so most collision helpers reduce to testing
; whether an inclusive horizontal run overlaps a 2-cell footprint at a specific
; row. Scratch bytes such as CheckObjectRow and CheckRunStart make those tests
; easy to follow in an emulator.
;==============================================================================

;------------------------------------------------------------------------------
; UpdateHorizontal
;
; Purpose:
;   Applies held left/right input to PlayerCol and records facing/move intent.
;
; Modified:
;   A, B
;------------------------------------------------------------------------------
UpdateHorizontal:
        ; PlayerMoveX is signed intent for this frame: $FF = left, 0 = no move,
        ; 1 = right. Sprite code reuses this instead of re-reading input.
        clr     PlayerMoveX

        lda     Dpad_Held
        bita    #c1_button_left_mask
        beq     UpdateHorizontalRight

        ; Moving left stores a negative one-byte value. BMI tests later can
        ; distinguish left from right without another compare.
        lda     #PLAYER_MOVE_LEFT
        sta     PlayerFacing
        ldb     PlayerCol
        cmpb    #PLAYER_MIN_COL
        bls     UpdateHorizontalDone
        decb
        stb     PlayerCol
        sta     PlayerMoveX
        bra     UpdateHorizontalDone

UpdateHorizontalRight:
        bita    #c1_button_right_mask
        beq     UpdateHorizontalDone

        lda     #PLAYER_MOVE_RIGHT
        sta     PlayerFacing
        ldb     PlayerCol
        cmpb    #PLAYER_MAX_COL
        bhs     UpdateHorizontalDone
        incb
        stb     PlayerCol
        sta     PlayerMoveX

UpdateHorizontalDone:
        rts

UpdatePlayerSprite:
        ; Sprite selection is state-derived. The renderer only cares about the
        ; final PlayerSprite byte, not the reasoning that produced it.
        lda     PlayerGrounded
        beq     UpdatePlayerSpriteAir

        lda     Dpad_Press
        anda    #c1_button_left_mask+c1_button_right_mask
        beq     UpdatePlayerSpriteLandingPose
        clr     PlayerLandingPose

UpdatePlayerSpriteLandingPose:
        lda     PlayerLandingPose
        beq     UpdatePlayerSpriteGroundedMove
        lda     #PLAYER_SPRITE_FRONT
        sta     PlayerSprite
        rts

UpdatePlayerSpriteGroundedMove:
        lda     PlayerMoveX
        beq     UpdatePlayerSpriteIdle
        bmi     UpdatePlayerSpriteWalkLeft

        lda     #PLAYER_SPRITE_WALK_RIGHT
        sta     PlayerSprite
        rts

UpdatePlayerSpriteWalkLeft:
        lda     #PLAYER_SPRITE_WALK_LEFT
        sta     PlayerSprite
        rts

UpdatePlayerSpriteIdle:
        lda     PlayerFacing
        bmi     UpdatePlayerSpriteIdleLeft
        lda     #PLAYER_SPRITE_WALK_RIGHT
        sta     PlayerSprite
        rts

UpdatePlayerSpriteIdleLeft:
        lda     #PLAYER_SPRITE_WALK_LEFT
        sta     PlayerSprite
        rts

UpdatePlayerSpriteAir:
        lda     PlayerDY
        bmi     UpdatePlayerSpriteRising

        lda     PlayerMoveX
        beq     UpdatePlayerSpriteDown
        bmi     UpdatePlayerSpriteDownLeft

        lda     #PLAYER_SPRITE_DOWN_RIGHT
        sta     PlayerSprite
        rts

UpdatePlayerSpriteDownLeft:
        lda     #PLAYER_SPRITE_DOWN_LEFT
        sta     PlayerSprite
        rts

UpdatePlayerSpriteDown:
        lda     #PLAYER_SPRITE_DOWN
        sta     PlayerSprite
        rts

UpdatePlayerSpriteRising:
        lda     PlayerMoveX
        beq     UpdatePlayerSpriteUp
        bmi     UpdatePlayerSpriteUpLeft

        lda     #PLAYER_SPRITE_UP_RIGHT
        sta     PlayerSprite
        rts

UpdatePlayerSpriteUpLeft:
        lda     #PLAYER_SPRITE_UP_LEFT
        sta     PlayerSprite
        rts

UpdatePlayerSpriteUp:
        lda     #PLAYER_SPRITE_UP
        sta     PlayerSprite
        rts

RefreshGroundState:
        ; Grounded is recomputed every frame from the current footprint. This
        ; lets Jacques walk off platform edges without special edge code.
        jsr     IsPlatformBelow
        beq     RefreshGroundAir
        ldb     PlayerGrounded
        sta     PlayerGrounded
        tstb
        bne     RefreshGroundStayGrounded
        lda     #1
        sta     PlayerLandingPose

RefreshGroundStayGrounded:
        clr     PlayerDY
        clr     PlayerFallCounter
        rts

RefreshGroundAir:
        clr     PlayerGrounded
        clr     PlayerLandingPose
        rts

TryJump:
        ; The game accepts either up or fire as the jump trigger. Dpad_Press and
        ; Fire_Press are edge-detected, so a held button starts only one jump.
        lda     Dpad_Press
        bita    #c1_button_up_mask
        bne     TryJumpStart

        lda     Fire_Press
        bita    #c1_button_A_mask
        beq     TryJumpDone

TryJumpStart:
        lda     PlayerGrounded
        beq     TryJumpDone

        ; Jumping stores a target row instead of a velocity. Each frame moves
        ; up one cell until the target row or a platform underside is reached.
        lda     PlayerRow
        cmpa    #PLAYER_MIN_ROW+PLAYER_JUMP_HEIGHT_ROWS
        bls     TryJumpUseMinTarget
        suba    #PLAYER_JUMP_HEIGHT_ROWS
        bra     TryJumpStoreTarget

TryJumpUseMinTarget:
        lda     #PLAYER_MIN_ROW

TryJumpStoreTarget:
        sta     PlayerJumpTargetRow
        lda     #PLAYER_RISE_STATE
        sta     PlayerDY
        clr     PlayerGrounded
        clr     PlayerFallCounter
        clr     PlayerLandingPose
        jsr     SoundJump

TryJumpDone:
        rts

ApplyVertical:
        ; PlayerDY is a direction/state flag, not a pixel velocity. Negative
        ; means rising; zero means falling or grounded.
        lda     PlayerDY
        bmi     ApplyVerticalUp

        lda     PlayerGrounded
        bne     ApplyVerticalDone

        jsr     ShouldDelayFall
        bne     ApplyVerticalDone

        inc     PlayerRow
        jsr     SnapToGroundIfNeeded
        bra     ApplyVerticalDone

ApplyVerticalUp:
        lda     PlayerRow
        cmpa    PlayerJumpTargetRow
        bls     ApplyVerticalStopRising
        jsr     IsPlatformAbove
        bne     ApplyVerticalStopRising

        dec     PlayerRow
        bra     ApplyVerticalDone

ApplyVerticalStopRising:
        clr     PlayerDY
        clr     PlayerFallCounter

ApplyVerticalDone:
        rts

SnapToGroundIfNeeded:
        ; After a one-cell fall, immediately test the new footprint. If a
        ; platform is directly below, landing pose and grounded state are set.
        jsr     IsPlatformBelow
        beq     SnapToGroundDone
        sta     PlayerGrounded
        sta     PlayerLandingPose
        clr     PlayerDY
        clr     PlayerFallCounter

SnapToGroundDone:
        rts

;------------------------------------------------------------------------------
; ShouldDelayFall
;
; Purpose:
;   Slows falling while jump is held, allowing horizontal floating.
;
; Output:
;   A = 0 when the player should fall this frame.
;   A = 1 when falling should be delayed this frame.
;
; Modified:
;   A
;------------------------------------------------------------------------------
ShouldDelayFall:
        lda     Fire_Held
        bita    #c1_button_A_mask
        bne     ShouldDelayFallHeld

        lda     Dpad_Held
        bita    #c1_button_up_mask
        bne     ShouldDelayFallHeld

        clr     PlayerFallCounter
        clra
        rts

ShouldDelayFallHeld:
        ; Slow-fall is implemented as "skip N-1 fall frames, fall on N". The
        ; counter resets when jump/up is released.
        inc     PlayerFallCounter
        lda     PlayerFallCounter
        cmpa    #SLOW_FALL_FRAMES
        bhs     ShouldDelayFallStep

        lda     #1
        rts

ShouldDelayFallStep:
        clr     PlayerFallCounter
        clra
        rts

;------------------------------------------------------------------------------
; IsPlatformBelow
;
; Purpose:
;   Tests whether the 2x2 player is standing directly above a platform run.
;
; Output:
;   A = 1 when solid ground is below, otherwise A = 0.
;
; Modified:
;   A, B
;------------------------------------------------------------------------------
IsPlatformBelow:
        ; Check the row immediately below Jacques' 2-cell-tall footprint.
        lda     PlayerRow
        adda    #PLAYER_HEIGHT
        sta     CheckObjectRow

        ; The floor is a special run. It is not stored in CurrentPlatform*,
        ; which keeps authored platform tables focused on floating platforms.
        cmpa    #FLOOR_ROW
        bne     IsPlatformBelowScan
        lda     #FLOOR_START_COL
        ldb     #FLOOR_START_COL+FLOOR_LENGTH-1
        jsr     IsPlayerOverColumnRun
        bne     IsPlatformBelowYes

IsPlatformBelowScan:
        ; CurrentPlatform records are row,start,length,end. The scan compares
        ; only records whose row matches the row under the player.
        ldx     #CurrentPlatform1Row
        lda     #PLATFORM_RUN_COUNT
        sta     PlatformScanRemaining

IsPlatformBelowScanLoop:
        lda     CheckObjectRow
        cmpa    ,x
        bne     IsPlatformBelowScanNext
        lda     1,x
        ldb     3,x
        jsr     IsPlayerOverColumnRun
        bne     IsPlatformBelowYes

IsPlatformBelowScanNext:
        leax    PLATFORM_RECORD_SIZE,x
        dec     PlatformScanRemaining
        bne     IsPlatformBelowScanLoop
        bra     IsPlatformBelowNo

IsPlatformBelowYes:
        lda     #1
        rts

IsPlatformBelowNo:
        clra
        rts

;------------------------------------------------------------------------------
; IsPlatformAbove
;
; Purpose:
;   Tests whether the player is about to hit the top boundary or platform
;   underside while rising.
;
; Output:
;   A = 1 when blocked above, otherwise A = 0.
;
; Modified:
;   A, B
;------------------------------------------------------------------------------
IsPlatformAbove:
        ; The top boundary is treated as a blocking ceiling before platform
        ; undersides are scanned.
        lda     PlayerRow
        cmpa    #PLAYER_MIN_ROW
        bls     IsPlatformAboveYes
        deca
        sta     CheckObjectRow

        ldx     #CurrentPlatform1Row
        lda     #PLATFORM_RUN_COUNT
        sta     PlatformScanRemaining

IsPlatformAboveScanLoop:
        lda     CheckObjectRow
        cmpa    ,x
        bne     IsPlatformAboveScanNext
        lda     1,x
        ldb     3,x
        jsr     IsPlayerOverColumnRun
        bne     IsPlatformAboveYes

IsPlatformAboveScanNext:
        leax    PLATFORM_RECORD_SIZE,x
        dec     PlatformScanRemaining
        bne     IsPlatformAboveScanLoop
        bra     IsPlatformAboveNo

IsPlatformAboveYes:
        lda     #1
        rts

IsPlatformAboveNo:
        clra
        rts

IsPlayerOverColumnRun:
        ; Generic 1D overlap test for the player's horizontal footprint:
        ; runEnd < playerLeft means "entirely left"; playerRight < runStart
        ; means "entirely right"; anything else overlaps.
        sta     CheckRunStart
        stb     CheckRunEnd

        lda     CheckRunEnd
        cmpa    PlayerCol
        blo     IsPlayerOverColumnRunNo

        lda     PlayerCol
        adda    #PLAYER_WIDTH-1
        cmpa    CheckRunStart
        blo     IsPlayerOverColumnRunNo

        lda     #1
        rts

IsPlayerOverColumnRunNo:
        clra
        rts

;------------------------------------------------------------------------------
; IsEnemy1OnFloor
;
; Purpose:
;   Tests whether enemy 1 has reached the bottom floor.
;
; Output:
;   A = 1 when enemy 1 is on or past the floor, otherwise A = 0.
;
; Modified:
;   A, B
;------------------------------------------------------------------------------
IsEnemy1OnFloor:
        lda     Enemy1Row
        adda    #ENEMY_HEIGHT
        cmpa    #FLOOR_ROW
        blo     IsEnemy1OnFloorNo

        lda     #FLOOR_START_COL
        ldb     #FLOOR_START_COL+FLOOR_LENGTH-1
        jmp     IsEnemy1OverColumnRun

IsEnemy1OnFloorNo:
        clra
        rts

;------------------------------------------------------------------------------
; IsEnemy1Grounded
;
; Purpose:
;   Tests whether enemy 1 has floor or platform support directly below.
;
; Output:
;   A = 1 when solid ground is below, otherwise A = 0.
;
; Modified:
;   A, B
;------------------------------------------------------------------------------
IsEnemy1Grounded:
        ; Enemy1 uses the same platform idea as Jacques but checks Enemy1Col and
        ; Enemy1Row. This is why the single-slot work-variable scheme matters.
        lda     Enemy1Row
        adda    #ENEMY_HEIGHT
        sta     CheckObjectRow

        cmpa    #FLOOR_ROW
        bne     IsEnemy1GroundedScan
        lda     #FLOOR_START_COL
        ldb     #FLOOR_START_COL+FLOOR_LENGTH-1
        jsr     IsEnemy1OverColumnRun
        bne     IsEnemy1GroundedYes

IsEnemy1GroundedScan:
        ldx     #CurrentPlatform1Row
        lda     #PLATFORM_RUN_COUNT
        sta     PlatformScanRemaining

IsEnemy1GroundedScanLoop:
        lda     CheckObjectRow
        cmpa    ,x
        bne     IsEnemy1GroundedScanNext
        lda     1,x
        ldb     3,x
        jsr     IsEnemy1OverColumnRun
        bne     IsEnemy1GroundedYes

IsEnemy1GroundedScanNext:
        leax    PLATFORM_RECORD_SIZE,x
        dec     PlatformScanRemaining
        bne     IsEnemy1GroundedScanLoop
        bra     IsEnemy1GroundedNo

IsEnemy1GroundedYes:
        lda     #1
        rts

IsEnemy1GroundedNo:
        clra
        rts

IsEnemy1OverColumnRun:
        sta     CheckRunStart
        stb     CheckRunEnd

        lda     CheckRunEnd
        cmpa    Enemy1Col
        blo     IsEnemy1OverColumnRunNo

        lda     Enemy1Col
        adda    #ENEMY_WIDTH-1
        cmpa    CheckRunStart
        blo     IsEnemy1OverColumnRunNo

        lda     #1
        rts

IsEnemy1OverColumnRunNo:
        clra
        rts

;------------------------------------------------------------------------------
; IsEnemyFootprintBlockedAtAB
;
; Purpose:
;   Tests whether a 2x2 enemy footprint would overlap a floor/platform run.
;
; Input:
;   A = target enemy column.
;   B = target enemy row.
;
; Output:
;   A = 1 when the target footprint is blocked, otherwise A = 0.
;
; Modified:
;   A, B
;------------------------------------------------------------------------------
IsEnemyFootprintBlockedAtAB:
        ; A/B describe a hypothetical enemy position. The routine stores them
        ; in scratch RAM because comparisons need to revisit both values.
        sta     CheckObjectCol
        stb     CheckObjectRow

        ; Unlike "grounded", blocked means any part of the 2x2 footprint would
        ; overlap a floor/platform row.
        lda     CheckObjectRow
        cmpa    #FLOOR_ROW
        bhi     IsEnemyFootprintBlockedScan
        lda     CheckObjectRow
        adda    #ENEMY_HEIGHT-1
        cmpa    #FLOOR_ROW
        blo     IsEnemyFootprintBlockedScan
        lda     #FLOOR_START_COL
        ldb     #FLOOR_START_COL+FLOOR_LENGTH-1
        jsr     IsCheckObjectOverColumnRun
        bne     IsEnemyFootprintBlockedYes

IsEnemyFootprintBlockedScan:
        ldx     #CurrentPlatform1Row
        lda     #PLATFORM_RUN_COUNT
        sta     PlatformScanRemaining

IsEnemyFootprintBlockedScanLoop:
        lda     CheckObjectRow
        cmpa    ,x
        bhi     IsEnemyFootprintBlockedScanNext
        lda     CheckObjectRow
        adda    #ENEMY_HEIGHT-1
        cmpa    ,x
        blo     IsEnemyFootprintBlockedScanNext
        lda     1,x
        ldb     3,x
        jsr     IsCheckObjectOverColumnRun
        bne     IsEnemyFootprintBlockedYes

IsEnemyFootprintBlockedScanNext:
        leax    PLATFORM_RECORD_SIZE,x
        dec     PlatformScanRemaining
        bne     IsEnemyFootprintBlockedScanLoop

IsEnemyFootprintBlockedNo:
        clra
        rts

IsEnemyFootprintBlockedYes:
        lda     #1
        rts

IsCheckObjectOverColumnRun:
        ; Same inclusive-run overlap as IsPlayerOverColumnRun, but using the
        ; generic CheckObjectCol footprint for enemies and moving items.
        sta     CheckRunStart
        stb     CheckRunEnd

        lda     CheckRunEnd
        cmpa    CheckObjectCol
        blo     IsCheckObjectOverColumnRunNo

        lda     CheckObjectCol
        adda    #ENEMY_WIDTH-1
        cmpa    CheckRunStart
        blo     IsCheckObjectOverColumnRunNo

        lda     #1
        rts

IsCheckObjectOverColumnRunNo:
        clra
        rts
