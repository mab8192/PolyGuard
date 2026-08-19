# TODO

## Tower Ideas

- Freeze Trap
  - Replace ice with an oil slick that makes them susceptible to fire damage? Would require more damage types which isn't great
- Some kind of pusher trap? Too similar to displacer?
- Rail gun (single direction piercing)
- Siphon (grants extra energy when enemies die on it)

## Endless mode

Should we apply this to all levels or only a subset that we think work well with endless?
How to procedurally generate increasingly difficult waves?
How to scale down energy earned so you can't infinitely build?
How to scale up enemy difficulty over time?

## Pathfinding

- [x] Tweak pathfinding so enemies only attack the minimum towers necessary to reopen the path (flow field Dijkstra using `TOWER_COST`)
- [x] Drop flow field cell size to 16px to align with 32px towers and allow pathfinding through 32px gaps

## BUGS

- [x] Wave completion when splitter is the last enemy (fixed via `pending_enemies` tracking)
