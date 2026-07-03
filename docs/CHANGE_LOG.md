# Change Log

## Post BUILD 008 Maintenance

Changed:

- Split the former `src/game.asm` monolith into focused `src/game/*.asm`
  modules while keeping `src/game.asm` as an include-order manifest.
- Preserved the original assembler order so the split is source organization
  only, not a gameplay or binary-layout change.
- Updated the browser sprite editor to read and write gameplay sprites from
  `src/game/sprites.asm`.
- Fixed the sprite editor label parser so the final label in a sprite file is
  handled correctly at end of file.
- Updated README and learning docs to reference the split gameplay layout.

Observed:

- `tools/build.sh` passes after the split.
- Rebuilt `build/bomb-jacques.k7` is byte-identical to
  `downloads/bomb-jacques.k7`.
- K7 SHA-256 remains
  `767114b73b45c30f6c466a595cbfef49acb850e4d4c5ae27b607bef02aed0cf8`.
- Sprite editor API smoke test reads 25 gameplay sprites and 896 sidebar art
  bytes.
- No regression issue found after review/testing of the split.

Status:

- Conservative source-organization cleanup complete.

## BUILD 008

Added:

- Title screen and hall-of-fame attract flow.
- Ten handcrafted levels with recent platform and bomb spacing polish.
- Name entry and hall-of-fame score insertion.
- Sequential bonus/power/energy item timing.
- Energy ball collection that restores one life when below 3 lives.
- Power freeze reduced to about 6 seconds, with frozen enemies blinking for the
  final 2 seconds.
- Frozen enemy rendering now replaces normal enemy sprites instead of overlaying
  transparent frozen art.
- Death flow where Jacques flies straight up offscreen at one-third normal
  movement speed, with movement frozen and respawn grace afterward.
- Front-facing player sprite used on spawn and after landing.
- Regenerated player walk-right sprite from reference art and mirrored
  walk-left sprite, both shifted down one pixel row.
- Right-panel `SidebarArtBitmap` art pass, including the bottom `JACQUES`
  banner.
- Browser sprite editor improvements: draw/erase tools, drag painting, live
  preview, sprite save/rebuild, and a `Right Panel` tab for the sidebar pixel
  art.
- `SQUEEPTY` cheat support for infinite lives and `N` next-level skip.
- Low-risk movement-counter staggering for smoother perceived enemy motion.
- BUILD 008 labels and load notes.

Expected:

- Program loads at `$6000`.
- `BOMB JACQUES BUILD 008` appears in-game.
- Title and hall-of-fame screens alternate until start is pressed.
- Gameplay supports score, lives, bombs, lit bombs, bonus/power/energy balls,
  frozen enemies, death/respawn, level clear, get-ready, name entry, and ten
  levels.
- The sprite editor runs from `node tools/sprite-editor.mjs` and can edit both
  gameplay sprites and the right-panel bitmap.

Observed:

- Assembles successfully with `lwasm`.
- Current milestone is tagged `milestone-game-feature-complete`.

Status:

- Game feature-complete milestone.

## BUILD 007

Added:

- Lives state starting at 3 lives.
- Visible `LIVES` HUD counter.
- Death state after touching either enemy.
- Short input-freezing death pause.
- Respawn at the starting position while lives remain.
- `GAME OVER` state and message when lives reach 0.
- PNG-spec sprite tuning for platforms, the 2x2 player, 2x2 bombs, and 2x2
  enemies.
- Left/middle/right platform tiles with rounded slab ends.
- Direction-specific left/right enemy sprite data.
- Stopped player sprite preserves the last left/right facing direction.
- Platform landing holds the straight jump sprite until a new movement or jump.
- Released jump now ends the upward rise instead of continuing until blocked.
- Enemy 1 now spawns from varied top columns, falls, walks on platforms, and
  transforms into phase 2 after reaching the bottom floor.
- Enemy 1 spawn is preceded by a one-second two-frame spawn effect.
- Enemy 1 phase-2 transition reuses the same one-second two-frame effect.
- Enemy 1 phase 2 uses new left/right sprites and flies with the same attraction
  model as enemy 2.
- Enemy 1 phase 2 and enemy 2 now use an 80% attraction rate toward Jacques and
  20% wandering movement.
- Extra temporary font glyphs for `G` and `V`.
- BUILD 007 labels and load notes.

Expected:

- Program loads at `$6000`.
- `BOMB JACQUES BUILD 007`, `LIVES 3`, and `SCORE 0000` appear at the top of
  the screen.
- Touching either enemy flashes `HIT`, subtracts one life, pauses briefly, and
  respawns Jacques at the starting position while lives remain.
- After the last life is lost, `GAME OVER` appears and gameplay stops.
- Bomb collection, bonus scoring, bonus highlight advancement, enemy 1
  spawn/falling/phase-2 behavior, and enemy 2 attraction flight still work.

Observed:

- Assembles successfully with `lwasm`.
- Emulator behavior still needs DCMOTO verification.

Status:

- Ready for emulator test.

## BUILD 006

Added:

- Second enemy state and fixed vertical patrol.
- Distinct second-enemy sprite and color.
- Player/enemy collision checks against both enemies.
- BUILD 006 labels and load notes.

Expected:

- Program loads at `$6000`.
- `BOMB JACQUES BUILD 006` and `SCORE 00` appear at the top of the screen.
- One enemy patrols along the floor.
- A second enemy patrols vertically above the right platform.
- Touching either enemy flashes `HIT` and returns Jacques to the starting
  position.
- Bomb collection, bonus scoring, and bonus highlight advancement still work.

Observed:

- Assembles successfully with `lwasm`.
- Emulator behavior still needs DCMOTO verification.

Status:

- Ready for emulator test.

## BUILD 005

Added:

- First enemy state and fixed horizontal patrol.
- 2x2 enemy sprite and color.
- Player/enemy collision against Jacques' 2x3 footprint.
- Temporary `HIT` HUD flash after touching the enemy.
- Player reset to the starting position after an enemy hit.
- Extra temporary font glyphs for `H` and `T`.

Expected:

- Program loads at `$6000`.
- `BOMB JACQUES BUILD 005` and `SCORE 00` appear at the top of the screen.
- One enemy patrols along the floor.
- Touching the enemy flashes `HIT` and returns Jacques to the starting position.
- Bomb collection, bonus scoring, and bonus highlight advancement still work.

Observed:

- Assembles successfully with `lwasm`.
- Emulator behavior still needs DCMOTO verification.

Status:

- Ready for emulator test.

## BUILD 004

Added:

- Highlighted bonus bomb state.
- Distinct lit-bomb cell pattern and color.
- Bonus scoring: highlighted bombs award 200 points, other bombs award 50
  points.
- Highlight advancement to the next remaining active bomb.
- Four-digit score display.
- Temporary `BONUS` HUD flash after collecting the highlighted bomb.
- Extra temporary font glyphs for digits `6`, `7`, `8`, `9`, and `N`.

Expected:

- Program loads at `$6000`.
- `BOMB JACQUES BUILD 004` and `SCORE 00` appear at the top of the screen.
- One bomb appears visually highlighted.
- Touching the highlighted bomb removes it, adds 200 points, flashes `BONUS`,
  and moves the highlight to another active bomb.
- Touching any non-highlighted bomb removes it and adds 50 points.

Observed:

- Assembles successfully with `lwasm`.
- Emulator behavior still needs DCMOTO verification.

Status:

- Ready for emulator test.

## BUILD 003

Added:

- Bomb active flags.
- Player/bomb overlap checks.
- Bomb removal after collection.
- Bomb score increase per collected bomb.
- Visible `SCORE` counter in the HUD.
- Bomb Jack-style jump tuning: Jacques rises until blocked, then falls.
- Held jump slows falling for horizontal floating.
- Extra temporary font glyphs for `R` and digits `3`, `4`, `5`.

Expected:

- Program loads at `$6000`.
- `BOMB JACQUES BUILD 003` and `SCORE 0` appear at the top of the screen.
- Touching a bomb removes it and increments the score.

Observed:

- Assembles successfully with `lwasm`.
- Emulator behavior still needs DCMOTO verification.

Status:

- Ready for emulator test.

## BUILD 002

Added:

- Static milestone arena with floor, platforms, bombs, and player sprite.
- Per-frame input state with held and newly pressed buttons.
- Keyboard fallback controls: `Q`, `D`, and `Space`.
- Standard MO5 game-extension joystick read path.
- Cell-based player movement, jump impulse, gravity, and platform landing.

Expected:

- Program loads at `$6000`.
- `BOMB JACQUES BUILD 002` appears at the top of the screen.
- Jacques moves left/right, jumps once per press, falls, and lands on platforms.

Observed:

- Assembles successfully with `lwasm`.
- Verified in DCMOTO: platforms, bombs, player rendering, left/right movement,
  and jump work.

Status:

- Verified.

## BUILD 001

Added:

- Initial project structure.
- LWTOOLS build script.
- Direct MO5 video-memory title screen.
- Baseline documentation for memory, video, build notes, and design.
- DCMOTO raw binary output with load-address notes.
- DCMOTO `.k7` cassette image output.

Expected:

- Program loads at `$6000`.
- Screen clears.
- `Bomb Jacques` appears above `BUILD 001`.

Observed:

- Assembles successfully with `lwasm`.
- Emulator behavior still needs DCMOTO verification.

Status:

- Ready for emulator test.
