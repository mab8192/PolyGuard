class_name Booster extends Enemy

const DEFAULT_AURA_RADIUS: float = 130.0

func _draw() -> void:
	var r: float = DEFAULT_AURA_RADIUS
	if effect_applier:
		for child in effect_applier.get_children():
			if child is CollisionShape2D and child.shape is CircleShape2D:
				r = (child.shape as CircleShape2D).radius
				break
	draw_circle(Vector2.ZERO, r, Color(1.0, 0.65, 0.1, 0.07))
	draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(1.0, 0.65, 0.1, 0.35), 1.5, true)
