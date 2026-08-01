extends Area2D

func _on_body_entered(body: Node2D) -> void:
	var enemy: Enemy = body as Enemy
	if enemy == null: return
	
	SignalBus.enemy_exit.emit(enemy)
	enemy.queue_free()
