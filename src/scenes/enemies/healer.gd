class_name Healer extends Enemy

const HEAL_RADIUS: float = 120.0
const HEAL_AMOUNT: float = 25.0
const HEAL_INTERVAL: float = 1.0

var _heal_timer: float = 0.0
var _pulse_anim: float = 0.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	_heal_timer += delta
	if _heal_timer >= HEAL_INTERVAL:
		_heal_timer = 0.0
		_pulse_heal()
		_pulse_anim = 1.0

	if _pulse_anim > 0.0:
		_pulse_anim = maxf(0.0, _pulse_anim - delta * 2.5)
		queue_redraw()

func _pulse_heal() -> void:
	var tree = get_tree()
	if not tree:
		return
	
	var enemies = tree.get_nodes_in_group("enemies")
	for node in enemies:
		if is_instance_valid(node) and node is Enemy and node != self and not node.is_queued_for_deletion():
			if global_position.distance_to(node.global_position) <= HEAL_RADIUS:
				var h = ComponentUtil.get_component(node, HealthComponent) as HealthComponent
				if h:
					h.heal(HEAL_AMOUNT)

func _draw() -> void:
	if _pulse_anim > 0.0:
		var current_r = HEAL_RADIUS * (1.0 - _pulse_anim * 0.3)
		var alpha = _pulse_anim * 0.4
		draw_circle(Vector2.ZERO, current_r, Color(0.0, 1.0, 0.6, alpha * 0.25))
		draw_arc(Vector2.ZERO, current_r, 0, TAU, 32, Color(0.0, 1.0, 0.7, alpha), 2.0, true)
