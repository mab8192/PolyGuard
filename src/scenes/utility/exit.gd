extends Area2D

func _on_body_entered(body: Node2D) -> void:
	var enemy: Enemy = body as Enemy
	if enemy == null: return
	
	enemy.queue_free()
	SignalBus.enemy_died.emit(enemy)
	SignalBus.enemy_exit.emit(enemy)
