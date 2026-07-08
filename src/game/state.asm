;==============================================================================
; game/state.asm
;
; Mutable gameplay state.
;
; These labels emit initialized bytes into the program image. When the MO5 loads
; the game, this block starts with the values below, and routines mutate those
; bytes in place. The reset routines in level_setup.asm and flow.asm restore the
; subsets that must return to known values between games, levels, or lives.
;
; `fcb` reserves/emits one byte. `fdb` reserves/emits one 16-bit word/address.
;==============================================================================

;------------------------------------------------------------------------------
; Player position, movement, sprite, and blink state
;------------------------------------------------------------------------------
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

;------------------------------------------------------------------------------
; Enemy 1 slot 1 work variables
;
; UpdateEnemy1 only reads/writes this field set. Extra slots are copied into
; these variables before running the shared routine.
;------------------------------------------------------------------------------
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

;------------------------------------------------------------------------------
; Enemy 1 slots 2-4
;
; These mirror the work-variable layout for additional logical enemies. Each
; slot has its own tuning values so shared AI code can still feel different.
;------------------------------------------------------------------------------
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

;------------------------------------------------------------------------------
; Save area used while updating/drawing enemy 1 slots 2-4
;------------------------------------------------------------------------------
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

;------------------------------------------------------------------------------
; Enemy 2 flyer state
;------------------------------------------------------------------------------
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

;------------------------------------------------------------------------------
; Power item and freeze-effect state
;------------------------------------------------------------------------------
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

;------------------------------------------------------------------------------
; Bonus and energy item state
;------------------------------------------------------------------------------
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

;------------------------------------------------------------------------------
; Current level pointers and mutable platform records
;
; CurrentBombPositions points at the selected level's bomb coordinate table.
; Platform records are expanded to row,start,length,end for faster collision.
;------------------------------------------------------------------------------
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

;------------------------------------------------------------------------------
; Run state, timers, cheats, and hall-of-fame editing scratch
;------------------------------------------------------------------------------
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

;------------------------------------------------------------------------------
; Bomb flags, scan counters, popup timers, and draw/collision scratch bytes
;------------------------------------------------------------------------------
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
RestoreScanIndex:
        fcb     0
RestoreScanRemaining:
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
