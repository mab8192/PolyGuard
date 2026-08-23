class_name Healer extends Enemy

const DEFAULT_HEAL_RADIUS: float = 120.0

var _pulse_anim: float = 0.0

func _ready() -> void:
	super._ready()
	if effect_applier:
		effect_applier.triggered.connect(_on_applier_triggered)

func _on_applier_triggered() -> void:
	_pulse_anim = 1.0
	queue_redraw()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if _pulse_anim > 0.0:
		_pulse_anim = maxf(0.0, _pulse_anim - delta * 2.5)
		queue_redraw()

func _draw() -> void:
	if _pulse_anim > 0.0:
		var r: float = DEFAULT_HEAL_RADIUS
		if effect_applier:
			for child in effect_applier.get_children():
				if child is CollisionShape2D and child.shape is CircleShape2D:
					r = (child.shape as CircleShape2D).radius
					break
		var current_r = r * (1.0 - _pulse_anim * 0.3)
		var alpha = _pulse_anim * 0.4
		draw_circle(Vector2.ZERO, current_r, Color(0.0, 1.0, 0.6, alpha * 0.25))
		draw_arc(Vector2.ZERO, current_r, 0, TAU, 32, Color(0.0, 1.0, 0.7, alpha), 2.0, true)

