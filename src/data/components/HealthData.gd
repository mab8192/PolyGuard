class_name HealthData extends Resource

@export var max_health: float = 100.0
@export var armor: float = 0.0
@export var magic_resistance: float = 0.0

func apply_to(component: HealthComponent) -> void:
	if not component:
		return
	component.apply_data(self)
