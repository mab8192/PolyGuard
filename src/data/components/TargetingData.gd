class_name TargetingData extends Resource

@export var strategy: TargetingComponent.Strategy = TargetingComponent.Strategy.FIRST
@export var max_targets: int = 1
@export var can_target_physical: bool = true
@export var can_target_ghost: bool = false

func apply_to(component: TargetingComponent) -> void:
	if not component:
		return
	component.apply_data(self)
