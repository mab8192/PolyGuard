extends Node2D

@onready var targeting_component: TargetingComponent = $"../TargetingComponent"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(targeting_component):
		return

	for target in targeting_component.get_targets():
		if not is_instance_valid(target):
			continue
		var start_pos := Vector2.ZERO
		var end_pos := to_local(target.global_position)
		var dist := start_pos.distance_to(end_pos)
		if dist <= 0.1:
			continue

		var dir := (end_pos - start_pos).normalized()
		var perp := Vector2(-dir.y, dir.x)
		var segments := int(clamp(dist / 16.0, 3.0, 8.0))
		
		var points: PackedVector2Array = [start_pos]
		for i in range(1, segments):
			var t := float(i) / float(segments)
			var base_point := start_pos.lerp(end_pos, t)
			var jitter := randf_range(-4.0, 4.0)
			points.append(base_point + perp * jitter)
		points.append(end_pos)

		for i in range(points.size() - 1):
			draw_line(points[i], points[i + 1], Color.CYAN, 3.0)
			draw_line(points[i], points[i + 1], Color.WHITE, 1.5)
