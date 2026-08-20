class_name FlowFieldVisualizer extends Node2D

## Visualizer and Debug Overlay for Flow Fields.
## Renders vector arrows, integration cost heatmaps, dynamic congestion, and wall clearance.
## Controls: F2 / F3 to cycle display mode, F4 to cycle field layer.

enum DisplayMode {
	OFF,
	ARROWS,
	HEATMAP_AND_ARROWS,
	HEATMAP_ONLY,
	CONGESTION,
	CLEARANCE
}

enum FieldLayer {
	PHYSICAL,
	GHOST,
	WALLS_ONLY
}

var mode: DisplayMode = DisplayMode.OFF:
	set(val):
		mode = val
		visible = (mode != DisplayMode.OFF)
		_update_badge_ui()
		queue_redraw()

var current_layer: FieldLayer = FieldLayer.PHYSICAL:
	set(val):
		current_layer = val
		_update_badge_ui()
		queue_redraw()

var manager: FlowFieldManager = null

# CanvasLayer HUD badge for visualizer status
var _badge_layer: CanvasLayer = null
var _badge_panel: PanelContainer = null
var _badge_label: Label = null

func setup(p_manager: FlowFieldManager) -> void:
	manager = p_manager
	z_index = 50 # Render above tiles and floor
	visible = false
	_create_badge_ui()
	_update_badge_ui()

func _create_badge_ui() -> void:
	_badge_layer = CanvasLayer.new()
	_badge_layer.name = "FlowFieldDebugLayer"
	_badge_layer.layer = 120 # Top of UI
	add_child(_badge_layer)

	_badge_panel = PanelContainer.new()
	_badge_panel.theme = preload("res://src/misc/theme.tres")
	_badge_panel.theme_type_variation = &"StatusBadge"
	_badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge_panel.visible = false

	# Position near top center
	_badge_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH

	_badge_label = Label.new()
	_badge_label.theme_type_variation = &"BadgeText"
	_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_badge_panel.add_child(_badge_label)
	_badge_layer.add_child(_badge_panel)

func _update_badge_ui() -> void:
	if not _badge_panel or not _badge_label:
		return

	if mode == DisplayMode.OFF:
		_badge_panel.visible = false
		return

	_badge_panel.visible = true
	var mode_name: String = ""
	match mode:
		DisplayMode.ARROWS: mode_name = "ARROWS"
		DisplayMode.HEATMAP_AND_ARROWS: mode_name = "HEATMAP + ARROWS"
		DisplayMode.HEATMAP_ONLY: mode_name = "HEATMAP"
		DisplayMode.CONGESTION: mode_name = "CONGESTION"
		DisplayMode.CLEARANCE: mode_name = "WALL CLEARANCE"

	var layer_name: String = ""
	match current_layer:
		FieldLayer.PHYSICAL: layer_name = "PHYSICAL"
		FieldLayer.GHOST: layer_name = "GHOST"
		FieldLayer.WALLS_ONLY: layer_name = "WALLS ONLY"

	_badge_label.text = "FLOW FIELD: [%s] | MODE: %s (F2/F3: Mode, F4: Layer)" % [layer_name, mode_name]
	_badge_panel.reset_size()
	var sz = _badge_panel.get_combined_minimum_size()
	_badge_panel.position = Vector2((1080.0 - sz.x) * 0.5, 110.0)

func cycle_mode() -> void:
	var next_mode = (int(mode) + 1) % 6
	mode = next_mode as DisplayMode

func cycle_layer() -> void:
	var next_layer = (int(current_layer) + 1) % 3
	current_layer = next_layer as FieldLayer

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_F2 or event.keycode == KEY_F3:
			cycle_mode()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F4:
			cycle_layer()
			get_viewport().set_input_as_handled()

func _get_active_field() -> FlowField:
	if not manager:
		return null
	match current_layer:
		FieldLayer.PHYSICAL: return manager.physical_field
		FieldLayer.GHOST: return manager.ghost_field
		FieldLayer.WALLS_ONLY: return manager.walls_only_field
	return manager.physical_field

func _draw() -> void:
	if mode == DisplayMode.OFF:
		return

	var field: FlowField = _get_active_field()
	if not field or field.total_cells == 0:
		return

	var w: int = field.grid_size.x
	var h: int = field.grid_size.y
	var origin: Vector2 = field.world_origin
	var cs: Vector2 = field.cell_size

	# Find max integration cost for normalizing heatmaps
	var max_cost: float = 1.0
	if mode == DisplayMode.HEATMAP_AND_ARROWS or mode == DisplayMode.HEATMAP_ONLY:
		for idx: int in range(field.total_cells):
			var c: float = field.integration_cost[idx]
			if c < FlowField.TOWER_COST and c > max_cost:
				max_cost = c

	var max_congestion: float = 1.0
	if mode == DisplayMode.CONGESTION:
		for idx: int in range(field.total_cells):
			var cong: float = field.congestion_cost[idx]
			if cong > max_congestion:
				max_congestion = cong

	# 1. Draw Heatmaps
	if mode == DisplayMode.HEATMAP_AND_ARROWS or mode == DisplayMode.HEATMAP_ONLY:
		for gy: int in range(h):
			var row: int = gy * w
			var cell_y: float = origin.y + float(gy) * cs.y
			for gx: int in range(w):
				var idx: int = row + gx
				var cell_x: float = origin.x + float(gx) * cs.x
				var cell_rect: Rect2 = Rect2(Vector2(cell_x, cell_y), cs)

				var base: float = field.base_cost[idx]
				if base >= FlowField.BLOCKED_COST:
					draw_rect(cell_rect, Color(0.06, 0.06, 0.1, 0.65), true)
				elif base >= FlowField.TOWER_COST:
					draw_rect(cell_rect, Color(0.9, 0.3, 0.1, 0.45), true)
				else:
					var cost: float = field.integration_cost[idx]
					if cost < FlowField.TOWER_COST:
						var t: float = clampf(cost / maxf(max_cost, 1.0), 0.0, 1.0)
						var col: Color = Color.from_hsv(lerp(0.5, 0.85, t), 0.75, 0.85, 0.35)
						draw_rect(cell_rect, col, true)

	elif mode == DisplayMode.CONGESTION:
		for gy: int in range(h):
			var row: int = gy * w
			var cell_y: float = origin.y + float(gy) * cs.y
			for gx: int in range(w):
				var idx: int = row + gx
				var cell_x: float = origin.x + float(gx) * cs.x
				var cell_rect: Rect2 = Rect2(Vector2(cell_x, cell_y), cs)

				var cong: float = field.congestion_cost[idx]
				if cong > 0.01:
					var t: float = clampf(cong / maxf(max_congestion, 1.0), 0.0, 1.0)
					var col: Color = Color(1.0, 0.2, 0.1, lerp(0.2, 0.7, t))
					draw_rect(cell_rect, col, true)

	elif mode == DisplayMode.CLEARANCE:
		for gy: int in range(h):
			var row: int = gy * w
			var cell_y: float = origin.y + float(gy) * cs.y
			for gx: int in range(w):
				var idx: int = row + gx
				var cell_x: float = origin.x + float(gx) * cs.x
				var cell_rect: Rect2 = Rect2(Vector2(cell_x, cell_y), cs)

				if field.base_cost[idx] >= FlowField.BLOCKED_COST:
					draw_rect(cell_rect, Color(0.06, 0.06, 0.1, 0.65), true)
				elif field.base_cost[idx] >= FlowField.TOWER_COST:
					draw_rect(cell_rect, Color(0.9, 0.3, 0.1, 0.45), true)
				elif field.clearance_cost[idx] > 0.0:
					var t: float = clampf(field.clearance_cost[idx] / 1.5, 0.0, 1.0)
					var col: Color = Color(0.2, 0.6, 1.0, lerp(0.2, 0.55, t))
					draw_rect(cell_rect, col, true)

	# 2. Draw Vector Arrows
	if mode == DisplayMode.ARROWS or mode == DisplayMode.HEATMAP_AND_ARROWS:
		var lines: PackedVector2Array = []
		var colors: PackedColorArray = []

		var arrow_len: float = cs.x * 0.42
		var head_size: float = 3.0

		for gy: int in range(h):
			var row: int = gy * w
			var center_y: float = origin.y + (float(gy) + 0.5) * cs.y
			for gx: int in range(w):
				var idx: int = row + gx
				var v: Vector2 = field.flow_vectors[idx]
				if v.length_squared() < 0.0001:
					continue

				var center_x: float = origin.x + (float(gx) + 0.5) * cs.x
				var center: Vector2 = Vector2(center_x, center_y)

				var start: Vector2 = center - v * (arrow_len * 0.4)
				var end: Vector2 = center + v * (arrow_len * 0.6)
				var perp: Vector2 = Vector2(-v.y, v.x)

				var head_left: Vector2 = end - v * head_size + perp * (head_size * 0.75)
				var head_right: Vector2 = end - v * head_size - perp * (head_size * 0.75)

				var col: Color
				if field.base_cost[idx] >= FlowField.TOWER_COST:
					col = Color(1.0, 0.55, 0.2, 0.8) # Tower orange
				elif field.integration_cost[idx] >= FlowField.TOWER_COST:
					col = Color(1.0, 0.85, 0.3, 0.75) # Blocked route yellow
				else:
					col = Color(0.1, 0.95, 0.9, 0.85) # Open cyan

				# Shaft (segment 1)
				lines.append(start)
				lines.append(end)
				colors.append(col)

				# Head Left (segment 2)
				lines.append(end)
				lines.append(head_left)
				colors.append(col)

				# Head Right (segment 3)
				lines.append(end)
				lines.append(head_right)
				colors.append(col)

		if not lines.is_empty():
			draw_multiline_colors(lines, colors, 1.5)
