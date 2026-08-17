class_name EffectManager extends Node

var effects_container: Node2D

const EXPLOSION: PackedScene = preload("res://src/scenes/effects/explosion.tscn")

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

	if GameManager and GameManager.stage_root and is_instance_valid(GameManager.stage_root.effects):
		GameManager.stage_root.effects.add_child(effect)
	elif effects_container and is_instance_valid(effects_container):
		effects_container.add_child(effect)
	else:
		add_child(effect)

func _on_enemy_died(enemy: Enemy) -> void:
	explosion(enemy.global_position)
