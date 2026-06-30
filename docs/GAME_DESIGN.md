# Game Design

## Core Loop

Jacques collects every bomb in a single-screen arena while avoiding enemies.
One bomb is highlighted; collecting it first awards a bonus.

## Sprite Behavior Reference

This table is reproduced from `src/prompt notes.md` as the design reference for
per-level sprite behavior. Timing values are target seconds from active play;
the current implementation uses game-loop tick counters, so exact wall-clock
seconds are approximate until timing is tied to a fixed interrupt. "At start"
means once the `GET READY` banner has cleared.

| Sprite | Count | Appears | Chase | Movement |
| --- | ---: | --- | --- | --- |
| Enemy 2 (flyer) | 1 | at start | 80% | Horizontal & Vertical |
| Enemy 1 (walker) | 4 | one every 5 seconds | none | falls/left/right |
| Enemy 1 (phase 2 hunter) | 3 | when reaches ground | 70%/80%/50% | Horizontal & Vertical |
| Enemy 1 (phase 3 hunter) | 1 | when reaches ground | 80% | Horizontal & Vertical (faster) |
| Power Ball | 1 | after 30 seconds | none | Diagonal |
| Bonus Ball | 1 | after 20 seconds | none | Diagonal |

## Scoring Reference

| Event | Score |
| --- | ---: |
| Bomb | 50 |
| Lit bomb | 200 |
| Bonus Ball | 500 |
| Frozen enemy | 100 |

## Current Timing Model

Until gameplay timing is tied to the MO5 50 Hz interrupt, active-play timers use
the temporary game-loop scale `PLAY_TICKS_PER_SECOND = 17`. Timers count only
while the game is in the playing state, so `GET READY`, death pause, title, hall
of fame, and level-clear states do not consume spawn time.

| Event | Design Target | Current Counter |
| --- | ---: | ---: |
| Enemy 1 walker spawn interval | 5 seconds | 85 active-play ticks |
| Bonus Ball spawn | 20 seconds | 340 active-play ticks |
| Power Ball spawn | 30 seconds | 510 active-play ticks |

## Milestone 7 Scope

BUILD 007 turns enemy collision into a real arcade life cycle. Jacques starts
with 3 lives. Touching either enemy enters a short death state: `HIT` flashes,
input and enemy movement pause, one life is removed, and Jacques respawns at
the starting position if any lives remain.

When the final life is lost, the game displays `GAME OVER` and stops gameplay.

Restart controls, title flow, high score, sound effects, and death animation
are deferred.

## Milestone 6 Scope

BUILD 006 introduces the second enemy. The first enemy spawns from varied top
columns with a one-second two-frame spawn effect, falls, walks when supported
by platforms, and plays the same effect before transforming into a flying phase
2 after reaching the bottom floor. The second enemy can fly horizontally and
vertically; 80% of movement ticks attract it toward Jacques, while the rest
wander.

Touching either enemy gives the same milestone feedback: `HIT` flashes in the
HUD and Jacques returns to the starting position. Lives, death animation, game
over, and more elaborate enemy AI remain deferred.

## Milestone 5 Scope

BUILD 005 introduces the first enemy. The 2x2 enemy patrols horizontally on the
floor at a fixed speed and reverses direction at patrol bounds.

Touching the enemy gives immediate feedback by flashing `HIT` in the HUD and
returning Jacques to the starting position. Lives, death animation, game over,
and enemy variety remain deferred.

## Milestone 4 Scope

BUILD 004 introduces the highlighted bonus bomb. One active bomb is drawn with a
distinct lit shape and color. Collecting it awards 200 points, briefly flashes
`BONUS` in the HUD, and moves the highlight to the next remaining active bomb.

Non-highlighted bombs remain collectable for 50 points. This keeps the game
playable even when the player misses the intended bonus order.

Enemies, level completion, sound effects, and more elaborate bonus chains are
deferred.

## Milestone 3 Scope

BUILD 003 introduces the first collection loop. When Jacques overlaps a bomb
cell, the bomb disappears and the visible score increases according to the
current scoring model.

The jump model is also tuned closer to Bomb Jack: Jacques rises while jump is
held, stopping when jump is released or when he reaches the top boundary or hits
the underside of a platform. If jump remains held during the fall, descent is
slowed so the player can drift horizontally through a row of bombs.

Bonus bombs, collection order, enemies, and win-state behavior are deliberately
deferred.

## Milestone 2 Scope

BUILD 002 is the first playable movement milestone. It introduces a static arena
with platforms and bombs, then proves the player can move left, move right,
jump, fall under gravity, and land.

## Milestone 0 Scope

BUILD 001 has no gameplay. Its job is to prove that the project can assemble,
load, take over the screen, and display a stable build label.

## Style

The game should feel like a plausible 1985 Thomson MO5 release:

- bright, readable colors
- simple animated shapes
- clear one-screen layouts
- restrained CPU use
- no arcade-machine mimicry for its own sake
