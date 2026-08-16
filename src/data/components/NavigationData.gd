class_name NavigationData extends Resource

enum NavStrategy {
	CLOSEST, # Closest by path length
	FARTHEST, # Farthest away by path length
	FIRST, # First in the _exits array
}

@export var strategy: NavStrategy = NavStrategy.CLOSEST
@export_flags_2d_navigation var nav_layer: int = 1
