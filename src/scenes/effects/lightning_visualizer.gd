extends Node2D

@onready var targeting_component: TargetingComponent = $"../TargetingComponent"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	## TODO: Make this look better
	for target in targeting_component.get_targets():
		draw_line(Vector2.ZERO, to_local(target.global_position), Color.AQUA, 4)
