# Sound Notes

This document explains the current Bomb Jacques sound pass. The implementation
lives in `src/sound.asm`.

## Hardware Path

The MO5 has a simple internal 1-bit buzzer. For this project, the buzzer is
driven through the system PIA port B address already named `KEYBOARD_PORT`:

```asm
KEYBOARD_PORT       equ     $A7C1
SOUND_BUZZER_PORT   equ     KEYBOARD_PORT
SOUND_BUZZER_BIT    equ     $01
```

Keyboard scanning writes selector bytes to `$A7C1`, then reads bit 7 back to
test the selected key. The buzzer listens to bit 0 of writes to the same port.
That means sound and keyboard can share the address as long as sound does not
run in the middle of a key scan.

`src/sound.asm` plays only short blocking effects between input scans. Each
effect ends by clearing `$A7C1`; the next input pass writes fresh selector bytes
before reading any key.

## Current Effects

| Routine | Event | Shape |
| --- | --- | --- |
| `SoundBombPickup` | Normal bomb pickup | Short medium-pitch blip. |
| `SoundLitBomb` | Lit bomb pickup | Short brighter blip near E#7/F7. |
| `SoundJump` | Jump start | Brighter long high tick. |
| `SoundEnemyHit` | Active enemy hit/player death and frozen-enemy collection | Louder stepped descending rasp. |
| `SoundRewardChirp` | Bonus, power, and energy pickups | Longer six-tone rising chirp. |
| `SoundLevelClear` | All bombs collected | Longer six-tone rising chirp. |
| `SoundGameOver` | Game over | Long falling decrescendo. |

## Tone Engine

`SoundTone` is the shared square-wave helper:

```asm
; A = half-period delay count. Higher values produce lower tones.
; B = number of full high/low cycles.
```

For each cycle, it writes bit 0 high, busy-waits for the requested half-period,
writes the port low, busy-waits again, then repeats. All public effect routines
save and restore `A`, `B`, and `X`.

The effect routines are blocking because the current game loop is already
busy-wait based. This keeps the first sound pass compact and easy to reason
about, but it also means effect lengths are part of gameplay feel.

## Gameplay Hooks

Sound is called directly from the gameplay event that owns the action:

| File | Hook |
| --- | --- |
| `src/game/collection_death.asm` | Bomb pickups, frozen-enemy scoring, active enemy hit/death, and game over. |
| `src/game/player_movement.asm` | Successful jump start. |
| `src/game/items.asm` | Bonus pickup, power collection, energy/life pickup. |
| `src/game/level_flow.asm` | Level-clear entry. |

The hooks intentionally sit after the state change that makes the event real,
so failed jumps, missed pickups, and ignored collisions remain silent.

## Tuning Notes

The current timings are a first musical sketch:

- Normal bomb pickup keeps the short medium blip.
- Lit bomb uses a short brighter blip near E#7/F7, keeping it close to the
  normal bomb pickup shape while making the highlighted bomb read higher.
- Jump keeps the bright high pitch but uses more cycles so it reads as a longer
  tick.
- Bonus, power, energy/life, and level clear all use the longer rising reward
  chirp.
- Level startup stays silent while `GET READY` is visible.
- Game over plays a long falling decrescendo after the final death animation
  resolves.
- The enemy rasp is shared by player death and frozen-enemy collection for now;
  this can be split later if those two moments should feel different.

Future interrupt-driven audio would need a different design. A per-frame update
alone is too slow for pitched 1-bit square waves; a real non-blocking engine
would need either a timer/IRQ cadence or carefully budgeted audio work inside
the frame loop.

## References

- MAME Thomson driver maps MO5 system PIA writes at `$A7C0-$A7C3` and connects
  system PIA port B writes to the 1-bit buzzer:
  <https://github.com/mamedev/mame/blob/master/src/mame/thomson/thomson.cpp>
- MAME Thomson machine code documents MO5 port A bits and keyboard matrix use of
  system PIA port B:
  <https://github.com/mamedev/mame/blob/master/src/mame/thomson/thomson_m.cpp>
