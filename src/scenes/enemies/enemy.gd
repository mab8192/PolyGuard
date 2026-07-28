class_name Enemy extends CharacterBody2D

@export var lives_penalty: int = 1

@export_category("Components")
@export var health: HealthComponent
@export var movement: MovementComponent
@export var nav: NavigationComponent

func _ready() -> void:
	nav.velocity_computed.connect(_on_velocity_computed)
	if health:
		health.died.connect(_on_died)
	
	var targets: Array[Node2D] = []
	for exit in get_tree().get_nodes_in_group("exits"):
		targets.append(exit)
	nav.set_targets(targets)

func _on_died() -> void:
	SignalBus.enemy_died.emit(self)
	queue_free()

func _physics_process(_delta: float) -> void:
	pass

func _on_velocity_computed(vel: Vector2):
	var dir = vel.normalized()
	movement.handle_movement(dir, get_physics_process_delta_time())
	look_at(global_position + velocity)
