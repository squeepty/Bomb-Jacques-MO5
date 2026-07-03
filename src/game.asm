;==============================================================================
; game.asm
;
; Gameplay include manifest.
;
; LWASM pastes each included file at this point, so this list is the physical
; order of the gameplay code and data in the final binary. Keeping this file as
; a manifest makes the large game easier to study while preserving the same
; address layout as the former monolithic game.asm.
;
; Reading order for learning:
;   flow.asm              frame/state-machine entry points
;   level_setup.asm       level data copied into mutable state
;   player_update.asm     high-level player update pipeline
;   items/enemies.asm     moving non-player objects
;   player_movement.asm   collision helpers shared by player and enemies
;   collection_death.asm  pickups, damage, respawn, game over
;   scoring_hall.asm      score digits and hall-of-fame mutation
;   level_flow.asm        lit bomb, popups, level transitions
;   rendering.asm         dirty redraw and sprite/cell drawing
;   tables/sprites/state  data, sprite bytes, and RAM variables
;==============================================================================

        include "game/flow.asm"
        include "game/level_setup.asm"
        include "game/player_update.asm"
        include "game/items.asm"
        include "game/enemies.asm"
        include "game/player_movement.asm"
        include "game/collection_death.asm"
        include "game/scoring_hall.asm"
        include "game/level_flow.asm"
        include "game/rendering.asm"
        include "game/tables.asm"
        include "game/sprites.asm"
        include "game/state.asm"
