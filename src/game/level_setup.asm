;==============================================================================
; game/level_setup.asm
;
; Level initialization and per-level reset routines.
;
; The authored level data in levels.asm is immutable table data. When a level
; starts, this module copies the selected platform records into CurrentPlatform*
; variables and points CurrentBombPositions at that level's bomb coordinate
; table. Moving actors and timers are reset here, but run-wide values such as
; score and lives are deliberately preserved.
;==============================================================================

;------------------------------------------------------------------------------
; StartCurrentLevel
;
; Purpose:
;   Resets the active level layout and moving objects while preserving score and
;   lives.
;
; Modified:
;   A, B, D, X, U
;------------------------------------------------------------------------------
StartCurrentLevel:
        ; Keep this order: platform and bomb pointers must be valid before
        ; reset/draw routines use them.
        jsr     SetCurrentLevelBombPositions
        jsr     SetCurrentLevelPlatformPositions
        jsr     ResetPlayerForLevel
        jsr     ResetBombs
        jsr     ResetEnemiesForLevel
        jsr     ResetPowerForLevel
        jsr     ResetBonusItemForLevel
        jsr     ResetEnergyItemForLevel
        rts

SetCurrentLevelBombPositions:
        ; Pointer tables contain 16-bit addresses. CurrentLevel is a byte index,
        ; so LSLB multiplies it by two before the indexed load through D,X.
        clra
        ldb     CurrentLevel
        lslb
        ldx     #LevelBombTable
        ldu     d,x
        stu     CurrentBombPositions
        rts

SetCurrentLevelPlatformPositions:
        ; Same pointer-table trick as bombs, then copy row/start/length records
        ; into mutable CurrentPlatform storage.
        clra
        ldb     CurrentLevel
        lslb
        ldx     #LevelPlatformTable
        ldu     d,x
        ldx     #CurrentPlatform1Row
        lda     #PLATFORM_RUN_COUNT
        sta     PlatformScanRemaining

SetCurrentLevelPlatformLoop:
        ; Authored record format: row, start column, length.
        lda     ,u+
        sta     ,x+
        lda     ,u+
        sta     ,x+
        sta     CheckRunStart
        lda     ,u+
        sta     ,x+
        ; Store an end column too. Collision code can then compare against a
        ; ready-made inclusive [start,end] run without recomputing length.
        adda    CheckRunStart
        deca
        sta     ,x+
        dec     PlatformScanRemaining
        bne     SetCurrentLevelPlatformLoop
        rts

ResetPlayerForLevel:
        ; Current and previous draw positions are initialized together so the
        ; first dirty-render comparison starts from a coherent state.
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
        lda     #PLAYER_SPRITE_FRONT
        sta     PlayerSprite
        sta     PlayerPrevSprite
        clr     PlayerGraceTimer
        clr     RespawnWaitTimer
        lda     #1
        sta     PlayerPrevGraceBlinkVisible
        lda     #1
        sta     PlayerGrounded
        rts

ResetEnemiesForLevel:
        ; Slot 1 uses the shared Enemy1* work variables and begins each level in
        ; its spawn effect. Later slots start inactive and are scheduled in.
        lda     #ENEMY1_SPAWN_SEED
        sta     Enemy1SpawnSeed
        lda     #ENEMY1_PHASE2_AI_SEED
        sta     Enemy1Phase2AiSeed
        lda     #ENEMY1_STEP_FRAMES
        sta     Enemy1StepFrames
        lda     #ENEMY1_PHASE2_STEP_FRAMES
        sta     Enemy1Phase2StepFrames
        lda     #ENEMY1_PHASE2_CHASE_RATE
        sta     Enemy1Phase2ChaseRate
        lda     #ENEMY1_PERSONALITY_BALANCED
        sta     Enemy1Personality
        jsr     StartEnemy1SpawnEffect
        lda     Enemy1Col
        sta     Enemy1PrevCol
        lda     Enemy1Row
        sta     Enemy1PrevRow
        lda     Enemy1Sprite
        sta     Enemy1PrevSprite
        lda     Enemy1State
        sta     Enemy1PrevState
        clra
        clrb
        std     Enemy1SpawnFrameCounter

        ; Slots 2-4 keep independent tuning values so the same UpdateEnemy1
        ; routine can produce different personalities after LoadEnemy1SlotN.
        lda     #ENEMY1_STATE_INACTIVE
        sta     Enemy1Slot2State
        sta     Enemy1Slot2PrevState
        sta     Enemy1Slot3State
        sta     Enemy1Slot3PrevState
        sta     Enemy1Slot4State
        sta     Enemy1Slot4PrevState
        lda     #ENEMY1_PERSONALITY_FLANKER
        sta     Enemy1Slot2Personality
        lda     #ENEMY1_SLOT2_STEP_FRAMES
        sta     Enemy1Slot2StepFrames
        lda     #ENEMY1_SLOT2_PHASE2_STEP_FRAMES
        sta     Enemy1Slot2Phase2StepFrames
        lda     #ENEMY1_SLOT2_PHASE2_CHASE_RATE
        sta     Enemy1Slot2Phase2ChaseRate
        clr     Enemy1Slot2FrameCounter
        clr     Enemy1Slot2SpawnTimer
        lda     #ENEMY1_PERSONALITY_DRIFTER
        sta     Enemy1Slot3Personality
        lda     #ENEMY1_SLOT3_STEP_FRAMES
        sta     Enemy1Slot3StepFrames
        lda     #ENEMY1_SLOT3_PHASE2_STEP_FRAMES
        sta     Enemy1Slot3Phase2StepFrames
        lda     #ENEMY1_SLOT3_PHASE2_CHASE_RATE
        sta     Enemy1Slot3Phase2ChaseRate
        clr     Enemy1Slot3FrameCounter
        clr     Enemy1Slot3SpawnTimer
        lda     #ENEMY1_PERSONALITY_PHASE3
        sta     Enemy1Slot4Personality
        lda     #ENEMY1_SLOT4_STEP_FRAMES
        sta     Enemy1Slot4StepFrames
        lda     #ENEMY1_SLOT4_PHASE3_STEP_FRAMES
        sta     Enemy1Slot4Phase2StepFrames
        lda     #ENEMY1_SLOT4_PHASE3_CHASE_RATE
        sta     Enemy1Slot4Phase2ChaseRate
        clr     Enemy1Slot4FrameCounter
        clr     Enemy1Slot4SpawnTimer

        lda     #ENEMY2_START_COL
        sta     Enemy2Col
        sta     Enemy2PrevCol
        lda     #ENEMY2_START_ROW
        sta     Enemy2Row
        sta     Enemy2PrevRow
        lda     #ENEMY_MOVE_RIGHT
        sta     Enemy2Dir
        lda     #1
        sta     Enemy2Active
        sta     Enemy2PrevActive
        lda     #ENEMY2_FRAME_STAGGER
        sta     Enemy2FrameCounter
        lda     #ENEMY2_AI_SEED
        sta     Enemy2AiSeed
        rts

ResetPowerForLevel:
        ; Power state includes both the moving pickup and the freeze timer. Both
        ; are reset here so a freeze cannot leak across level boundaries.
        lda     #POWER_INACTIVE
        sta     PowerActive
        sta     PowerPrevActive
        lda     #POWER_MIN_COL
        sta     PowerCol
        sta     PowerPrevCol
        lda     #POWER_MIN_ROW
        sta     PowerRow
        sta     PowerPrevRow
        clr     PowerMoveCounter
        clr     PowerFreezeTimer
        clr     PowerFreezeTimer+1
        clr     PowerPrevFreezeActive
        clr     PowerPrevFreezeBlinkVisible
        clr     PowerSpawnArmed
        clr     PowerSpawnTimer
        clr     PowerSpawnTimer+1
        lda     Enemy1SpawnSeed
        sta     PowerSeed
        rts

ResetBonusItemForLevel:
        ; The bonus item is armed immediately and will appear after its timer.
        ; Its seed is mixed from existing enemy seeds for lightweight variation.
        lda     #BONUS_ITEM_INACTIVE
        sta     BonusItemActive
        sta     BonusItemPrevActive
        lda     #POWER_MIN_COL
        sta     BonusItemCol
        sta     BonusItemPrevCol
        lda     #POWER_MIN_ROW
        sta     BonusItemRow
        sta     BonusItemPrevRow
        clr     BonusItemMoveCounter
        lda     #1
        sta     BonusItemSpawnArmed
        ldd     #BONUS_ITEM_SPAWN_FRAMES
        std     BonusItemSpawnTimer
        lda     Enemy2AiSeed
        eora    Enemy1SpawnSeed
        bne     ResetBonusItemSeedStore
        lda     #$7D

ResetBonusItemSeedStore:
        sta     BonusItemSeed
        rts

ResetEnergyItemForLevel:
        ; Energy appears only after collecting a power item, so it begins
        ; unarmed even though its coordinates and seed are prepared.
        lda     #ENERGY_ITEM_INACTIVE
        sta     EnergyItemActive
        sta     EnergyItemPrevActive
        lda     #POWER_MIN_COL
        sta     EnergyItemCol
        sta     EnergyItemPrevCol
        lda     #POWER_MIN_ROW
        sta     EnergyItemRow
        sta     EnergyItemPrevRow
        clr     EnergyItemMoveCounter
        clr     EnergyItemSpawnArmed
        clr     EnergyItemSpawnTimer
        clr     EnergyItemSpawnTimer+1
        lda     Enemy1Phase2AiSeed
        eora    Enemy2AiSeed
        eora    BonusItemSeed
        bne     ResetEnergyItemSeedStore
        lda     #$B5

ResetEnergyItemSeedStore:
        sta     EnergyItemSeed
        rts

;------------------------------------------------------------------------------
; ResetBombs
;
; Purpose:
;   Marks every current-level bomb active and chooses the first one as bonus.
;
; Modified:
;   A, B, X
;------------------------------------------------------------------------------
ResetBombs:
        ; Popup timers and active flags are parallel arrays indexed by bomb
        ; number. Clearing timers first prevents stale "200" sprites.
        ldx     #BombScorePopupTimers
        ldb     #BOMB_COUNT

ResetBombScorePopupTimersLoop:
        clr     ,x+
        decb
        bne     ResetBombScorePopupTimersLoop

        ldx     #BombActiveFlags
        ldb     #BOMB_COUNT

ResetBombsLoop:
        lda     #1
        sta     ,x+
        decb
        bne     ResetBombsLoop

        lda     #1
        sta     BombLitIndex
        rts
