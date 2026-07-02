# Prompt Notes

Working scratch notes for current gameplay tuning. The canonical docs are
`README.md`, `docs/GAME_DESIGN.md`, `docs/BUILD_NOTES.md`, and
`docs/CHANGELOG.md`; this file keeps the quick reference material that came out
of the late gameplay-polish passes.

## Current Sprite Behavior

| Sprite | Count | Appears | Chase | Movement |
| --- | ---: | --- | --- | --- |
| Enemy 2 flyer | 1 | at start | 80% | Horizontal and vertical |
| Enemy 1 walker | 4 | one every 5 seconds | none | Falls, then walks left/right |
| Enemy 1 phase 2 hunter | 3 | when the walker reaches the ground | 70%/80%/50% | Horizontal and vertical |
| Enemy 1 phase 3 hunter | 1 | when the walker reaches the ground | 80% | Horizontal and vertical, faster |
| Bonus Ball | 1 | after 20 seconds of active play | none | Diagonal |
| Power Ball | 1 | 20 seconds after the Bonus Ball is caught | none | Diagonal |
| Energy Ball | 1 | 20 seconds after the Power Ball is caught | none | Diagonal |

Timers use `PLAY_TICKS_PER_SECOND = 17`, so the values above are gameplay
targets rather than hardware-interrupt wall-clock timing.

## Freeze Behavior

The Power Ball freezes active enemies for about 6 seconds. During freeze, normal
enemy sprites are replaced by the frozen enemy sprite rather than overdrawn by
transparent frozen art. The frozen enemies blink for the final 2 seconds.

Surviving enemies resume movement when freeze expires. Enemy 1 slots eaten while
frozen return through their normal spawn cadence. Enemy 2 is special-cased:
if eaten while frozen, it respawns immediately when the freeze period ends.

## Scoring

| Event | Score |
| --- | ---: |
| Bomb | 50 |
| Lit bomb | 200 |
| Bonus Ball | 500 |
| Frozen enemy | 100 |

The Energy Ball gives one extra life only when Jacques has fewer than 3 lives.

## Player And Death Flow

Jacques uses a front-facing sprite when spawning and after landing on a
platform. The walking sprites were regenerated late in BUILD 008: walk-right
was recreated from reference art, walk-left mirrors it, and both were shifted
down one pixel row.

On enemy hit, gameplay freezes and Jacques flies straight up offscreen at about
one-third normal movement speed while cycling jump-left, jump-up, and
jump-right poses. The sprite stops rendering before it crosses the top black
border. After respawn, gameplay waits for 2 seconds and then resumes with a
blinking grace period.

## Smoother Playability Notes

The current renderer and collision remain grid-based. Enemies move in whole 8x8
cells after step counters expire:

- Enemy 1 base: `ENEMY1_STEP_FRAMES = 5`, about 3.4 cells/sec.
- Enemy 1 slot variants: 4 to 7 frames, about 2.4 to 4.25 cells/sec.
- Enemy 2: `ENEMY2_STEP_FRAMES = 7`, about 2.4 cells/sec.
- Player horizontal movement has no equivalent step delay and can move about
  17 cells/sec while held.

That is why Jacques feels much faster than the enemies. The low-risk smoother
motion pass staggered enemy/item counters so fewer sprites step on the same
frame; it did not change their speeds.

The medium-risk half-cell interpolation experiment is intentionally not part of
the current milestone. The current performance-safe path is counter staggering
plus cell-based rendering.

## Milestone Tags

- `milestone-pre-staggered-movement`: checkpoint before counter staggering.
- `milestone-pre-half-cell-interpolation`: checkpoint before the interpolation
  experiment.
- `milestone-near-complete-game`: near-complete gameplay polish checkpoint.
- `milestone-game-feature-complete`: current game feature-complete state.
