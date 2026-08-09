class_name TargetingData extends Resource

@export var strategy: TargetingComponent.Strategy = TargetingComponent.Strategy.FIRST
@export var max_targets: int = 1
@export var can_target_physical: bool = true
@export var can_target_ghost: bool = false
@export var can_target_through_walls: bool = false
