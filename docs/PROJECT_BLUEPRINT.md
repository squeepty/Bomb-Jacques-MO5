# PROJECT BLUEPRINT

# Bomb Jacques

### A Thomson MO5 Assembly Game

#### An Educational Retro Game Development Project

---

# Vision

**Bomb Jacques** is an original one-screen arcade game inspired by the gameplay spirit of Bomb Jack, designed specifically for the Thomson MO5.

The objective is **not** to recreate the arcade machine, but rather to imagine:

> *"What if Bomb Jack had been officially released on the Thomson MO5 in 1985?"*

This project has two equally important goals:

1. Build a genuinely fun MO5 game.
2. Produce an exceptionally documented educational codebase that teaches Motorola 6809 assembly and MO5 game programming.

Every source file should be written as if it were part of a programming book.

---

# Project Philosophy

This project values:

* readability
* modularity
* educational value
* authenticity
* incremental development

It does **not** value:

* premature optimization
* clever but unreadable code
* giant rewrites
* feature creep

Every milestone must produce a working build.

---

# Target Platform

Computer:

Thomson MO5

CPU:

Motorola 6809E @ 1 MHz

Development:

* 6809 Assembly
* macOS
* Visual Studio Code
* Codex

Testing:

DCMOTO emulator running under Wine.

---

# Gameplay

The player controls Jacques, a fearless acrobat.

Goal:

Collect every bomb on the screen while avoiding enemies.

One bomb is always highlighted.

Collecting the highlighted bomb awards bonus points.

When all bombs are collected:

* level complete
* next arena loads
* enemies become slightly faster

Simple.

Fast.

Arcade.

---

# Visual Direction

The project should look like a genuine Thomson MO5 commercial game.

Not an arcade conversion.

Not a modern pixel-art game.

Think:

* Lorann
* Mandragore
* Sapiens
* James Debug
* L'Aigle d'Or

Bright colors.

Simple graphics.

Very readable.

---

# Graphics Philosophy

Use color intelligently.

Avoid excessive moving pixels.

The background should be colorful.

Moving objects should remain simple.

Recommended sprite sizes:

Player

16×16 pixels

Enemies

8×8 or 12×12

Bombs

8×8

Platforms

8×8 or 16×8 tiles

The game should favor smooth animation over graphic complexity.

---

# Audio

Initially:

* jump
* collect bomb
* bonus
* death

Music is postponed until gameplay is complete.

---

# Technical Architecture

```
src/

    main.asm

    constants.asm

    memory.asm

    video.asm

    input.asm

    sprites.asm

    renderer.asm

    physics.asm

    collision.asm

    enemies.asm

    levels.asm

    score.asm

    sound.asm

    title.asm

docs/

    PROJECT_BLUEPRINT.md

    MEMORY_MAP.md

    BUILD_NOTES.md

    GAME_DESIGN.md

    CPU_NOTES.md

    SPRITE_FORMAT.md

tools/

    build.sh

README.md

CHANGELOG.md

KNOWN_BUGS.md
```

Every module must have a single responsibility.

---

# Rendering Strategy

Avoid redrawing the entire screen.

Instead:

* draw static background once
* redraw only moving objects
* restore background under sprites
* keep dirty rectangles as small as possible

The project should evolve toward an efficient renderer.

---

# Coding Style

Every routine must begin with:

Purpose

Inputs

Outputs

Registers modified

Algorithm explanation

Example:

```
;-----------------------------------------
; DrawPlayer
;
; Draws player sprite at current position.
;
; Input:
;   PlayerX
;   PlayerY
;
; Output:
;   Sprite visible
;
; Modified:
;   A
;   X
;
;-----------------------------------------
```

Heavy comments are encouraged.

---

# Development Workflow

Never implement multiple systems simultaneously.

Instead:

Implement

↓

Test

↓

Fix

↓

Commit

↓

Continue

Small steps only.

---

# Milestones

## Milestone 0

Project boots.

Displays

```
Bomb Jacques

BUILD 001
```

Nothing else.

---

## Milestone 1

Static arena.

Platforms.

Bombs.

Player.

---

## Milestone 2

Player movement.

Left.

Right.

Jump.

Gravity.

Landing.

---

## Milestone 3

Bomb collection.

Bomb disappears.

Score increases.

---

## Milestone 4

Highlighted bomb.

Bonus scoring.

Visual feedback.

---

## Milestone 5

Enemy #1.

Simple movement.

Collision.

---

## Milestone 6

Enemy #2.

Different movement pattern.

---

## Milestone 7

Lives.

Death.

Respawn.

Game Over.

---

## Milestone 8

Multiple handcrafted levels.

Difficulty progression.

---

## Milestone 9

Title screen.

Instructions.

High score.

Sound effects.

Polish.

---

## Milestone 10

Release Candidate.

Bug fixing only.

No new features.

---

# Testing Strategy

Every build must be playable.

Every build receives a version number.

Example:

BUILD 017

Testing cycle

1. Codex modifies code.
2. Assemble.
3. Launch in DCMOTO.
4. Verify expected behavior.
5. Capture screenshot if necessary.
6. Fix only the observed issue.
7. Repeat.

No speculative rewrites.

---

# Build Log Format

```
## BUILD 017

Added:

- enemy collision

Expected:

Player dies when touching enemy.

Observed:

Collision works.

Respawn broken.

Status:

Needs fixing.
```

---

# Codex Responsibilities

Codex acts as a senior retro game programmer.

Responsibilities include:

* writing assembly
* explaining assembly
* documenting every module
* preserving previous working builds
* minimizing regressions
* updating documentation
* maintaining code quality

Codex should never perform unnecessary rewrites.

---

# Human Responsibilities

The developer will:

* assemble the project
* run DCMOTO under Wine
* verify gameplay
* provide screenshots or descriptions
* approve gameplay decisions
* make artistic choices

---

# Documentation Standards

Every important concept deserves its own document.

Examples:

MEMORY_MAP.md

How RAM is organized.

SPRITE_FORMAT.md

Sprite encoding.

VIDEO.md

Video memory layout.

CPU_NOTES.md

6809 explanations.

Every document should assume the reader has never programmed a Thomson computer before.

---

# Optimization Philosophy

Correctness first.

Gameplay second.

Optimization third.

Do not optimize until the game is enjoyable.

---

# Long-Term Vision

After the first public release, the engine should become reusable for future MO5 games.

Potential future projects include:

* platform games
* puzzle games
* arcade conversions
* educational assembly tutorials

The long-term objective is to establish a modern, open-source, educational Thomson MO5 development framework.

---

# Release

When complete:

Release on GitHub.

Publish a development article.

Create gameplay video.

Submit to Pouët.

Submit to Demozoo.

Share with the Thomson community.

The project should be remembered not only as a fun game, but as one of the most approachable introductions to Motorola 6809 game development on the Thomson MO5.

---

# Guiding Principle

> Build the game that a passionate French home-computer studio could realistically have shipped for the Thomson MO5 in 1985, while documenting every step so that someone discovering 6809 assembly forty years later can understand, learn, and build upon it.
