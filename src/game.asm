;==============================================================================
; game.asm
;
; BUILD 008 static arena, player movement, bomb collection, bonus bombs,
; enemies, lives, death/respawn, game over, and level transitions.
;==============================================================================

;------------------------------------------------------------------------------
; InitGame
;
; Purpose:
;   Initializes the milestone 8 arena, player, bombs, score, highlighted bonus
;   bomb, enemies, lives, level state, and play state.
;
; Modified:
;   A, B, D, X, Y, U
;------------------------------------------------------------------------------
InitGame:
        jsr     InitHallOfFameDefaults
        jsr     ClearScreen
        jmp     EnterTitleScreen

StartNewGame:
        clr     CurrentLevel
        jsr     StartCurrentLevel
        clr     LevelTransitionTimer
        clr     LevelMessageColorIndex
        clr     LevelMessageColorCounter
        clr     DeathAnimStepPhase
        clr     DeathSpritePhase
        clr     RespawnWaitTimer
        clr     PlayerGraceTimer
        lda     #START_LIVES
        sta     LivesValue
        lda     #'0'
        sta     ScoreThousandsText
        sta     ScoreHundredsText
        sta     ScoreTensText
        sta     ScoreOnesText
        jsr     ClearGameArea
        jsr     DrawGameplayStatus
        jsr     DrawStaticArena
        jsr     DrawPlayer
        jmp     EnterGetReadyState

EnterTitleScreen:
        jsr     DrawScreenChrome
        jsr     DrawHudSidebar

EnterTitleScreenNoChrome:
        jsr     DrawTitleScreen
        jsr     ResetAttractScreenTimer
        lda     #GAME_STATE_TITLE
        sta     GameState
        rts

EnterHallOfFameScreen:
        jsr     DrawScreenChrome
        jsr     DrawHudSidebar

EnterHallOfFameScreenNoChrome:
        jsr     DrawHallOfFameScreen
        jsr     ResetAttractScreenTimer
        lda     #GAME_STATE_HALL_OF_FAME
        sta     GameState
        rts

ResetAttractScreenTimer:
        lda     #ATTRACT_SCREEN_FRAMES
        sta     AttractScreenTimer
        rts

TickAttractScreenTimer:
        lda     AttractScreenTimer
        beq     TickAttractScreenTimerElapsed
        deca
        sta     AttractScreenTimer
        beq     TickAttractScreenTimerElapsed
        clra
        rts

TickAttractScreenTimerElapsed:
        lda     #1
        rts

UpdateAttractCheat:
        lda     InfiniteLivesFlag
        bne     UpdateAttractCheatDone

        lda     NameKey_Press
        beq     UpdateAttractCheatDone
        ldb     CheatSqueeptyIndex
        ldx     #CheatSqueeptyText
        abx
        cmpa    ,x
        bne     UpdateAttractCheatMismatch

        inc     CheatSqueeptyIndex
        lda     CheatSqueeptyIndex
        cmpa    #CHEAT_SQUEEPTY_LEN
        blo     UpdateAttractCheatDone
        lda     #1
        sta     InfiniteLivesFlag
        clr     CheatSqueeptyIndex
        rts

UpdateAttractCheatMismatch:
        cmpa    #'S'
        bne     UpdateAttractCheatClear
        lda     #1
        sta     CheatSqueeptyIndex
        rts

UpdateAttractCheatClear:
        clr     CheatSqueeptyIndex

UpdateAttractCheatDone:
        rts

TryCheatNextLevel:
        lda     InfiniteLivesFlag
        beq     TryCheatNextLevelRelease

        lda     #KEY_N_SELECTOR
        sta     KEYBOARD_PORT
        lda     KEYBOARD_PORT
        bita    #$80
        bne     TryCheatNextLevelRelease

        lda     CheatNextLevelHeld
        bne     TryCheatNextLevelNo
        lda     #1
        sta     CheatNextLevelHeld
        jsr     StartNextLevelGetReady
        lda     #1
        rts

TryCheatNextLevelRelease:
        clr     CheatNextLevelHeld

TryCheatNextLevelNo:
        clra
        rts

;------------------------------------------------------------------------------
; RunGameFrame
;
; Purpose:
;   Runs one input/physics/render frame.
;
; Modified:
;   A, B, D, X, Y, U
;------------------------------------------------------------------------------
RunGameFrame:
        lda     GameState
        cmpa    #GAME_STATE_PLAYING
        lbeq    RunGameFramePlaying
        cmpa    #GAME_STATE_DYING
        lbeq    RunGameFrameDying
        cmpa    #GAME_STATE_RESPAWN_WAIT
        lbeq    RunGameFrameRespawnWait
        cmpa    #GAME_STATE_LEVEL_CLEAR
        lbeq    RunGameFrameLevelClear
        cmpa    #GAME_STATE_GET_READY
        lbeq    RunGameFrameGetReady
        cmpa    #GAME_STATE_NAME_ENTRY
        lbeq    RunGameFrameNameEntry
        cmpa    #GAME_STATE_HALL_OF_FAME
        lbeq    RunGameFrameHallOfFame
        cmpa    #GAME_STATE_TITLE
        lbeq    RunGameFrameTitle
        jsr     WaitFrame
        rts

RunGameFramePlaying:
        jsr     ReadInput
        jsr     TryCheatNextLevel
        lbne    RunGameFramePlayingWait
        jsr     SavePlayerRenderState
        jsr     SaveEnemyRenderState
        jsr     SavePowerRenderState
        jsr     SaveBonusItemRenderState
        jsr     SaveEnergyItemRenderState
        jsr     UpdatePlayer
        jsr     UpdatePlayerGraceTimer
        jsr     UpdatePowerSystem
        jsr     UpdateBonusItemSystem
        jsr     UpdateEnergyItemSystem
        jsr     CheckPowerCollection
        jsr     CheckBonusItemCollection
        jsr     CheckEnergyItemCollection
        ldd     PowerFreezeTimer
        bne     RunGameFrameEnemiesDone
        jsr     UpdateEnemy1All
        jsr     UpdateEnemy1SpawnSchedule
        lda     Enemy2Active
        beq     RunGameFrameEnemiesDone
        jsr     UpdateEnemy2

RunGameFrameEnemiesDone:
        jsr     CheckBombCollection
        lda     GameState
        cmpa    #GAME_STATE_PLAYING
        bne     RunGameFrameCollisionDone
        jsr     CheckEnemyCollision

RunGameFrameCollisionDone:
        clr     FrameStaticDirty
        jsr     UpdateBombScorePopup
        jsr     EraseEnemy1AllIfChanged
        jsr     EraseEnemy2IfChanged
        jsr     ErasePowerIfChanged
        jsr     EraseBonusItemIfChanged
        jsr     EraseEnergyItemIfChanged
        jsr     ErasePlayerIfChanged
        jsr     DrawStaticArenaIfDirty
        jsr     DrawPlayerIfChanged
        jsr     DrawEnemy1AllIfChanged
        jsr     DrawEnemy2IfChanged
        jsr     DrawPowerIfChanged
        jsr     DrawBonusItemIfChanged
        jsr     DrawEnergyItemIfChanged
        jsr     DrawBombScorePopup
        lda     GameState
        cmpa    #GAME_STATE_LEVEL_CLEAR
        bne     RunGameFramePlayingWait
        jsr     DrawWellDoneText

RunGameFramePlayingWait:
        jsr     WaitFrame
        rts

RunGameFrameDying:
        jsr     ReadInput
        clr     FrameStaticDirty
        jsr     SavePlayerRenderState
        jsr     UpdateDeathState
        lda     GameState
        cmpa    #GAME_STATE_DYING
        bne     RunGameFrameDyingWait
        jsr     ErasePlayerIfChanged
        lda     FrameStaticDirty
        beq     RunGameFrameDyingDrawPlayer
        jsr     DrawStaticArena
        jsr     DrawEnemy1All
        jsr     DrawEnemy2
        jsr     DrawPower
        jsr     DrawBonusItem
        jsr     DrawEnergyItem

RunGameFrameDyingDrawPlayer:
        jsr     DrawPlayerIfChanged

RunGameFrameDyingWait:
        jsr     WaitFrame
        rts

RunGameFrameRespawnWait:
        jsr     ReadInput
        clr     FrameStaticDirty
        jsr     SavePlayerRenderState
        jsr     UpdateRespawnWaitState
        jsr     ErasePlayerIfChanged
        lda     FrameStaticDirty
        beq     RunGameFrameRespawnWaitDrawPlayer
        jsr     DrawStaticArena
        jsr     DrawEnemy1All
        jsr     DrawEnemy2
        jsr     DrawPower
        jsr     DrawBonusItem
        jsr     DrawEnergyItem

RunGameFrameRespawnWaitDrawPlayer:
        jsr     DrawPlayerIfChanged
        jsr     WaitFrame
        rts

RunGameFrameLevelClear:
        jsr     UpdateBombScorePopup
        jsr     DrawStaticArenaIfDirty
        jsr     DrawBombScorePopup
        jsr     UpdateLevelClearState
        jsr     WaitFrame
        rts

RunGameFrameGetReady:
        jsr     UpdateGetReadyState
        jsr     WaitFrame
        rts

RunGameFrameNameEntry:
        jsr     ReadInput
        jsr     ReadNameKeyboardHardware
        jsr     UpdateNameEntryState
        jsr     WaitFrame
        rts

RunGameFrameHallOfFame:
        jsr     ReadInput
        jsr     ReadNameKeyboardHardware
        jsr     UpdateAttractCheat
        lda     Fire_Press
        bita    #c1_button_A_mask
        beq     RunGameFrameHallOfFameTick
        jsr     EnterTitleScreenNoChrome
        bra     RunGameFrameHallOfFameWait

RunGameFrameHallOfFameTick:
        jsr     TickAttractScreenTimer
        tsta
        beq     RunGameFrameHallOfFameWait
        jsr     EnterTitleScreenNoChrome

RunGameFrameHallOfFameWait:
        jsr     WaitFrame
        rts

RunGameFrameTitle:
        jsr     ReadInput
        jsr     ReadNameKeyboardHardware
        jsr     UpdateAttractCheat
        lda     Fire_Press
        bita    #c1_button_A_mask
        beq     RunGameFrameTitleTick
        jsr     StartNewGame
        bra     RunGameFrameTitleWait

RunGameFrameTitleTick:
        jsr     TickAttractScreenTimer
        tsta
        beq     RunGameFrameTitleWait
        jsr     EnterHallOfFameScreenNoChrome

RunGameFrameTitleWait:
        jsr     WaitFrame
        rts

;------------------------------------------------------------------------------
; SavePlayerRenderState
;
; Purpose:
;   Remembers the currently drawn player cell before simulation can move or
;   retarget the sprite for this frame.
;
; Modified:
;   A
;------------------------------------------------------------------------------
SavePlayerRenderState:
        lda     PlayerCol
        sta     PlayerPrevCol
        lda     PlayerRow
        sta     PlayerPrevRow
        lda     PlayerSprite
        sta     PlayerPrevSprite
        jsr     IsPlayerRenderVisible
        sta     PlayerPrevGraceBlinkVisible
        rts

;------------------------------------------------------------------------------
; SaveEnemyRenderState
;
; Purpose:
;   Remembers the currently drawn enemy cell before the patrol update.
;
; Modified:
;   A
;------------------------------------------------------------------------------
SaveEnemyRenderState:
        lda     Enemy1Col
        sta     Enemy1PrevCol
        lda     Enemy1Row
        sta     Enemy1PrevRow
        lda     Enemy1Sprite
        sta     Enemy1PrevSprite
        lda     Enemy1State
        sta     Enemy1PrevState
        lda     Enemy1Slot2Col
        sta     Enemy1Slot2PrevCol
        lda     Enemy1Slot2Row
        sta     Enemy1Slot2PrevRow
        lda     Enemy1Slot2Sprite
        sta     Enemy1Slot2PrevSprite
        lda     Enemy1Slot2State
        sta     Enemy1Slot2PrevState
        lda     Enemy1Slot3Col
        sta     Enemy1Slot3PrevCol
        lda     Enemy1Slot3Row
        sta     Enemy1Slot3PrevRow
        lda     Enemy1Slot3Sprite
        sta     Enemy1Slot3PrevSprite
        lda     Enemy1Slot3State
        sta     Enemy1Slot3PrevState
        lda     Enemy1Slot4Col
        sta     Enemy1Slot4PrevCol
        lda     Enemy1Slot4Row
        sta     Enemy1Slot4PrevRow
        lda     Enemy1Slot4Sprite
        sta     Enemy1Slot4PrevSprite
        lda     Enemy1Slot4State
        sta     Enemy1Slot4PrevState
        lda     Enemy2Col
        sta     Enemy2PrevCol
        lda     Enemy2Row
        sta     Enemy2PrevRow
        lda     Enemy2Active
        sta     Enemy2PrevActive
        rts

;------------------------------------------------------------------------------
; SavePowerRenderState
;
; Purpose:
;   Remembers the currently drawn power-up before it can move or despawn.
;
; Modified:
;   A, B, D
;------------------------------------------------------------------------------
SavePowerRenderState:
        lda     PowerCol
        sta     PowerPrevCol
        lda     PowerRow
        sta     PowerPrevRow
        lda     PowerActive
        sta     PowerPrevActive
        ldd     PowerFreezeTimer
        beq     SavePowerRenderNoFreeze
        lda     #1
        bra     SavePowerRenderFreezeStore

SavePowerRenderNoFreeze:
        clra

SavePowerRenderFreezeStore:
        sta     PowerPrevFreezeActive
        jsr     IsPowerFreezeBlinkVisible
        sta     PowerPrevFreezeBlinkVisible
        rts

SaveBonusItemRenderState:
        lda     BonusItemCol
        sta     BonusItemPrevCol
        lda     BonusItemRow
        sta     BonusItemPrevRow
        lda     BonusItemActive
        sta     BonusItemPrevActive
        rts

SaveEnergyItemRenderState:
        lda     EnergyItemCol
        sta     EnergyItemPrevCol
        lda     EnergyItemRow
        sta     EnergyItemPrevRow
        lda     EnergyItemActive
        sta     EnergyItemPrevActive
        rts

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
        clra
        ldb     CurrentLevel
        lslb
        ldx     #LevelBombTable
        ldu     d,x
        stu     CurrentBombPositions
        rts

SetCurrentLevelPlatformPositions:
        clra
        ldb     CurrentLevel
        lslb
        ldx     #LevelPlatformTable
        ldu     d,x
        ldx     #CurrentPlatform1Row
        lda     #PLATFORM_RUN_COUNT
        sta     PlatformScanRemaining

SetCurrentLevelPlatformLoop:
        lda     ,u+
        sta     ,x+
        lda     ,u+
        sta     ,x+
        sta     CheckRunStart
        lda     ,u+
        sta     ,x+
        adda    CheckRunStart
        deca
        sta     ,x+
        dec     PlatformScanRemaining
        bne     SetCurrentLevelPlatformLoop
        rts

ResetPlayerForLevel:
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

;------------------------------------------------------------------------------
; UpdatePlayer

;
; Purpose:
;   Applies left/right movement, jump, gravity, and landing.
;
; Modified:
;   A, B
;------------------------------------------------------------------------------
UpdatePlayer:
        jsr     UpdateHorizontal
        jsr     RefreshGroundState
        jsr     TryJump
        jsr     ApplyVertical
        jsr     UpdatePlayerSprite
        rts

UpdatePlayerGraceTimer:
        lda     PlayerGraceTimer
        beq     UpdatePlayerGraceTimerDone
        dec     PlayerGraceTimer

UpdatePlayerGraceTimerDone:
        rts

;------------------------------------------------------------------------------
; UpdatePowerSystem
;
; Purpose:
;   Schedules, moves, and times the power-up/frozen-enemy grace period.
;
; Modified:
;   A, B, D, X
;------------------------------------------------------------------------------
UpdatePowerSystem:
        ldd     PowerFreezeTimer
        beq     UpdatePowerNoFreeze

        subd    #1
        std     PowerFreezeTimer
        lbne    UpdatePowerDone
        jsr     EndPowerFreeze
        rts

UpdatePowerNoFreeze:
        lda     PowerActive
        cmpa    #POWER_ACTIVE
        beq     UpdatePowerMove

        lda     PowerSpawnArmed
        lbeq    UpdatePowerDone
        ldd     PowerSpawnTimer
        beq     SpawnPower
        subd    #1
        std     PowerSpawnTimer
        lbne    UpdatePowerDone

SpawnPower:
        jsr     AdvancePowerSeed
        anda    #7
        tfr     a,b
        ldx     #PowerSpawnCols
        lda     b,x
        sta     PowerCol
        ldx     #PowerSpawnRows
        lda     b,x
        sta     PowerRow

        jsr     AdvancePowerSeed
        bita    #1
        beq     SpawnPowerRight
        lda     #ENEMY_MOVE_LEFT
        bra     SpawnPowerStoreDirX

SpawnPowerRight:
        lda     #ENEMY_MOVE_RIGHT

SpawnPowerStoreDirX:
        sta     PowerDirX

        lda     PowerSeed
        bita    #2
        beq     SpawnPowerDown
        lda     #ENEMY_MOVE_UP
        bra     SpawnPowerStoreDirY

SpawnPowerDown:
        lda     #ENEMY_MOVE_DOWN

SpawnPowerStoreDirY:
        sta     PowerDirY
        clr     PowerMoveCounter
        lda     #POWER_ACTIVE
        sta     PowerActive
        clr     PowerSpawnArmed
        rts

UpdatePowerMove:
        inc     PowerMoveCounter
        lda     PowerMoveCounter
        cmpa    #POWER_STEP_FRAMES
        lblo    UpdatePowerDone
        clr     PowerMoveCounter

        lda     PowerDirX
        bmi     UpdatePowerMoveLeft

        lda     PowerCol
        cmpa    #POWER_MAX_COL
        blo     UpdatePowerTryRight
UpdatePowerBounceLeft:
        lda     #ENEMY_MOVE_LEFT
        sta     PowerDirX
        lda     PowerCol
        cmpa    #POWER_MIN_COL
        bls     UpdatePowerMoveY
        dec     PowerCol
        bra     UpdatePowerMoveY

UpdatePowerTryRight:
        inca
        ldb     PowerRow
        jsr     IsEnemyFootprintBlockedAtAB
        bne     UpdatePowerBounceLeft
        inc     PowerCol
        bra     UpdatePowerMoveY

UpdatePowerMoveLeft:
        lda     PowerCol
        cmpa    #POWER_MIN_COL
        bhi     UpdatePowerTryLeft
UpdatePowerBounceRight:
        lda     #ENEMY_MOVE_RIGHT
        sta     PowerDirX
        lda     PowerCol
        cmpa    #POWER_MAX_COL
        bhs     UpdatePowerMoveY
        inc     PowerCol
        bra     UpdatePowerMoveY

UpdatePowerTryLeft:
        deca
        ldb     PowerRow
        jsr     IsEnemyFootprintBlockedAtAB
        bne     UpdatePowerBounceRight
        dec     PowerCol

UpdatePowerMoveY:
        lda     PowerDirY
        bmi     UpdatePowerMoveUp

        lda     PowerRow
        cmpa    #POWER_MAX_ROW
        blo     UpdatePowerTryDown
UpdatePowerBounceUp:
        lda     #ENEMY_MOVE_UP
        sta     PowerDirY
        lda     PowerRow
        cmpa    #POWER_MIN_ROW
        bls     UpdatePowerDone
        dec     PowerRow
        bra     UpdatePowerDone

UpdatePowerTryDown:
        ldb     PowerRow
        incb
        lda     PowerCol
        jsr     IsEnemyFootprintBlockedAtAB
        bne     UpdatePowerBounceUp
        inc     PowerRow
        bra     UpdatePowerDone

UpdatePowerMoveUp:
        lda     PowerRow
        cmpa    #POWER_MIN_ROW
        bhi     UpdatePowerTryUp
UpdatePowerBounceDown:
        lda     #ENEMY_MOVE_DOWN
        sta     PowerDirY
        lda     PowerRow
        cmpa    #POWER_MAX_ROW
        bhs     UpdatePowerDone
        inc     PowerRow
        bra     UpdatePowerDone

UpdatePowerTryUp:
        ldb     PowerRow
        decb
        lda     PowerCol
        jsr     IsEnemyFootprintBlockedAtAB
        bne     UpdatePowerBounceDown
        dec     PowerRow

UpdatePowerDone:
        rts

CheckPowerCollection:
        lda     PowerActive
        cmpa    #POWER_ACTIVE
        bne     CheckPowerCollectionDone
        lda     PowerCol
        ldb     PowerRow
        jsr     IsPlayerOverEnemyAtAB
        beq     CheckPowerCollectionDone

        clr     PowerActive
        clr     PowerSpawnArmed
        ldd     #POWER_FREEZE_FRAMES
        std     PowerFreezeTimer
        lda     #1
        sta     EnergyItemSpawnArmed
        ldd     #ENERGY_ITEM_SPAWN_AFTER_POWER_FRAMES
        std     EnergyItemSpawnTimer
        jsr     ForcePlayerRedraw

CheckPowerCollectionDone:
        rts

UpdateBonusItemSystem:
        lda     BonusItemActive
        cmpa    #BONUS_ITEM_ACTIVE
        beq     UpdateBonusItemMove

        lda     BonusItemSpawnArmed
        lbeq    UpdateBonusItemDone
        ldd     BonusItemSpawnTimer
        beq     SpawnBonusItem
        subd    #1
        std     BonusItemSpawnTimer
        lbne    UpdateBonusItemDone

SpawnBonusItem:
        lda     BonusItemSeed
        eora    Enemy2AiSeed
        eora    Enemy1SpawnSeed
        bne     SpawnBonusItemSeedStore
        lda     #$7D

SpawnBonusItemSeedStore:
        sta     BonusItemSeed
        jsr     AdvanceBonusItemSeed
        anda    #7
        tfr     a,b
        ldx     #PowerSpawnCols
        lda     b,x
        sta     BonusItemCol
        ldx     #PowerSpawnRows
        lda     b,x
        sta     BonusItemRow

        jsr     AdvanceBonusItemSeed
        bita    #1
        beq     SpawnBonusItemRight
        lda     #ENEMY_MOVE_LEFT
        bra     SpawnBonusItemStoreDirX

SpawnBonusItemRight:
        lda     #ENEMY_MOVE_RIGHT

SpawnBonusItemStoreDirX:
        sta     BonusItemDirX

        lda     BonusItemSeed
        bita    #2
        beq     SpawnBonusItemDown
        lda     #ENEMY_MOVE_UP
        bra     SpawnBonusItemStoreDirY

SpawnBonusItemDown:
        lda     #ENEMY_MOVE_DOWN

SpawnBonusItemStoreDirY:
        sta     BonusItemDirY
        clr     BonusItemMoveCounter
        lda     #BONUS_ITEM_ACTIVE
        sta     BonusItemActive
        clr     BonusItemSpawnArmed
        rts

UpdateBonusItemMove:
        inc     BonusItemMoveCounter
        lda     BonusItemMoveCounter
        cmpa    #POWER_STEP_FRAMES
        lblo    UpdateBonusItemDone
        clr     BonusItemMoveCounter

        lda     BonusItemDirX
        bmi     UpdateBonusItemMoveLeft

        lda     BonusItemCol
        cmpa    #POWER_MAX_COL
        blo     UpdateBonusItemTryRight
UpdateBonusItemBounceLeft:
        lda     #ENEMY_MOVE_LEFT
        sta     BonusItemDirX
        lda     BonusItemCol
        cmpa    #POWER_MIN_COL
        bls     UpdateBonusItemMoveY
        dec     BonusItemCol
        bra     UpdateBonusItemMoveY

UpdateBonusItemTryRight:
        inca
        ldb     BonusItemRow
        jsr     IsEnemyFootprintBlockedAtAB
        bne     UpdateBonusItemBounceLeft
        inc     BonusItemCol
        bra     UpdateBonusItemMoveY

UpdateBonusItemMoveLeft:
        lda     BonusItemCol
        cmpa    #POWER_MIN_COL
        bhi     UpdateBonusItemTryLeft
UpdateBonusItemBounceRight:
        lda     #ENEMY_MOVE_RIGHT
        sta     BonusItemDirX
        lda     BonusItemCol
        cmpa    #POWER_MAX_COL
        bhs     UpdateBonusItemMoveY
        inc     BonusItemCol
        bra     UpdateBonusItemMoveY

UpdateBonusItemTryLeft:
        deca
        ldb     BonusItemRow
        jsr     IsEnemyFootprintBlockedAtAB
        bne     UpdateBonusItemBounceRight
        dec     BonusItemCol

UpdateBonusItemMoveY:
        lda     BonusItemDirY
        bmi     UpdateBonusItemMoveUp

        lda     BonusItemRow
        cmpa    #POWER_MAX_ROW
        blo     UpdateBonusItemTryDown
UpdateBonusItemBounceUp:
        lda     #ENEMY_MOVE_UP
        sta     BonusItemDirY
        lda     BonusItemRow
        cmpa    #POWER_MIN_ROW
        bls     UpdateBonusItemDone
        dec     BonusItemRow
        bra     UpdateBonusItemDone

UpdateBonusItemTryDown:
        ldb     BonusItemRow
        incb
        lda     BonusItemCol
        jsr     IsEnemyFootprintBlockedAtAB
        bne     UpdateBonusItemBounceUp
        inc     BonusItemRow
        bra     UpdateBonusItemDone

UpdateBonusItemMoveUp:
        lda     BonusItemRow
        cmpa    #POWER_MIN_ROW
        bhi     UpdateBonusItemTryUp
UpdateBonusItemBounceDown:
        lda     #ENEMY_MOVE_DOWN
        sta     BonusItemDirY
        lda     BonusItemRow
        cmpa    #POWER_MAX_ROW
        bhs     UpdateBonusItemDone
        inc     BonusItemRow
        bra     UpdateBonusItemDone

UpdateBonusItemTryUp:
        ldb     BonusItemRow
        decb
        lda     BonusItemCol
        jsr     IsEnemyFootprintBlockedAtAB
        bne     UpdateBonusItemBounceDown
        dec     BonusItemRow

UpdateBonusItemDone:
        rts

CheckBonusItemCollection:
        lda     BonusItemActive
        cmpa    #BONUS_ITEM_ACTIVE
        bne     CheckBonusItemCollectionDone
        lda     BonusItemCol
        ldb     BonusItemRow
        jsr     IsPlayerOverEnemyAtAB
        beq     CheckBonusItemCollectionDone

        clr     BonusItemActive
        clr     BonusItemSpawnArmed
        clr     BonusItemSpawnTimer
        clr     BonusItemSpawnTimer+1
        lda     #1
        sta     PowerSpawnArmed
        ldd     #POWER_SPAWN_AFTER_BONUS_FRAMES
        std     PowerSpawnTimer
        jsr     AddBonusItemScore
        jsr     ForcePlayerRedraw

CheckBonusItemCollectionDone:
        rts

AdvanceBonusItemSeed:
        lda     BonusItemSeed
        lsra
        bcc     AdvanceBonusItemSeedStore
        eora    #$B8

AdvanceBonusItemSeedStore:
        sta     BonusItemSeed
        rts

UpdateEnergyItemSystem:
        lda     EnergyItemActive
        cmpa    #ENERGY_ITEM_ACTIVE
        beq     UpdateEnergyItemMove

        lda     EnergyItemSpawnArmed
        lbeq    UpdateEnergyItemDone
        ldd     EnergyItemSpawnTimer
        beq     SpawnEnergyItem
        subd    #1
        std     EnergyItemSpawnTimer
        lbne    UpdateEnergyItemDone

SpawnEnergyItem:
        lda     EnergyItemSeed
        eora    Enemy1Phase2AiSeed
        eora    Enemy2AiSeed
        bne     SpawnEnergyItemSeedStore
        lda     #$B5

SpawnEnergyItemSeedStore:
        sta     EnergyItemSeed
        jsr     AdvanceEnergyItemSeed
        anda    #7
        tfr     a,b
        ldx     #PowerSpawnCols
        lda     b,x
        sta     EnergyItemCol
        ldx     #PowerSpawnRows
        lda     b,x
        sta     EnergyItemRow

        jsr     AdvanceEnergyItemSeed
        bita    #1
        beq     SpawnEnergyItemRight
        lda     #ENEMY_MOVE_LEFT
        bra     SpawnEnergyItemStoreDirX

SpawnEnergyItemRight:
        lda     #ENEMY_MOVE_RIGHT

SpawnEnergyItemStoreDirX:
        sta     EnergyItemDirX

        lda     EnergyItemSeed
        bita    #2
        beq     SpawnEnergyItemDown
        lda     #ENEMY_MOVE_UP
        bra     SpawnEnergyItemStoreDirY

SpawnEnergyItemDown:
        lda     #ENEMY_MOVE_DOWN

SpawnEnergyItemStoreDirY:
        sta     EnergyItemDirY
        clr     EnergyItemMoveCounter
        lda     #ENERGY_ITEM_ACTIVE
        sta     EnergyItemActive
        clr     EnergyItemSpawnArmed
        rts

UpdateEnergyItemMove:
        inc     EnergyItemMoveCounter
        lda     EnergyItemMoveCounter
        cmpa    #POWER_STEP_FRAMES
        lblo    UpdateEnergyItemDone
        clr     EnergyItemMoveCounter

        lda     EnergyItemDirX
        bmi     UpdateEnergyItemMoveLeft

        lda     EnergyItemCol
        cmpa    #POWER_MAX_COL
        blo     UpdateEnergyItemTryRight
UpdateEnergyItemBounceLeft:
        lda     #ENEMY_MOVE_LEFT
        sta     EnergyItemDirX
        lda     EnergyItemCol
        cmpa    #POWER_MIN_COL
        bls     UpdateEnergyItemMoveY
        dec     EnergyItemCol
        bra     UpdateEnergyItemMoveY

UpdateEnergyItemTryRight:
        inca
        ldb     EnergyItemRow
        jsr     IsEnemyFootprintBlockedAtAB
        bne     UpdateEnergyItemBounceLeft
        inc     EnergyItemCol
        bra     UpdateEnergyItemMoveY

UpdateEnergyItemMoveLeft:
        lda     EnergyItemCol
        cmpa    #POWER_MIN_COL
        bhi     UpdateEnergyItemTryLeft
UpdateEnergyItemBounceRight:
        lda     #ENEMY_MOVE_RIGHT
        sta     EnergyItemDirX
        lda     EnergyItemCol
        cmpa    #POWER_MAX_COL
        bhs     UpdateEnergyItemMoveY
        inc     EnergyItemCol
        bra     UpdateEnergyItemMoveY

UpdateEnergyItemTryLeft:
        deca
        ldb     EnergyItemRow
        jsr     IsEnemyFootprintBlockedAtAB
        bne     UpdateEnergyItemBounceRight
        dec     EnergyItemCol

UpdateEnergyItemMoveY:
        lda     EnergyItemDirY
        bmi     UpdateEnergyItemMoveUp

        lda     EnergyItemRow
        cmpa    #POWER_MAX_ROW
        blo     UpdateEnergyItemTryDown
UpdateEnergyItemBounceUp:
        lda     #ENEMY_MOVE_UP
        sta     EnergyItemDirY
        lda     EnergyItemRow
        cmpa    #POWER_MIN_ROW
        bls     UpdateEnergyItemDone
        dec     EnergyItemRow
        bra     UpdateEnergyItemDone

UpdateEnergyItemTryDown:
        ldb     EnergyItemRow
        incb
        lda     EnergyItemCol
        jsr     IsEnemyFootprintBlockedAtAB
        bne     UpdateEnergyItemBounceUp
        inc     EnergyItemRow
        bra     UpdateEnergyItemDone

UpdateEnergyItemMoveUp:
        lda     EnergyItemRow
        cmpa    #POWER_MIN_ROW
        bhi     UpdateEnergyItemTryUp
UpdateEnergyItemBounceDown:
        lda     #ENEMY_MOVE_DOWN
        sta     EnergyItemDirY
        lda     EnergyItemRow
        cmpa    #POWER_MAX_ROW
        bhs     UpdateEnergyItemDone
        inc     EnergyItemRow
        bra     UpdateEnergyItemDone

UpdateEnergyItemTryUp:
        ldb     EnergyItemRow
        decb
        lda     EnergyItemCol
        jsr     IsEnemyFootprintBlockedAtAB
        bne     UpdateEnergyItemBounceDown
        dec     EnergyItemRow

UpdateEnergyItemDone:
        rts

CheckEnergyItemCollection:
        lda     EnergyItemActive
        cmpa    #ENERGY_ITEM_ACTIVE
        bne     CheckEnergyItemCollectionDone
        lda     EnergyItemCol
        ldb     EnergyItemRow
        jsr     IsPlayerOverEnemyAtAB
        beq     CheckEnergyItemCollectionDone

        clr     EnergyItemActive
        clr     EnergyItemSpawnArmed
        clr     EnergyItemSpawnTimer
        clr     EnergyItemSpawnTimer+1
        jsr     AddEnergyItemLife
        jsr     ForcePlayerRedraw

CheckEnergyItemCollectionDone:
        rts

AddEnergyItemLife:
        lda     LivesValue
        cmpa    #START_LIVES
        bhs     AddEnergyItemLifeDone
        inc     LivesValue
        jsr     DrawLives

AddEnergyItemLifeDone:
        rts

AdvanceEnergyItemSeed:
        lda     EnergyItemSeed
        lsra
        bcc     AdvanceEnergyItemSeedStore
        eora    #$B8

AdvanceEnergyItemSeedStore:
        sta     EnergyItemSeed
        rts

EndPowerFreeze:
        jsr     RespawnEnemy2AfterPowerIfEaten
        jmp     DisablePowerSpawn

RespawnEnemy2AfterPowerIfEaten:
        lda     Enemy2Active
        beq     RespawnEnemy2
        rts

RespawnEnemy2:
        lda     #ENEMY2_START_COL
        sta     Enemy2Col
        lda     #ENEMY2_START_ROW
        sta     Enemy2Row
        lda     #ENEMY_MOVE_RIGHT
        sta     Enemy2Dir
        lda     #ENEMY2_FRAME_STAGGER
        sta     Enemy2FrameCounter
        lda     #ENEMY2_AI_SEED
        sta     Enemy2AiSeed
        lda     #1
        sta     Enemy2Active
        rts

ArmPowerSpawnAfterPhase3:
        rts

DisablePowerSpawn:
        clr     PowerSpawnArmed
        clr     PowerSpawnTimer
        clr     PowerSpawnTimer+1
        rts

AdvancePowerSeed:
        lda     PowerSeed
        lsra
        bcc     AdvancePowerSeedStore
        eora    #$B8

AdvancePowerSeedStore:
        sta     PowerSeed

        rts

;------------------------------------------------------------------------------
; UpdateEnemy1All
;
; Purpose:
;   Updates every active enemy-1 slot by reusing the single-enemy work routines.
;
; Modified:
;   A, B, X
;------------------------------------------------------------------------------
UpdateEnemy1All:
        lda     Enemy1State
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     UpdateEnemy1AllSave
        jsr     UpdateEnemy1

UpdateEnemy1AllSave:
        jsr     SaveEnemy1WorkVars

        lda     Enemy1Slot2State
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     UpdateEnemy1AllSlot3
        jsr     LoadEnemy1Slot2
        jsr     UpdateEnemy1
        jsr     StoreEnemy1Slot2Current

UpdateEnemy1AllSlot3:
        lda     Enemy1Slot3State
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     UpdateEnemy1AllSlot4
        jsr     LoadEnemy1Slot3
        jsr     UpdateEnemy1
        jsr     StoreEnemy1Slot3Current

UpdateEnemy1AllSlot4:
        lda     Enemy1Slot4State
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     UpdateEnemy1AllDone
        jsr     LoadEnemy1Slot4
        jsr     UpdateEnemy1
        jsr     StoreEnemy1Slot4Current

UpdateEnemy1AllDone:
        jmp     RestoreEnemy1WorkVars

;------------------------------------------------------------------------------
; UpdateEnemy1SpawnSchedule
;
; Purpose:
;   Spawns one additional enemy 1 every 5 seconds until four enemy-1 slots are
;   active at once. Timing uses the temporary active-play tick scale until the
;   build gains a 50 Hz IRQ.
;
; Modified:
;   A, B, D, X
;------------------------------------------------------------------------------
UpdateEnemy1SpawnSchedule:
        ldd     PowerFreezeTimer
        bne     UpdateEnemy1SpawnDone
        lda     Enemy1State
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     UpdateEnemy1SpawnClock
        lda     Enemy1Slot2State
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     UpdateEnemy1SpawnClock
        lda     Enemy1Slot3State
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     UpdateEnemy1SpawnClock
        lda     Enemy1Slot4State
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     UpdateEnemy1SpawnClock

UpdateEnemy1SpawnDone:
        rts

UpdateEnemy1SpawnClock:
        ldd     Enemy1SpawnFrameCounter
        addd    #1
        cmpd    #ENEMY1_SPAWN_INTERVAL_FRAMES
        blo     UpdateEnemy1SpawnClockStore

        clra
        clrb
        std     Enemy1SpawnFrameCounter
        jmp     SpawnNextEnemy1Slot

UpdateEnemy1SpawnClockStore:
        std     Enemy1SpawnFrameCounter
        rts

SpawnNextEnemy1Slot:
        lda     Enemy1State
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     SpawnEnemy1Slot1

        lda     Enemy1Slot2State
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     SpawnEnemy1Slot2

        lda     Enemy1Slot3State
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     SpawnEnemy1Slot3

        lda     Enemy1Slot4State
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     SpawnEnemy1Slot4
        rts

SpawnEnemy1Slot1:
        lda     #ENEMY1_PERSONALITY_BALANCED
        sta     Enemy1Personality
        lda     #ENEMY1_STEP_FRAMES
        sta     Enemy1StepFrames
        lda     #ENEMY1_PHASE2_STEP_FRAMES
        sta     Enemy1Phase2StepFrames
        lda     #ENEMY1_PHASE2_CHASE_RATE
        sta     Enemy1Phase2ChaseRate
        jsr     StartEnemy1SpawnEffect
        lda     #ENEMY1_STATE_INACTIVE
        sta     Enemy1PrevState
        rts

SpawnEnemy1Slot2:
        jsr     SaveEnemy1WorkVars
        jsr     StartEnemy1SpawnEffect
        lda     #ENEMY1_PERSONALITY_FLANKER
        sta     Enemy1Personality
        lda     #ENEMY1_SLOT2_STEP_FRAMES
        sta     Enemy1StepFrames
        lda     #ENEMY1_SLOT2_PHASE2_STEP_FRAMES
        sta     Enemy1Phase2StepFrames
        lda     #ENEMY1_SLOT2_PHASE2_CHASE_RATE
        sta     Enemy1Phase2ChaseRate
        jsr     StoreEnemy1Slot2Current
        lda     #ENEMY1_STATE_INACTIVE
        sta     Enemy1Slot2PrevState
        jmp     RestoreEnemy1WorkVars

SpawnEnemy1Slot3:
        jsr     SaveEnemy1WorkVars
        jsr     StartEnemy1SpawnEffect
        lda     #ENEMY1_PERSONALITY_DRIFTER
        sta     Enemy1Personality
        lda     #ENEMY1_SLOT3_STEP_FRAMES
        sta     Enemy1StepFrames
        lda     #ENEMY1_SLOT3_PHASE2_STEP_FRAMES
        sta     Enemy1Phase2StepFrames
        lda     #ENEMY1_SLOT3_PHASE2_CHASE_RATE
        sta     Enemy1Phase2ChaseRate
        jsr     StoreEnemy1Slot3Current
        lda     #ENEMY1_STATE_INACTIVE
        sta     Enemy1Slot3PrevState
        jmp     RestoreEnemy1WorkVars

SpawnEnemy1Slot4:
        jsr     SaveEnemy1WorkVars
        jsr     StartEnemy1SpawnEffect
        lda     #ENEMY1_PERSONALITY_PHASE3
        sta     Enemy1Personality
        lda     #ENEMY1_SLOT4_STEP_FRAMES
        sta     Enemy1StepFrames
        lda     #ENEMY1_SLOT4_PHASE3_STEP_FRAMES
        sta     Enemy1Phase2StepFrames
        lda     #ENEMY1_SLOT4_PHASE3_CHASE_RATE
        sta     Enemy1Phase2ChaseRate
        jsr     StoreEnemy1Slot4Current
        lda     #ENEMY1_STATE_INACTIVE
        sta     Enemy1Slot4PrevState
        jmp     RestoreEnemy1WorkVars

SaveEnemy1WorkVars:
        lda     Enemy1Col
        sta     Enemy1SavedCol
        lda     Enemy1Row
        sta     Enemy1SavedRow
        lda     Enemy1PrevCol
        sta     Enemy1SavedPrevCol
        lda     Enemy1PrevRow
        sta     Enemy1SavedPrevRow
        lda     Enemy1PrevSprite
        sta     Enemy1SavedPrevSprite
        lda     Enemy1PrevState
        sta     Enemy1SavedPrevState
        lda     Enemy1Dir
        sta     Enemy1SavedDir
        lda     Enemy1FrameCounter
        sta     Enemy1SavedFrameCounter
        lda     Enemy1Phase2AiSeed
        sta     Enemy1SavedPhase2AiSeed
        lda     Enemy1StepFrames
        sta     Enemy1SavedStepFrames
        lda     Enemy1Phase2StepFrames
        sta     Enemy1SavedPhase2StepFrames
        lda     Enemy1Phase2ChaseRate
        sta     Enemy1SavedPhase2ChaseRate
        lda     Enemy1Personality
        sta     Enemy1SavedPersonality
        lda     Enemy1SpawnTimer
        sta     Enemy1SavedSpawnTimer
        lda     Enemy1State
        sta     Enemy1SavedState
        lda     Enemy1Sprite
        sta     Enemy1SavedSprite
        rts

RestoreEnemy1WorkVars:
        lda     Enemy1SavedCol
        sta     Enemy1Col
        lda     Enemy1SavedRow
        sta     Enemy1Row
        lda     Enemy1SavedPrevCol
        sta     Enemy1PrevCol
        lda     Enemy1SavedPrevRow
        sta     Enemy1PrevRow
        lda     Enemy1SavedPrevSprite
        sta     Enemy1PrevSprite
        lda     Enemy1SavedPrevState
        sta     Enemy1PrevState
        lda     Enemy1SavedDir
        sta     Enemy1Dir
        lda     Enemy1SavedFrameCounter
        sta     Enemy1FrameCounter
        lda     Enemy1SavedPhase2AiSeed
        sta     Enemy1Phase2AiSeed
        lda     Enemy1SavedStepFrames
        sta     Enemy1StepFrames
        lda     Enemy1SavedPhase2StepFrames
        sta     Enemy1Phase2StepFrames
        lda     Enemy1SavedPhase2ChaseRate
        sta     Enemy1Phase2ChaseRate
        lda     Enemy1SavedPersonality
        sta     Enemy1Personality
        lda     Enemy1SavedSpawnTimer
        sta     Enemy1SpawnTimer
        lda     Enemy1SavedState
        sta     Enemy1State
        lda     Enemy1SavedSprite
        sta     Enemy1Sprite
        rts

LoadEnemy1Slot2:
        lda     Enemy1Slot2Col
        sta     Enemy1Col
        lda     Enemy1Slot2Row
        sta     Enemy1Row
        lda     Enemy1Slot2PrevCol
        sta     Enemy1PrevCol
        lda     Enemy1Slot2PrevRow
        sta     Enemy1PrevRow
        lda     Enemy1Slot2PrevSprite
        sta     Enemy1PrevSprite
        lda     Enemy1Slot2PrevState
        sta     Enemy1PrevState
        lda     Enemy1Slot2Dir
        sta     Enemy1Dir
        lda     Enemy1Slot2FrameCounter
        sta     Enemy1FrameCounter
        lda     Enemy1Slot2Phase2AiSeed
        sta     Enemy1Phase2AiSeed
        lda     Enemy1Slot2StepFrames
        sta     Enemy1StepFrames
        lda     Enemy1Slot2Phase2StepFrames
        sta     Enemy1Phase2StepFrames
        lda     Enemy1Slot2Phase2ChaseRate
        sta     Enemy1Phase2ChaseRate
        lda     Enemy1Slot2Personality
        sta     Enemy1Personality
        lda     Enemy1Slot2SpawnTimer
        sta     Enemy1SpawnTimer
        lda     Enemy1Slot2State
        sta     Enemy1State
        lda     Enemy1Slot2Sprite
        sta     Enemy1Sprite
        rts

StoreEnemy1Slot2Current:
        lda     Enemy1Col
        sta     Enemy1Slot2Col
        lda     Enemy1Row
        sta     Enemy1Slot2Row
        lda     Enemy1Dir
        sta     Enemy1Slot2Dir
        lda     Enemy1FrameCounter
        sta     Enemy1Slot2FrameCounter
        lda     Enemy1Phase2AiSeed
        sta     Enemy1Slot2Phase2AiSeed
        lda     Enemy1StepFrames
        sta     Enemy1Slot2StepFrames
        lda     Enemy1Phase2StepFrames
        sta     Enemy1Slot2Phase2StepFrames
        lda     Enemy1Phase2ChaseRate
        sta     Enemy1Slot2Phase2ChaseRate
        lda     Enemy1Personality
        sta     Enemy1Slot2Personality
        lda     Enemy1SpawnTimer
        sta     Enemy1Slot2SpawnTimer
        lda     Enemy1State
        sta     Enemy1Slot2State
        lda     Enemy1Sprite
        sta     Enemy1Slot2Sprite
        rts

LoadEnemy1Slot3:
        lda     Enemy1Slot3Col
        sta     Enemy1Col
        lda     Enemy1Slot3Row
        sta     Enemy1Row
        lda     Enemy1Slot3PrevCol
        sta     Enemy1PrevCol
        lda     Enemy1Slot3PrevRow
        sta     Enemy1PrevRow
        lda     Enemy1Slot3PrevSprite
        sta     Enemy1PrevSprite
        lda     Enemy1Slot3PrevState
        sta     Enemy1PrevState
        lda     Enemy1Slot3Dir
        sta     Enemy1Dir
        lda     Enemy1Slot3FrameCounter
        sta     Enemy1FrameCounter
        lda     Enemy1Slot3Phase2AiSeed
        sta     Enemy1Phase2AiSeed
        lda     Enemy1Slot3StepFrames
        sta     Enemy1StepFrames
        lda     Enemy1Slot3Phase2StepFrames
        sta     Enemy1Phase2StepFrames
        lda     Enemy1Slot3Phase2ChaseRate
        sta     Enemy1Phase2ChaseRate
        lda     Enemy1Slot3Personality
        sta     Enemy1Personality
        lda     Enemy1Slot3SpawnTimer
        sta     Enemy1SpawnTimer
        lda     Enemy1Slot3State
        sta     Enemy1State
        lda     Enemy1Slot3Sprite
        sta     Enemy1Sprite
        rts

StoreEnemy1Slot3Current:
        lda     Enemy1Col
        sta     Enemy1Slot3Col
        lda     Enemy1Row
        sta     Enemy1Slot3Row
        lda     Enemy1Dir
        sta     Enemy1Slot3Dir
        lda     Enemy1FrameCounter
        sta     Enemy1Slot3FrameCounter
        lda     Enemy1Phase2AiSeed
        sta     Enemy1Slot3Phase2AiSeed
        lda     Enemy1StepFrames
        sta     Enemy1Slot3StepFrames
        lda     Enemy1Phase2StepFrames
        sta     Enemy1Slot3Phase2StepFrames
        lda     Enemy1Phase2ChaseRate
        sta     Enemy1Slot3Phase2ChaseRate
        lda     Enemy1Personality
        sta     Enemy1Slot3Personality
        lda     Enemy1SpawnTimer
        sta     Enemy1Slot3SpawnTimer
        lda     Enemy1State
        sta     Enemy1Slot3State
        lda     Enemy1Sprite
        sta     Enemy1Slot3Sprite
        rts

LoadEnemy1Slot4:
        lda     Enemy1Slot4Col
        sta     Enemy1Col
        lda     Enemy1Slot4Row
        sta     Enemy1Row
        lda     Enemy1Slot4PrevCol
        sta     Enemy1PrevCol
        lda     Enemy1Slot4PrevRow
        sta     Enemy1PrevRow
        lda     Enemy1Slot4PrevSprite
        sta     Enemy1PrevSprite
        lda     Enemy1Slot4PrevState
        sta     Enemy1PrevState
        lda     Enemy1Slot4Dir
        sta     Enemy1Dir
        lda     Enemy1Slot4FrameCounter
        sta     Enemy1FrameCounter
        lda     Enemy1Slot4Phase2AiSeed
        sta     Enemy1Phase2AiSeed
        lda     Enemy1Slot4StepFrames
        sta     Enemy1StepFrames
        lda     Enemy1Slot4Phase2StepFrames
        sta     Enemy1Phase2StepFrames
        lda     Enemy1Slot4Phase2ChaseRate
        sta     Enemy1Phase2ChaseRate
        lda     Enemy1Slot4Personality
        sta     Enemy1Personality
        lda     Enemy1Slot4SpawnTimer
        sta     Enemy1SpawnTimer
        lda     Enemy1Slot4State
        sta     Enemy1State
        lda     Enemy1Slot4Sprite
        sta     Enemy1Sprite
        rts

StoreEnemy1Slot4Current:
        lda     Enemy1Col
        sta     Enemy1Slot4Col
        lda     Enemy1Row
        sta     Enemy1Slot4Row
        lda     Enemy1Dir
        sta     Enemy1Slot4Dir
        lda     Enemy1FrameCounter
        sta     Enemy1Slot4FrameCounter
        lda     Enemy1Phase2AiSeed
        sta     Enemy1Slot4Phase2AiSeed
        lda     Enemy1StepFrames
        sta     Enemy1Slot4StepFrames
        lda     Enemy1Phase2StepFrames
        sta     Enemy1Slot4Phase2StepFrames
        lda     Enemy1Phase2ChaseRate
        sta     Enemy1Slot4Phase2ChaseRate
        lda     Enemy1Personality
        sta     Enemy1Slot4Personality
        lda     Enemy1SpawnTimer
        sta     Enemy1Slot4SpawnTimer
        lda     Enemy1State
        sta     Enemy1Slot4State
        lda     Enemy1Sprite
        sta     Enemy1Slot4Sprite
        rts

;------------------------------------------------------------------------------
; UpdateEnemy1
;
; Purpose:
;   Moves the first enemy as a falling walker. It spawns at the top, falls
;   until supported by a platform, walks off edges, and transforms into phase 2
;   when it reaches the bottom floor.
;
; Modified:
;   A, B, X
;------------------------------------------------------------------------------
UpdateEnemy1:
        lda     Enemy1State
        cmpa    #ENEMY1_STATE_INACTIVE
        lbeq    UpdateEnemy1Done
        cmpa    #ENEMY1_STATE_SPAWNING
        lbeq    UpdateEnemy1Spawning
        cmpa    #ENEMY1_STATE_PHASE2
        lbeq    UpdateEnemy1Phase2
        cmpa    #ENEMY1_STATE_PHASE2_SPAWNING
        lbeq    UpdateEnemy1Phase2Spawning
        cmpa    #ENEMY1_STATE_PHASE3
        lbeq    UpdateEnemy1Phase2
        cmpa    #ENEMY1_STATE_PHASE3_SPAWNING
        lbeq    UpdateEnemy1Phase3Spawning

        inc     Enemy1FrameCounter
        lda     Enemy1FrameCounter
        cmpa    Enemy1StepFrames
        blo     UpdateEnemy1Done
        clr     Enemy1FrameCounter

        jsr     IsEnemy1OnFloor
        bne     UpdateEnemy1Transform

        jsr     IsEnemy1Grounded
        beq     UpdateEnemy1Fall

        jsr     RandomizeEnemy1WalkDirection
        lda     Enemy1Dir
        bmi     UpdateEnemy1Left

        lda     Enemy1Col
        cmpa    #ENEMY1_MAX_COL
        blo     UpdateEnemy1StepRight
        lda     #ENEMY_MOVE_LEFT
        sta     Enemy1Dir
        dec     Enemy1Col
        rts

UpdateEnemy1StepRight:
        inc     Enemy1Col
        rts

UpdateEnemy1Left:
        lda     Enemy1Col
        cmpa    #ENEMY1_MIN_COL
        bhi     UpdateEnemy1StepLeft
        lda     #ENEMY_MOVE_RIGHT
        sta     Enemy1Dir
        inc     Enemy1Col
        rts

UpdateEnemy1StepLeft:
        dec     Enemy1Col
        rts

RandomizeEnemy1WalkDirection:
        lda     Enemy1SpawnTimer
        beq     RandomizeEnemy1WalkDirectionRoll
        dec     Enemy1SpawnTimer
        rts

RandomizeEnemy1WalkDirectionRoll:
        lda     #ENEMY1_WALK_DIR_HOLD_STEPS
        sta     Enemy1SpawnTimer
        jsr     AdvanceEnemy1Phase2AiSeed
        bita    #1
        beq     RandomizeEnemy1WalkRight

        lda     #ENEMY_MOVE_LEFT
        sta     Enemy1Dir
        rts

RandomizeEnemy1WalkRight:
        lda     #ENEMY_MOVE_RIGHT
        sta     Enemy1Dir
        rts

UpdateEnemy1Fall:
        clr     Enemy1SpawnTimer
        inc     Enemy1Row
        jsr     IsEnemy1OnFloor
        bne     UpdateEnemy1Transform

UpdateEnemy1Done:
        rts

UpdateEnemy1Transform:
        jmp     TransformEnemy1ToPhase2

UpdateEnemy1Spawning:
        lda     Enemy1SpawnTimer
        beq     ActivateEnemy1FromSpawn
        dec     Enemy1SpawnTimer
        beq     ActivateEnemy1FromSpawn
        jmp     UpdateEnemy1SpawnSprite

ActivateEnemy1FromSpawn:
        lda     #ENEMY1_STATE_ACTIVE
        sta     Enemy1State
        lda     #ENEMY1_SPRITE_ACTIVE
        sta     Enemy1Sprite
        jmp     SetEnemy1MovementCounterStagger

TransformEnemy1ToPhase2:
        lda     Enemy1Personality
        cmpa    #ENEMY1_PERSONALITY_PHASE3
        beq     TransformEnemy1ToPhase3
        lda     #ENEMY1_STATE_PHASE2_SPAWNING
        sta     Enemy1State
        clr     Enemy1FrameCounter

        lda     Enemy1Phase2AiSeed
        eora    #ENEMY1_PHASE2_AI_SEED
        sta     Enemy1Phase2AiSeed
        lda     #ENEMY1_SPAWN_EFFECT_FRAMES
        sta     Enemy1SpawnTimer
        jmp     UpdateEnemy1SpawnSprite

TransformEnemy1ToPhase3:
        lda     #ENEMY1_STATE_PHASE3_SPAWNING
        sta     Enemy1State
        clr     Enemy1FrameCounter

        lda     Enemy1Phase2AiSeed
        eora    #ENEMY1_PHASE2_AI_SEED
        sta     Enemy1Phase2AiSeed
        lda     #ENEMY1_SPAWN_EFFECT_FRAMES
        sta     Enemy1SpawnTimer
        jmp     UpdateEnemy1SpawnSprite

UpdateEnemy1Phase2Spawning:
        lda     Enemy1SpawnTimer
        beq     ActivateEnemy1Phase2
        dec     Enemy1SpawnTimer
        beq     ActivateEnemy1Phase2
        jmp     UpdateEnemy1SpawnSprite

UpdateEnemy1Phase3Spawning:
        lda     Enemy1SpawnTimer
        beq     ActivateEnemy1Phase3
        dec     Enemy1SpawnTimer
        beq     ActivateEnemy1Phase3
        jmp     UpdateEnemy1SpawnSprite

ActivateEnemy1Phase2:
        lda     #ENEMY1_STATE_PHASE2
        sta     Enemy1State
        jsr     SetEnemy1MovementCounterStagger

        lda     Enemy1Dir
        bmi     ActivateEnemy1Phase2Left
        lda     #ENEMY1_SPRITE_PHASE2_RIGHT
        sta     Enemy1Sprite
        rts

ActivateEnemy1Phase2Left:
        lda     #ENEMY1_SPRITE_PHASE2_LEFT
        sta     Enemy1Sprite
        rts

ActivateEnemy1Phase3:
        lda     #ENEMY1_STATE_PHASE3
        sta     Enemy1State
        jsr     SetEnemy1MovementCounterStagger
        lda     #ENEMY1_SPRITE_PHASE3
        sta     Enemy1Sprite
        jmp     ArmPowerSpawnAfterPhase3

SetEnemy1MovementCounterStagger:
        lda     Enemy1Personality
        cmpa    #ENEMY1_PERSONALITY_FLANKER
        beq     SetEnemy1MovementCounterSlot2
        cmpa    #ENEMY1_PERSONALITY_DRIFTER
        beq     SetEnemy1MovementCounterSlot3
        cmpa    #ENEMY1_PERSONALITY_PHASE3
        beq     SetEnemy1MovementCounterSlot4
        lda     #ENEMY1_FRAME_STAGGER
        bra     SetEnemy1MovementCounterStore

SetEnemy1MovementCounterSlot2:
        lda     #ENEMY1_SLOT2_FRAME_STAGGER
        bra     SetEnemy1MovementCounterStore

SetEnemy1MovementCounterSlot3:
        lda     #ENEMY1_SLOT3_FRAME_STAGGER
        bra     SetEnemy1MovementCounterStore

SetEnemy1MovementCounterSlot4:
        lda     #ENEMY1_SLOT4_FRAME_STAGGER

SetEnemy1MovementCounterStore:
        sta     Enemy1FrameCounter
        rts

;------------------------------------------------------------------------------
; StartEnemy1SpawnEffect
;
; Purpose:
;   Places enemy 1 at a varied top-of-arena column and shows its spawn effect.
;
; Modified:
;   A, B, X
;------------------------------------------------------------------------------
StartEnemy1SpawnEffect:
        jsr     AdvanceEnemy1SpawnSeed
        anda    #ENEMY1_SPAWN_MASK
        tfr     a,b
        ldx     #Enemy1SpawnCols
        lda     b,x
        sta     Enemy1Col
        lda     #ENEMY1_SPAWN_ROW
        sta     Enemy1Row
        clr     Enemy1FrameCounter
        lda     #ENEMY1_STATE_SPAWNING
        sta     Enemy1State
        lda     #ENEMY1_SPAWN_EFFECT_FRAMES
        sta     Enemy1SpawnTimer
        lda     Enemy1SpawnSeed
        sta     Enemy1Phase2AiSeed

        lda     Enemy1SpawnSeed
        bita    #1
        beq     SpawnEnemy1FaceRight

        lda     #ENEMY_MOVE_LEFT
        bra     SpawnEnemy1StoreDir

SpawnEnemy1FaceRight:
        lda     #ENEMY_MOVE_RIGHT

SpawnEnemy1StoreDir:
        sta     Enemy1Dir
        jmp     UpdateEnemy1SpawnSprite

UpdateEnemy1SpawnSprite:
        lda     Enemy1SpawnTimer
        anda    #ENEMY1_SPAWN_ANIM_BIT
        beq     UpdateEnemy1SpawnSpriteA
        lda     #ENEMY1_SPRITE_SPAWN_B
        sta     Enemy1Sprite
        rts

UpdateEnemy1SpawnSpriteA:
        lda     #ENEMY1_SPRITE_SPAWN_A
        sta     Enemy1Sprite
        rts

AdvanceEnemy1SpawnSeed:
        lda     Enemy1SpawnSeed
        lsra
        bcc     AdvanceEnemy1SpawnSeedStore
        eora    #$B8

AdvanceEnemy1SpawnSeedStore:
        sta     Enemy1SpawnSeed
        rts

;------------------------------------------------------------------------------
; UpdateEnemy1Phase2
;
; Purpose:
;   Moves enemy 1's phase-2 form as a platform-aware hunter. It climbs around
;   platforms by sidestepping when a vertical chase step is blocked.
;
; Modified:
;   A, B, X
;------------------------------------------------------------------------------
UpdateEnemy1Phase2:
        inc     Enemy1FrameCounter
        lda     Enemy1FrameCounter
        cmpa    Enemy1Phase2StepFrames
        lblo    UpdateEnemy1Done
        clr     Enemy1FrameCounter

        jsr     Enemy1Phase2Roll10
        cmpa    Enemy1Phase2ChaseRate
        blo     UpdateEnemy1Phase2Chase

UpdateEnemy1Phase2Wander:
        jsr     AdvanceEnemy1Phase2AiSeed
        anda    #3
        beq     Enemy1Phase2TryMoveLeft
        cmpa    #1
        lbeq    Enemy1Phase2TryMoveRight
        cmpa    #2
        lbeq    Enemy1Phase2TryMoveUp
        lbra    Enemy1Phase2TryMoveDown

UpdateEnemy1Phase2Chase:
        lda     Enemy1Personality
        cmpa    #ENEMY1_PERSONALITY_FLANKER
        beq     UpdateEnemy1Phase2ChaseXFirst
        cmpa    #ENEMY1_PERSONALITY_DRIFTER
        beq     UpdateEnemy1Phase2ChaseDrifter

UpdateEnemy1Phase2ChaseYFirst:
        jsr     Enemy1Phase2ChaseVerticalOrDetour
        lbne    UpdateEnemy1Done
        jsr     Enemy1Phase2StepTowardPlayerX
        lbne    UpdateEnemy1Done
        lbra    UpdateEnemy1Phase2Wander

UpdateEnemy1Phase2ChaseXFirst:
        jsr     Enemy1Phase2StepTowardPlayerX
        lbne    UpdateEnemy1Done
        jsr     Enemy1Phase2ChaseVerticalOrDetour
        lbne    UpdateEnemy1Done
        lbra    UpdateEnemy1Phase2Wander

UpdateEnemy1Phase2ChaseDrifter:
        jsr     AdvanceEnemy1Phase2AiSeed
        bita    #1
        bne     UpdateEnemy1Phase2ChaseXFirst
        bra     UpdateEnemy1Phase2ChaseYFirst

Enemy1Phase2ChaseVerticalOrDetour:
        lda     Enemy1Row
        cmpa    PlayerRow
        blo     Enemy1Phase2ChaseDownOrDetour
        bhi     Enemy1Phase2ChaseUpOrDetour
        clra
        rts

Enemy1Phase2ChaseUpOrDetour:
        jsr     Enemy1Phase2TryMoveUp
        bne     Enemy1Phase2ChaseMoved
        lbra    Enemy1Phase2Detour

Enemy1Phase2ChaseDownOrDetour:
        jsr     Enemy1Phase2TryMoveDown
        bne     Enemy1Phase2ChaseMoved
        lbra    Enemy1Phase2Detour

Enemy1Phase2ChaseMoved:
        lda     #1
        rts

Enemy1Phase2StepTowardPlayerX:
        lda     Enemy1Col
        cmpa    PlayerCol
        blo     Enemy1Phase2TryMoveRight
        bhi     Enemy1Phase2TryMoveLeft
        clra
        rts

Enemy1Phase2TryMoveLeft:
        lda     Enemy1Col
        cmpa    #ENEMY2_MIN_COL
        lbls    Enemy1Phase2NoMove
        deca
        ldb     Enemy1Row
        jsr     IsEnemyFootprintBlockedAtAB
        lbne    Enemy1Phase2NoMove
        dec     Enemy1Col
        lda     #ENEMY_MOVE_LEFT
        sta     Enemy1Dir
        jsr     SetEnemy1Phase2LeftSprite
        lda     #1
        rts

Enemy1Phase2TryMoveRight:
        lda     Enemy1Col
        cmpa    #ENEMY2_MAX_COL
        lbhs    Enemy1Phase2NoMove
        inca
        ldb     Enemy1Row
        jsr     IsEnemyFootprintBlockedAtAB
        lbne    Enemy1Phase2NoMove
        inc     Enemy1Col
        lda     #ENEMY_MOVE_RIGHT
        sta     Enemy1Dir
        jsr     SetEnemy1Phase2RightSprite
        lda     #1
        rts

SetEnemy1Phase2LeftSprite:
        lda     Enemy1State
        cmpa    #ENEMY1_STATE_PHASE3
        beq     SetEnemy1Phase3Sprite
        lda     #ENEMY1_SPRITE_PHASE2_LEFT
        sta     Enemy1Sprite
        rts

SetEnemy1Phase2RightSprite:
        lda     Enemy1State
        cmpa    #ENEMY1_STATE_PHASE3
        beq     SetEnemy1Phase3Sprite
        lda     #ENEMY1_SPRITE_PHASE2_RIGHT
        sta     Enemy1Sprite
        rts

SetEnemy1Phase3Sprite:
        lda     #ENEMY1_SPRITE_PHASE3
        sta     Enemy1Sprite
        rts

Enemy1Phase2TryMoveUp:
        lda     Enemy1Row
        cmpa    #ENEMY2_MIN_ROW
        lbls    Enemy1Phase2NoMove
        ldb     Enemy1Row
        decb
        lda     Enemy1Col
        jsr     IsEnemyFootprintBlockedAtAB
        lbne    Enemy1Phase2NoMove
        dec     Enemy1Row
        lda     #1
        rts

Enemy1Phase2TryMoveDown:
        lda     Enemy1Row
        cmpa    #ENEMY2_MAX_ROW
        bhs     Enemy1Phase2NoMove
        ldb     Enemy1Row
        incb
        lda     Enemy1Col
        jsr     IsEnemyFootprintBlockedAtAB
        bne     Enemy1Phase2NoMove
        inc     Enemy1Row
        lda     #1
        rts

Enemy1Phase2Detour:
        lda     Enemy1Personality
        cmpa    #ENEMY1_PERSONALITY_FLANKER
        beq     Enemy1Phase2DetourAwayFromPlayer
        cmpa    #ENEMY1_PERSONALITY_DRIFTER
        beq     Enemy1Phase2DetourRandom

        lda     Enemy1Dir
        bmi     Enemy1Phase2DetourLeftFirst

        jsr     Enemy1Phase2TryMoveRight
        bne     Enemy1Phase2DetourMoved
        jsr     Enemy1Phase2TryMoveLeft
        bne     Enemy1Phase2DetourMoved
        jsr     Enemy1Phase2TryMoveDown
        bne     Enemy1Phase2DetourMoved
        jmp     Enemy1Phase2TryMoveUp

Enemy1Phase2DetourLeftFirst:
        jsr     Enemy1Phase2TryMoveLeft
        bne     Enemy1Phase2DetourMoved
        jsr     Enemy1Phase2TryMoveRight
        bne     Enemy1Phase2DetourMoved
        jsr     Enemy1Phase2TryMoveDown
        bne     Enemy1Phase2DetourMoved
        jmp     Enemy1Phase2TryMoveUp

Enemy1Phase2DetourAwayFromPlayer:
        lda     Enemy1Col
        cmpa    PlayerCol
        blo     Enemy1Phase2DetourLeftFirst
        bhi     Enemy1Phase2DetourRightFirst
        lda     Enemy1Phase2AiSeed
        bita    #1
        bne     Enemy1Phase2DetourRightFirst
        bra     Enemy1Phase2DetourLeftFirst

Enemy1Phase2DetourRightFirst:
        jsr     Enemy1Phase2TryMoveRight
        bne     Enemy1Phase2DetourMoved
        jsr     Enemy1Phase2TryMoveLeft
        bne     Enemy1Phase2DetourMoved
        jsr     Enemy1Phase2TryMoveUp
        bne     Enemy1Phase2DetourMoved
        jmp     Enemy1Phase2TryMoveDown

Enemy1Phase2DetourRandom:
        jsr     AdvanceEnemy1Phase2AiSeed
        bita    #1
        bne     Enemy1Phase2DetourRightFirst
        bra     Enemy1Phase2DetourLeftFirst

Enemy1Phase2DetourMoved:
        lda     #1
        rts

Enemy1Phase2NoMove:
        clra
        rts

Enemy1Phase2Roll10:
        jsr     AdvanceEnemy1Phase2AiSeed
        anda    #$0F
        cmpa    #10
        bhs     Enemy1Phase2Roll10
        rts

AdvanceEnemy1Phase2AiSeed:
        lda     Enemy1Phase2AiSeed
        lsra
        bcc     AdvanceEnemy1Phase2AiSeedStore
        eora    #$B8

AdvanceEnemy1Phase2AiSeedStore:
        sta     Enemy1Phase2AiSeed
        rts

;------------------------------------------------------------------------------
; UpdateEnemy2
;
; Purpose:
;   Moves the second enemy as a flyer. Each step has an 80% attraction rate
;   toward Jacques; otherwise it wanders horizontally or vertically. Its blocked
;   chase sidestep sweeps away from Jacques to find platform edges.
;
; Modified:
;   A, B, X
;------------------------------------------------------------------------------
UpdateEnemy2:
        inc     Enemy2FrameCounter
        lda     Enemy2FrameCounter
        cmpa    #ENEMY2_STEP_FRAMES
        lblo    UpdateEnemy2Done
        clr     Enemy2FrameCounter

        jsr     Enemy2Roll10
        cmpa    #ENEMY2_CHASE_RATE
        blo     UpdateEnemy2Chase

UpdateEnemy2Wander:
        jsr     AdvanceEnemy2AiSeed
        anda    #3
        beq     Enemy2TryMoveLeft
        cmpa    #1
        beq     Enemy2TryMoveRight
        cmpa    #2
        beq     Enemy2TryMoveUp
        lbra    Enemy2TryMoveDown

UpdateEnemy2Chase:
        jsr     Enemy2ChaseVerticalOrDetour
        lbne    UpdateEnemy2Done
        jsr     Enemy2StepTowardPlayerX
        lbne    UpdateEnemy2Done
        lbra    UpdateEnemy2Wander

Enemy2ChaseVerticalOrDetour:
        lda     Enemy2Row
        cmpa    PlayerRow
        blo     Enemy2ChaseDownOrDetour
        bhi     Enemy2ChaseUpOrDetour
        clra
        rts

Enemy2ChaseUpOrDetour:
        jsr     Enemy2TryMoveUp
        bne     Enemy2ChaseMoved
        lbra    Enemy2Detour

Enemy2ChaseDownOrDetour:
        jsr     Enemy2TryMoveDown
        bne     Enemy2ChaseMoved
        lbra    Enemy2Detour

Enemy2ChaseMoved:
        lda     #1
        rts

Enemy2StepTowardPlayerX:
        lda     Enemy2Col
        cmpa    PlayerCol
        blo     Enemy2TryMoveRight
        bhi     Enemy2TryMoveLeft
        clra
        rts

Enemy2TryMoveLeft:
        lda     Enemy2Col
        cmpa    #ENEMY2_MIN_COL
        lbls    Enemy2NoMove
        deca
        ldb     Enemy2Row
        jsr     IsEnemyFootprintBlockedAtAB
        lbne    Enemy2NoMove
        dec     Enemy2Col
        lda     #ENEMY_MOVE_LEFT
        sta     Enemy2Dir
        lda     #1
        rts

Enemy2TryMoveRight:
        lda     Enemy2Col
        cmpa    #ENEMY2_MAX_COL
        bhs     Enemy2NoMove
        inca
        ldb     Enemy2Row
        jsr     IsEnemyFootprintBlockedAtAB
        bne     Enemy2NoMove
        inc     Enemy2Col
        lda     #ENEMY_MOVE_RIGHT
        sta     Enemy2Dir
        lda     #1
        rts

Enemy2TryMoveUp:
        lda     Enemy2Row
        cmpa    #ENEMY2_MIN_ROW
        bls     Enemy2NoMove
        ldb     Enemy2Row
        decb
        lda     Enemy2Col
        jsr     IsEnemyFootprintBlockedAtAB
        bne     Enemy2NoMove
        dec     Enemy2Row
        lda     #1
        rts

Enemy2TryMoveDown:
        lda     Enemy2Row
        cmpa    #ENEMY2_MAX_ROW
        bhs     Enemy2NoMove
        ldb     Enemy2Row
        incb
        lda     Enemy2Col
        jsr     IsEnemyFootprintBlockedAtAB
        bne     Enemy2NoMove
        inc     Enemy2Row
        lda     #1
        rts

Enemy2Detour:
        lda     Enemy2Col
        cmpa    PlayerCol
        blo     Enemy2DetourLeftFirst
        bhi     Enemy2DetourRightFirst

        jsr     AdvanceEnemy2AiSeed
        bita    #1
        bne     Enemy2DetourRightFirst

Enemy2DetourLeftFirst:
        jsr     Enemy2TryMoveLeft
        bne     Enemy2DetourMoved
        jsr     Enemy2TryMoveRight
        bne     Enemy2DetourMoved
        jsr     Enemy2TryMoveDown
        bne     Enemy2DetourMoved
        jmp     Enemy2TryMoveUp

Enemy2DetourRightFirst:
        jsr     Enemy2TryMoveRight
        bne     Enemy2DetourMoved
        jsr     Enemy2TryMoveLeft
        bne     Enemy2DetourMoved
        jsr     Enemy2TryMoveUp
        bne     Enemy2DetourMoved
        jmp     Enemy2TryMoveDown

Enemy2DetourMoved:
        lda     #1
        rts

Enemy2NoMove:
        clra
        rts

Enemy2Roll10:
        jsr     AdvanceEnemy2AiSeed
        anda    #$0F
        cmpa    #10
        bhs     Enemy2Roll10
        rts

AdvanceEnemy2AiSeed:
        lda     Enemy2AiSeed
        lsra
        bcc     AdvanceEnemy2AiSeedStore
        eora    #$B8

AdvanceEnemy2AiSeedStore:
        sta     Enemy2AiSeed
        rts

UpdateEnemy2Done:
        rts

UpdateHorizontal:
        clr     PlayerMoveX

        lda     Dpad_Held
        bita    #c1_button_left_mask
        beq     UpdateHorizontalRight

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
        lda     Dpad_Press
        bita    #c1_button_up_mask
        bne     TryJumpStart

        lda     Fire_Press
        bita    #c1_button_A_mask
        beq     TryJumpDone

TryJumpStart:
        lda     PlayerGrounded
        beq     TryJumpDone

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

TryJumpDone:
        rts

ApplyVertical:
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
        lda     PlayerRow
        adda    #PLAYER_HEIGHT
        sta     CheckObjectRow

        cmpa    #FLOOR_ROW
        bne     IsPlatformBelowScan
        lda     #FLOOR_START_COL
        ldb     #FLOOR_START_COL+FLOOR_LENGTH-1
        jsr     IsPlayerOverColumnRun
        bne     IsPlatformBelowYes

IsPlatformBelowScan:
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
        sta     CheckObjectCol
        stb     CheckObjectRow

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

;------------------------------------------------------------------------------

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
        lda     #1
        sta     BombScanIndex
        lda     #BOMB_COUNT
        sta     BombScanRemaining
        ldx     #BombActiveFlags
        ldu     CurrentBombPositions

CheckBombCollectionLoop:
        lda     ,x
        beq     CheckBombCollectionNext

        lda     ,u
        ldb     1,u
        jsr     IsPlayerOverBombAtAB
        beq     CheckBombCollectionNext

        lda     BombScanIndex
        cmpa    BombLitIndex
        bne     CheckBombCollectionEraseNormal

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
        leax    1,x
        leau    2,u
        inc     BombScanIndex
        dec     BombScanRemaining
        bne     CheckBombCollectionLoop

CheckBombDone:
        rts

AreAllBombsCollected:
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
        sta     CheckObjectCol
        stb     CheckObjectRow

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
        lda     PlayerGraceTimer
        lbne    CheckEnemyCollisionDone

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

;------------------------------------------------------------------------------

; AwardBombScore
;
; Purpose:
;   Awards normal or bonus points for a collected bomb.
;
; Input:
;   A = number of the bomb just collected, 1-BOMB_COUNT.
;
; Modified:
;   A, B, X, Y, U
;------------------------------------------------------------------------------
AwardBombScore:
        cmpa    BombLitIndex
        beq     AwardBombScoreBonus

        jmp     AddScore50

AwardBombScoreBonus:
        jsr     AddScore200
        jsr     SelectNextLitBomb
        rts

;------------------------------------------------------------------------------
; Score add helpers
;
; Purpose:
;   Adds the fixed game scoring values to the four-digit ASCII score. The score
;   caps at 9999.
;
; Modified:
;   A, X, Y, U
;------------------------------------------------------------------------------
AddScore50:
        lda     ScoreTensText
        adda    #5
        cmpa    #'9'
        bls     AddScore50Store
        suba    #10
        sta     ScoreTensText
        jsr     AddScore100Raw
        jmp     DrawScore

AddScore50Store:
        sta     ScoreTensText
        jmp     DrawScore

AddScore100:
        jsr     AddScore100Raw
        jmp     DrawScore

AddScore200:
        jsr     AddScore100Raw
        jsr     AddScore100Raw
        jmp     DrawScore

AddScore500:
        jsr     AddScore100Raw
        jsr     AddScore100Raw
        jsr     AddScore100Raw
        jsr     AddScore100Raw
        jsr     AddScore100Raw
        jmp     DrawScore

AddScore100Raw:
        lda     ScoreHundredsText
        cmpa    #'9'
        bhs     AddScore100CarryThousands
        inca
        sta     ScoreHundredsText
        rts

AddScore100CarryThousands:
        lda     #'0'
        sta     ScoreHundredsText
        lda     ScoreThousandsText
        cmpa    #'9'
        bhs     SetScoreMaxed
        inca
        sta     ScoreThousandsText
        rts

SetScoreMaxed:
        lda     #'9'
        sta     ScoreThousandsText
        sta     ScoreHundredsText
        sta     ScoreTensText
        sta     ScoreOnesText
        rts

;------------------------------------------------------------------------------
; Hall of Fame
;------------------------------------------------------------------------------
InitHallOfFameDefaults:
        ldd     #HallDefaultEntry1
        std     HallCopySrc
        ldd     #HallEntry1
        std     HallCopyDest
        lda     #HALL_ENTRY_COUNT
        sta     HallShiftIndex

InitHallOfFameDefaultsLoop:
        jsr     CopyHallEntry
        ldd     HallCopySrc
        addd    #HALL_ENTRY_SIZE
        std     HallCopySrc
        ldd     HallCopyDest
        addd    #HALL_ENTRY_SIZE
        std     HallCopyDest
        dec     HallShiftIndex
        bne     InitHallOfFameDefaultsLoop
        rts

BuildPlayerHallEntryFields:
        lda     ScoreThousandsText
        sta     PlayerScoreText
        lda     ScoreHundredsText
        sta     PlayerScoreText+1
        lda     ScoreTensText
        sta     PlayerScoreText+2
        lda     ScoreOnesText
        sta     PlayerScoreText+3

        lda     CurrentLevel
        inca
        cmpa    #10
        blo     BuildPlayerLevelOneDigit
        lda     #'1'
        sta     PlayerLevelText
        lda     #'0'
        sta     PlayerLevelText+1
        rts

BuildPlayerLevelOneDigit:
        adda    #'0'
        sta     PlayerLevelText+1
        lda     #'0'
        sta     PlayerLevelText
        rts

IsHallOfFameScore:
        ldx     #HallEntry5
        jmp     ComparePlayerScoreToEntryAtX

ComparePlayerScoreToEntryAtX:
        lda     PlayerScoreText
        cmpa    HALL_SCORE_OFFSET,x
        bhi     ComparePlayerScoreGreater
        blo     ComparePlayerScoreNotGreater
        lda     PlayerScoreText+1
        cmpa    HALL_SCORE_OFFSET+1,x
        bhi     ComparePlayerScoreGreater
        blo     ComparePlayerScoreNotGreater
        lda     PlayerScoreText+2
        cmpa    HALL_SCORE_OFFSET+2,x
        bhi     ComparePlayerScoreGreater
        blo     ComparePlayerScoreNotGreater
        lda     PlayerScoreText+3
        cmpa    HALL_SCORE_OFFSET+3,x
        bhi     ComparePlayerScoreGreater

ComparePlayerScoreNotGreater:
        clra
        rts

ComparePlayerScoreGreater:
        lda     #1
        rts

EnterNameEntry:
        jsr     ClearPlayerName
        jsr     DrawNameEntryScreen
        lda     #GAME_STATE_NAME_ENTRY
        sta     GameState
        rts

ClearPlayerName:
        ldx     #PlayerNameText
        ldb     #HALL_NAME_LEN
        lda     #' '

ClearPlayerNameLoop:
        sta     ,x+
        decb
        bne     ClearPlayerNameLoop

        clr     ,x
        ldx     #PlayerNameText
        lda     #'A'
        sta     ,x
        clr     NameEntryIndex
        rts

UpdateNameEntryState:
        lda     NameKey_Press
        beq     UpdateNameEntryDpad
        cmpa    #NAME_KEY_ENTER
        lbeq    CommitNameEntry
        cmpa    #NAME_KEY_BACKSPACE
        beq     BackspaceNameEntryChar
        cmpa    #'A'
        blo     UpdateNameEntryDpad
        cmpa    #'Z'
        bhi     UpdateNameEntryDpad
        jsr     TypeNameEntryChar
        rts

UpdateNameEntryDpad:
        lda     Dpad_Press
        bita    #c1_button_left_mask
        beq     UpdateNameEntryRight
        jsr     DecrementNameEntryChar

UpdateNameEntryRight:
        lda     Dpad_Press
        bita    #c1_button_right_mask
        beq     UpdateNameEntryConfirm
        jsr     IncrementNameEntryChar

UpdateNameEntryConfirm:
        lda     Fire_Press
        bita    #c1_button_A_mask
        bne     ConfirmNameEntryChar
        lda     Dpad_Press
        bita    #c1_button_up_mask
        beq     UpdateNameEntryDone

ConfirmNameEntryChar:
        jsr     StoreDefaultNameEntryChar

AdvanceNameEntryIndex:
        inc     NameEntryIndex
        lda     NameEntryIndex
        cmpa    #HALL_NAME_LEN
        bhs     CommitNameEntry
        jsr     DrawPlayerNameEntry
        rts

CommitNameEntry:
        jsr     InsertHallOfFameEntry
        jmp     EnterHallOfFameScreenNoChrome

UpdateNameEntryDone:
        rts

StoreDefaultNameEntryChar:
        clra
        ldb     NameEntryIndex
        ldx     #PlayerNameText
        leax    d,x
        lda     ,x
        cmpa    #' '
        bne     StoreDefaultNameEntryCharDone
        lda     #'A'
        sta     ,x

StoreDefaultNameEntryCharDone:
        rts

TypeNameEntryChar:
        pshs    a
        jsr     LoadCurrentNameEntryPointer
        puls    a
        sta     ,x
        jmp     AdvanceNameEntryIndex

BackspaceNameEntryChar:
        lda     NameEntryIndex
        beq     BackspaceNameEntryAtCurrent
        dec     NameEntryIndex

BackspaceNameEntryAtCurrent:
        jsr     LoadCurrentNameEntryPointer
        lda     #' '
        sta     ,x
        jmp     DrawPlayerNameEntry

DecrementNameEntryChar:
        jsr     StoreDefaultNameEntryChar
        jsr     LoadCurrentNameEntryPointer
        lda     ,x
        cmpa    #'A'
        bhi     DecrementNameEntryStore
        lda     #'Z'+1

DecrementNameEntryStore:
        deca
        sta     ,x
        jmp     DrawPlayerNameEntry

IncrementNameEntryChar:
        jsr     StoreDefaultNameEntryChar
        jsr     LoadCurrentNameEntryPointer
        lda     ,x
        cmpa    #'Z'
        blo     IncrementNameEntryStore
        lda     #'A'-1

IncrementNameEntryStore:
        inca
        sta     ,x
        jmp     DrawPlayerNameEntry

LoadCurrentNameEntryPointer:
        clra
        ldb     NameEntryIndex
        ldx     #PlayerNameText
        leax    d,x
        rts

InsertHallOfFameEntry:
        jsr     FindHallInsertIndex
        beq     InsertHallOfFameDone

        lda     #HALL_ENTRY_COUNT-1
        sta     HallShiftIndex

InsertHallOfFameShiftLoop:
        lda     HallShiftIndex
        cmpa    HallInsertIndex
        bls     InsertHallOfFameWrite
        ldb     HallShiftIndex
        jsr     LoadHallEntryPointer
        stx     HallCopyDest
        ldb     HallShiftIndex
        decb
        jsr     LoadHallEntryPointer
        stx     HallCopySrc
        jsr     CopyHallEntry
        dec     HallShiftIndex
        bra     InsertHallOfFameShiftLoop

InsertHallOfFameWrite:
        ldb     HallInsertIndex
        jsr     LoadHallEntryPointer
        stx     HallCopyDest
        jsr     WritePlayerHallEntry

InsertHallOfFameDone:
        rts

FindHallInsertIndex:
        clr     HallInsertIndex
        ldx     #HallEntry1

FindHallInsertIndexLoop:
        jsr     ComparePlayerScoreToEntryAtX
        bne     FindHallInsertIndexFound
        leax    HALL_ENTRY_SIZE,x
        inc     HallInsertIndex
        lda     HallInsertIndex
        cmpa    #HALL_ENTRY_COUNT
        blo     FindHallInsertIndexLoop
        clra
        rts

FindHallInsertIndexFound:
        lda     #1
        rts

LoadHallEntryPointer:
        clra
        lslb
        ldx     #HallEntryPointers
        ldx     d,x
        rts

CopyHallEntry:
        ldx     HallCopySrc
        ldu     HallCopyDest
        ldb     #HALL_ENTRY_SIZE

CopyHallEntryLoop:
        lda     ,x+
        sta     ,u+
        decb
        bne     CopyHallEntryLoop
        rts

WritePlayerHallEntry:
        ldx     HallCopyDest
        lda     PlayerLevelText
        sta     ,x
        lda     PlayerLevelText+1
        sta     1,x
        lda     #' '
        sta     2,x

        leax    HALL_NAME_OFFSET,x
        ldu     #PlayerNameText
        ldb     #HALL_NAME_LEN

WritePlayerHallNameLoop:
        lda     ,u+
        sta     ,x+
        decb
        bne     WritePlayerHallNameLoop

        ldx     HallCopyDest
        lda     #' '
        sta     13,x
        lda     PlayerScoreText
        sta     HALL_SCORE_OFFSET,x
        lda     PlayerScoreText+1
        sta     HALL_SCORE_OFFSET+1,x
        lda     PlayerScoreText+2
        sta     HALL_SCORE_OFFSET+2,x
        lda     PlayerScoreText+3
        sta     HALL_SCORE_OFFSET+3,x
        clr     HALL_ENTRY_SIZE-1,x
        rts

;------------------------------------------------------------------------------
; SelectNextLitBomb
;
; Purpose:
;   Points the bonus highlight at the first remaining active bomb.
;
; Modified:
;   A, B, X
;------------------------------------------------------------------------------
SelectNextLitBomb:
        lda     #1
        sta     BombScanIndex
        ldb     #BOMB_COUNT
        ldx     #BombActiveFlags

SelectNextLitBombLoop:
        lda     ,x+
        bne     SelectNextLitBombFound
        inc     BombScanIndex
        decb
        bne     SelectNextLitBombLoop
        clr     BombLitIndex
        rts

SelectNextLitBombFound:
        lda     BombScanIndex
        sta     BombLitIndex
        rts

;------------------------------------------------------------------------------
; UpdateBombScorePopup
;
; Purpose:
;   Keeps the 200 score sprite visible briefly after collecting the lit bomb.
;
; Modified:
;   A, B, X, Y, U
;------------------------------------------------------------------------------
UpdateBombScorePopup:
        lda     #BOMB_COUNT
        sta     BombScanRemaining
        ldx     #BombScorePopupTimers
        ldu     CurrentBombPositions

UpdateBombScorePopupLoop:
        lda     ,x
        beq     UpdateBombScorePopupNext

        deca
        sta     ,x
        bne     UpdateBombScorePopupNext

        lda     ,u
        ldb     1,u
        pshs    x,u
        jsr     EraseBombAtAB
        jsr     MarkStaticRedraw
        puls    x,u

UpdateBombScorePopupNext:
        leax    1,x
        leau    2,u
        dec     BombScanRemaining
        bne     UpdateBombScorePopupLoop

UpdateBombScorePopupDone:
        rts

StartBombScorePopup:
        pshs    a,b
        ldb     BombScanIndex
        decb
        ldx     #BombScorePopupTimers
        abx
        lda     #BOMB_SCORE_POPUP_FRAMES
        sta     ,x
        puls    a,b
        jmp     DrawBombScorePopupAtAB

ClearBombScorePopup:
        lda     #BOMB_COUNT
        sta     BombScanRemaining
        ldx     #BombScorePopupTimers
        ldu     CurrentBombPositions

ClearBombScorePopupLoop:
        lda     ,x
        beq     ClearBombScorePopupNext

        clr     ,x
        lda     ,u
        ldb     1,u
        pshs    x,u
        jsr     EraseBombAtAB
        jsr     MarkStaticRedraw
        puls    x,u

ClearBombScorePopupNext:
        leax    1,x
        leau    2,u
        dec     BombScanRemaining
        bne     ClearBombScorePopupLoop

ClearBombScorePopupDone:
        rts

;------------------------------------------------------------------------------
; Level transition state
;------------------------------------------------------------------------------
EnterLevelClear:
        lda     GameState
        cmpa    #GAME_STATE_PLAYING
        bne     EnterLevelClearDone

        lda     #GAME_STATE_LEVEL_CLEAR
        sta     GameState
        lda     #LEVEL_CLEAR_FRAMES
        sta     LevelTransitionTimer
        clr     LevelMessageColorIndex
        lda     #LEVEL_MESSAGE_COLOR_FRAMES
        sta     LevelMessageColorCounter
        jsr     DrawWellDoneText

EnterLevelClearDone:
        rts

UpdateLevelClearState:
        lda     LevelTransitionTimer
        beq     StartNextLevelGetReady
        dec     LevelTransitionTimer
        beq     StartNextLevelGetReady
        jmp     UpdateWellDoneColor

UpdateWellDoneColor:
        dec     LevelMessageColorCounter
        bne     UpdateWellDoneColorDone

        lda     #LEVEL_MESSAGE_COLOR_FRAMES
        sta     LevelMessageColorCounter
        lda     LevelMessageColorIndex
        inca
        cmpa    #LEVEL_MESSAGE_COLOR_COUNT
        blo     UpdateWellDoneColorStore
        clra

UpdateWellDoneColorStore:
        sta     LevelMessageColorIndex
        jsr     DrawWellDoneText

UpdateWellDoneColorDone:
        rts

StartNextLevelGetReady:
        jsr     AdvanceCurrentLevel
        jsr     StartCurrentLevel
        jsr     ClearGameArea
        jsr     DrawLevelLabel
        jsr     DrawStaticArena
        jsr     DrawPlayer
        jmp     EnterGetReadyState

EnterGetReadyState:
        lda     #GAME_STATE_GET_READY
        sta     GameState
        lda     #GET_READY_FRAMES
        sta     LevelTransitionTimer
        clr     LevelMessageColorIndex
        lda     #LEVEL_MESSAGE_COLOR_FRAMES
        sta     LevelMessageColorCounter
        jmp     DrawGetReadyText

AdvanceCurrentLevel:
        lda     CurrentLevel
        inca
        cmpa    #LEVEL_COUNT
        blo     AdvanceCurrentLevelStore
        clra

AdvanceCurrentLevelStore:
        sta     CurrentLevel
        rts

UpdateGetReadyState:
        lda     LevelTransitionTimer
        beq     BeginLevelPlay
        dec     LevelTransitionTimer
        beq     BeginLevelPlay
        jmp     UpdateGetReadyColor

UpdateGetReadyColor:
        dec     LevelMessageColorCounter
        bne     UpdateGetReadyColorDone

        lda     #LEVEL_MESSAGE_COLOR_FRAMES
        sta     LevelMessageColorCounter
        lda     LevelMessageColorIndex
        inca
        cmpa    #LEVEL_MESSAGE_COLOR_COUNT
        blo     UpdateGetReadyColorStore
        clra

UpdateGetReadyColorStore:
        sta     LevelMessageColorIndex
        jsr     DrawGetReadyText

UpdateGetReadyColorDone:
        rts

BeginLevelPlay:
        jsr     EraseLevelMessage
        jsr     DrawStaticArena
        jsr     DrawEnemy1All
        jsr     DrawEnemy2
        jsr     DrawPlayer
        clr     GameState
        rts

;------------------------------------------------------------------------------
; Drawing

;------------------------------------------------------------------------------
DrawTitleScreen:
        jsr     ClearGameArea

        lda     #COLOR_HALL_HEADER
        sta     DrawCellColor
        lda     #TITLE_TEXT_COL
        sta     DrawRunCol
        lda     #TITLE_TEXT_ROW
        sta     DrawRunRow
        lda     #TITLE_TEXT_LEN
        sta     DrawRunRemaining
        jsr     DrawTextCells
        ldu     #TitleText
        lda     #TITLE_TEXT_COL
        ldb     #TITLE_TEXT_ROW
        jsr     DrawString

        jsr     DrawTitleBombRow
        jsr     DrawTitleLitBombRow
        jsr     DrawTitleBonusRow
        jsr     DrawTitleFrozenRow

        lda     #COLOR_HALL_TEXT
        sta     DrawCellColor
        lda     #TITLE_INSTRUCTIONS_COL
        sta     DrawRunCol
        lda     #TITLE_INSTRUCTIONS_ROW
        sta     DrawRunRow
        lda     #TITLE_INSTRUCTIONS_LEN
        sta     DrawRunRemaining
        jsr     DrawTextCells
        ldu     #TitleInstructionsText
        lda     #TITLE_INSTRUCTIONS_COL
        ldb     #TITLE_INSTRUCTIONS_ROW
        jsr     DrawStringShiftRight4

        lda     #COLOR_HALL_HEADER
        sta     DrawCellColor
        lda     #TITLE_START_COL
        sta     DrawRunCol
        lda     #TITLE_START_ROW
        sta     DrawRunRow
        lda     #TITLE_START_LEN
        sta     DrawRunRemaining
        jsr     DrawTextCells
        ldu     #TitleStartText
        lda     #TITLE_START_COL
        ldb     #TITLE_START_ROW
        jmp     DrawString

DrawTitleBombRow:
        lda     #TITLE_BOMB_TEXT_ROW
        sta     DrawRunRow
        jsr     DrawTitleTableTextCells
        lda     #TITLE_ICON_COL
        ldb     #TITLE_BOMB_ROW
        jsr     DrawTitleBombIcon
        ldu     #TitleBombName
        lda     #TITLE_NAME_COL
        ldb     #TITLE_BOMB_TEXT_ROW
        jsr     DrawTitleCenteredString
        ldu     #TitleBombScoreText
        lda     #TITLE_SCORE_COL
        ldb     #TITLE_BOMB_TEXT_ROW
        jmp     DrawTitleCenteredString

DrawTitleLitBombRow:
        lda     #TITLE_LIT_BOMB_TEXT_ROW
        sta     DrawRunRow
        jsr     DrawTitleTableTextCells
        lda     #TITLE_ICON_COL
        ldb     #TITLE_LIT_BOMB_ROW
        jsr     DrawTitleLitBombIcon
        ldu     #TitleLitBombName
        lda     #TITLE_NAME_COL
        ldb     #TITLE_LIT_BOMB_TEXT_ROW
        jsr     DrawTitleCenteredString
        ldu     #TitleLitBombScoreText
        lda     #TITLE_SCORE_COL
        ldb     #TITLE_LIT_BOMB_TEXT_ROW
        jmp     DrawTitleCenteredString

DrawTitleBonusRow:
        lda     #TITLE_BONUS_TEXT_ROW
        sta     DrawRunRow
        jsr     DrawTitleTableTextCells
        lda     #TITLE_ICON_COL
        ldb     #TITLE_BONUS_ROW
        jsr     DrawTitleBonusIcon
        ldu     #TitleBonusName
        lda     #TITLE_NAME_COL
        ldb     #TITLE_BONUS_TEXT_ROW
        jsr     DrawTitleCenteredString
        ldu     #TitleBonusScoreText
        lda     #TITLE_SCORE_COL
        ldb     #TITLE_BONUS_TEXT_ROW
        jmp     DrawTitleCenteredString

DrawTitleFrozenRow:
        lda     #TITLE_FROZEN_TEXT_ROW
        sta     DrawRunRow
        jsr     DrawTitleTableTextCells
        lda     #TITLE_ICON_COL
        ldb     #TITLE_FROZEN_ROW
        jsr     DrawTitleFrozenIcon
        ldu     #TitleFrozenName
        lda     #TITLE_NAME_COL
        ldb     #TITLE_FROZEN_TEXT_ROW
        jsr     DrawTitleCenteredString
        ldu     #TitleFrozenScoreText
        lda     #TITLE_SCORE_COL
        ldb     #TITLE_FROZEN_TEXT_ROW
        jmp     DrawTitleCenteredString

DrawTitleTableTextCells:
        lda     #COLOR_HALL_TEXT
        sta     DrawCellColor
        lda     #TITLE_NAME_COL
        sta     DrawRunCol
        lda     #TITLE_TABLE_TEXT_LEN
        sta     DrawRunRemaining
        jsr     DrawTextCells
        inc     DrawRunRow
        lda     #TITLE_NAME_COL
        sta     DrawRunCol
        lda     #TITLE_TABLE_TEXT_LEN
        sta     DrawRunRemaining
        jmp     DrawTextCells

DrawTitleCenteredString:
        jsr     CellAddress
        leax    TITLE_CENTER_TEXT_OFFSET,x
        leay    TITLE_CENTER_TEXT_OFFSET,y

DrawTitleCenteredStringNext:
        lda     ,u+
        beq     DrawTitleCenteredStringDone

        pshs    x,y,u
        jsr     DrawGlyphAtCell
        puls    x,y,u

        leax    1,x
        leay    1,y
        bra     DrawTitleCenteredStringNext

DrawTitleCenteredStringDone:
        rts

DrawTitleBombIcon:
        pshs    a,b
        lda     #COLOR_BOMB
        sta     DrawCellColor
        ldu     #CellBombTopLeft
        puls    a,b
        bra     DrawTitle2x2Icon

DrawTitleLitBombIcon:
        pshs    a,b
        lda     #COLOR_BOMB
        sta     DrawCellColor
        ldu     #CellLitBombTopLeft
        puls    a,b
        bra     DrawTitle2x2Icon

DrawTitleBonusIcon:
        pshs    a,b
        lda     #COLOR_BOMB
        sta     DrawCellColor
        ldu     #CellBonusItem
        puls    a,b
        bra     DrawTitle2x2Icon

DrawTitleFrozenIcon:
        pshs    a,b
        lda     #COLOR_FROZEN
        sta     DrawCellColor
        ldu     #CellEnemyFrozen
        puls    a,b

DrawTitle2x2Icon:
        sta     DrawObjectCol
        stb     DrawObjectRow
        lda     DrawObjectCol
        ldb     DrawObjectRow
        jsr     DrawCellPatternMasked

        lda     DrawObjectCol
        inca
        ldb     DrawObjectRow
        jsr     DrawCellPatternMasked

        lda     DrawObjectCol
        ldb     DrawObjectRow
        incb
        jsr     DrawCellPatternMasked

        lda     DrawObjectCol
        inca
        ldb     DrawObjectRow
        incb
        jmp     DrawCellPatternMasked

DrawScreenChrome:
        jsr     DrawTopBorder
        jsr     DrawLeftBorder
        jsr     DrawBottomBorder
        jsr     DrawSidebarBackground
        jmp     DrawRightMargin

DrawTopBorder:
        clr     DrawRunRow

DrawTopBorderRow:
        clr     DrawRunCol

DrawTopBorderCol:
        lda     DrawRunCol
        ldb     DrawRunRow
        jsr     DrawBorderEmptyAtAB
        inc     DrawRunCol
        lda     DrawRunCol
        cmpa    #SIDEBAR_START_COL
        blo     DrawTopBorderCol

        inc     DrawRunRow
        lda     DrawRunRow
        cmpa    #ARENA_TOP_ROW
        blo     DrawTopBorderRow
        rts

DrawLeftBorder:
        clr     DrawRunRow

DrawLeftBorderRow:
        clr     DrawRunCol

DrawLeftBorderCol:
        lda     DrawRunCol
        ldb     DrawRunRow
        jsr     DrawBorderEmptyAtAB
        inc     DrawRunCol
        lda     DrawRunCol
        cmpa    #ARENA_LEFT_COL
        blo     DrawLeftBorderCol

        inc     DrawRunRow
        lda     DrawRunRow
        cmpa    #TEXT_ROWS
        blo     DrawLeftBorderRow
        rts

DrawBottomBorder:
        clr     DrawRunCol

DrawBottomBorderCol:
        lda     DrawRunCol
        ldb     #TEXT_ROWS-1
        jsr     DrawBorderEmptyAtAB
        inc     DrawRunCol
        lda     DrawRunCol
        cmpa    #SIDEBAR_START_COL
        blo     DrawBottomBorderCol
        rts

DrawSidebarBackground:
        clr     DrawRunRow

DrawSidebarBackgroundRow:
        lda     #SIDEBAR_START_COL
        sta     DrawRunCol

DrawSidebarBackgroundCol:
        lda     DrawRunCol
        ldb     DrawRunRow
        jsr     DrawSidebarEmptyAtAB
        inc     DrawRunCol
        lda     DrawRunCol
        cmpa    #SIDEBAR_RIGHT_MARGIN_COL
        blo     DrawSidebarBackgroundCol

        inc     DrawRunRow
        lda     DrawRunRow
        cmpa    #TEXT_ROWS
        blo     DrawSidebarBackgroundRow
        rts

DrawRightMargin:
        clr     DrawRunRow

DrawRightMarginRow:
        lda     #SIDEBAR_RIGHT_MARGIN_COL
        ldb     DrawRunRow
        jsr     DrawBorderEmptyAtAB
        inc     DrawRunRow
        lda     DrawRunRow
        cmpa    #TEXT_ROWS
        blo     DrawRightMarginRow
        rts

DrawHud:
        jsr     DrawScreenChrome
        jsr     DrawLevelLabel
        jmp     DrawHudSidebar

DrawGameplayStatus:
        jsr     DrawLevelLabel
        jsr     DrawScore
        jmp     DrawLives

DrawHudSidebar:
        ldu     #Player1Text
        lda     #SIDEBAR_TEXT_COL
        ldb     #SIDEBAR_PLAYER1_ROW
        jsr     DrawString
        jsr     DrawScore
        jsr     DrawLives
        jsr     DrawSidebarArt
        rts

DrawLevelLabel:
        jsr     UpdateLevelLabelText
        lda     #COLOR_LEVEL
        sta     DrawCellColor
        jsr     DrawLevelLabelCells
        ldu     #LevelLabelText
        lda     #LEVEL_LABEL_COL
        ldb     #LEVEL_LABEL_ROW
        jmp     DrawStringDown4

EraseLevelLabel:
        lda     #COLOR_BORDER
        sta     DrawCellColor
        jmp     DrawLevelLabelCells

DrawLevelLabelCells:
        lda     #LEVEL_LABEL_COL
        sta     DrawRunCol
        lda     #LEVEL_LABEL_ROW
        sta     DrawRunRow
        lda     #LEVEL_LABEL_LEN
        sta     DrawRunRemaining
        jsr     DrawTextCells

        lda     #LEVEL_LABEL_COL
        sta     DrawRunCol
        lda     #LEVEL_LABEL_ROW+1
        sta     DrawRunRow
        lda     #LEVEL_LABEL_LEN
        sta     DrawRunRemaining
        jmp     DrawTextCells

UpdateLevelLabelText:
        lda     CurrentLevel
        inca
        cmpa    #10
        blo     UpdateLevelLabelOneDigit
        lda     #'1'
        sta     LevelLabelText+6
        lda     #'0'
        sta     LevelLabelText+7
        rts

UpdateLevelLabelOneDigit:
        adda    #'0'
        sta     LevelLabelText+7
        lda     #'0'
        sta     LevelLabelText+6
        rts

DrawSidebarArt:
        jsr     SelectBitmapPlane
        ldx     #VIDEO_BITMAP_BASE+SIDEBAR_ART_BASE_OFFSET
        ldu     #SidebarArtBitmap
        ldy     #SIDEBAR_ART_PIXEL_ROWS

DrawSidebarArtBitmapRow:
        ldb     #SIDEBAR_ART_BYTES_PER_ROW

DrawSidebarArtBitmapByte:
        lda     ,u+
        sta     ,x+
        decb
        bne     DrawSidebarArtBitmapByte
        leax    VIDEO_BYTES_PER_ROW-SIDEBAR_ART_BYTES_PER_ROW,x
        leay    -1,y
        bne     DrawSidebarArtBitmapRow

        jsr     SelectColorPlane
        ldx     #VIDEO_COLOR_BASE+SIDEBAR_ART_BASE_OFFSET
        ldy     #SIDEBAR_ART_PIXEL_ROWS

DrawSidebarArtColorRow:
        ldb     #SIDEBAR_ART_BYTES_PER_ROW
        lda     #COLOR_SIDEBAR_ART

DrawSidebarArtColorByte:
        sta     ,x+
        decb
        bne     DrawSidebarArtColorByte
        leax    VIDEO_BYTES_PER_ROW-SIDEBAR_ART_BYTES_PER_ROW,x
        leay    -1,y
        bne     DrawSidebarArtColorRow

        jmp     SelectBitmapPlane

DrawLives:
        lda     LivesValue
        cmpa    #3
        blo     DrawLivesErase1
        lda     #LIFE_ICON1_COL
        ldb     #LIFE_ICON_ROW
        jsr     DrawLifeIconAtAB
        bra     DrawLivesSlot2

DrawLivesErase1:
        lda     #LIFE_ICON1_COL
        ldb     #LIFE_ICON_ROW
        jsr     EraseLifeIconAtAB

DrawLivesSlot2:
        lda     LivesValue
        cmpa    #2
        blo     DrawLivesErase2
        lda     #LIFE_ICON2_COL
        ldb     #LIFE_ICON_ROW
        jsr     DrawLifeIconAtAB
        bra     DrawLivesSlot3

DrawLivesErase2:
        lda     #LIFE_ICON2_COL
        ldb     #LIFE_ICON_ROW
        jsr     EraseLifeIconAtAB

DrawLivesSlot3:
        lda     LivesValue
        cmpa    #1
        blo     DrawLivesErase3
        lda     #LIFE_ICON3_COL
        ldb     #LIFE_ICON_ROW
        jmp     DrawLifeIconAtAB

DrawLivesErase3:
        lda     #LIFE_ICON3_COL
        ldb     #LIFE_ICON_ROW
        jmp     EraseLifeIconAtAB

DrawLifeIconAtAB:
        sta     DrawObjectCol
        jsr     SelectBitmapPlane
        clra
        ldb     DrawObjectCol
        addd    #VIDEO_BITMAP_BASE+LIFE_ICON_BASE_OFFSET
        tfr     d,x

        ldu     #CellPlayerUpRight
        ldy     #CellPlayerUpRight+TEXT_CELL_HEIGHT
        ldb     #TEXT_CELL_HEIGHT

DrawLifeIconTopBitmapRow:
        lda     ,u+
        sta     ,x
        lda     ,y+
        sta     1,x
        leax    VIDEO_BYTES_PER_ROW,x
        decb
        bne     DrawLifeIconTopBitmapRow

        ldu     #CellPlayerUpRight+TEXT_CELL_HEIGHT*2
        ldy     #CellPlayerUpRight+TEXT_CELL_HEIGHT*3
        ldb     #TEXT_CELL_HEIGHT

DrawLifeIconBottomBitmapRow:
        lda     ,u+
        sta     ,x
        lda     ,y+
        sta     1,x
        leax    VIDEO_BYTES_PER_ROW,x
        decb
        bne     DrawLifeIconBottomBitmapRow

        jsr     SelectColorPlane
        clra
        ldb     DrawObjectCol
        addd    #VIDEO_COLOR_BASE+LIFE_ICON_BASE_OFFSET
        tfr     d,x
        lda     #COLOR_LIFE
        ldb     #TEXT_CELL_HEIGHT*PLAYER_HEIGHT

DrawLifeIconColorRow:
        sta     ,x
        sta     1,x
        leax    VIDEO_BYTES_PER_ROW,x
        decb
        bne     DrawLifeIconColorRow

        jmp     SelectBitmapPlane

EraseLifeIconAtAB:
        sta     DrawObjectCol
        jsr     SelectBitmapPlane
        clra
        ldb     DrawObjectCol
        addd    #VIDEO_BITMAP_BASE+LIFE_ICON_BASE_OFFSET
        tfr     d,x
        ldb     #TEXT_CELL_HEIGHT*PLAYER_HEIGHT

EraseLifeIconBitmapRow:
        clr     ,x
        clr     1,x
        leax    VIDEO_BYTES_PER_ROW,x
        decb
        bne     EraseLifeIconBitmapRow

        jsr     SelectColorPlane
        clra
        ldb     DrawObjectCol
        addd    #VIDEO_COLOR_BASE+LIFE_ICON_BASE_OFFSET
        tfr     d,x
        lda     #COLOR_SIDEBAR
        ldb     #TEXT_CELL_HEIGHT*PLAYER_HEIGHT

EraseLifeIconColorRow:
        sta     ,x
        sta     1,x
        leax    VIDEO_BYTES_PER_ROW,x
        decb
        bne     EraseLifeIconColorRow

        jmp     SelectBitmapPlane

DrawScore:
        lda     #SCORE_DIGIT_COL
        ldb     #SCORE_TEXT_ROW
        jsr     DrawScoreCellAtAB

        lda     #SCORE_DIGIT_COL+1
        ldb     #SCORE_TEXT_ROW
        jsr     DrawScoreCellAtAB

        lda     #SCORE_DIGIT_COL+2
        ldb     #SCORE_TEXT_ROW
        jsr     DrawScoreCellAtAB

        lda     #SCORE_DIGIT_COL+3
        ldb     #SCORE_TEXT_ROW
        jsr     DrawScoreCellAtAB

        ldu     #ScoreDigitsText
        lda     #SCORE_DIGIT_COL
        ldb     #SCORE_TEXT_ROW
        jsr     DrawString
        rts

DrawScoreCellAtAB:
        pshs    a,b
        lda     #COLOR_SCORE
        sta     DrawCellColor
        ldu     #CellEmpty
        puls    a,b
        jmp     DrawCellPattern

DrawGameOverText:
        ldu     #GameOverText
        lda     #GAME_OVER_TEXT_COL
        ldb     #GAME_OVER_TEXT_ROW
        jmp     DrawString

DrawWellDoneText:
        jsr     LoadLevelMessageColor
        jsr     DrawWellDoneCells
        ldu     #WellDoneText
        lda     #WELL_DONE_TEXT_COL
        ldb     #LEVEL_MESSAGE_ROW
        jmp     DrawString

LoadLevelMessageColor:
        clra
        ldb     LevelMessageColorIndex
        ldx     #LevelMessageColors
        lda     b,x
        sta     DrawCellColor
        rts

DrawGetReadyText:
        jsr     LoadLevelMessageColor
        jsr     DrawGetReadyCells
        ldu     #GetReadyText
        lda     #GET_READY_TEXT_COL
        ldb     #LEVEL_MESSAGE_ROW
        jmp     DrawStringShiftRight4

EraseLevelMessage:
        lda     #COLOR_BACKGROUND
        sta     DrawCellColor
        jmp     DrawWellDoneCells

DrawWellDoneCells:
        lda     #WELL_DONE_TEXT_COL
        sta     DrawRunCol
        lda     #WELL_DONE_TEXT_LEN
        sta     DrawRunRemaining
        bra     DrawLevelMessageCells

DrawGetReadyCells:
        lda     #GET_READY_TEXT_COL
        sta     DrawRunCol
        lda     #GET_READY_TEXT_LEN
        sta     DrawRunRemaining

DrawLevelMessageCells:
        ldu     #CellEmpty
        lda     DrawRunCol
        ldb     #LEVEL_MESSAGE_ROW
        jsr     DrawCellPattern
        inc     DrawRunCol
        dec     DrawRunRemaining
        bne     DrawLevelMessageCells
        rts

DrawTextCells:
        ldu     #CellEmpty
        lda     DrawRunCol
        ldb     DrawRunRow
        jsr     DrawCellPattern
        inc     DrawRunCol
        dec     DrawRunRemaining
        bne     DrawTextCells
        rts

ClearGameArea:
        lda     #ARENA_TOP_ROW
        sta     DrawRunRow

ClearGameAreaRow:
        lda     #ARENA_LEFT_COL
        sta     DrawRunCol

ClearGameAreaCol:
        lda     DrawRunCol
        ldb     DrawRunRow
        jsr     DrawEmptyAtAB
        inc     DrawRunCol
        lda     DrawRunCol
        cmpa    #ARENA_RIGHT_COL+1
        blo     ClearGameAreaCol

        inc     DrawRunRow
        lda     DrawRunRow
        cmpa    #FLOOR_ROW
        blo     ClearGameAreaRow
        rts

DrawHallOfFameScreen:
        jsr     ClearGameArea

        ldb     #0
        jsr     LoadHallLineColor
        lda     #HALL_TITLE_COL
        sta     DrawRunCol
        lda     #HALL_TITLE_ROW
        sta     DrawRunRow
        lda     #HALL_TITLE_LEN
        sta     DrawRunRemaining
        jsr     DrawTextCells
        ldu     #HallOfFameTitle
        lda     #HALL_TITLE_COL
        ldb     #HALL_TITLE_ROW
        jsr     DrawString

        ldb     #1
        jsr     LoadHallLineColor
        lda     #HALL_HEADER_COL
        sta     DrawRunCol
        lda     #HALL_HEADER_ROW
        sta     DrawRunRow
        lda     #HALL_HEADER_LEN
        sta     DrawRunRemaining
        jsr     DrawTextCells
        ldu     #HallHeaderText
        lda     #HALL_HEADER_COL
        ldb     #HALL_HEADER_ROW
        jsr     DrawString

        ldd     #HallEntry1
        std     HallDrawEntryPtr
        lda     #HALL_FIRST_ROW
        sta     HallDrawRow
        lda     #HALL_ENTRY_COUNT
        sta     HallDrawRemaining

DrawHallOfFameRows:
        lda     #HALL_ENTRY_COUNT+2
        suba    HallDrawRemaining
        tfr     a,b
        jsr     LoadHallLineColor
        lda     #HALL_RANK_COL
        sta     DrawRunCol
        lda     HallDrawRow
        sta     DrawRunRow
        lda     #HALL_ROW_TEXT_LEN
        sta     DrawRunRemaining
        jsr     DrawTextCells

        lda     #HALL_ENTRY_COUNT+1
        suba    HallDrawRemaining
        adda    #'0'
        sta     HallRankText
        ldu     #HallRankText
        lda     #HALL_RANK_COL
        ldb     HallDrawRow
        jsr     DrawString
        ldu     HallDrawEntryPtr
        lda     #HALL_ENTRY_COL
        ldb     HallDrawRow
        jsr     DrawString

        ldd     HallDrawEntryPtr
        addd    #HALL_ENTRY_SIZE
        std     HallDrawEntryPtr
        lda     HallDrawRow
        adda    #HALL_ENTRY_ROW_STEP
        sta     HallDrawRow
        dec     HallDrawRemaining
        bne     DrawHallOfFameRows
        rts

DrawNameEntryScreen:
        jsr     ClearGameArea

        ldb     #0
        jsr     LoadHallLineColor
        lda     #HALL_TITLE_COL
        sta     DrawRunCol
        lda     #HALL_TITLE_ROW
        sta     DrawRunRow
        lda     #HALL_TITLE_LEN
        sta     DrawRunRemaining
        jsr     DrawTextCells
        ldu     #HallOfFameTitle
        lda     #HALL_TITLE_COL
        ldb     #HALL_TITLE_ROW
        jsr     DrawString

        ldb     #1
        jsr     LoadHallLineColor
        lda     #NAME_ENTRY_TITLE_COL
        sta     DrawRunCol
        lda     #NAME_ENTRY_TITLE_ROW
        sta     DrawRunRow
        lda     #NAME_ENTRY_TITLE_LEN
        sta     DrawRunRemaining
        jsr     DrawTextCells
        ldu     #NameEntryTitle
        lda     #NAME_ENTRY_TITLE_COL
        ldb     #NAME_ENTRY_TITLE_ROW
        jsr     DrawString

        jmp     DrawPlayerNameEntry

LoadHallLineColor:
        ldx     #HallLineColors
        lda     b,x
        sta     DrawCellColor
        rts

DrawPlayerNameEntry:
        jsr     DrawNameEntryCells
        ldu     #PlayerNameText
        lda     #NAME_ENTRY_COL
        ldb     #NAME_ENTRY_ROW
        jmp     DrawString

DrawNameEntryCells:
        lda     #COLOR_SCORE
        sta     DrawCellColor
        lda     #NAME_ENTRY_COL
        sta     DrawRunCol
        lda     #HALL_NAME_LEN
        sta     DrawRunRemaining

DrawNameEntryCellsLoop:
        ldu     #CellEmpty
        lda     DrawRunCol
        ldb     #NAME_ENTRY_ROW
        jsr     DrawCellPattern
        inc     DrawRunCol
        dec     DrawRunRemaining
        bne     DrawNameEntryCellsLoop
        rts

DrawStaticArena:

        ldx     #CurrentPlatform1Row
        lda     #PLATFORM_RUN_COUNT
        sta     PlatformScanRemaining

DrawStaticArenaPlatformLoop:
        clra
        ldb     2,x
        tfr     d,y
        lda     1,x
        ldb     ,x
        pshs    x
        jsr     DrawPlatformRun
        puls    x
        leax    PLATFORM_RECORD_SIZE,x
        dec     PlatformScanRemaining
        bne     DrawStaticArenaPlatformLoop

        jsr     DrawBombs
        jsr     DrawBombScorePopup

DrawStaticArenaDone:
        rts

MarkStaticRedraw:
        lda     #1
        sta     FrameStaticDirty
        rts

DrawStaticArenaIfDirty:
        lda     FrameStaticDirty
        beq     DrawStaticArenaIfDirtyDone
        jmp     DrawStaticArena

DrawStaticArenaIfDirtyDone:
        rts

DrawBombs:
        lda     #1
        sta     BombScanIndex
        lda     #BOMB_COUNT
        sta     BombScanRemaining
        ldx     #BombActiveFlags
        ldu     CurrentBombPositions

DrawBombsLoop:
        lda     ,x
        beq     DrawBombsNext

        lda     BombLitIndex
        cmpa    BombScanIndex
        bne     DrawBombsNormal

        lda     ,u
        ldb     1,u
        pshs    x,u
        jsr     DrawLitBombAtAB
        puls    x,u
        bra     DrawBombsNext

DrawBombsNormal:
        lda     ,u
        ldb     1,u
        pshs    x,u
        jsr     DrawBombAtAB
        puls    x,u

DrawBombsNext:
        leax    1,x
        leau    2,u
        inc     BombScanIndex
        dec     BombScanRemaining
        bne     DrawBombsLoop
        rts

DrawBombScorePopup:
        lda     #BOMB_COUNT
        sta     BombScanRemaining
        ldx     #BombScorePopupTimers
        ldu     CurrentBombPositions

DrawBombScorePopupLoop:
        lda     ,x
        beq     DrawBombScorePopupNext

        lda     ,u
        ldb     1,u
        pshs    x,u
        jsr     DrawBombScorePopupAtAB
        puls    x,u

DrawBombScorePopupNext:
        leax    1,x
        leau    2,u
        dec     BombScanRemaining
        bne     DrawBombScorePopupLoop

DrawBombScorePopupDone:
        rts

DrawPlatformRun:
        sta     DrawRunCol
        stb     DrawRunRow
        pshs    y
        lda     DrawRunCol
        ldb     DrawRunRow
        jsr     DrawPlatformLeftAtAB
        puls    y

        inc     DrawRunCol
        leay    -2,y
        beq     DrawPlatformRunRight

DrawPlatformRunMiddleLoop:
        lda     DrawRunCol
        ldb     DrawRunRow
        pshs    y
        jsr     DrawPlatformAtAB
        puls    y
        inc     DrawRunCol
        leay    -1,y
        bne     DrawPlatformRunMiddleLoop

DrawPlatformRunRight:
        lda     DrawRunCol
        ldb     DrawRunRow
        jmp     DrawPlatformRightAtAB

EraseEnemy1AllIfChanged:
        jsr     EraseEnemyIfChanged
        jsr     SaveEnemy1WorkVars

        lda     Enemy1Slot2PrevState
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     EraseEnemy1AllSlot3
        jsr     LoadEnemy1Slot2
        jsr     EraseEnemyIfChanged

EraseEnemy1AllSlot3:
        lda     Enemy1Slot3PrevState
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     EraseEnemy1AllSlot4
        jsr     LoadEnemy1Slot3
        jsr     EraseEnemyIfChanged

EraseEnemy1AllSlot4:
        lda     Enemy1Slot4PrevState
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     EraseEnemy1AllDone
        jsr     LoadEnemy1Slot4
        jsr     EraseEnemyIfChanged

EraseEnemy1AllDone:
        jmp     RestoreEnemy1WorkVars

DrawEnemy1AllIfChanged:
        lda     Enemy1State
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     DrawEnemy1AllIfChangedSave
        jsr     DrawEnemyIfChanged

DrawEnemy1AllIfChangedSave:
        jsr     SaveEnemy1WorkVars

        lda     Enemy1Slot2State
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     DrawEnemy1AllIfChangedSlot3
        jsr     LoadEnemy1Slot2
        jsr     DrawEnemyIfChanged

DrawEnemy1AllIfChangedSlot3:
        lda     Enemy1Slot3State
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     DrawEnemy1AllIfChangedSlot4
        jsr     LoadEnemy1Slot3
        jsr     DrawEnemyIfChanged

DrawEnemy1AllIfChangedSlot4:
        lda     Enemy1Slot4State
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     DrawEnemy1AllIfChangedDone
        jsr     LoadEnemy1Slot4
        jsr     DrawEnemyIfChanged

DrawEnemy1AllIfChangedDone:
        jmp     RestoreEnemy1WorkVars

DrawEnemy1All:
        lda     Enemy1State
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     DrawEnemy1AllSave
        jsr     DrawEnemy

DrawEnemy1AllSave:
        jsr     SaveEnemy1WorkVars

        lda     Enemy1Slot2State
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     DrawEnemy1AllSlot3
        jsr     LoadEnemy1Slot2
        jsr     DrawEnemy

DrawEnemy1AllSlot3:
        lda     Enemy1Slot3State
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     DrawEnemy1AllSlot4
        jsr     LoadEnemy1Slot3
        jsr     DrawEnemy

DrawEnemy1AllSlot4:
        lda     Enemy1Slot4State
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     DrawEnemy1AllDone
        jsr     LoadEnemy1Slot4
        jsr     DrawEnemy

DrawEnemy1AllDone:
        jmp     RestoreEnemy1WorkVars

EraseEnemyIfChanged:
        lda     Enemy1PrevState
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     EraseEnemyUnchanged
        jsr     IsPowerFreezeRenderChanged
        bne     EraseEnemyChanged
        lda     Enemy1Col
        cmpa    Enemy1PrevCol
        bne     EraseEnemyChanged

        lda     Enemy1Row
        cmpa    Enemy1PrevRow
        bne     EraseEnemyChanged

        lda     Enemy1Sprite
        cmpa    Enemy1PrevSprite
        bne     EraseEnemyChanged
        lda     Enemy1State
        cmpa    Enemy1PrevState
        bne     EraseEnemyChanged

EraseEnemyUnchanged:
        rts

EraseEnemyChanged:
        lda     Enemy1PrevCol
        ldb     Enemy1PrevRow
        jsr     EraseEnemyAtAB
        jmp     MarkStaticRedraw

IsPowerFreezeRenderChanged:
        ldd     PowerFreezeTimer
        beq     IsPowerFreezeRenderInactive
        lda     #1
        bra     IsPowerFreezeRenderCompare

IsPowerFreezeRenderInactive:
        clra

IsPowerFreezeRenderCompare:
        cmpa    PowerPrevFreezeActive
        bne     IsPowerFreezeRenderYes
        jsr     IsPowerFreezeBlinkVisible
        cmpa    PowerPrevFreezeBlinkVisible
        bne     IsPowerFreezeRenderYes
        clra
        rts

IsPowerFreezeRenderYes:
        lda     #1
        rts

IsPowerFreezeBlinkVisible:
        ldd     PowerFreezeTimer
        beq     IsPowerFreezeBlinkHidden
        cmpd    #POWER_FREEZE_BLINK_FRAMES
        bhi     IsPowerFreezeBlinkShown
        lda     PowerFreezeTimer+1
        bita    #POWER_FREEZE_BLINK_MASK
        bne     IsPowerFreezeBlinkHidden

IsPowerFreezeBlinkShown:
        lda     #1
        rts

IsPowerFreezeBlinkHidden:
        clra
        rts

DrawEnemyIfChanged:
        lda     Enemy1State
        cmpa    Enemy1PrevState
        bne     DrawEnemy
        lda     FrameStaticDirty
        bne     DrawEnemy
        jsr     IsPowerFreezeRenderChanged
        bne     DrawEnemy
        lda     Enemy1Col
        cmpa    Enemy1PrevCol
        bne     DrawEnemy

        lda     Enemy1Row
        cmpa    Enemy1PrevRow
        bne     DrawEnemy

        lda     Enemy1Sprite
        cmpa    Enemy1PrevSprite
        bne     DrawEnemy
        rts

DrawEnemy:
        lda     Enemy1Col
        ldb     Enemy1Row
        jsr     DrawEnemyAtAB
        rts

EraseEnemy2IfChanged:
        lda     Enemy2PrevActive
        beq     EraseEnemy2Unchanged
        jsr     IsPowerFreezeRenderChanged
        bne     EraseEnemy2Changed
        lda     Enemy2Active
        cmpa    Enemy2PrevActive
        bne     EraseEnemy2Changed
        lda     Enemy2Col
        cmpa    Enemy2PrevCol
        bne     EraseEnemy2Changed

        lda     Enemy2Row
        cmpa    Enemy2PrevRow
        bne     EraseEnemy2Changed

EraseEnemy2Unchanged:
        rts

EraseEnemy2Changed:
        lda     Enemy2PrevCol
        ldb     Enemy2PrevRow
        jsr     EraseEnemyAtAB
        jmp     MarkStaticRedraw

DrawEnemy2IfChanged:
        lda     Enemy2Active
        beq     DrawEnemy2Unchanged
        lda     Enemy2PrevActive
        beq     DrawEnemy2
        lda     FrameStaticDirty
        bne     DrawEnemy2
        jsr     IsPowerFreezeRenderChanged
        bne     DrawEnemy2
        lda     Enemy2Col
        cmpa    Enemy2PrevCol
        bne     DrawEnemy2

        lda     Enemy2Row
        cmpa    Enemy2PrevRow
        bne     DrawEnemy2

DrawEnemy2Unchanged:
        rts

DrawEnemy2:
        lda     Enemy2Active
        beq     DrawEnemy2Done
        lda     Enemy2Col
        ldb     Enemy2Row
        jsr     DrawEnemy2AtAB

DrawEnemy2Done:
        rts

ErasePowerIfChanged:
        lda     PowerPrevActive
        cmpa    #POWER_ACTIVE
        bne     ErasePowerUnchanged
        lda     PowerActive
        cmpa    PowerPrevActive
        bne     ErasePowerChanged
        lda     PowerCol
        cmpa    PowerPrevCol
        bne     ErasePowerChanged
        lda     PowerRow
        cmpa    PowerPrevRow
        bne     ErasePowerChanged

ErasePowerUnchanged:
        rts

ErasePowerChanged:
        lda     PowerPrevCol
        ldb     PowerPrevRow
        jsr     EraseEnemyAtAB
        jmp     MarkStaticRedraw

DrawPowerIfChanged:
        lda     PowerActive
        cmpa    #POWER_ACTIVE
        bne     DrawPowerUnchanged
        bra     DrawPower

DrawPowerUnchanged:
        rts

DrawPower:
        lda     PowerActive
        cmpa    #POWER_ACTIVE
        bne     DrawPowerDone
        lda     PowerCol
        ldb     PowerRow
        jsr     DrawPowerAtAB
DrawPowerDone:
        rts

EraseBonusItemIfChanged:
        lda     BonusItemPrevActive
        cmpa    #BONUS_ITEM_ACTIVE
        bne     EraseBonusItemUnchanged
        lda     BonusItemActive
        cmpa    BonusItemPrevActive
        bne     EraseBonusItemChanged
        lda     BonusItemCol
        cmpa    BonusItemPrevCol
        bne     EraseBonusItemChanged
        lda     BonusItemRow
        cmpa    BonusItemPrevRow
        bne     EraseBonusItemChanged

EraseBonusItemUnchanged:
        rts

EraseBonusItemChanged:
        lda     BonusItemPrevCol
        ldb     BonusItemPrevRow
        jsr     EraseEnemyAtAB
        jmp     MarkStaticRedraw

DrawBonusItemIfChanged:
        lda     BonusItemActive
        cmpa    #BONUS_ITEM_ACTIVE
        bne     DrawBonusItemUnchanged
        bra     DrawBonusItem

DrawBonusItemUnchanged:
        rts

DrawBonusItem:
        lda     BonusItemActive
        cmpa    #BONUS_ITEM_ACTIVE
        bne     DrawBonusItemDone
        lda     BonusItemCol
        ldb     BonusItemRow
        jsr     DrawBonusItemAtAB

DrawBonusItemDone:
        rts

EraseEnergyItemIfChanged:
        lda     EnergyItemPrevActive
        cmpa    #ENERGY_ITEM_ACTIVE
        bne     EraseEnergyItemUnchanged
        lda     EnergyItemActive
        cmpa    EnergyItemPrevActive
        bne     EraseEnergyItemChanged
        lda     EnergyItemCol
        cmpa    EnergyItemPrevCol
        bne     EraseEnergyItemChanged
        lda     EnergyItemRow
        cmpa    EnergyItemPrevRow
        bne     EraseEnergyItemChanged

EraseEnergyItemUnchanged:
        rts

EraseEnergyItemChanged:
        lda     EnergyItemPrevCol
        ldb     EnergyItemPrevRow
        jsr     EraseEnemyAtAB
        jmp     MarkStaticRedraw

DrawEnergyItemIfChanged:
        lda     EnergyItemActive
        cmpa    #ENERGY_ITEM_ACTIVE
        bne     DrawEnergyItemUnchanged
        bra     DrawEnergyItem

DrawEnergyItemUnchanged:
        rts

DrawEnergyItem:
        lda     EnergyItemActive
        cmpa    #ENERGY_ITEM_ACTIVE
        bne     DrawEnergyItemDone
        lda     EnergyItemCol
        ldb     EnergyItemRow
        jsr     DrawEnergyItemAtAB

DrawEnergyItemDone:
        rts

ErasePlayerIfChanged:
        lda     PlayerPrevGraceBlinkVisible
        beq     ErasePlayerUnchanged
        jsr     IsPlayerRenderVisible
        cmpa    PlayerPrevGraceBlinkVisible
        bne     ErasePlayerChanged

        lda     PlayerCol
        cmpa    PlayerPrevCol
        bne     ErasePlayerChanged

        lda     PlayerRow
        cmpa    PlayerPrevRow
        bne     ErasePlayerChanged

        lda     PlayerSprite
        cmpa    PlayerPrevSprite
        bne     ErasePlayerChanged

ErasePlayerUnchanged:
        rts

ErasePlayerChanged:
        lda     PlayerPrevCol
        ldb     PlayerPrevRow
        jsr     ErasePlayerAtAB
        jmp     MarkStaticRedraw

DrawPlayerIfChanged:
        jsr     IsPlayerRenderVisible
        beq     DrawPlayerUnchanged
        cmpa    PlayerPrevGraceBlinkVisible
        bne     DrawPlayer

        lda     FrameStaticDirty
        bne     DrawPlayer
        lda     PlayerCol
        cmpa    PlayerPrevCol
        bne     DrawPlayer

        lda     PlayerRow
        cmpa    PlayerPrevRow
        bne     DrawPlayer

        lda     PlayerSprite
        cmpa    PlayerPrevSprite
        bne     DrawPlayer

DrawPlayerUnchanged:
        rts

DrawPlayer:
        jsr     IsPlayerRenderVisible
        beq     DrawPlayerDone
        lda     PlayerCol
        ldb     PlayerRow
        jsr     DrawPlayerAtAB

DrawPlayerDone:
        rts

IsPlayerGraceBlinkVisible:
        lda     PlayerGraceTimer
        beq     IsPlayerGraceBlinkShown
        bita    #PLAYER_GRACE_BLINK_MASK
        bne     IsPlayerGraceBlinkHidden

IsPlayerGraceBlinkShown:
        lda     #1
        rts

IsPlayerGraceBlinkHidden:
        clra
        rts

IsPlayerRenderVisible:
        jsr     IsPlayerGraceBlinkVisible
        beq     IsPlayerRenderHidden
        lda     GameState
        cmpa    #GAME_STATE_DYING
        bne     IsPlayerRenderShown
        lda     PlayerRow
        cmpa    #ARENA_TOP_ROW
        blo     IsPlayerRenderHidden

IsPlayerRenderShown:
        lda     #1
        rts

IsPlayerRenderHidden:
        clra
        rts

ErasePlayer:
        lda     PlayerCol
        ldb     PlayerRow
        jsr     ErasePlayerAtAB
        rts

ErasePlayerAtAB:
        sta     DrawObjectCol
        stb     DrawObjectRow
        lda     DrawObjectCol
        ldb     DrawObjectRow
        jsr     RestorePlayerCellAtAB

        lda     DrawObjectCol
        inca
        ldb     DrawObjectRow
        jsr     RestorePlayerCellAtAB

        lda     DrawObjectCol
        ldb     DrawObjectRow
        incb
        jsr     RestorePlayerCellAtAB

        lda     DrawObjectCol
        inca
        ldb     DrawObjectRow
        incb
        jmp     RestorePlayerCellAtAB

RestorePlayerCellAtAB:
        cmpb    #ARENA_TOP_ROW
        blo     RestorePlayerCellBorder
        cmpb    #FLOOR_ROW
        bhs     RestorePlayerCellBorder
        cmpa    #ARENA_LEFT_COL
        blo     RestorePlayerCellBorder
        cmpa    #ARENA_RIGHT_COL
        bhi     RestorePlayerCellBorder
        jmp     DrawEmptyAtAB

RestorePlayerCellBorder:
        jmp     DrawBorderEmptyAtAB

DrawEmptyAtAB:
        pshs    a,b
        lda     #COLOR_BACKGROUND
        sta     DrawCellColor
        ldu     #CellEmpty
        puls    a,b
        jmp     DrawCellPattern

DrawBorderEmptyAtAB:
        pshs    a,b
        lda     #COLOR_BORDER
        sta     DrawCellColor
        ldu     #CellEmpty
        puls    a,b
        jmp     DrawCellPattern

DrawSidebarEmptyAtAB:
        pshs    a,b
        lda     #COLOR_SIDEBAR
        sta     DrawCellColor
        ldu     #CellEmpty
        puls    a,b
        jmp     DrawCellPattern

DrawPlatformAtAB:
        pshs    a,b
        lda     #COLOR_PLATFORM
        sta     DrawCellColor
        ldu     #CellPlatformMiddle
        puls    a,b
        jmp     DrawCellPattern

DrawPlatformLeftAtAB:
        pshs    a,b
        lda     #COLOR_PLATFORM
        sta     DrawCellColor
        ldu     #CellPlatformLeft
        puls    a,b
        jmp     DrawCellPattern

DrawPlatformRightAtAB:
        pshs    a,b
        lda     #COLOR_PLATFORM
        sta     DrawCellColor
        ldu     #CellPlatformRight
        puls    a,b
        jmp     DrawCellPattern

EraseEnemyAtAB:
        sta     DrawObjectCol
        stb     DrawObjectRow
        lda     DrawObjectCol
        ldb     DrawObjectRow
        jsr     DrawEmptyAtAB

        lda     DrawObjectCol
        inca
        ldb     DrawObjectRow
        jsr     DrawEmptyAtAB

        lda     DrawObjectCol
        ldb     DrawObjectRow
        incb
        jsr     DrawEmptyAtAB

        lda     DrawObjectCol
        inca
        ldb     DrawObjectRow
        incb
        jmp     DrawEmptyAtAB

DrawEnemyAtAB:
        sta     DrawObjectCol
        stb     DrawObjectRow
        ldd     PowerFreezeTimer
        beq     DrawEnemyNormal
        jsr     IsPowerFreezeBlinkVisible
        beq     DrawEnemyFrozenHidden
        lda     #COLOR_FROZEN
        sta     DrawCellColor
        ldu     #CellEnemyFrozen
        bra     DrawEnemyCells

DrawEnemyFrozenHidden:
        rts

DrawEnemyNormal:
        lda     #COLOR_ENEMY
        sta     DrawCellColor
        lda     Enemy1Sprite
        cmpa    #ENEMY1_SPRITE_SPAWN_A
        beq     DrawEnemyUseSpawnA
        cmpa    #ENEMY1_SPRITE_SPAWN_B
        beq     DrawEnemyUseSpawnB
        cmpa    #ENEMY1_SPRITE_PHASE2_LEFT
        beq     DrawEnemyUsePhase2Left
        cmpa    #ENEMY1_SPRITE_PHASE2_RIGHT
        beq     DrawEnemyUsePhase2Right
        cmpa    #ENEMY1_SPRITE_PHASE3
        beq     DrawEnemyUsePhase3

        lda     Enemy1Dir
        bmi     DrawEnemyUseLeft
        ldu     #CellEnemy1Right
        bra     DrawEnemyCells

DrawEnemyUseLeft:
        ldu     #CellEnemy1Left
        bra     DrawEnemyCells

DrawEnemyUseSpawnA:
        ldu     #CellEnemy1SpawnA
        bra     DrawEnemyCells

DrawEnemyUseSpawnB:
        ldu     #CellEnemy1SpawnB
        bra     DrawEnemyCells

DrawEnemyUsePhase2Left:
        ldu     #CellEnemy1Phase2Left
        bra     DrawEnemyCells

DrawEnemyUsePhase2Right:
        ldu     #CellEnemy1Phase2Right
        bra     DrawEnemyCells

DrawEnemyUsePhase3:
        ldu     #CellEnemy1Phase3

DrawEnemyCells:
        lda     DrawObjectCol
        ldb     DrawObjectRow
        jsr     DrawCellPatternMasked

        lda     DrawObjectCol
        inca
        ldb     DrawObjectRow
        jsr     DrawCellPatternMasked

        lda     DrawObjectCol
        ldb     DrawObjectRow
        incb
        jsr     DrawCellPatternMasked

        lda     DrawObjectCol
        inca
        ldb     DrawObjectRow
        incb
        jmp     DrawCellPatternMasked

DrawEnemy2AtAB:
        sta     DrawObjectCol
        stb     DrawObjectRow
        ldd     PowerFreezeTimer
        beq     DrawEnemy2Normal
        jsr     IsPowerFreezeBlinkVisible
        beq     DrawEnemy2FrozenHidden
        lda     #COLOR_FROZEN
        sta     DrawCellColor
        ldu     #CellEnemyFrozen
        bra     DrawEnemy2Cells

DrawEnemy2FrozenHidden:
        rts

DrawEnemy2Normal:
        lda     #COLOR_ENEMY2
        sta     DrawCellColor
        lda     Enemy2Dir
        bmi     DrawEnemy2UseLeft
        ldu     #CellEnemy2Right
        bra     DrawEnemy2Cells

DrawEnemy2UseLeft:
        ldu     #CellEnemy2Left

DrawEnemy2Cells:
        lda     DrawObjectCol
        ldb     DrawObjectRow
        jsr     DrawCellPatternMasked

        lda     DrawObjectCol
        inca
        ldb     DrawObjectRow
        jsr     DrawCellPatternMasked

        lda     DrawObjectCol
        ldb     DrawObjectRow
        incb
        jsr     DrawCellPatternMasked

        lda     DrawObjectCol
        inca
        ldb     DrawObjectRow
        incb
        jmp     DrawCellPatternMasked

DrawPowerAtAB:
        sta     DrawObjectCol
        stb     DrawObjectRow
        lda     #COLOR_POWER
        sta     DrawCellColor
        ldu     #CellPower

DrawPowerCells:
        lda     DrawObjectCol
        ldb     DrawObjectRow
        jsr     DrawCellPatternMasked

        lda     DrawObjectCol
        inca
        ldb     DrawObjectRow
        jsr     DrawCellPatternMasked

        lda     DrawObjectCol
        ldb     DrawObjectRow
        incb
        jsr     DrawCellPatternMasked

        lda     DrawObjectCol
        inca
        ldb     DrawObjectRow
        incb
        jmp     DrawCellPatternMasked

DrawBonusItemAtAB:
        sta     DrawObjectCol
        stb     DrawObjectRow
        lda     #COLOR_BONUS_ITEM
        sta     DrawCellColor
        ldu     #CellBonusItem
        jmp     DrawPowerCells

DrawEnergyItemAtAB:
        sta     DrawObjectCol
        stb     DrawObjectRow
        lda     #COLOR_ENERGY_ITEM
        sta     DrawCellColor
        ldu     #CellEnergyItem
        jmp     DrawPowerCells

DrawBombAtAB:
        sta     DrawObjectCol
        stb     DrawObjectRow
        lda     #COLOR_BOMB
        sta     DrawCellColor
        ldu     #CellBombTopLeft
        lda     DrawObjectCol
        ldb     DrawObjectRow
        jsr     DrawCellPatternMasked

        ldu     #CellBombTopRight
        lda     DrawObjectCol
        inca
        ldb     DrawObjectRow
        jsr     DrawCellPatternMasked

        ldu     #CellBombBottomLeft
        lda     DrawObjectCol
        ldb     DrawObjectRow
        incb
        jsr     DrawCellPatternMasked

        ldu     #CellBombBottomRight
        lda     DrawObjectCol
        inca
        ldb     DrawObjectRow
        incb
        jmp     DrawCellPatternMasked

DrawLitBombAtAB:
        sta     DrawObjectCol
        stb     DrawObjectRow
        lda     #COLOR_BOMB_LIT
        sta     DrawCellColor
        ldu     #CellLitBombTopLeft
        lda     DrawObjectCol
        ldb     DrawObjectRow
        jsr     DrawCellPatternMasked

        ldu     #CellLitBombTopRight
        lda     DrawObjectCol
        inca
        ldb     DrawObjectRow
        jsr     DrawCellPatternMasked

        ldu     #CellLitBombBottomLeft
        lda     DrawObjectCol
        ldb     DrawObjectRow
        incb
        jsr     DrawCellPatternMasked

        ldu     #CellLitBombBottomRight
        lda     DrawObjectCol
        inca
        ldb     DrawObjectRow
        incb
        jmp     DrawCellPatternMasked

DrawBombScorePopupAtAB:
        sta     DrawObjectCol
        stb     DrawObjectRow
        lda     #COLOR_BOMB_LIT
        sta     DrawCellColor
        ldu     #CellScore200TopLeft
        lda     DrawObjectCol
        ldb     DrawObjectRow
        jsr     DrawCellPattern

        ldu     #CellScore200TopRight
        lda     DrawObjectCol
        inca
        ldb     DrawObjectRow
        jsr     DrawCellPattern

        ldu     #CellScore200BottomLeft
        lda     DrawObjectCol
        ldb     DrawObjectRow
        incb
        jsr     DrawCellPattern

        ldu     #CellScore200BottomRight
        lda     DrawObjectCol
        inca
        ldb     DrawObjectRow
        incb
        jmp     DrawCellPattern

EraseBombAtAB:
        sta     DrawObjectCol
        stb     DrawObjectRow
        lda     DrawObjectCol
        ldb     DrawObjectRow
        jsr     DrawEmptyAtAB

        lda     DrawObjectCol
        inca
        ldb     DrawObjectRow
        jsr     DrawEmptyAtAB

        lda     DrawObjectCol
        ldb     DrawObjectRow
        incb
        jsr     DrawEmptyAtAB

        lda     DrawObjectCol
        inca
        ldb     DrawObjectRow
        incb
        jmp     DrawEmptyAtAB

DrawPlayerAtAB:
        sta     DrawObjectCol
        stb     DrawObjectRow
        lda     #COLOR_PLAYER
        sta     DrawCellColor
        clra
        ldb     PlayerSprite
        lslb
        ldx     #PlayerSpriteTable
        ldu     d,x
        lda     DrawObjectCol
        ldb     DrawObjectRow
        jsr     DrawCellPatternMasked

        lda     DrawObjectCol
        inca
        ldb     DrawObjectRow
        jsr     DrawCellPatternMasked

        lda     DrawObjectCol
        ldb     DrawObjectRow
        incb
        jsr     DrawCellPatternMasked

        lda     DrawObjectCol
        inca
        ldb     DrawObjectRow
        incb
        jmp     DrawCellPatternMasked

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
        ldx     #FRAME_DELAY_OUTER

WaitFrameOuter:
        ldy     #FRAME_DELAY_INNER

WaitFrameInner:
        leay    -1,y
        bne     WaitFrameInner
        leax    -1,x
        bne     WaitFrameOuter
        rts

PowerSpawnCols:
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

        include "levels.asm"

TitleText:
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
        fcc     "SQUEEPTY"

HudText:
        fcc     "BOMB JACQUES BUILD 008"
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
        fdb     HallEntry1
        fdb     HallEntry2
        fdb     HallEntry3
        fdb     HallEntry4
        fdb     HallEntry5

HallDefaultEntry1:
        fcc     "10 SQUEEPTY   6000"
        fcb     0
HallDefaultEntry2:
        fcc     "08 PROUDLY    5000"
        fcb     0
HallDefaultEntry3:
        fcc     "06 PRESENT    4000"
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
        fcc     "06 PRESENT    4000"
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
        fcb     COLOR_HALL_HEADER
        fcb     COLOR_HALL_HEADER
        fcb     COLOR_HALL_TEXT
        fcb     COLOR_HALL_TEXT
        fcb     COLOR_HALL_TEXT
        fcb     COLOR_HALL_TEXT
        fcb     COLOR_HALL_TEXT

LevelMessageColors:
        fcb     $16
        fcb     $26
        fcb     $36
        fcb     $46
        fcb     $56
        fcb     $76

        include "sidebar_art.asm"

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

Enemy1SpawnCols:
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

PlayerCol:
        fcb     PLAYER_START_COL
PlayerRow:
        fcb     PLAYER_START_ROW
PlayerJumpTargetRow:
        fcb     PLAYER_FLOOR_JUMP_TARGET_ROW
PlayerDY:
        fcb     0
PlayerGrounded:
        fcb     1
PlayerFallCounter:
        fcb     0
PlayerMoveX:
        fcb     PLAYER_MOVE_NONE
PlayerLandingPose:
        fcb     0
PlayerFacing:
        fcb     PLAYER_MOVE_RIGHT
PlayerSprite:
        fcb     PLAYER_SPRITE_FRONT
PlayerPrevCol:
        fcb     PLAYER_START_COL
PlayerPrevRow:
        fcb     PLAYER_START_ROW
PlayerPrevSprite:
        fcb     PLAYER_SPRITE_FRONT
PlayerGraceTimer:
        fcb     0
PlayerPrevGraceBlinkVisible:
        fcb     1
Enemy1Col:
        fcb     ENEMY1_START_COL
Enemy1Row:
        fcb     ENEMY1_ROW
Enemy1PrevCol:
        fcb     ENEMY1_START_COL
Enemy1PrevRow:
        fcb     ENEMY1_ROW
Enemy1PrevSprite:
        fcb     ENEMY1_SPRITE_SPAWN_A
Enemy1PrevState:
        fcb     ENEMY1_STATE_SPAWNING
Enemy1Dir:
        fcb     ENEMY_MOVE_RIGHT
Enemy1FrameCounter:
        fcb     0
Enemy1SpawnSeed:
        fcb     ENEMY1_SPAWN_SEED
Enemy1Phase2AiSeed:
        fcb     ENEMY1_PHASE2_AI_SEED
Enemy1StepFrames:
        fcb     ENEMY1_STEP_FRAMES
Enemy1Phase2StepFrames:
        fcb     ENEMY1_PHASE2_STEP_FRAMES
Enemy1Phase2ChaseRate:
        fcb     ENEMY1_PHASE2_CHASE_RATE
Enemy1Personality:
        fcb     ENEMY1_PERSONALITY_BALANCED
Enemy1SpawnTimer:
        fcb     ENEMY1_SPAWN_EFFECT_FRAMES
Enemy1State:
        fcb     ENEMY1_STATE_SPAWNING
Enemy1Sprite:
        fcb     ENEMY1_SPRITE_SPAWN_A
Enemy1SpawnFrameCounter:
        fdb     0
Enemy1Slot2Col:
        fcb     ENEMY1_START_COL
Enemy1Slot2Row:
        fcb     ENEMY1_ROW
Enemy1Slot2PrevCol:
        fcb     ENEMY1_START_COL
Enemy1Slot2PrevRow:
        fcb     ENEMY1_ROW
Enemy1Slot2PrevSprite:
        fcb     ENEMY1_SPRITE_SPAWN_A
Enemy1Slot2PrevState:
        fcb     ENEMY1_STATE_INACTIVE
Enemy1Slot2Dir:
        fcb     ENEMY_MOVE_RIGHT
Enemy1Slot2FrameCounter:
        fcb     0
Enemy1Slot2Phase2AiSeed:
        fcb     ENEMY1_PHASE2_AI_SEED
Enemy1Slot2StepFrames:
        fcb     ENEMY1_SLOT2_STEP_FRAMES
Enemy1Slot2Phase2StepFrames:
        fcb     ENEMY1_SLOT2_PHASE2_STEP_FRAMES
Enemy1Slot2Phase2ChaseRate:
        fcb     ENEMY1_SLOT2_PHASE2_CHASE_RATE
Enemy1Slot2Personality:
        fcb     ENEMY1_PERSONALITY_FLANKER
Enemy1Slot2SpawnTimer:
        fcb     0
Enemy1Slot2State:
        fcb     ENEMY1_STATE_INACTIVE
Enemy1Slot2Sprite:
        fcb     ENEMY1_SPRITE_SPAWN_A
Enemy1Slot3Col:
        fcb     ENEMY1_START_COL
Enemy1Slot3Row:
        fcb     ENEMY1_ROW
Enemy1Slot3PrevCol:
        fcb     ENEMY1_START_COL
Enemy1Slot3PrevRow:
        fcb     ENEMY1_ROW
Enemy1Slot3PrevSprite:
        fcb     ENEMY1_SPRITE_SPAWN_A
Enemy1Slot3PrevState:
        fcb     ENEMY1_STATE_INACTIVE
Enemy1Slot3Dir:
        fcb     ENEMY_MOVE_RIGHT
Enemy1Slot3FrameCounter:
        fcb     0
Enemy1Slot3Phase2AiSeed:
        fcb     ENEMY1_PHASE2_AI_SEED
Enemy1Slot3StepFrames:
        fcb     ENEMY1_SLOT3_STEP_FRAMES
Enemy1Slot3Phase2StepFrames:
        fcb     ENEMY1_SLOT3_PHASE2_STEP_FRAMES
Enemy1Slot3Phase2ChaseRate:
        fcb     ENEMY1_SLOT3_PHASE2_CHASE_RATE
Enemy1Slot3Personality:
        fcb     ENEMY1_PERSONALITY_DRIFTER
Enemy1Slot3SpawnTimer:
        fcb     0
Enemy1Slot3State:
        fcb     ENEMY1_STATE_INACTIVE
Enemy1Slot3Sprite:
        fcb     ENEMY1_SPRITE_SPAWN_A
Enemy1Slot4Col:
        fcb     ENEMY1_START_COL
Enemy1Slot4Row:
        fcb     ENEMY1_ROW
Enemy1Slot4PrevCol:
        fcb     ENEMY1_START_COL
Enemy1Slot4PrevRow:
        fcb     ENEMY1_ROW
Enemy1Slot4PrevSprite:
        fcb     ENEMY1_SPRITE_SPAWN_A
Enemy1Slot4PrevState:
        fcb     ENEMY1_STATE_INACTIVE
Enemy1Slot4Dir:
        fcb     ENEMY_MOVE_RIGHT
Enemy1Slot4FrameCounter:
        fcb     0
Enemy1Slot4Phase2AiSeed:
        fcb     ENEMY1_PHASE2_AI_SEED
Enemy1Slot4StepFrames:
        fcb     ENEMY1_SLOT4_STEP_FRAMES
Enemy1Slot4Phase2StepFrames:
        fcb     ENEMY1_SLOT4_PHASE3_STEP_FRAMES
Enemy1Slot4Phase2ChaseRate:
        fcb     ENEMY1_SLOT4_PHASE3_CHASE_RATE
Enemy1Slot4Personality:
        fcb     ENEMY1_PERSONALITY_PHASE3
Enemy1Slot4SpawnTimer:
        fcb     0
Enemy1Slot4State:
        fcb     ENEMY1_STATE_INACTIVE
Enemy1Slot4Sprite:
        fcb     ENEMY1_SPRITE_SPAWN_A
Enemy1SavedCol:
        fcb     ENEMY1_START_COL
Enemy1SavedRow:
        fcb     ENEMY1_ROW
Enemy1SavedPrevCol:
        fcb     ENEMY1_START_COL
Enemy1SavedPrevRow:
        fcb     ENEMY1_ROW
Enemy1SavedPrevSprite:
        fcb     ENEMY1_SPRITE_SPAWN_A
Enemy1SavedPrevState:
        fcb     ENEMY1_STATE_SPAWNING
Enemy1SavedDir:
        fcb     ENEMY_MOVE_RIGHT
Enemy1SavedFrameCounter:
        fcb     0
Enemy1SavedPhase2AiSeed:
        fcb     ENEMY1_PHASE2_AI_SEED
Enemy1SavedStepFrames:
        fcb     ENEMY1_STEP_FRAMES
Enemy1SavedPhase2StepFrames:
        fcb     ENEMY1_PHASE2_STEP_FRAMES
Enemy1SavedPhase2ChaseRate:
        fcb     ENEMY1_PHASE2_CHASE_RATE
Enemy1SavedPersonality:
        fcb     ENEMY1_PERSONALITY_BALANCED
Enemy1SavedSpawnTimer:
        fcb     ENEMY1_SPAWN_EFFECT_FRAMES
Enemy1SavedState:
        fcb     ENEMY1_STATE_SPAWNING
Enemy1SavedSprite:
        fcb     ENEMY1_SPRITE_SPAWN_A
Enemy2Col:
        fcb     ENEMY2_START_COL
Enemy2Row:
        fcb     ENEMY2_START_ROW
Enemy2PrevCol:
        fcb     ENEMY2_START_COL
Enemy2PrevRow:
        fcb     ENEMY2_START_ROW
Enemy2Dir:
        fcb     ENEMY_MOVE_DOWN
Enemy2Active:
        fcb     1
Enemy2PrevActive:
        fcb     1
Enemy2FrameCounter:
        fcb     0
Enemy2AiSeed:
        fcb     ENEMY2_AI_SEED
PowerActive:
        fcb     POWER_INACTIVE
PowerPrevActive:
        fcb     POWER_INACTIVE
PowerCol:
        fcb     POWER_MIN_COL
PowerRow:
        fcb     POWER_MIN_ROW
PowerPrevCol:
        fcb     POWER_MIN_COL
PowerPrevRow:
        fcb     POWER_MIN_ROW
PowerDirX:
        fcb     ENEMY_MOVE_RIGHT
PowerDirY:
        fcb     ENEMY_MOVE_DOWN
PowerMoveCounter:
        fcb     0
PowerSpawnArmed:
        fcb     0
PowerSpawnTimer:
        fdb     0
PowerFreezeTimer:
        fdb     0
PowerPrevFreezeActive:
        fcb     0
PowerPrevFreezeBlinkVisible:
        fcb     0
PowerSeed:
        fcb     ENEMY1_SPAWN_SEED
BonusItemActive:
        fcb     BONUS_ITEM_INACTIVE
BonusItemPrevActive:
        fcb     BONUS_ITEM_INACTIVE
BonusItemCol:
        fcb     POWER_MIN_COL
BonusItemRow:
        fcb     POWER_MIN_ROW
BonusItemPrevCol:
        fcb     POWER_MIN_COL
BonusItemPrevRow:
        fcb     POWER_MIN_ROW
BonusItemDirX:
        fcb     ENEMY_MOVE_RIGHT
BonusItemDirY:
        fcb     ENEMY_MOVE_DOWN
BonusItemMoveCounter:
        fcb     0
BonusItemSpawnArmed:
        fcb     0
BonusItemSpawnTimer:
        fdb     BONUS_ITEM_SPAWN_FRAMES
BonusItemSeed:
        fcb     $7D
EnergyItemActive:
        fcb     ENERGY_ITEM_INACTIVE
EnergyItemPrevActive:
        fcb     ENERGY_ITEM_INACTIVE
EnergyItemCol:
        fcb     POWER_MIN_COL
EnergyItemRow:
        fcb     POWER_MIN_ROW
EnergyItemPrevCol:
        fcb     POWER_MIN_COL
EnergyItemPrevRow:
        fcb     POWER_MIN_ROW
EnergyItemDirX:
        fcb     ENEMY_MOVE_RIGHT
EnergyItemDirY:
        fcb     ENEMY_MOVE_DOWN
EnergyItemMoveCounter:
        fcb     0
EnergyItemSpawnArmed:
        fcb     0
EnergyItemSpawnTimer:
        fdb     0
EnergyItemSeed:
        fcb     $B5
CurrentLevel:
        fcb     0
CurrentBombPositions:
        fdb     Level1BombPositions
CurrentPlatform1Row:
        fcb     PLATFORM1_ROW
CurrentPlatform1Start:
        fcb     PLATFORM1_START_COL
CurrentPlatform1Length:
        fcb     PLATFORM1_LENGTH
CurrentPlatform1End:
        fcb     PLATFORM1_END_COL
CurrentPlatform2Row:
        fcb     PLATFORM2_ROW
CurrentPlatform2Start:
        fcb     PLATFORM2_START_COL
CurrentPlatform2Length:
        fcb     PLATFORM2_LENGTH
CurrentPlatform2End:
        fcb     PLATFORM2_END_COL
CurrentPlatform3Row:
        fcb     PLATFORM3_ROW
CurrentPlatform3Start:
        fcb     PLATFORM3_START_COL
CurrentPlatform3Length:
        fcb     PLATFORM3_LENGTH
CurrentPlatform3End:
        fcb     PLATFORM3_END_COL
CurrentPlatform4Row:
        fcb     PLATFORM4_ROW
CurrentPlatform4Start:
        fcb     PLATFORM4_START_COL
CurrentPlatform4Length:
        fcb     PLATFORM4_LENGTH
CurrentPlatform4End:
        fcb     PLATFORM4_END_COL
CurrentPlatform5Row:
        fcb     PLATFORM5_ROW
CurrentPlatform5Start:
        fcb     PLATFORM5_START_COL
CurrentPlatform5Length:
        fcb     PLATFORM5_LENGTH
CurrentPlatform5End:
        fcb     PLATFORM5_END_COL
ScoreAddRemaining:
        fcb     0
LivesValue:
        fcb     START_LIVES
GameState:
        fcb     GAME_STATE_PLAYING
DeathAnimStepPhase:
        fcb     0
DeathSpritePhase:
        fcb     0
RespawnWaitTimer:
        fcb     0
LevelTransitionTimer:
        fcb     0
LevelMessageColorIndex:
        fcb     0
LevelMessageColorCounter:
        fcb     0
AttractScreenTimer:
        fcb     0
CheatSqueeptyIndex:
        fcb     0
InfiniteLivesFlag:
        fcb     0
CheatNextLevelHeld:
        fcb     0
NameEntryIndex:
        fcb     0
HallInsertIndex:
        fcb     0
HallShiftIndex:
        fcb     0
HallDrawRow:
        fcb     0
HallDrawRemaining:
        fcb     0
HallDrawEntryPtr:
        fdb     HallEntry1
HallCopySrc:
        fdb     HallEntry1
HallCopyDest:
        fdb     HallEntry1
PlayerLevelText:
        fcc     "01"
        fcb     0
PlayerScoreText:
        fcc     "0000"
        fcb     0
PlayerNameText:
        fcc     "A         "
        fcb     0
BombActiveFlags:
        fcb     1,1,1,1,1,1
        fcb     1,1,1,1,1,1
        fcb     1,1,1,1,1,1
BombLitIndex:
        fcb     1
BombScanIndex:
        fcb     1
BombScanRemaining:
        fcb     0
PlatformScanRemaining:
        fcb     0
BombScorePopupTimers:
        fcb     0,0,0,0,0,0
        fcb     0,0,0,0,0,0
        fcb     0,0,0,0,0,0
FrameStaticDirty:
        fcb     0
DrawRunCol:
        fcb     0
DrawRunRow:
        fcb     0
DrawRunRemaining:
        fcb     0
DrawObjectCol:
        fcb     0
DrawObjectRow:
        fcb     0
CheckRunStart:
        fcb     0
CheckRunEnd:
        fcb     0
CheckObjectCol:
        fcb     0
CheckObjectRow:
        fcb     0
