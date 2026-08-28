class_name EffectManager extends Node

var effects_container: Node2D

const EXPLOSION: PackedScene = preload("res://src/scenes/effects/explosion.tscn")
const SIPHON_BURST: PackedScene = preload("res://src/scenes/effects/particles/siphon_burst.tscn")

func setup() -> void:
	SignalBus.enemy_died.connect(_on_enemy_died)

func explosion(pos: Vector2, color: Color = Color.WHITE) -> void:
	var effect = EXPLOSION.instantiate() as CPUParticles2D
	if not effect:
		return
	var parent_node: Node = GameManager.stage_root.effects if (GameManager.stage_root and GameManager.stage_root.effects) else effects_container
	if is_instance_valid(parent_node) and parent_node is Node2D:
		effect.position = (parent_node as Node2D).to_local(pos)
		parent_node.add_child(effect)
	else:
		effect.position = pos
		add_child(effect)
	effect.reset_physics_interpolation()
	effect.color = color
	effect.emitting = true
	effect.finished.connect(func(): if is_instance_valid(effect): effect.queue_free())

func siphon_burst(pos: Vector2) -> void:
	var effect = SIPHON_BURST.instantiate() as CPUParticles2D
	if not effect:
		return
	var parent_node: Node = GameManager.stage_root.effects if (GameManager.stage_root and GameManager.stage_root.effects) else effects_container
	if is_instance_valid(parent_node) and parent_node is Node2D:
		effect.position = (parent_node as Node2D).to_local(pos)
		parent_node.add_child(effect)
	else:
		effect.position = pos
		add_child(effect)
	effect.reset_physics_interpolation()
	effect.emitting = true
	effect.finished.connect(func(): if is_instance_valid(effect): effect.queue_free())

func _on_enemy_died(enemy: Enemy) -> void:
	if is_instance_valid(enemy) and enemy.effect_receiver.get_energy_reward_multiplier() > 1.0:
		siphon_burst(enemy.global_position)
	elif is_instance_valid(enemy):
		explosion(enemy.global_position)
