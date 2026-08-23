class_name NavigationData extends Resource

enum NavStrategy {
	CLOSEST, # Closest by path length
	FARTHEST, # Farthest away by path length
	FIRST, # First in the _exits array
}

enum AgentSize {
	SMALL,  ## 16px (1 cell footprint)
	MEDIUM, ## 32px (2 cells footprint)
	LARGE   ## 64px (4 cells footprint)
}

@export var strategy: NavStrategy = NavStrategy.CLOSEST ## Strategy for selecting which destination/exit to navigate toward
@export var size: AgentSize = AgentSize.SMALL ## Physical footprint size class
@export_flags_2d_navigation var nav_layer: int = 1 ## Godot navigation layers bitmask used for pathfinding
@export var targets_towers: bool = false ## If true, entity navigates toward and prioritizes attacking player towers over exits

@export_group("Boid Separation")
@export var enable_separation: bool = true ## Enables local boid separation steering force to prevent clustering
@export var separation_radius: float = 32.0 ## Detection radius in pixels around the entity for finding neighboring enemies to repel
@export var separation_weight: float = 0.6 ## Blend weight of the separation repulsion force relative to the goal path heading
@export var congestion_weight: float = 1.0 ## Multiplier for traffic congestion penalty deposited by this enemy onto the flow field
