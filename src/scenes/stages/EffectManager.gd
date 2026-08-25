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
	effect.global_position = pos
	effect.color = color
	effect.emitting = true
	effect.finished.connect(func(): effect.queue_free())

	if GameManager.stage_root:
		GameManager.stage_root.effects.add_child(effect)
	elif is_instance_valid(effects_container):
		effects_container.add_child(effect)
	else:
		add_child(effect)

func siphon_burst(pos: Vector2) -> void:
	var effect = SIPHON_BURST.instantiate() as CPUParticles2D
	if not effect:
		return
	effect.global_position = pos
	effect.emitting = true
	effect.finished.connect(func(): effect.queue_free())

	if GameManager.stage_root:
		GameManager.stage_root.effects.add_child(effect)
	elif is_instance_valid(effects_container):
		effects_container.add_child(effect)
	else:
		add_child(effect)

func _on_enemy_died(enemy: Enemy) -> void:
	if is_instance_valid(enemy) and enemy.effect_receiver.get_energy_reward_multiplier() > 1.0:
		siphon_burst(enemy.global_position)
	elif is_instance_valid(enemy):
		explosion(enemy.global_position)
