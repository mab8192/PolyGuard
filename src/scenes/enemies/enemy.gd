class_name Enemy extends CharacterBody2D

@export var target: Node2D
@export var agent: NavigationAgent2D
@export var speed: float = 100
@export var lives_penalty: int = 1

@export_category("Components")
@export var health: HealthComponent
@export var movement: MovementComponent

func _ready() -> void:
	agent.target_position = target.global_position
	agent.velocity_computed.connect(_on_velocity_computed)

func _physics_process(_delta: float) -> void:
	if agent.is_navigation_finished():
		movement.stop()
		return
	
	var next_pos = agent.get_next_path_position()
	
	var dir = global_position.direction_to(next_pos)
	var intended_vel = dir * movement.max_speed
	agent.velocity = intended_vel

func _on_velocity_computed(vel: Vector2):
	var dir = vel.normalized()
	movement.handle_movement(dir, get_physics_process_delta_time())
