class_name MovementData extends Resource

@export var max_speed: float = 100.0
@export var acceleration: float = 1200.0
@export var friction: float = 1000.0

func apply_to(component: MovementComponent) -> void:
	if not component:
		return
	component.apply_data(self)
