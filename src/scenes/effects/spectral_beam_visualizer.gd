class_name SpectralBeamVisualizer extends Node2D

@onready var targeting_component: TargetingComponent = $"../TargetingComponent"

var _pulse_offset: float = 0.0

func _process(delta: float) -> void:
	_pulse_offset = fmod(_pulse_offset + delta * 2.5, 1.0)
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(targeting_component):
		return

	var targets = targeting_component.get_targets()
	if targets.is_empty():
		return

	var start_pos := Vector2(0, -2) # Center of the soul lantern flame

	for target in targets:
		if not is_instance_valid(target) or target.is_queued_for_deletion():
			continue
		
		var end_pos := to_local(target.global_position)
		var dist := start_pos.distance_to(end_pos)
		if dist <= 2.0:
			continue

		var dir := (end_pos - start_pos).normalized()
		var perp := Vector2(-dir.y, dir.x)

		# 1. Broad outer ethereal violet aura
		draw_line(start_pos, end_pos, Color(0.7, 0.25, 0.95, 0.22), 8.0)
		
		# 2. Main incandescent cyan spirit beam
		draw_line(start_pos, end_pos, Color(0.0, 0.92, 1.0, 0.85), 3.5)
		
		# 3. Core white-gold laser filament
		draw_line(start_pos, end_pos, Color(1.0, 0.98, 0.85, 1.0), 1.5)

		# 4. Traveling spirit energy nodes along the beam
		for i in range(3):
			var t = fmod(_pulse_offset + float(i) * 0.33, 1.0)
			var node_pos = start_pos.lerp(end_pos, t)
			draw_circle(node_pos, 3.0, Color(0.8, 0.95, 1.0, 0.9))
			draw_circle(node_pos, 1.5, Color.WHITE)

		# 5. Target impact flare
		draw_circle(end_pos, 5.0, Color(0.0, 0.92, 1.0, 0.6))
		draw_circle(end_pos, 2.5, Color.WHITE)
