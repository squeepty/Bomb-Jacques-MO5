;==============================================================================
; game/items.asm
;
; Moving pickup systems: power, bonus, and energy.
;
; Each item uses the same small state model:
;   Active byte        0 = absent, 1 = visible/moving
;   SpawnArmed byte    whether a countdown may create the item
;   SpawnTimer word    countdown in active-play ticks
;   Col/Row + DirX/Y   current 2x2-cell footprint and bounce direction
;
; The power item also owns PowerFreezeTimer. While that word is non-zero, enemy
; movement pauses and the renderer draws enemies with the frozen sprite/blink.
;==============================================================================

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
        ; A non-zero freeze timer means the collectible is gone and only the
        ; temporary frozen-enemy effect remains to update.
        ldd     PowerFreezeTimer
        beq     UpdatePowerNoFreeze

        subd    #1
        std     PowerFreezeTimer
        lbne    UpdatePowerDone
        jsr     EndPowerFreeze
        rts

UpdatePowerNoFreeze:
        ; If the power is already visible, skip spawn scheduling and move it.
        lda     PowerActive
        cmpa    #POWER_ACTIVE
        beq     UpdatePowerMove

        ; SpawnArmed gates the timer. This lets other systems schedule a future
        ; spawn without needing a special state value in PowerActive.
        lda     PowerSpawnArmed
        lbeq    UpdatePowerDone
        ldd     PowerSpawnTimer
        beq     SpawnPower
        subd    #1
        std     PowerSpawnTimer
        lbne    UpdatePowerDone

SpawnPower:
        ; Advance the seed, mask to 0-7, then use that value as an index into
        ; parallel column/row spawn tables.
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
        ; Direction values reuse ENEMY_MOVE_LEFT/RIGHT/UP/DOWN: $FF for
        ; negative movement and 1 for positive movement.
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
        ; Items move one cell only every POWER_STEP_FRAMES ticks. The frame
        ; counter keeps visual speed slower than the main frame loop.
        inc     PowerMoveCounter
        lda     PowerMoveCounter
        cmpa    #POWER_STEP_FRAMES
        lblo    UpdatePowerDone
        clr     PowerMoveCounter

        lda     PowerDirX
        bmi     UpdatePowerMoveLeft

        ; Horizontal movement tries the current direction, bounces at bounds or
        ; solid cells, then vertical movement repeats the same idea.
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
        ; Items use the same 2x2 overlap helper as enemies because their
        ; footprints are the same size as enemy sprites.
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
        ; Collecting power arms the later energy item, giving the run a delayed
        ; extra-life opportunity.
        lda     #1
        sta     EnergyItemSpawnArmed
        ldd     #ENERGY_ITEM_SPAWN_AFTER_POWER_FRAMES
        std     EnergyItemSpawnTimer
        jsr     ForcePlayerRedraw
        jsr     SoundRewardChirp

CheckPowerCollectionDone:
        rts

UpdateBonusItemSystem:
        ; Bonus has no freeze timer; it is either waiting to spawn, moving, or
        ; absent after collection.
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
        ; Mix nearby AI seeds into the bonus seed. If the XOR collapses to zero,
        ; substitute a non-zero seed so the LFSR can keep moving.
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
        ; Bonus collection awards points and schedules the power item later in
        ; the run.
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
        jsr     SoundLevelClear
        jsr     ForcePlayerRedraw

CheckBonusItemCollectionDone:
        rts

AdvanceBonusItemSeed:
        ; Tiny 8-bit LFSR-style step. LSRA shifts the seed; if the old low bit
        ; was 1, EORA applies the feedback mask.
        lda     BonusItemSeed
        lsra
        bcc     AdvanceBonusItemSeedStore
        eora    #$B8

AdvanceBonusItemSeedStore:
        sta     BonusItemSeed
        rts

UpdateEnergyItemSystem:
        ; Energy mirrors bonus movement but is armed only after power collection.
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
        ; Energy gets its own seed mix so it does not always reuse the previous
        ; bonus/power route through the spawn table.
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
        ; Energy collection never schedules another item; it only attempts to
        ; increase the life counter.
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
        jsr     SoundLevelClear
        jsr     ForcePlayerRedraw

CheckEnergyItemCollectionDone:
        rts

AddEnergyItemLife:
        ; START_LIVES is also the maximum life display. Extra energy at max
        ; lives is harmless and leaves the icons unchanged.
        lda     LivesValue
        cmpa    #START_LIVES
        bhs     AddEnergyItemLifeDone
        inc     LivesValue
        jsr     DrawLives

AddEnergyItemLifeDone:
        rts

AdvanceEnergyItemSeed:
        ; Same feedback step as bonus/power, kept separate so each item can have
        ; independent pseudo-random state.
        lda     EnergyItemSeed
        lsra
        bcc     AdvanceEnergyItemSeedStore
        eora    #$B8

AdvanceEnergyItemSeedStore:
        sta     EnergyItemSeed
        rts

EndPowerFreeze:
        ; Freeze ending can bring back enemy 2 if it was eaten while frozen.
        jsr     RespawnEnemy2AfterPowerIfEaten
        jmp     DisablePowerSpawn

RespawnEnemy2AfterPowerIfEaten:
        lda     Enemy2Active
        beq     RespawnEnemy2
        rts

RespawnEnemy2:
        ; Enemy 2 returns to its initial flyer state rather than resuming where
        ; it was collected.
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
        ; Clearing both bytes of the timer keeps future 16-bit LDD checks simple.
        clr     PowerSpawnArmed
        clr     PowerSpawnTimer
        clr     PowerSpawnTimer+1
        rts

AdvancePowerSeed:
        ; Same 8-bit LFSR-style seed advance used by the other moving items.
        lda     PowerSeed
        lsra
        bcc     AdvancePowerSeedStore
        eora    #$B8

AdvancePowerSeedStore:
        sta     PowerSeed

        rts
