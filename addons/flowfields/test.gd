extends Node2D

var field: FlowField

const GRID_SIZE = 32

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	field = FlowField.new(40, 40, GRID_SIZE, Vector2.ZERO)

	field.add_target(Vector2(300, 300))
	field.add_target(Vector2(300 + GRID_SIZE, 300))
	field.add_target(Vector2(300, 300 + GRID_SIZE))
	field.add_target(Vector2(300 + GRID_SIZE, 300 + GRID_SIZE))
	
	field.rebuild()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			var pos = get_global_mouse_position()
			field.set_cost(pos, 100)
			field.rebuild()

func _draw() -> void:
	if not field:
		return

	for x in range(field.width):
		for y in range(field.height):
			var idx: int = field._index(Vector2i(x, y))
			var pos: Vector2 = Vector2(x, y) * GRID_SIZE
			var cost: float = field.integration_grid[idx]
			var cell_cost: float = field.cost_grid[idx]

			# Draw cell background
			if cost == 0:
				draw_rect(Rect2(pos, Vector2(GRID_SIZE, GRID_SIZE)), Color(0.1, 0.8, 0.3, 0.8), true) # Target green
			elif cell_cost >= FlowField.COST_IMPASSABLE or cell_cost >= 10:
				draw_rect(Rect2(pos, Vector2(GRID_SIZE, GRID_SIZE)), Color(0.85, 0.2, 0.2, 0.8), true) # Wall/Obstacle red
			elif cost < FlowField.INTEGRATION_MAX:
				draw_rect(Rect2(pos, Vector2(GRID_SIZE, GRID_SIZE)), Color(0.1, 0.2, 0.45, 0.7), true) # Open path blue
			else:
				draw_rect(Rect2(pos, Vector2(GRID_SIZE, GRID_SIZE)), Color(0.08, 0.08, 0.12, 0.7), true) # Unreached dark

			# Grid cell border
			draw_rect(Rect2(pos, Vector2(GRID_SIZE, GRID_SIZE)), Color(1.0, 1.0, 1.0, 0.08), false, 1.0)

			# Draw flow direction arrow
			var dir: Vector2 = field.field[idx]
			if dir != Vector2.ZERO:
				var center: Vector2 = pos + Vector2(GRID_SIZE, GRID_SIZE) * 0.5
				var arrow_len: float = float(GRID_SIZE) * 0.38
				var start: Vector2 = center - dir * (arrow_len * 0.3)
				var end: Vector2 = center + dir * (arrow_len * 0.7)
				var arrow_color := Color(1.0, 1.0, 1.0, 0.9)

				# Arrow shaft
				draw_line(start, end, arrow_color, 1.5)

				# Arrowhead
				var perp := Vector2(-dir.y, dir.x)
				var head_size: float = 8.0
				var p1 := end - dir * head_size + perp * (head_size * 0.6)
				var p2 := end - dir * head_size - perp * (head_size * 0.6)
				draw_line(end, p1, arrow_color, 1.5)
				draw_line(end, p2, arrow_color, 1.5)

			# Draw integration cost text
			var font := ThemeDB.fallback_font
			var font_size: int = clampi(int(GRID_SIZE * 0.35), 8, 14)
			var text: String = "%.2f" % cost if cost < FlowField.INTEGRATION_MAX else "∞"
			var text_color := Color(1.0, 1.0, 1.0, 0.85) if cost == 0 else Color(0.9, 0.9, 1.0, 0.65)
			draw_string(font, pos + Vector2(3, font_size + 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	queue_redraw()
