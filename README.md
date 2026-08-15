# Poly Guard 2D

This project is intended to be a stepping stone towards a full OMD-style tower defense mobile game.
The full version is intended to be in landscape mode, with a player character that you control with
on-screen joysticks, with special abilities, etc.

This version is a simple sandbox-like tower defense game, with highly simplified graphics and a
very basic premise. There are no abilities and there is no player character. The game is oriented
in portrait with a simple UI bar at the top to view health, waves, energy, etc. and some buttons at
the bottom for building towers and advancing to the next wave.

## Stages

The game will be organized into 25 different stages, comprising the "Main Campaign". I do not
currently have a story planned out. They will just be 25 stages in increasing difficulty, both in
layout and in wave composition.

Stages will vary in open-ness, from simple corridors in the earlier stages to wider open spaces in
the later stages. Big gaps are harder to block off and require more thought from the player in how
best to handle each situation.

## Towers/Traps

There will be 3 main different categories of towers:

1. Blocking + Damaging
1. Non-blocking + Damaging
1. Non-blocking + Passive Effect

All towers will be placed on the floor, so there are no wall or ceiling traps in this version.

Examples of each type of tower:

### Block + Damaging

These are towers that are solid and block enemy movement, and inflict damage on enemies within some
region of the level (typically surrounding the tower).

Examples include:

- Archer Tower
- Bomb Tower
- Tesla Tower

### Non-blocking + Damaging

These are towers that are not solid (and therefore do not block movement) but do inflict damage
on the enemies that walk over/near it.

Examples include:

- Brimstone
- Spike Traps
- Acid Floor

### Non-blocking + Passive Effects

These are towers that are not solid and do not inflict damage, but do inflict some kind of debuff
on an enemy.

Examples include:

- Ice
- Tar
- Corrosive Vapor (reduces armor)

## Enemies

### Speeders & Rushers

#### Small Yellow Triangle (The Sprint)

Visual: Small, bright neon yellow, sharp forward-pointing triangle.

Role: Early-wave rusher and path tester.

Stats: Low HP | 0 Armor | Fast Attack | Very High Speed

Behavior: Sprints straight for open routes. When blocked by a tower, it attacks rapidly with low damage per hit, quickly wearing down low-tier barricades through speed rather than power.

#### Orange Rhombus / Diamond (The Phase Diamond)

Visual: Medium orange, elongated wireframe diamond.

Role: Trap/Blockade bypasser.

Stats: Low HP | 0 Armor | No Attack | High Speed

Behavior: Completely ignores path-blocking towers by "phasing" over them without taking collision or attacking them. Players must kill it with direct ranged towers before it reaches the portal.

### Tanks & Siege Engines

#### Large Dark Red Square (The Wall Breaker)

Visual: Large, solid dark red square with thick outer borders.

Role: Tower demolition tank.

Stats: High HP | High Armor | Heavy Attack (Slow) | Low Speed

Behavior: The primary threat to player barricades. When blocked, its heavy attack deals 2x bonus damage to player towers/traps, clearing a path for faster units behind it.

#### Slate Grey Hexagon (The Citadel)

Visual: Very large, slow-rotating slate grey hexagon.

Role: Ultimate bullet-sponge tank.

Stats: Extremely High HP | Max Armor | Moderate Attack | Very Low Speed

Behavior: Moves like a slow glacier. It takes negligible damage from fast-firing light towers (especially if using flat armor reduction) and absorbs high-damage shots meant for squishier targets.

### Swarmers & Splitters

#### Green Circle (The Basic Peon)

Visual: Medium emerald green circle.

Role: Standard wave filler.

Stats: Moderate HP | 0 Armor | Low Attack | Moderate Speed

Behavior: Predictable and steady. Serves as the baseline for balancing tower DPS.

#### Magenta Octagon (The Cluster / Splitter)

Visual: Medium bright magenta octagon that pulses rhythmically.

Role: Multi-target distractor.

Stats: Moderate HP | Low Armor | Low Attack | Moderate Speed

Behavior: Upon taking fatal damage, it splits into 3 Small Magenta Circles, forcing your towers to retarget and potentially overwhelming single-target defenses.

#### Cyan Ellipse (The Swarm Cluster)

Visual: Tiny cyan oval shapes that spawn in tight clusters of 6 to 10.

Role: AoE / Splash test.

Stats: Fragile (1 HP) | 0 Armor | Moderate Combined Attack | Fast Speed

Behavior: They move together in a tight pack. Single-target towers waste time shooting them individually, while Area-of-Effect (AoE) towers or traps obliterate the whole swarm at once.

### Buffers & Support Units

#### Purple Pentagon (The Shield Generator)

Visual: Medium deep-purple pentagon with a faint glowing ring around it.

Role: Mobile armor support.

Stats: Moderate HP | Medium Armor | Low Attack | Moderate Speed

Behavior: Emits a passive aura ring. All nearby shapes inside the ring gain +10 Bonus Armor (or 20% damage reduction), turning squishy triangles into resilient threats until the Pentagon is destroyed.

#### Lime Green Cross / Plus (The Repair Node)

Visual: Bright lime green 4-pointed cross.

Role: Mobile healer.

Stats: Low HP | 0 Armor | No Attack | Moderate Speed

Behavior: Periodically emits a pulse that restores health to nearby damaged shapes, prioritizing tanks that are currently stuck attacking player barricades.

### Disruptors & Ranged Threats

#### Gold Star / Decagram (The Siege Sniper)

Visual: Golden 10-pointed star.

Role: Long-range tower breaker.

Stats: Low HP | Low Armor | High Attack | Low Speed

Behavior: Doesn't wait until it physical bumps into a blocking tower. When it comes within range of a player tower, it stops moving and attacks from a distance with a beam, destroying your chokepoint before even reaching it.

#### White Ring / Ring-Torus (The Magnet)

Visual: White hollow circle with a transparent center.

Role: Formation disruptor.

Stats: High HP | Medium Armor | No Direct Attack | Slow Speed

Behavior: Pulls light units behind it closer to its position, clumping enemies into a dense mass that pushes past player traps as a unified wave.

#### Prismatic Crescent / Moon (The Dimension Shifter)

Visual: Iridescent/changing color crescent shape.

Role: Teleporting speeder.

Stats: Low HP | 0 Armor | Moderate Attack | Variable Speed

Behavior: Every few seconds, it short-range "blinks" 50 pixels forward along the track, instantly skipping over small ground traps and forcing precise tower placement.

## Future Ideas

### Multiplayer VS.

From Jackson. The idea would be to have a mode where one player builds a stage, configures the enemies, etc. and the other player tries to defend.

### Custom Levels

Players can build their own stages and upload them to a server. They can specify what towers can be used.
Players play these custom levels and rate them.
