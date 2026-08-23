# Pathfinding & Flow Field System Architecture

This document describes the pathfinding and flow field system in **Poly Guard 2D**, covering global architecture, multi-tier size categorization, navigation strategies, dynamic blocked-path failover, tower destruction, and wall/congestion avoidance.

---

## 1. System Overview & Architecture Separation

The pathfinding system is strictly separated into two layers:
1. **Generic Engine Addon (`addons/flowfields/`)**: Completely generic, game-agnostic flow field implementation (`FlowField`, `FlowFieldManager`). Contains no references to towers, enemies, or game-specific logic.
2. **Game Pathfinding Layer (`src/scenes/stages/StagePathfinding.gd` & `src/components/NavigationComponent.gd`)**: Builds the stage grid, applies size-tier footprint filtering, handles selective tower re-baking, multi-exit strategies, A* tower hunting, and dynamic boid separation.

```
                  +---------------------------------------+
                  |           FlowFieldManager            |
                  |     (Generic Autoload Singleton)      |
                  |      Stores named FlowFields          |
                  +---------------------------------------+
                     |           |           |         |
      +--------------+           |           |         +---------------+
      |                          |           |                         |
      v                          v           v                         v
+------------------+   +-------------------+   +----------------+   +-----------------+
| Physical Fields  |   |   Ghost Fields    |   | Per-Exit Fields|   | Generic Sampling|
| (Small/Med/Large)|   | (Small/Med/Large) |   | (0, 1, 2...)   |   |   (Bilinear)    |
+------------------+   +-------------------+   +----------------+   +-----------------+
      ^                          ^                     ^
      |                          |                     |
      +--------------------------+---------------------+
                                 |
                     +-----------------------+
                     |    StagePathfinding   |
                     |  (Game Stage Manager) |
                     +-----------------------+
                                 |
                                 v
                     +-----------------------+
                     |  NavigationComponent  |
                     |     (Enemy Units)     |
                     +-----------------------+
```

### Core Benefits
- **O(1) Per-Frame Sampling**: Hundreds of enemies query precomputed flow directions simultaneously via `FlowFieldManager.get_field(id)` with zero CPU path search overhead.
- **Continuous Directional Flow**: Flow vectors are derived from the continuous gradient of the Dijkstra integration field (Sobel-style operator) and sampled via bilinear interpolation, eliminating 45-degree grid staircasing.
- **Selective Background Re-baking**: Placing or destroying towers re-bakes only the physical fields by default. Ghost fields are only re-baked if the placed or destroyed tower blocks ghosts (e.g. Spectral Towers), running asynchronously on a background `Thread`.

---

## 2. Size Tiers & Clearance System

Different enemy units have varying physical footprints. To prevent large units from attempting to squeeze through narrow 1-tile bottlenecks, `StagePathfinding` generates **three separate size classes** for both **Physical** and **Ghost** enemy types:

| Size Class | Pixel Width / Diameter | Cell Clearance | Applicable Units | Navigation Behavior |
| :--- | :--- | :--- | :--- | :--- |
| **Small** | `< 16px` | 1 Cell (16px) | Light, Speeder, Light Ghost | Navigates through 1-tile gaps and narrow passageways. |
| **Medium** | `16px – 32px` | 2 Cells (32px) | Grunt, Heavy, Tank, Bomber, Healer, Booster, Sniper, Ghost, Heavy Ghost | Requires at least a 2x2 cell opening; 1-tile pinches are impassable. |
| **Large** | `32px – 64px` | 3–4 Cells (48px–64px) | Citadel, Bosses | Requires wide corridors (>= 48px); rejects 1-tile and 2-tile pinches. |

### Size-Clearance Filtering
When generating Medium and Large fields, `StagePathfinding` performs a footprint convolution over the walkable grid:
- A cell is valid for an agent of footprint $N \times N$ if and only if it is part of at least **one fully walkable $N \times N$ block of cells**.
- Any cell failing this test is marked with `COST_TOWER` or `COST_IMPASSABLE`, ensuring Dijkstra paths naturally route around narrow chokepoints.

---

## 3. Physical vs. Ghost Navigation Models & Selective Re-baking

1. **Physical Enemies**:
   - Collide with **Level Walls** (Layer 1), **Solid Player Towers** (Layer 2), and **Spectral Towers** (Layer 5).
   - Re-baked whenever towers are placed, sold, or destroyed.
2. **Ghost Enemies**:
   - Phase through standard solid physical towers.
   - Collide with **Level Walls** (Layer 1) and **Spectral Towers** (Layer 5).
   - **Selective Re-baking**: When a tower is placed or destroyed, the game checks if the tower blocks ghosts (`tower.collision_layer == 16`). Ghost fields are only re-baked if true, eliminating redundant re-bakes for standard physical towers.
   - **Terrain Reference**: The Small Ghost field (`"ghost_small"`) serves as the baseline pure walls-only terrain path for spawner line previews and unobstructed distance checks.

---

## 4. Multi-Exit Routing & Navigation Strategies

Enemies navigate towards stage exits based on their assigned `NavStrategy`:

| Strategy | Enum Value | Description |
| :--- | :--- | :--- |
| `CLOSEST` | `0` | Paths to the exit with the lowest integration distance. Uses the unified multi-goal field. |
| `FARTHEST` | `1` | Paths to the exit with the greatest integration distance. Evaluates per-exit fields. |
| `FIRST` | `2` | Paths to the primary exit (Exit 0). Evaluates per-exit fields. |

### Dynamic Blocked-Exit Failover
If an exit becomes blocked by player towers during gameplay:
1. `NavigationComponent` checks if the assigned exit is open (integration cost $< 750$).
2. If the assigned exit is **blocked**, but alternative exits remain **open**, the enemy dynamically fails over to an open exit.
3. If **all exits are blocked**, the enemy follows the shortest path through the blocking towers and attacks them.

---

## 5. Tower Blocking & Minimal Destruction Pathing

When the player completely blocks off all open paths to exits with towers:
1. **Tower Cell Cost**: Tower cells are stamped with a high but finite cost (`COST_TOWER = 80`), while walls are strictly impassable (`COST_IMPASSABLE = 255`).
2. **Shortest Breakthrough Path**: Dijkstra integrates the high tower costs into the flow field. As a result, the flow vectors point directly through the **minimal subset of towers** necessary to destroy to reopen the route.
3. **Attack Trigger**:
   - When an enemy detects that no open path exists (`nav.can_reach_exit() == false`), it emits `no_path_available`.
   - As the enemy moves along the flow field, it engages and attacks the obstructing towers in its targeting zone.
   - Once the blocking towers are destroyed, `SignalBus.tower_destroyed` triggers a re-bake, restoring open path status (`can_reach_exit() == true`) and allowing the enemy to continue to the exit without further attacking.

---

## 6. Wall Clearance & Corner Avoidance

To prevent enemies from getting stuck or clipping against wall corners:
1. **Clearance Cost Gradient**:
   - Cells directly adjacent to level walls receive a clearance penalty cost (`+4`), encouraging paths to track down corridor centerlines.
2. **Smooth Sobel Boundary Repulsion**:
   - In `FlowField._sample_integration_for_gradient`, wall and out-of-bounds cells add a virtual height penalty (`WALL_GRADIENT_PENALTY = 60`), producing continuous vector fields that naturally repel units away from walls by at least **1/2 of their radius**.
3. **Corner Cutting Prevention**:
   - In Dijkstra relaxation, diagonal movements are rejected if either flanking cardinal cell is impassable (`prevent_corner_cutting = true`), preventing sharp 90-degree corner cutting.

---

## 7. Direct Tower-Targeting Pathfinding (A*)

Specialized enemy archetypes (such as **Snipers** and **Bombers**) prioritize attacking player towers over exits:
- Instead of following exit flow fields, these units query `StagePathfinding.find_grid_path(from, to)` and `StagePathfinding.get_grid_path_distance(from, to)`.
- Uses internal `AStarGrid2D` instances (`_astar_full` avoiding walls/towers, and `_astar_walls` as fallback).
- Enemies evaluate candidate towers by actual **walking distance around walls** (not straight-line Euclidean distance), navigate to the closest tower along waypoints, destroy it, and then acquire the next target.
- If no towers remain on the stage, these units fall back to standard exit flow fields.

---

## 8. Swarm Separation & Congestion Avoidance

1. **O(1) Spatial Hash Grid**:
   - `StagePathfinding` maintains flat spatial bucket arrays (`_cell_head`, `_enemy_next`, `_enemy_positions`) updated in O(N) each physics frame.
2. **Lateral Corridor Boid Separation**:
   - `StagePathfinding.get_separation_vector(pos, radius)` calculates local repulsive forces from neighboring units in O(1).
   - In `NavigationComponent`, this force is projected **laterally** (perpendicular to the flow vector), causing crowds to fan out into lanes across corridors without slowing down movement.
3. **Dynamic Congestion Avoidance**:
   - Swarm density is accumulated in `congestion_density`.
   - `StagePathfinding.get_congestion_avoidance_vector(pos, desire_dir)` calculates the negative gradient of crowd density ahead of moving units, gently deflecting incoming enemies away from congested bottlenecks.

---

## 9. Developer Tools & Visualizer

A debug visualizer (`FlowFieldVisualizer`) provides real-time overlay graphics:
- **Keyboard Shortcuts**:
  - `F2` / `F3`: Cycle Display Mode (`OFF`, `ARROWS`, `HEATMAP + ARROWS`, `HEATMAP`, `CONGESTION`, `CLEARANCE`)
  - `F4`: Cycle Layer (`PHYSICAL SMALL`, `PHYSICAL MEDIUM`, `PHYSICAL LARGE`, `GHOST SMALL`, `GHOST MEDIUM`, `GHOST LARGE`)
- **Dev Cheat Menu (`F1` / `` ` ``)**: Provides UI buttons to toggle visualizer modes and cycle active inspection layers.
