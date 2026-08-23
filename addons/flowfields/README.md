# Godot 4 Flow Field Pathfinding

A fully statically-typed, mobile-optimized flow field implementation for Godot 4.
Good for RTS/tower-defense style games where many units path toward the same
goal(s) and you want to avoid running A* per-agent every frame.

## Files

| File                        | Purpose                                                              |
|------------------------------|-----------------------------------------------------------------------|
| `flow_field.gd`               | Core `FlowField` class (cost/integration/flow fields, baking, sampling) |
| `flow_field_manager.gd`       | Autoload singleton (`FFManager`) that owns named `FlowField`s          |
| `flow_field_agent.gd`         | Example `CharacterBody2D` that steers using a field                   |
| `flow_field_debug_draw.gd`    | `Node2D` overlay to visualize cost walls + flow arrows                |

## Setup

1. Copy all four scripts into your project (e.g. `res://addons/flow_field/`).
2. In **Project Settings > Autoload**, add `flow_field_manager.gd` with the
   node name **`FlowFieldManager`** (this exact name matters — the agent and
   debug scripts look it up at `/root/FlowFieldManager`).
3. Create and bake a field somewhere early in your level (e.g. in the level's
   `_ready()`):

```gdscript
func _ready() -> void:
    var manager: FFManager = get_node("/root/FlowFieldManager") as FFManager
    var field: FlowField = manager.create_field(
        "default",           # id
        64, 64,               # width, height in cells
        32.0,                 # cell_size in pixels
        Vector2.ZERO          # world_origin
    )

    # Option A: build obstacles manually
    field.set_obstacle_rect(Rect2i(10, 10, 6, 3))

    # Option B: build obstacles from a TileMap, using a boolean custom
    # data layer named "solid" on your TileSet
    # field.build_cost_from_tilemap(tile_map, 0, "solid")

    field.set_goal_world(Vector2(1800, 1800))
    field.bake_async() # or field.bake() for a synchronous bake
```

4. Add `FlowFieldAgent` (or your own script following its pattern) to your
   unit scenes, set `field_id = "default"`, and it will steer itself.
5. Optionally add a `FlowFieldDebugDraw` node to your scene to see the field.

## Re-baking when the world changes

Whenever obstacles move or the goal changes:

```gdscript
field.set_obstacle_rect(new_building_rect)
field.set_goal_world(new_target_position)
field.bake_async()
```

`bake_async()` runs the Dijkstra pass and flow-field derivation on a worker
`Thread` and emits `bake_finished` on the main thread when done — this is the
recommended path on mobile so a re-bake never causes a visible hitch.
**Do not** read `integration_field` / `flow_field` or mutate `cost_field`
while `field.is_baking()` is `true`.

## API summary (`FlowField`)

**Grid setup**
- `resize(width, height)`
- `world_to_grid(world_pos) -> Vector2i`, `grid_to_world(cell) -> Vector2`

**Cost field**
- `set_cost(x, y, cost)`, `set_obstacle(x, y)`, `clear_obstacle(x, y)`
- `set_cost_rect(rect, cost)`, `set_obstacle_rect(rect)`, `reset_costs()`
- `build_cost_from_tilemap(tilemap, layer, custom_data_name := "solid")`

**Goals** (supports multiple simultaneous goals — useful for "flee toward
any exit" style fields)
- `set_goal_world(pos)` / `set_goal_cell(cell)` — replaces existing goals
- `add_goal_world(pos)` / `add_goal_cell(cell)` — adds an additional goal
- `set_goals_world(PackedVector2Array)`, `clear_goals()`

**Baking**
- `bake()` — synchronous
- `bake_async()` / `is_baking()` — threaded, emits `bake_finished`
- `smooth_gradient_flow: bool` (default `true`) — when on, `bake()` also
  derives a continuous per-cell direction from the gradient of the
  integration field (Sobel-style), instead of only the discrete 8-direction
  pick. This removes the 45-degree "staircase" look from agent paths at
  basically no extra cost. Set to `false` to save 8 bytes/cell on very large
  grids where the coarser discrete field is good enough.

**Sampling (per-agent, per-frame)**
- `sample_flow_world(world_pos, smooth := true) -> Vector2` — bilinearly
  interpolated direction, recommended for movement
- `get_flow_vector(x, y) -> Vector2` — raw single-cell direction
- `get_integration_at_world(world_pos) -> int` — rough distance-to-goal
- `has_reached_goal_world(world_pos) -> bool`

## Performance notes for mobile

- **Grid resolution**: pick the coarsest cell size that still gives
  believable movement. A 64×64 field bakes in a fraction of a millisecond;
  a 512×512 field is still fine *asynchronously* but avoid baking it
  synchronously every frame.
- **Bake only on change**: don't call `bake()`/`bake_async()` every frame —
  only when the goal moves or obstacles change. Sampling
  (`sample_flow_world`) is O(1) and is what you call every frame per agent.
- **Shared field**: hundreds of agents can call `sample_flow_world()` against
  the *same* baked `FlowField` for effectively free pathfinding — this is
  the whole point of flow fields versus per-agent A*.
- **Packed arrays only**: the implementation deliberately avoids
  `Array`/`Dictionary` in hot paths (cost/integration/flow storage, the
  Dijkstra heap) in favor of `PackedByteArray` / `PackedInt32Array` /
  `PackedVector2Array`, which are contiguous, unboxed, and much cheaper on
  mobile CPUs and for GC pressure.
- **Diagonals**: set `allow_diagonals = false` on very large fields if you
  want a faster, purely 4-directional bake (fewer edges to relax).
- **Direction smoothness**: `flow_field` (the byte-indexed field) only ever
  points along one of 8 fixed 45-degree angles. `flow_field_smooth` (on by
  default) instead comes from the integration field's gradient, so it can
  point at any angle — this is what removes the "grid-aligned" look from
  movement. It's one extra cheap pass per bake, not per frame, so it's safe
  to leave on for mobile.
- **Very large worlds**: if you need a field larger than a few hundred cells
  per side, consider splitting the world into sectors, each with its own
  `FlowField`, and only baking/keeping resident the sectors near active
  agents — the API here is intentionally sector-friendly since each
  `FlowField` is a self-contained `RefCounted` object with its own
  `world_origin`.
