class_name Enemy extends CharacterBody2D

@export var lives_penalty: int = 1
@export var gold_reward: int = 1

@export_category("Components")
@export var health: HealthComponent
@export var movement: MovementComponent
@export var nav: NavigationComponent

var _active_effects: Array[ActiveEffect] = []

func apply_effect(effect: ActiveEffect) -> void:
	_active_effects.append(effect)
	effect.apply(self)
	print("Added effect! Effects active: " + str(_active_effects.size()))

func remove_effect(effect: ActiveEffect) -> void:
	_active_effects.erase(effect)
	effect.remove()
	print("Removed effect! Effects active: " + str(_active_effects.size()))

func _ready() -> void:
	nav.velocity_computed.connect(_on_velocity_computed)
	if health:
		health.died.connect(_on_died)
	
	if nav:
		# Apply common settings shared by all enemies
		#nav.agent.path_max_distance = 10
		#nav.agent.avoidance_enabled = true
		#
		# Assign targets from the stage
		var targets: Array[Node2D] = []
		for exit in get_tree().get_nodes_in_group("exits"):
			targets.append(exit)
		nav.set_targets(targets)

func _on_died() -> void:
	SignalBus.enemy_died.emit(self)
	queue_free()

func _process(delta: float) -> void:
	for effect in _active_effects:
		effect.tick(delta)

func _on_velocity_computed(vel: Vector2):
	var dir = vel.normalized()
	movement.handle_movement(dir, get_physics_process_delta_time())
	look_at(global_position + velocity)
