# Known Bugs

## BUILD 008 / Current

- No blocking gameplay bugs are currently known after
  `milestone-game-rom-initial-version` and the later conservative `src/game/`
  split verification.
- No regression issue was found after splitting the former `src/game.asm`
  monolith; the rebuilt K7 remains byte-identical to the tracked downloadable
  cassette image.
- Final DCMOTO play-through verification is still recommended across all ten
  levels.
- Timing still uses the temporary busy-wait loop and
  `PLAY_TICKS_PER_SECOND = 17`, not a 50 Hz interrupt.
- Sound effects are not implemented.
- The title, hall-of-fame, sprite editor, and right-panel art flows are
  functional but still open to visual polish.

## BUILD 007

- Lives, death pause, respawn, and game-over behavior have not yet been
  verified in DCMOTO.
- Respawn returns Jacques to the fixed starting position; there is no temporary
  invulnerability yet.
- `GAME OVER` is a terminal state for this milestone. Restart/title flow is
  deliberately deferred.
- The `BONUS` and `HIT` HUD flashes use fixed frame counters tied to the
  temporary busy-wait timing.

## BUILD 006

- Two-enemy patrol and collision behavior has not yet been verified in DCMOTO.
- Enemy collision only resets Jacques for this milestone. Lives, death
  animation, and game over are deliberately deferred.
- The `BONUS` and `HIT` HUD flashes use fixed frame counters tied to the
  temporary busy-wait timing.

## BUILD 005

- Enemy patrol and collision behavior has not yet been verified in DCMOTO.
- Enemy collision only resets Jacques for this milestone. Lives, death
  animation, and game over are deliberately deferred.
- The `BONUS` and `HIT` HUD flashes use fixed frame counters tied to the
  temporary busy-wait timing.

## BUILD 004

- Highlighted bonus bomb behavior has not yet been verified in DCMOTO.
- The `BONUS` HUD flash uses a fixed frame counter tied to the temporary busy
  wait timing.

## BUILD 003

- Bomb collection and score display have not yet been verified in DCMOTO.
- Bomb collision is cell-based and requires Jacques to overlap the bomb cell.

## BUILD 002

- Movement is cell-based for the milestone. Pixel movement and animation are
  intentionally deferred.
- The joystick path is based on the standard MO5 game-extension PIA and needs
  hardware/emulator validation.

## BUILD 001

- DCMOTO loading and visual output have not yet been verified in the emulator.
- The temporary font only contains glyphs needed by the BUILD 001 title screen.
