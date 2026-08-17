class_name TargetingData extends Resource

enum Strategy { FIRST, LAST, CLOSEST, FARTHEST, STRONGEST, WEAKEST }

@export var strategy: Strategy = Strategy.FIRST
@export var max_targets: int = 1
@export_flags_2d_physics var targeting_mask: int = 4
@export var can_target_through_walls: bool = false
