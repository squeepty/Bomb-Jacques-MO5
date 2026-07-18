;==============================================================================
; game/enemies.asm
;
; Enemy spawning, slot management, and AI movement.
;
; Enemy 1 is implemented as one reusable "work" enemy plus three extra saved
; slots. UpdateEnemy1 operates only on the Enemy1* work variables. Slot 2-4 are
; updated by loading their fields into Enemy1*, running the shared routine, and
; storing the result back. This saves code space on a small 8-bit system at the
; cost of explicit copy routines.
;
; Enemy 2 is simpler: one active flyer with its own position, direction, frame
; counter, and AI seed.
;==============================================================================

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
        ; Slot 1 already lives in the Enemy1* work variables.
        lda     Enemy1State
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     UpdateEnemy1AllSave
        jsr     UpdateEnemy1

UpdateEnemy1AllSave:
        ; Preserve slot 1 before temporarily reusing the work variables for the
        ; other logical enemies.
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
;   timing model is redesigned around a 50 Hz IRQ.
;
; Modified:
;   A, B, D, X
;------------------------------------------------------------------------------
UpdateEnemy1SpawnSchedule:
        ; Frozen time pauses spawning as well as movement, so the player can use
        ; the power-up window without new enemy-1 slots appearing.
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
        ; The spawn interval is a 16-bit counter because it can exceed 255 ticks.
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
        ; Spawn into the first inactive slot. This keeps enemy pressure growing
        ; predictably from slot 1 through slot 4.
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
        ; For slot 2+, start the shared spawn effect in work variables, then
        ; stamp per-slot personality/timing before storing the slot back.
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
        ; Manual struct copy: each Enemy1* work field has a matching Saved field.
        ; This is verbose, but it is transparent and assembler-portable.
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
        ; Restore slot 1 after a slot 2-4 load/update/store pass.
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
        ; Load a logical enemy slot into the shared Enemy1* work variables.
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
        ; Store only current simulation fields. Previous-render fields are saved
        ; separately by SaveEnemyRenderState before movement begins.
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
        ; Slot 3 uses the same field layout as slot 2, with different defaults.
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
        ; Slot 4 is the phase-3 personality slot. The copy mechanics are the
        ; same even though its tuning constants differ.
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
        ; State dispatch for one loaded Enemy1 slot. Phase 2 and phase 3 share
        ; the hunter movement routine; sprite selection distinguishes them.
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

        ; Phase 1 is a platform walker. Reaching the floor transforms it into a
        ; chasing phase instead of continuing as a walker.
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
        ; Enemy1SpawnTimer is reused here as a direction-hold counter after the
        ; spawn effect has finished.
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
        ; Falling clears the direction-hold counter so the next platform landing
        ; can choose a fresh walking direction.
        clr     Enemy1SpawnTimer
        inc     Enemy1Row
        jsr     IsEnemy1OnFloor
        bne     UpdateEnemy1Transform

UpdateEnemy1Done:
        rts

UpdateEnemy1Transform:
        jmp     TransformEnemy1ToPhase2

UpdateEnemy1Spawning:
        ; Spawn states show an animated sprite for a fixed countdown before the
        ; enemy becomes collidable as a normal active enemy.
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
        ; Phase3 personality skips the phase-2 sprite/state and transforms into
        ; the stronger phase-3 hunter instead.
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
        ; Staggered counters prevent all slots from stepping on the same frame,
        ; which reads as smoother movement and lowers per-frame work spikes.
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
        ; Spawn columns are table-driven. The seed is masked to the table size
        ; and then used as an indexed offset.
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
        ; A single timer bit toggles between the two spawn sprite frames.
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
        ; 8-bit LFSR-style pseudo-random step. The carry from LSRA tells whether
        ; the feedback mask should be applied.
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
        ; Phase-2/phase-3 movement has its own speed counter, separate from the
        ; falling-walker speed used in phase 1.
        inc     Enemy1FrameCounter
        lda     Enemy1FrameCounter
        cmpa    Enemy1Phase2StepFrames
        lblo    UpdateEnemy1Done
        clr     Enemy1FrameCounter

        jsr     Enemy1Phase2Roll10
        ; Roll10 returns 0-9. Values below ChaseRate choose pursuit; the rest
        ; choose wandering, giving a small amount of unpredictability.
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
        ; Personalities bias chase order: balanced prefers vertical first,
        ; flanker prefers horizontal first, drifter alternates by seed bit.
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
        ; TryMove routines return A=1 on success and A=0 on blocked/no move.
        ; That lets chase code chain attempts with BNE/BEQ.
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
        ; A detour is attempted when a direct vertical chase step hits a
        ; platform. Different personalities choose different side-step orders.
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
        ; Masking an LFSR byte gives 0-15; reject 10-15 so chase probability is
        ; based on a true 0-9 range.
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
        ; Enemy2 uses the same chase/wander shape as phase-2 Enemy1 but without
        ; spawn phases, slot copying, or sprite-state transforms.
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
        ; Enemy2 detours away from Jacques horizontally when vertical movement
        ; is blocked, then falls back through the remaining directions.
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
        ; Same rejection-sampling trick as Enemy1Phase2Roll10.
        jsr     AdvanceEnemy2AiSeed
        anda    #$0F
        cmpa    #10
        bhs     Enemy2Roll10
        rts

AdvanceEnemy2AiSeed:
        ; Independent LFSR-style seed for the flyer.
        lda     Enemy2AiSeed
        lsra
        bcc     AdvanceEnemy2AiSeedStore
        eora    #$B8

AdvanceEnemy2AiSeedStore:
        sta     Enemy2AiSeed
        rts

UpdateEnemy2Done:
        rts
