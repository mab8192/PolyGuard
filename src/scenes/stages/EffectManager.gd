class_name EffectManager extends Node

var effects_container: Node2D

const EXPLOSION: PackedScene = preload("res://src/scenes/effects/explosion.tscn")

func setup() -> void:
	SignalBus.enemy_died.connect(_on_enemy_died)

func explosion(pos: Vector2, color: Color = Color.WHITE) -> void:
	var effect = EXPLOSION.instantiate() as GPUParticles2D
	effect.global_position = pos
	effect.emitting = true
	
	var mat: ParticleProcessMaterial = effect.process_material as ParticleProcessMaterial
	if !mat:
		push_error("Explosion is missing particle process material!")
	
	mat.color = color
	effect.finished.connect(func(): effect.queue_free())

	GameManager.stage_root.effects.add_child(effect)

func _on_enemy_died(enemy: Enemy) -> void:
	explosion(enemy.global_position)
