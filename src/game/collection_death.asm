;==============================================================================
; game/collection_death.asm
;
; Bomb pickup checks, enemy collision, frozen-enemy collection, death animation,
; respawn, and game-over transition.
;
; This module is where "touching something" becomes game rules: bombs become
; score, frozen enemies become points, active enemies become deaths, and the last
; death either enters name entry or returns to the hall screen.
;==============================================================================

; CheckBombCollection
;
; Purpose:
;   Collects the first active level-one bomb whose 2x2 cell footprint overlaps
;   Jacques.
;
; Modified:
;   A, B, X, U
;------------------------------------------------------------------------------
CheckBombCollection:
        ; BombActiveFlags and CurrentBombPositions are parallel arrays:
        ; one active byte per bomb and two coordinate bytes per bomb.
        lda     #1
        sta     BombScanIndex
        lda     #BOMB_COUNT
        sta     BombScanRemaining
        ldx     #BombActiveFlags
        ldu     CurrentBombPositions

CheckBombCollectionLoop:
        lda     ,x
        beq     CheckBombCollectionNext

        ; U points at the current bomb's col,row pair. A/B form the conventional
        ; coordinate input used by collision/drawing helpers.
        lda     ,u
        ldb     1,u
        jsr     IsPlayerOverBombAtAB
        beq     CheckBombCollectionNext

        lda     BombScanIndex
        cmpa    BombLitIndex
        bne     CheckBombCollectionEraseNormal

        ; The lit bomb shows a temporary "200" popup. Normal bombs are erased
        ; immediately because there is no popup occupying the same cells.
        clr     ,x
        lda     ,u
        ldb     1,u
        jsr     StartBombScorePopup
        bra     CheckBombCollectionNoPopup

CheckBombCollectionEraseNormal:
        clr     ,x
        lda     ,u
        ldb     1,u
        jsr     EraseBombAtAB

CheckBombCollectionNoPopup:
        jsr     ForcePlayerRedraw
        lda     BombScanIndex
        jsr     AwardBombScore
        jsr     AreAllBombsCollected
        beq     CheckBombCollectedDone
        jsr     EnterLevelClear

CheckBombCollectedDone:
        rts

CheckBombCollectionNext:
        ; Advance one active flag and one two-byte coordinate pair.
        leax    1,x
        leau    2,u
        inc     BombScanIndex
        dec     BombScanRemaining
        bne     CheckBombCollectionLoop

CheckBombDone:
        rts

AreAllBombsCollected:
        ; Return A=1 only if every flag byte is zero.
        ldx     #BombActiveFlags
        ldb     #BOMB_COUNT

AreAllBombsCollectedLoop:
        lda     ,x+
        bne     AreAllBombsCollectedNo
        decb
        bne     AreAllBombsCollectedLoop

        lda     #1
        rts

AreAllBombsCollectedNo:
        clra
        rts

IsPlayerOverBombAtAB:
        ; Bombs are 2x2 objects like player/enemy sprites, but the authored bomb
        ; coordinate is the top-left cell. Store it so both axes can be tested.
        sta     CheckObjectCol
        stb     CheckObjectRow

        ; Axis-aligned overlap, horizontal then vertical:
        ; objectRight < playerLeft => no overlap
        ; playerRight < objectLeft => no overlap
        ; same idea for rows.
        lda     CheckObjectCol
        inca
        cmpa    PlayerCol
        blo     IsPlayerOverBombAtABNo

        lda     PlayerCol
        adda    #PLAYER_WIDTH-1
        cmpa    CheckObjectCol
        blo     IsPlayerOverBombAtABNo

        lda     CheckObjectRow
        inca
        cmpa    PlayerRow
        blo     IsPlayerOverBombAtABNo

        lda     PlayerRow
        adda    #PLAYER_HEIGHT-1
        cmpa    CheckObjectRow
        blo     IsPlayerOverBombAtABNo

        lda     #1
        rts

IsPlayerOverBombAtABNo:
        clra
        rts

ForcePlayerRedraw:
        ; Force dirty rendering by making previous sprite impossible. Useful
        ; after a pickup changes what should be visible under Jacques.
        lda     #$FF
        sta     PlayerPrevSprite
        rts

AwardFrozenEnemyScore:
        jsr     AddScore100
        jsr     ForcePlayerRedraw
        rts

AddBonusItemScore:
        jmp     AddScore500

;------------------------------------------------------------------------------
; CheckEnemyCollision
;
; Purpose:
;   Detects overlap between the 2x2 enemy and Jacques' 2x2 footprint.
;
; Modified:
;   A
;------------------------------------------------------------------------------
CheckEnemyCollision:
        ; Respawn grace makes Jacques temporarily immune and blink-rendered.
        lda     PlayerGraceTimer
        lbne    CheckEnemyCollisionDone

        ; Spawning enemies are ignored unless freeze is active. During freeze,
        ; any visible enemy body can be collected for points.
        lda     Enemy1State
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     CheckEnemyCollisionEnemy1Slot2
        ldd     PowerFreezeTimer
        bne     CheckEnemyCollisionEnemy1Slot1Body
        lda     Enemy1State
        cmpa    #ENEMY1_STATE_SPAWNING
        beq     CheckEnemyCollisionEnemy1Slot2
        cmpa    #ENEMY1_STATE_PHASE2_SPAWNING
        beq     CheckEnemyCollisionEnemy1Slot2
        cmpa    #ENEMY1_STATE_PHASE3_SPAWNING
        beq     CheckEnemyCollisionEnemy1Slot2

CheckEnemyCollisionEnemy1Slot1Body:
        lda     Enemy1Col
        ldb     Enemy1Row
        jsr     IsPlayerOverEnemyAtAB
        beq     CheckEnemyCollisionEnemy1Slot2
        ldd     PowerFreezeTimer
        lbne    CollectFrozenEnemy1Slot1
        lbra    CheckEnemyCollisionHit

CheckEnemyCollisionEnemy1Slot2:
        lda     Enemy1Slot2State
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     CheckEnemyCollisionEnemy1Slot3
        ldd     PowerFreezeTimer
        bne     CheckEnemyCollisionEnemy1Slot2Body
        lda     Enemy1Slot2State
        cmpa    #ENEMY1_STATE_SPAWNING
        beq     CheckEnemyCollisionEnemy1Slot3
        cmpa    #ENEMY1_STATE_PHASE2_SPAWNING
        beq     CheckEnemyCollisionEnemy1Slot3
        cmpa    #ENEMY1_STATE_PHASE3_SPAWNING
        beq     CheckEnemyCollisionEnemy1Slot3

CheckEnemyCollisionEnemy1Slot2Body:
        lda     Enemy1Slot2Col
        ldb     Enemy1Slot2Row
        jsr     IsPlayerOverEnemyAtAB
        beq     CheckEnemyCollisionEnemy1Slot3
        ldd     PowerFreezeTimer
        bne     CollectFrozenEnemy1Slot2
        bra     CheckEnemyCollisionHit

CheckEnemyCollisionEnemy1Slot3:
        lda     Enemy1Slot3State
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     CheckEnemyCollisionEnemy1Slot4
        ldd     PowerFreezeTimer
        bne     CheckEnemyCollisionEnemy1Slot3Body
        lda     Enemy1Slot3State
        cmpa    #ENEMY1_STATE_SPAWNING
        beq     CheckEnemyCollisionEnemy1Slot4
        cmpa    #ENEMY1_STATE_PHASE2_SPAWNING
        beq     CheckEnemyCollisionEnemy1Slot4
        cmpa    #ENEMY1_STATE_PHASE3_SPAWNING
        beq     CheckEnemyCollisionEnemy1Slot4

CheckEnemyCollisionEnemy1Slot3Body:
        lda     Enemy1Slot3Col
        ldb     Enemy1Slot3Row
        jsr     IsPlayerOverEnemyAtAB
        beq     CheckEnemyCollisionEnemy1Slot4
        ldd     PowerFreezeTimer
        bne     CollectFrozenEnemy1Slot3
        bra     CheckEnemyCollisionHit

CheckEnemyCollisionEnemy1Slot4:
        lda     Enemy1Slot4State
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     CheckEnemyCollisionEnemy2
        ldd     PowerFreezeTimer
        bne     CheckEnemyCollisionEnemy1Slot4Body
        lda     Enemy1Slot4State
        cmpa    #ENEMY1_STATE_SPAWNING
        beq     CheckEnemyCollisionEnemy2
        cmpa    #ENEMY1_STATE_PHASE2_SPAWNING
        beq     CheckEnemyCollisionEnemy2
        cmpa    #ENEMY1_STATE_PHASE3_SPAWNING
        beq     CheckEnemyCollisionEnemy2

CheckEnemyCollisionEnemy1Slot4Body:
        lda     Enemy1Slot4Col
        ldb     Enemy1Slot4Row
        jsr     IsPlayerOverEnemyAtAB
        beq     CheckEnemyCollisionEnemy2
        ldd     PowerFreezeTimer
        bne     CollectFrozenEnemy1Slot4
        bra     CheckEnemyCollisionHit

CheckEnemyCollisionEnemy2:
        ; Enemy2 has only an active flag, so its collision check is shorter than
        ; the four Enemy1 slot checks.
        lda     Enemy2Active
        beq     CheckEnemyCollisionDone
        lda     Enemy2Col
        ldb     Enemy2Row
        jsr     IsPlayerOverEnemyAtAB
        beq     CheckEnemyCollisionDone
        ldd     PowerFreezeTimer
        bne     CollectFrozenEnemy2

CheckEnemyCollisionHit:
        jsr     HandleEnemyHit

CheckEnemyCollisionDone:
        rts

CollectFrozenEnemy1Slot1:
        ; Frozen collection removes the touched slot and awards the fixed frozen
        ; enemy score. Other frozen enemies remain available until the timer ends.
        lda     #ENEMY1_STATE_INACTIVE
        sta     Enemy1State
        jsr     AwardFrozenEnemyScore
        rts

CollectFrozenEnemy1Slot2:
        lda     #ENEMY1_STATE_INACTIVE
        sta     Enemy1Slot2State
        jsr     AwardFrozenEnemyScore
        rts

CollectFrozenEnemy1Slot3:
        lda     #ENEMY1_STATE_INACTIVE
        sta     Enemy1Slot3State
        jsr     AwardFrozenEnemyScore
        rts

CollectFrozenEnemy1Slot4:
        lda     #ENEMY1_STATE_INACTIVE
        sta     Enemy1Slot4State
        jsr     AwardFrozenEnemyScore
        rts

CollectFrozenEnemy2:
        clr     Enemy2Active
        jsr     AwardFrozenEnemyScore
        rts

IsPlayerOverEnemyAtAB:
        ; Generic 2x2-vs-2x2 overlap helper. Items reuse this routine because
        ; they occupy the same footprint as enemies.
        sta     CheckObjectCol
        stb     CheckObjectRow

        lda     CheckObjectCol
        adda    #ENEMY_WIDTH-1
        cmpa    PlayerCol
        blo     IsPlayerOverEnemyAtABNo

        lda     PlayerCol
        adda    #PLAYER_WIDTH-1
        cmpa    CheckObjectCol
        blo     IsPlayerOverEnemyAtABNo

        lda     CheckObjectRow
        adda    #ENEMY_HEIGHT-1
        cmpa    PlayerRow
        blo     IsPlayerOverEnemyAtABNo

        lda     PlayerRow
        adda    #PLAYER_HEIGHT-1
        cmpa    CheckObjectRow
        blo     IsPlayerOverEnemyAtABNo

        lda     #1
        rts

IsPlayerOverEnemyAtABNo:
        clra
        rts

;------------------------------------------------------------------------------
; HandleEnemyHit
;
; Purpose:
;   Starts the death sequence after Jacques touches either enemy.
;
; Modified:
;   A, B, X, Y, U
;------------------------------------------------------------------------------
HandleEnemyHit:
        ; Guard against duplicate hits while the state machine is already dying
        ; or transitioning.
        lda     GameState
        cmpa    #GAME_STATE_PLAYING
        bne     HandleEnemyHitDone

        lda     #GAME_STATE_DYING
        sta     GameState
        clr     DeathAnimStepPhase
        clr     DeathSpritePhase
        clr     PlayerGraceTimer
        clr     PlayerDY
        clr     PlayerFallCounter
        clr     PlayerMoveX
        clr     PlayerGrounded
        clr     PlayerLandingPose
        lda     #PLAYER_SPRITE_UP_LEFT
        sta     PlayerSprite

        ; Infinite lives is a cheat flag; otherwise decrement only when the
        ; counter is already non-zero.
        lda     InfiniteLivesFlag
        bne     HandleEnemyHitNoLifeDec
        lda     LivesValue
        beq     HandleEnemyHitNoLifeDec
        dec     LivesValue

HandleEnemyHitNoLifeDec:
        jsr     DrawLives

        jsr     ClearBombScorePopup

HandleEnemyHitDone:
        rts

;------------------------------------------------------------------------------
; UpdateDeathState
;
; Purpose:
;   Animates Jacques straight up until he exits the top of the screen, then
;   either respawns him or shows game over.
;
; Modified:
;   A, B, X, Y, U
;------------------------------------------------------------------------------
UpdateDeathState:
        ; Death movement is intentionally slower than one row every frame. The
        ; phase counter says whether this frame advances the upward motion.
        jsr     ShouldAdvanceDeathAnim
        beq     UpdateDeathStateDone

        clr     PlayerMoveX
        clr     PlayerDY
        clr     PlayerGrounded
        clr     PlayerLandingPose
        jsr     AdvanceDeathSprite

        lda     PlayerRow
        beq     UpdateDeathStateResolve
        dec     PlayerRow
        rts

UpdateDeathStateResolve:
        lda     LivesValue
        lbeq    EnterGameOver
        jsr     RespawnPlayer
        bra     UpdateDeathStateDone

UpdateDeathStateDone:
        rts

UpdateRespawnWaitState:
        ; Respawn wait gives the player a moment to see Jacques back at the
        ; start before PLAYING resumes with grace frames.
        lda     RespawnWaitTimer
        beq     UpdateRespawnWaitResume
        dec     RespawnWaitTimer
        bne     UpdateRespawnWaitDone

UpdateRespawnWaitResume:
        lda     #PLAYER_RESPAWN_GRACE_FRAMES
        sta     PlayerGraceTimer
        clr     GameState

UpdateRespawnWaitDone:
        rts

ShouldAdvanceDeathAnim:
        lda     DeathAnimStepPhase
        cmpa    #DEATH_ANIM_STEP_MOVE_PHASE
        bne     ShouldAdvanceDeathAnimSkip

        jsr     AdvanceDeathAnimStepPhase
        lda     #1
        rts

ShouldAdvanceDeathAnimSkip:
        jsr     AdvanceDeathAnimStepPhase
        clra
        rts

AdvanceDeathAnimStepPhase:
        inc     DeathAnimStepPhase
        lda     DeathAnimStepPhase
        cmpa    #DEATH_ANIM_STEP_PHASE_COUNT
        blo     AdvanceDeathAnimStepPhaseDone
        clr     DeathAnimStepPhase

AdvanceDeathAnimStepPhaseDone:
        rts

AdvanceDeathSprite:
        ; Cycle through three upward-looking sprites while Jacques flies away.
        lda     DeathSpritePhase
        beq     AdvanceDeathSpriteUseLeft
        cmpa    #1
        beq     AdvanceDeathSpriteUseUp

        lda     #PLAYER_SPRITE_UP_RIGHT
        bra     AdvanceDeathSpriteStore

AdvanceDeathSpriteUseLeft:
        lda     #PLAYER_SPRITE_UP_LEFT
        bra     AdvanceDeathSpriteStore

AdvanceDeathSpriteUseUp:
        lda     #PLAYER_SPRITE_UP

AdvanceDeathSpriteStore:
        sta     PlayerSprite
        inc     DeathSpritePhase
        lda     DeathSpritePhase
        cmpa    #DEATH_ANIM_SPRITE_PHASE_COUNT
        blo     AdvanceDeathSpriteDone
        clr     DeathSpritePhase

AdvanceDeathSpriteDone:
        rts

;------------------------------------------------------------------------------
; RespawnPlayer
;
; Purpose:
;   Restores the arena under the dead player and returns Jacques to start.
;
; Modified:
;   A, B, X, Y, U
;------------------------------------------------------------------------------
RespawnPlayer:
        ; Erase both previous and current death positions because the sprite may
        ; have moved since the last saved render state.
        lda     PlayerPrevCol
        ldb     PlayerPrevRow
        jsr     ErasePlayerAtAB
        lda     PlayerCol
        ldb     PlayerRow
        jsr     ErasePlayerAtAB

        jsr     DrawStaticArena
        jsr     DrawEnemy1All
        jsr     DrawEnemy2
        jsr     DrawPower
        jsr     DrawBonusItem
        jsr     DrawEnergyItem

        ; Reset Jacques only; enemy and item states continue after a life loss.
        lda     #PLAYER_START_COL
        sta     PlayerCol
        sta     PlayerPrevCol
        lda     #PLAYER_START_ROW
        sta     PlayerRow
        sta     PlayerPrevRow
        clr     PlayerDY
        clr     PlayerFallCounter
        clr     PlayerMoveX
        clr     PlayerLandingPose
        lda     #PLAYER_MOVE_RIGHT
        sta     PlayerFacing
        lda     #1
        sta     PlayerGrounded
        lda     #PLAYER_SPRITE_FRONT
        sta     PlayerSprite
        sta     PlayerPrevSprite
        clr     PlayerGraceTimer
        lda     #RESPAWN_WAIT_FRAMES
        sta     RespawnWaitTimer
        lda     #1
        sta     PlayerPrevGraceBlinkVisible
        jsr     DrawPlayer
        lda     #GAME_STATE_RESPAWN_WAIT
        sta     GameState
        rts

;------------------------------------------------------------------------------
; EnterGameOver
;
; Purpose:
;   Ends play after the last life and shows the game-over message.
;
; Modified:
;   A, B, X, Y, U
;------------------------------------------------------------------------------
EnterGameOver:
        ; Like respawn, first clean up the final player sprite from both tracked
        ; positions so the hall/name screen starts from a clean arena.
        lda     PlayerPrevCol
        ldb     PlayerPrevRow
        jsr     ErasePlayerAtAB
        lda     PlayerCol
        ldb     PlayerRow
        jsr     ErasePlayerAtAB

        jsr     DrawStaticArena
        jsr     DrawEnemy1All
        jsr     DrawEnemy2
        jsr     DrawPower
        jsr     DrawBonusItem
        jsr     DrawEnergyItem

        jsr     BuildPlayerHallEntryFields
        jsr     IsHallOfFameScore
        beq     EnterGameOverHallOnly
        jsr     ResetEndGameStatus
        jmp     EnterNameEntry

EnterGameOverHallOnly:
        jsr     ResetEndGameStatus
        jmp     EnterHallOfFameScreenNoChrome

ResetEndGameStatus:
        ; Once play is over, the sidebar should no longer show the just-finished
        ; run. Reset score/lives and remove the level indicator before attract
        ; or name-entry screens continue.
        lda     #START_LIVES
        sta     LivesValue
        lda     #'0'
        sta     ScoreThousandsText
        sta     ScoreHundredsText
        sta     ScoreTensText
        sta     ScoreOnesText
        jsr     DrawScore
        jsr     DrawLives
        jmp     EraseLevelLabel
