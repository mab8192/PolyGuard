class_name FlowFieldDebugDraw
extends Node2D

## ============================================================================
## FlowFieldDebugDraw
## ----------------------------------------------------------------------------
## Attach to a Node2D placed at (0,0) in your scene to visualize a shared
## FlowField's cost field and/or flow direction arrows.
## ============================================================================

@export var field_id: String = "default"
@export var draw_arrows: bool = true
@export var draw_cost_overlay: bool = true
@export var draw_grid_lines: bool = false
@export var arrow_color: Color = Color(0.15, 0.95, 1.0, 0.9)
@export var wall_color: Color = Color(1.0, 0.15, 0.15, 0.35)
@export var grid_line_color: Color = Color(1.0, 1.0, 1.0, 0.08)
@export var arrow_length_scale: float = 0.4

var _field: FlowField


func _ready() -> void:
	var manager: FlowFieldManager = get_node_or_null("/root/FlowFieldManager") as FlowFieldManager
	if manager != null:
		_field = manager.get_field(field_id)
		manager.flow_fields_updated.connect(queue_redraw)
	queue_redraw()


func set_field(field: FlowField) -> void:
	_field = field
	queue_redraw()


func _draw() -> void:
	if _field == null:
		return

	var cs: float = float(_field.cell_size)
	var half: Vector2 = Vector2(cs, cs) * 0.5

	for y: int in range(_field.height):
		for x: int in range(_field.width):
			var idx: int = _field._index(Vector2i(x, y))
			var center: Vector2 = _field.origin + Vector2(float(x) + 0.5, float(y) + 0.5) * cs

			if draw_grid_lines:
				draw_rect(Rect2(center - half, Vector2(cs, cs)), grid_line_color, false, 1.0)

			if draw_cost_overlay and _field.cost_grid[idx] >= FlowField.COST_IMPASSABLE:
				draw_rect(Rect2(center - half, Vector2(cs, cs)), wall_color)

			if draw_arrows:
				var dir: Vector2 = _field.field[idx]
				if dir != Vector2.ZERO:
					var end: Vector2 = center + dir * cs * arrow_length_scale
					draw_line(center, end, arrow_color, 2.0)
					_draw_arrowhead(center, end, arrow_color)


func _draw_arrowhead(from: Vector2, to: Vector2, color: Color) -> void:
	var dir: Vector2 = (to - from).normalized()
	var perp: Vector2 = Vector2(-dir.y, dir.x)
	var head_size: float = 4.0
	var p1: Vector2 = to - dir * head_size + perp * head_size * 0.5
	var p2: Vector2 = to - dir * head_size - perp * head_size * 0.5
	draw_line(to, p1, color, 2.0)
	draw_line(to, p2, color, 2.0)
