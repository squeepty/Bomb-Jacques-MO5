
Spec of sprites behaviors for each level:

Sprite                         Count    Appears                 Chase           Movement
----------------------------   -----    -------------------     ------------    ------------------------------
Enemy 2 (flyer)                 1       at start                80%             Horizontal & Vertical

Enemy 1 (walker)                4       one every 5 seconds     none            falls/left/right
    Enemy 1 (phase 2 hunter)    3       when reaches ground     70%/80%/50%     Horizontal & Vertical
    Enemy 1 (phase 3 hunter)    1       when reaches ground     80%             Horizontal & Vertical (faster)

Bonus Ball                      1       after 20 seconds        none            Diagonal
Power Ball                      1       after 30 seconds        none            Diagonal           
Energy Ball                     1       after 50 seconds        none            Diagonal

Spec for scoring:

Sprite          Score
-------------   ------
Bomb            50   
Bomb lit        200
Bonus           500
Enemy frozen    100

Smoother playability:

Yes, but I would not start with true pixel-smooth movement for every enemy.

Right now enemies move in whole 8x8 cells after step counters expire: `ENEMY1_STEP_FRAMES` is 4-7-ish depending slot/phase, and `ENEMY2_STEP_FRAMES` is 7. Rendering is also cell-based: a changed 2x2 sprite gets erased, `FrameStaticDirty` causes static arena redraw, then all changed dynamic sprites are redrawn.

With max active load after the Energy ball change, worst case is:

- 4 enemy-1 slots
- 1 enemy-2
- player
- power ball
- bonus ball
- energy ball

That is up to 9 dynamic 2x2 sprites, plus static redraw of platforms and up to 18 bombs when any moving sprite erases over the arena.

Best path:

1. **Low risk: stagger movement counters**
   Keep enemy speed exactly the same, but initialize enemy/item frame counters with offsets so fewer sprites step on the same frame. This won’t make one sprite glide, but it makes the whole screen feel less “chunky” under max load and costs almost nothing.

2. **Medium risk: half-cell visual interpolation**
   Keep logic/collision on the current grid, but render one intermediate 4-pixel visual step between cells. This is the first option that makes individual enemies look smoother. Cost rises because a shifted 16x16 sprite can touch 2x3, 3x2, or 3x3 cells instead of 2x2.

3. **High risk: true pixel/sub-cell movement**
   Smoothest visually, but expensive with the current renderer. It would need pre-shifted sprites or runtime bit shifting, larger dirty regions, and probably a better local background restore instead of broad static redraw. Under max sprite load, this could threaten playability.

My recommendation: implement **counter staggering first**, then test **half-cell interpolation only for flying enemies** or only enemy phase 2/3. That keeps gameplay speed stable and avoids turning every frame into a max-cost redraw.

