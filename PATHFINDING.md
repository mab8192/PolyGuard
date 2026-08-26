# Pathfinding & Flow Field System Architecture

This document describes the pathfinding and flow field system in **Poly Guard 2D**, covering global architecture, multi-resolution size categorization, navigation strategies, dynamic blocked-path failover, tower destruction, and boid separation.

---

## 1. System Overview & Architecture Separation

The pathfinding system is strictly separated into two layers:
1. **Generic Engine Addon (`addons/flowfields/`)**: Completely generic, game-agnostic flow field implementation (`FlowField`, `FlowFieldManager`). Contains no references to towers, enemies, or game-specific logic.
2. **Game Pathfinding Layer (`src/scenes/stages/Stage.gd` & `src/components/NavigationComponent.gd`)**: Builds the stage grid, applies multi-resolution cell sizing, handles tower re-baking, multi-exit strategies, and dynamic boid separation.

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
| (Small/Med/Large)|   | (Small/Med/Large) |   | (0, 1, 2...)   |   |   (World-Space) |
+------------------+   +-------------------+   +----------------+   +-----------------+
      ^                          ^                     ^
      |                          |                     |
      +--------------------------+---------------------+
                                 |
                     +-----------------------+
                     |        Stage.gd       |
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
- **Continuous Directional Flow**: Flow vectors are derived from the continuous gradient of the Dijkstra integration field using an upwind downhill-only gradient, eliminating 45-degree grid staircasing and obstacle shadow repulsion.
- **Multi-Resolution Sizing**: Small (16px), Medium (32px), and Large (64px) grids naturally enforce clearances with 4× to 16× computational speedups.

---

## 2. Size Tiers, Clearance Dilation & Targeting Distance

Different enemy units have varying physical footprints. `Stage.gd` generates tier-specific flow fields on a unified 16px grid with soft obstacle clearance dilation:

| Size Class | Pixel Footprint | Padding Radius | Added Wall Penalty | Applicable Units | Navigation Behavior |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Small** | `< 16px` | 0 cells | 0.0 | Light, Speeder, Light Ghost | Navigates tightly through narrow 1-tile passages without clearance penalty. |
| **Medium** | `16px – 32px` | 1 cell | 4.0 | Grunt, Heavy, Tank, Bomber, Healer, Booster, Sniper, Ghost, Heavy Ghost | Softly steers away from walls toward the center of corridors. |
| **Large** | `32px – 64px` | 2 cells | 8.0 | Citadel, Bosses | Strongly avoids narrow corridors and hugging obstacle edges. |

Enemies select their size and navigation behavior directly via `NavigationData`:
- `size`: `AgentSize.SMALL`, `AgentSize.MEDIUM`, or `AgentSize.LARGE`
- `nav_layer`: Layer flags (e.g. `nav_layer & 4 != 0` for Ghost units)

### Decoupled Steering vs. Distance Queries
- **Steering (`field.query`)**: Units query their respective tier field (`physical_medium`, `physical_large`, etc.) to steer with smooth clearance dilation around walls and towers.
- **Progress & Distance (`dist_field.get_integration_cost`)**: Units query the **unpadded baseline field** (`physical_small` or `ghost_small`) scaled by `cell_size` in world pixels. This prevents clearance dilation penalties from inflating the remaining distance of medium/large enemies, ensuring towers targeting `FIRST` or `LAST` compare true topological distance to the exit across all size classes with zero backup pathfinding overhead.

---

## 3. Visualizer & Debug Controls

`FlowFieldVisualizer.gd` provides an in-game HUD overlay:
- **F2 / F3**: Cycle display modes (`OFF`, `ARROWS`, `HEATMAP + ARROWS`, `HEATMAP ONLY`).
- **F4**: Cycle layer (`PHYSICAL_SMALL`, `PHYSICAL_MEDIUM`, `PHYSICAL_LARGE`, `GHOST_SMALL`, `GHOST_MEDIUM`, `GHOST_LARGE`).

---

## 4. Local Boid Separation Steering

To prevent unnatural clump compression in crowded choke points, `NavigationComponent` applies local repulsion forces with lateral corridor lane spreading.

Separation is computed via a high-performance **2D Spatial Hash Grid**:
- **$O(N)$ Construction**: Automatically constructed once per physics tick on demand (`Engine.get_physics_frames()`), bucketing registered active enemies into 48px cells (`SPATIAL_CELL_SIZE`).
- **$O(1)$ Neighbor Sampling**: Each enemy queries only its 9 adjacent spatial buckets, testing against nearby units rather than performing global scene tree searches.
- **Zero GC Churn**: Avoids `get_nodes_in_group` allocations and Variant marshalling overhead during the physics process.


