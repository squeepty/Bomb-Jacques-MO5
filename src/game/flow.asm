;==============================================================================
; game/flow.asm
;
; Top-level gameplay flow for Bomb Jacques.
;
; The game is organized as a single-byte state machine in GameState. The main
; loop in main.asm calls RunGameFrame forever; this file decides which state
; handler should run, which subsystems update, and which render passes are
; necessary. It is the best starting point for understanding the runtime.
;
; A key rendering idea lives here too: before gameplay mutates positions, the
; Save...RenderState routines copy current values into "Prev" variables. Later,
; rendering compares previous/current values to erase and redraw only changed
; cells. That avoids flicker outside the active game area and keeps the MO5 work
; small enough for a simple busy-wait frame loop.
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
        ; Hall data lives in RAM so it can be edited during play. Seed it once
        ; at cold start before any title/hall screens can display it.
        jsr     InitHallOfFameDefaults
        jsr     ClearScreen
        jmp     EnterTitleScreen

StartNewGame:
        ; A brand-new game always begins on level index 0. StartCurrentLevel
        ; sets level-specific objects, while the score/lives reset happens here
        ; because those belong to the whole run rather than one level.
        clr     CurrentLevel
        jsr     StartCurrentLevel

        ; Clear transient state that might have been left by a previous run,
        ; level transition, death animation, or respawn pause.
        clr     LevelTransitionTimer
        clr     LevelMessageColorIndex
        clr     LevelMessageColorCounter
        clr     DeathAnimStepPhase
        clr     DeathSpritePhase
        clr     RespawnWaitTimer
        clr     PlayerGraceTimer
        lda     #START_LIVES
        sta     LivesValue

        ; Score digits are stored as display-ready ASCII. This keeps DrawScore
        ; very cheap: it draws the four bytes directly as glyphs.
        lda     #'0'
        sta     ScoreThousandsText
        sta     ScoreHundredsText
        sta     ScoreTensText
        sta     ScoreOnesText

        ; Only the game area is cleared here. The sidebar/chrome were already
        ; drawn by the attract screens, so preserving them avoids a full-screen
        ; flash when play starts.
        jsr     ClearGameArea
        jsr     DrawGameplayStatus
        jsr     DrawStaticArena
        jsr     DrawPlayer
        jmp     EnterGetReadyState

EnterTitleScreen:
        ; Full entry points redraw the shared frame/sidebar. The NoChrome
        ; variants below swap only the center content during attract cycling.
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
        ; Return A=0 while the timer is still running and A=1 when the caller
        ; should switch to the other attract screen.
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
        ; The SQUEEPTY cheat is recognized only from one-shot key presses, not
        ; held keys, so a long key hold cannot accidentally advance the sequence.
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
        ; The next-level cheat reads the raw keyboard matrix directly because
        ; the normalized gameplay input only tracks directions and jump.
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
        ; Straight compare/branch dispatch is verbose but beginner-friendly and
        ; easy to inspect in a monitor. Long branches are used because the state
        ; handlers can move farther away as the project grows.
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

        ; Snapshot what is currently on screen before simulation mutates object
        ; positions. Later erase/draw routines compare previous and current
        ; fields to decide whether a cell actually needs work.
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

        ; During a freeze power-up, enemies remain drawn but do not advance.
        ; Collision code below can still collect them for points.
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
        ; Moving sprites are erased first. If an erase exposes arena content,
        ; MarkStaticRedraw asks DrawStaticArenaIfDirty to restore platforms,
        ; bombs, and popups before sprites are drawn at their new positions.
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
        ; Death/respawn keep the same chrome and sidebar visible. Only the
        ; active arena objects are redrawn when needed.
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
        ; Attract screens still read the name-entry keyboard table because the
        ; hidden cheat is typed as letters, not as gameplay directions.
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
        ; Previous player state means "what the screen currently shows", not
        ; merely "what the last simulation frame computed".
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
        ; Enemy 1 has four logical slots. Slot 1 is stored in the work variables
        ; directly; slots 2-4 have their own previous/current fields.
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
        ; The freeze effect changes rendering even if enemy coordinates do not,
        ; so the previous freeze-active/blink-visible values are tracked here.
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
