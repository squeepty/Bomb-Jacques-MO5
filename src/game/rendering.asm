;==============================================================================
; game/rendering.asm
;
; All game-specific drawing routines.
;
; The low-level MO5 video primitives live in video.asm. This module uses those
; primitives to draw title/hall screens, sidebar status, arena platforms, bombs,
; enemies, items, and Jacques. Most moving objects are 2x2 text cells. Drawing
; code therefore tends to store the top-left cell in DrawObjectCol/Row, draw four
; cells in top-left/top-right/bottom-left/bottom-right order, and then return.
;
; The active-game renderer is "dirty" rather than full-screen: it erases objects
; only when their previous/current state differs, restores static arena content
; if an erase exposed it, and redraws only objects that need it.
;==============================================================================

;------------------------------------------------------------------------------
DrawTitleScreen:
        ; Title and hall screens reuse the game-area rectangle. The chrome and
        ; sidebar are handled by flow.asm entry points.
        jsr     ClearGameArea

        ; Text cells are colored by first drawing empty 8x8 cells with the
        ; desired color attribute, then drawing glyph bitmap bits over them.
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
        ; Each title table entry reserves two rows of colored text cells so the
        ; icon can sit beside centered name/score text.
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
        ; CellAddress returns byte addresses for the top-left of a text cell.
        ; Adding TITLE_CENTER_TEXT_OFFSET nudges the text inside the wider row.
        jsr     CellAddress
        leax    TITLE_CENTER_TEXT_OFFSET,x
        leay    TITLE_CENTER_TEXT_OFFSET,y

DrawTitleCenteredStringNext:
        lda     ,u+
        beq     DrawTitleCenteredStringDone

        ; DrawGlyphAtCell uses X/Y/U, so save the current string/destination
        ; pointers around the call.
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
        ; U points at the first 8x8 cell pattern. DrawCellPatternMasked advances
        ; U by eight bytes, so the next call naturally draws the next quadrant.
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
        ; Chrome is the fixed frame: top/left/bottom border, sidebar fill, and
        ; right margin. It is redrawn only on screen transitions that need it.
        jsr     DrawTopBorder
        jsr     DrawLeftBorder
        jsr     DrawBottomBorder
        jsr     DrawSidebarBackground
        jmp     DrawRightMargin

DrawTopBorder:
        ; Border routines are simple nested loops over text-cell coordinates.
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
        ; Full HUD draw includes chrome. Gameplay status updates below touch only
        ; the changing label/score/lives elements.
        jsr     DrawScreenChrome
        jsr     DrawLevelLabel
        jmp     DrawHudSidebar

DrawGameplayStatus:
        ; Used when starting a game: draw status content without repainting the
        ; whole outside-of-game area.
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
        ; Update the mutable "LEVEL 01" string before drawing its glyphs.
        jsr     UpdateLevelLabelText
        lda     #COLOR_LEVEL
        sta     DrawCellColor
        jsr     DrawLevelLabelCells
        ldu     #LevelLabelText
        lda     #LEVEL_LABEL_COL
        ldb     #LEVEL_LABEL_ROW
        jmp     DrawStringDown4

EraseLevelLabel:
        ; At game over the level indicator is removed by repainting its cells as
        ; border-colored empties.
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
        ; Levels are displayed 01-10 while CurrentLevel is stored as 0-9.
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
        ; Sidebar art is wider than one text cell, so it writes raw consecutive
        ; video bytes instead of going through DrawCellPattern.
        jsr     SelectBitmapPlane
        ldx     #VIDEO_BITMAP_BASE+SIDEBAR_ART_BASE_OFFSET
        ldu     #SidebarArtBitmap
        ldy     #SIDEBAR_ART_PIXEL_ROWS

DrawSidebarArtBitmapRow:
        ldb     #SIDEBAR_ART_BYTES_PER_ROW

DrawSidebarArtBitmapByte:
        ; Copy seven bitmap bytes, then skip the remainder of the 40-byte video
        ; scanline to reach the next art row.
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
        ; The color plane gets one matching color byte for every art bitmap byte.
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
        ; LivesValue is a count, but the sidebar has three fixed icon slots.
        ; Each slot is independently drawn or erased.
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
        ; Life icons are drawn with direct video offsets because they always live
        ; in the sidebar at LIFE_ICON_BASE_OFFSET and use a fixed 2x2 sprite.
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
        ; Top-left and top-right sprite bytes are written side by side, then X
        ; jumps down one physical scanline.
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
        ; Erasing a life icon restores sidebar color, not game-area background.
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
        ; First clear/recolor the four score cells, then draw the ASCII digit
        ; string that scoring_hall.asm maintains.
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
        ; Color cycling is a table lookup indexed by LevelMessageColorIndex.
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
        ; DrawRunCol/Row/Remaining form a tiny parameter block for horizontal
        ; runs of empty colored cells.
        ldu     #CellEmpty
        lda     DrawRunCol
        ldb     DrawRunRow
        jsr     DrawCellPattern
        inc     DrawRunCol
        dec     DrawRunRemaining
        bne     DrawTextCells
        rts

ClearGameArea:
        ; Clear only the playable arena rows, leaving border and sidebar alone.
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
        ; Hall rows are just colored text bands plus fixed strings. The mutable
        ; entries were prepared by scoring_hall.asm.
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
        ; HallDrawRemaining counts down. Subtracting it from constants derives
        ; both the color-table row and the displayed rank.
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
        ; Name entry uses the same title/header style as the hall, then draws
        ; the editable PlayerNameText field.
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
        ; B is the line-color index on entry. The table keeps hall title/header
        ; colors separate from normal entry rows.
        ldx     #HallLineColors
        lda     b,x
        sta     DrawCellColor
        rts

DrawPlayerNameEntry:
        ; Redraw the whole ten-character name field after each edit. It is small
        ; enough that per-character dirty tracking would add more complexity.
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
        ; Static arena means "things that moving sprites may erase over":
        ; platforms, bombs, and any active bomb score popups.
        ldx     #CurrentPlatform1Row
        lda     #PLATFORM_RUN_COUNT
        sta     PlatformScanRemaining

DrawStaticArenaPlatformLoop:
        ; DrawPlatformRun expects A=start column, B=row, Y=length.
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
        ; One byte is enough to say "a sprite erase may have damaged static
        ; background; redraw static arena before drawing moving objects."
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
        ; BombActiveFlags and CurrentBombPositions are scanned in parallel, just
        ; as in collection_death.asm.
        lda     #1
        sta     BombScanIndex
        lda     #BOMB_COUNT
        sta     BombScanRemaining
        ldx     #BombActiveFlags
        ldu     CurrentBombPositions

DrawBombsLoop:
        lda     ,x
        beq     DrawBombsNext

        ; The lit bomb uses alternate cells/color but still occupies the same
        ; 2x2 footprint.
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
        ; A non-zero timer means draw a "200" sprite at that bomb's coordinates.
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
        ; Platform length includes both end caps. After the left cap, subtract
        ; two so Y counts only middle cells before the right cap.
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
        ; Erase slot 1, then temporarily load each additional slot into the
        ; shared Enemy1* work variables and use the same erase helper.
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
        ; Draw only active slots whose current state differs from their saved
        ; previous render state, or when static background was refreshed.
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
        ; Full draw used after clearing/redrawing the arena, such as respawn.
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
        ; If the previous state was inactive, nothing was drawn last frame and
        ; there is nothing to erase.
        lda     Enemy1PrevState
        cmpa    #ENEMY1_STATE_INACTIVE
        beq     EraseEnemyUnchanged
        ; Freeze/blink changes can make a stationary enemy appear/disappear, so
        ; they count as render changes even when coordinates match.
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
        ; Convert the 16-bit timer to a boolean active flag, then compare both
        ; active state and blink visibility against the saved previous values.
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
        ; Early in the freeze window, enemies are always visible. Near the end,
        ; a timer bit toggles visibility to warn the player.
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
        ; Drawing can be required because the enemy changed, because static
        ; background was redrawn under it, or because freeze blink changed.
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
        ; Enemy2 has no sprite-state byte, so position/active/freeze state are
        ; enough to decide whether its old footprint must be erased.
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
        ; If Enemy2 just became active, draw it even though no previous active
        ; state exists to compare against.
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
        ; Pickup erases are identical in shape: if the item was visible and then
        ; moved or disappeared, erase its old 2x2 footprint.
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
        ; Active pickups are cheap to redraw, so this routine only gates on
        ; visibility. Erase helpers already handled the old footprint.
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
        ; If the player was hidden by grace blinking last frame, there is no old
        ; player sprite to erase.
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
        ; The player may need a redraw because he moved, changed pose, blinked
        ; visible, or because static background was refreshed under him.
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
        ; During grace, one timer bit decides whether the player is shown. When
        ; grace reaches zero, the player is always visible.
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
        ; Death can move the player above the arena; hide the sprite once its
        ; top-left row is above ARENA_TOP_ROW.
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
        ; Erasing the player is not always just background: near edges, part of
        ; the 2x2 footprint may be border, so each cell is restored separately.
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
        ; Decide which kind of empty cell belongs under this coordinate.
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
        ; Small wrapper: choose color/pattern, restore A/B, call the generic
        ; 8x8 cell draw routine.
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
        ; Enemies/items/bombs are always erased back to game-area background.
        ; If a platform or bomb was underneath, FrameStaticDirty will trigger a
        ; static redraw after the erase.
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
        ; Freeze overrides the enemy's normal sprite. When the blink says hidden,
        ; the caller leaves the restored background visible.
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
        ; Enemy1Sprite selects spawn/phase sprites. The normal phase-1 walker
        ; falls back to direction-based left/right art.
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
        ; Most 2x2 sprites are stored as four consecutive 8-byte cell patterns:
        ; top-left, top-right, bottom-left, bottom-right.
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
        ; Enemy2 uses its own color and direction art but shares frozen rendering
        ; and 2x2 draw order with Enemy1.
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
        ; Power/bonus/energy share DrawPowerCells because their art is also four
        ; consecutive 8-byte cell patterns.
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
        ; Bomb quadrants are separate labels rather than one contiguous 32-byte
        ; block, so each quadrant loads U explicitly.
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
        ; The score popup is drawn opaque with DrawCellPattern, replacing the
        ; bomb cells for the duration of the timer.
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
        ; Bomb erases also go to background; platform/bomb redraw is handled by
        ; the static arena pass when needed.
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
        ; PlayerSprite is a small numeric index. Doubling it selects the
        ; corresponding 16-bit pointer from PlayerSpriteTable.
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
