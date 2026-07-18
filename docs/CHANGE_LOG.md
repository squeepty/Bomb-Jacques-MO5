# Change Log

## V2 Release

Added:

- Final graduated dither treatment for the solid shadow beneath the sphinx
  head. The approved reference was re-encoded into the resident one-bit
  background, changing only the original shadow interior.
- Pyramid background art on the high-score name-entry screen.

Changed:

- Promoted the project and build output from `final v2 candidate` to
  `Bomb Jacques V2 release`.
- Removed the unused legacy `HudText` string containing `BUILD 008`.
- Refreshed source headers, renderer comments, learning documents, release
  metadata, and downloadable cassette artifacts.
- Corrected the video/CPU documentation to describe the optimized `MUL`-based
  cell addressing and unrolled `PULU D` cell drawing paths.

Verified:

- `tools/build.sh` passes.
- `git diff --check` passes.
- The background remains 120 stored rows by 30 bytes, covering source rows
  56-175.
- All 259 background pixel changes are black-to-cyan openings inside the
  original sphinx-shadow mask; no pyramid, face, outline, or ground pixel is
  changed.
- V2 raw binary: 19677 bytes, loaded at `$4000-$8CDC`.
- V2 `LOADM` stream: 19687 bytes.
- V2 K7 image: 21381 bytes.
- V2 K7 SHA-256:
  `9fac6f699a76f0cafd605abe4413aa158698c87d2467630b6c54669d4dedffeb`.

## Final v2 Candidate

Changed:

- Current milestone name is now `BOMB JACQUES final v2 candidate`.
- Git milestone tag is `milestone-final-v2-candidate`.
- Build load notes now identify the generated artifact as the final v2
  candidate.

Observed:

- `tools/build.sh` passes.
- `git diff --check` passes.
- Candidate raw binary range was `$4000-$8CF3`.
- Candidate downloadable K7 size was 21404 bytes.

## v2 Sound Pass

Added:

- `src/sound.asm` with short 1-bit MO5 buzzer phrases.
- Sound hooks for normal bomb pickup, lit bomb pickup, jump start, active enemy
  hit/player death, frozen-enemy collection, level clear, power pickup, and
  game over.
- `docs/SOUND_NOTES.md` documenting the buzzer port, effect shapes, hooks, and
  timing caveats.

Changed:

- `src/main.asm` initializes sound at startup and includes the new sound module.
- Downloadable K7 artifact rebuilt after adding sound.
- Audio feedback pass keeps the normal bomb pickup blip, gives lit bomb a short
  brighter blip near E#7/F7, extends jump into a bright long high tick, shares the
  longer rising chirp across bonus, power, energy/life, and level-clear rewards,
  and keeps the enemy/death rasp.
- Level startup stays silent while the `GET READY` banner is visible.
- Game over now plays a long falling decrescendo after the final death
  animation.
- Version label now draws inside the lower-left play area only on title and
  hall-of-fame screens, with black text on cyan paper.

Observed:

- `tools/build.sh` passes.
- Sound-pass raw binary range was `$4000-$8CF3`.
- Sound-pass downloadable K7 size was 21404 bytes.

Status:

- Audio should be checked in DCMOTO or on hardware for volume, clickiness, and
  whether any blocking phrase feels too long during play.

## v2 Candidate

Added:

- Cropped 240x176 Egypt gameplay background image support.
- `src/game/backgrounds.asm` generated from the two-color PNG background.
- Background-aware static cell restoration, so sprite erases restore pyramid and
  sphinx pixels instead of flat cyan.
- Initial `(v2)` version label.
- Dedicated `docs/SPRITE_OPTIMIZATION.md` deep dive for the anti-flicker sprite
  optimization pass.

Changed:

- Program origin moved from `$6000` to `$4000` to make room for resident
  background bitmap data while keeping stack headroom.
- `tools/build.sh` now derives the raw/debugger load origin from
  `src/constants.asm`.
- New-game and next-level setup draw `DrawArenaBackground` before platforms,
  bombs, and actors.

Observed:

- `tools/build.sh` passes.
- `git diff --check` passes.
- Current raw binary range before sound was `$4000-$8B74`.
- Downloadable K7 size before sound was 21000 bytes.

Status:

- Tagged as `milestone-v2-candidate-background-image-support-docs`; DCMOTO
  visual verification over the new background is still recommended.

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
