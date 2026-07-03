# Game Design

This document describes the current intended game rules and feel. Historical
build-by-build changes live in `docs/CHANGE_LOG.md`.

## Core Loop

Jacques collects every bomb in a single-screen arena while avoiding enemies.
One bomb is highlighted; collecting it first awards a bonus and moves the
highlight to the next remaining bomb.

Each level follows this rhythm:

1. Show `GET READY`.
2. Start active play.
3. Spawn enemies and timed bonus items while the player collects bombs.
4. When all bombs are collected, show `WELL DONE!`.
5. Advance to the next arena.

## Screens And Flow

The game opens into an attract loop:

- title screen
- hall-of-fame screen

Pressing fire on the title screen starts a new game. When the final life is
lost, qualifying scores enter the name-entry screen before returning to the
hall of fame.

## Player Rules

Jacques starts each game with 3 lives.

Movement is cell-based:

- `Q`: move left
- `D`: move right
- `Space`: jump
- standard MO5 game-extension joystick support when present

Jump behavior:

- pressing jump starts an upward rise
- releasing jump ends the rise early
- hitting the top boundary or underside of a platform ends the rise
- holding jump while falling slows descent, making horizontal bomb collection
  easier

Jacques respawns at the starting position after losing a life.

## Death And Respawn

Touching an active enemy starts the death sequence unless Jacques is in respawn
grace or the enemy is frozen and collectable.

Death sequence:

- gameplay movement freezes
- Jacques flies straight up at one-third normal movement speed
- the sprite rotates through jump-left, jump-up, and jump-right poses
- one life is removed unless the `SQUEEPTY` cheat is active
- if lives remain, Jacques respawns after a short hold
- movement resumes with blinking grace

When no lives remain, the game captures the final score/level for hall-of-fame
handling, clears gameplay status from the persistent chrome, and moves into
name entry or hall-of-fame display.

## Scoring

| Event | Score |
| --- | ---: |
| Bomb | 50 |
| Lit bomb | 200 |
| Bonus Ball | 500 |
| Frozen enemy | 100 |

Normal bombs are always worth collecting. The lit bomb is the preferred order
target and creates the higher-value route through each level.

## Enemies

| Sprite | Count | Appears | Chase | Movement |
| --- | ---: | --- | --- | --- |
| Enemy 2 (flyer) | 1 | at start | 80% | Horizontal & Vertical |
| Enemy 1 (walker) | 4 | one every 5 seconds | none | falls/left/right |
| Enemy 1 (phase 2 hunter) | 3 | when reaches ground | 70%/80%/50% | Horizontal & Vertical |
| Enemy 1 (phase 3 hunter) | 1 | when reaches ground | 80% | Horizontal & Vertical (faster) |

Enemy 1 begins as a falling/walking enemy. When it reaches the floor, it changes
into a flying hunter phase. Enemy slots use different movement timing and chase
rates so the screen pressure builds without every enemy stepping in lockstep.

Enemy 2 is active from the start of play and flies horizontally and vertically.
Most movement ticks step toward Jacques; the rest wander.

## Bonus, Power, And Energy Items

| Sprite | Count | Appears | Movement |
| --- | ---: | --- | --- |
| Bonus Ball | 1 | after 20 seconds | Diagonal |
| Power Ball | 1 | 20 seconds after Bonus Ball is caught | Diagonal |
| Energy Ball | 1 | 20 seconds after Power Ball is caught | Diagonal |

The item chain is sequential:

1. Bonus Ball can appear first and awards 500 points.
2. Catching the Bonus Ball arms the Power Ball timer.
3. Catching the Power Ball freezes active enemies.
4. Catching the Power Ball also arms the Energy Ball timer.
5. Energy Ball restores one life only when Jacques has fewer than 3 lives.

Power freeze lasts about 6 seconds. During freeze, active enemies use a frozen
replacement sprite and blink during the final 2 seconds. Frozen enemies can be
collected for 100 points.

Frozen-enemy collection has one special respawn rule:

- Enemy 1 slots become inactive and return through their normal spawn cadence.
- Enemy 2 is reactivated immediately when the freeze period ends if it was
  collected while frozen.

## Level Progression

The game has ten handcrafted levels. Each level defines:

- platform runs
- bomb positions
- the current lit-bomb order through remaining active bombs

After level 10, progression wraps back to level 1.

## Timing Model

Until gameplay timing is tied to the MO5 50 Hz interrupt, active-play timers use
the temporary game-loop scale `PLAY_TICKS_PER_SECOND = 17`. Timers count only
while the game is in the playing state, so `GET READY`, death pause, title, hall
of fame, name entry, and level-clear states do not consume spawn time.

| Event | Design Target | Current Counter |
| --- | ---: | ---: |
| Enemy 1 walker spawn interval | 5 seconds | 85 active-play ticks |
| Bonus Ball spawn | 20 seconds | 340 active-play ticks |
| Power Ball after Bonus Ball caught | 20 seconds | 340 active-play ticks |
| Energy Ball after Power Ball caught | 20 seconds | 340 active-play ticks |

Movement remains 8x8-cell based. Step counters decide when enemies and moving
items advance by one cell:

| Object | Step counter | Approximate pace at 17 ticks/sec |
| --- | ---: | ---: |
| Enemy 1 base walker | 5 frames | 3.4 cells/sec |
| Enemy 1 slot variants | 4 to 7 frames | 4.25 to 2.4 cells/sec |
| Enemy 2 flyer | 7 frames | 2.4 cells/sec |
| Bonus/Power/Energy balls | 4 frames | 4.25 cells/sec |
| Jacques horizontal movement | every active frame while held | up to 17 cells/sec |

Enemy frame counters are staggered so fewer enemies step on the same frame.
Timed items use their own 4-frame movement counters and enter play sequentially.
This smooths perceived motion without changing the grid-based collision or
drawing model. Half-cell interpolation is intentionally outside the current
milestone.

## Cheat

The `SQUEEPTY` cheat can be entered on the title or hall-of-fame screens.

When active:

- enemy hits do not decrement lives
- `N` advances to the next level during gameplay

The cheat is intentionally kept outside normal play input so it does not
interfere with movement.

## Sprite Editor

The browser sprite editor supports:

- 2x2 gameplay sprites in `src/game/sprites.asm`
- the 56x128 right-panel `SidebarArtBitmap` in `src/sidebar_art.asm`

The editor is a production aid, not an in-game feature.

## Style

The game should feel like a plausible 1985 Thomson MO5 release:

- bright, readable colors
- simple animated shapes
- clear one-screen layouts
- restrained CPU use
- no arcade-machine mimicry for its own sake
