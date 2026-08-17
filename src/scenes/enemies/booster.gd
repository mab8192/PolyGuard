class_name Booster extends Enemy

const AURA_RADIUS: float = 130.0
const SPEED_BUFF: float = 1.35 ## +35% speed

var _boosted_enemies: Array[MovementComponent] = []

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_update_aura()
	queue_redraw()

func _update_aura() -> void:
	var tree = get_tree()
	if not tree:
		return
	
	var current_in_range: Array[MovementComponent] = []
	var enemies = tree.get_nodes_in_group("enemies")
	for node in enemies:
		if is_instance_valid(node) and node is Enemy and node != self and not node.is_queued_for_deletion():
			if global_position.distance_to(node.global_position) <= AURA_RADIUS:
				var m = ComponentUtil.get_component(node, MovementComponent) as MovementComponent
				if m:
					current_in_range.append(m)
					if not _boosted_enemies.has(m):
						m.speed_multiplier *= SPEED_BUFF
						_boosted_enemies.append(m)
	
	for m in _boosted_enemies.duplicate():
		if not is_instance_valid(m) or not current_in_range.has(m):
			if is_instance_valid(m):
				m.speed_multiplier /= SPEED_BUFF
			_boosted_enemies.erase(m)

func _exit_tree() -> void:
	_clear_boosts()

func _on_died() -> void:
	_clear_boosts()
	super._on_died()

func _clear_boosts() -> void:
	for m in _boosted_enemies:
		if is_instance_valid(m):
			m.speed_multiplier /= SPEED_BUFF
	_boosted_enemies.clear()

func _draw() -> void:
	draw_circle(Vector2.ZERO, AURA_RADIUS, Color(1.0, 0.65, 0.1, 0.07))
	draw_arc(Vector2.ZERO, AURA_RADIUS, 0, TAU, 32, Color(1.0, 0.65, 0.1, 0.35), 1.5, true)
