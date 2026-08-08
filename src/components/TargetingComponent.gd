class_name TargetingComponent extends Area2D

enum Strategy {FIRST, LAST, CLOSEST, STRONGEST}

@export var strategy: Strategy = Strategy.FIRST
@export var max_targets: int = 1
var can_target_physical: bool = true:
	set(val):
		can_target_physical = val
		_update_collision_mask()

var can_target_ghost: bool = false:
	set(val):
		can_target_ghost = val
		_update_collision_mask()

var targets: Array[Enemy] = []
var active_targets: Array[Enemy] = []

func _ready() -> void:
	_update_collision_mask()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _update_collision_mask() -> void:
	var mask: int = 0
	if can_target_physical:
		mask |= 4 # Physics Layer 3 (Physical Enemies)
	if can_target_ghost:
		mask |= 8 # Physics Layer 4 (Ghost Enemies)
	collision_mask = mask

func _physics_process(_delta: float) -> void:
	_select_target()

## Assigns up to `max_targets` enemies from `targets` to `active_targets` according to `strategy`
func _select_target() -> void:
	targets = targets.filter(func(t: Enemy) -> bool: return is_instance_valid(t))
	active_targets.clear()

	if targets.is_empty():
		return

	# Sort candidates according to the selected strategy
	var candidates: Array[Enemy] = targets.duplicate()

	match strategy:
		Strategy.FIRST:
			candidates.sort_custom(func(a: Enemy, b: Enemy) -> bool:
				var dist_a = a.nav.distance_to_goal() if a.nav else INF
				var dist_b = b.nav.distance_to_goal() if b.nav else INF
				return dist_a < dist_b
			)
		Strategy.LAST:
			candidates.sort_custom(func(a: Enemy, b: Enemy) -> bool:
				var dist_a = a.nav.distance_to_goal() if a.nav else -INF
				var dist_b = b.nav.distance_to_goal() if b.nav else -INF
				return dist_a > dist_b
			)
		Strategy.CLOSEST:
			candidates.sort_custom(func(a: Enemy, b: Enemy) -> bool:
				var dist_a = global_position.distance_squared_to(a.global_position)
				var dist_b = global_position.distance_squared_to(b.global_position)
				return dist_a < dist_b
			)
		Strategy.STRONGEST:
			candidates.sort_custom(func(a: Enemy, b: Enemy) -> bool:
				var hp_a = a.health.health if a.health else 0.0
				var hp_b = b.health.health if b.health else 0.0
				return hp_a > hp_b
			)

	var limit: int = candidates.size()
	if max_targets > 0:
		limit = min(max_targets, candidates.size())

	active_targets = candidates.slice(0, limit)

func _on_body_entered(body: Node2D) -> void:
	var enemy = body as Enemy
	if body and not targets.has(body):
		targets.append(enemy)

func _on_body_exited(body: Node2D) -> void:
	if body is Enemy:
		targets.erase(body)

func _process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	for target in active_targets:
		if is_instance_valid(target):
			draw_circle(to_local(target.global_position), 20, Color.RED)
