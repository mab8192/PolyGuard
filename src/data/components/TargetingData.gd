class_name TargetingData extends Resource

enum Strategy { FIRST, LAST, CLOSEST, FARTHEST, STRONGEST, WEAKEST }

@export var strategy: Strategy = Strategy.FIRST ## Priority sorting criteria used to pick target(s) within range
@export var max_targets: int = 1 ## Maximum number of simultaneous targets this entity can acquire
@export_flags_2d_physics var targeting_mask: int = 4 ## Physics collision layer mask for filtering valid target bodies (e.g. physical vs ghost enemies)
@export var can_target_through_walls: bool = false ## If false, performs line-of-sight raycasts to prevent targeting behind obstacles
@export var lock_on: bool = false ## If true, does not re-target until an existing target dies
