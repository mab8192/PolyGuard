class_name FlowFieldVisualizer
extends Node2D

## Visualizer and Debug Overlay for Multi-Tier Flow Fields.
## Renders vector arrows and integration cost heatmaps.
## Controls: F2 / F3 to cycle display mode, F4 to cycle field layer.

enum DisplayMode {
	OFF,
	ARROWS,
	HEATMAP_AND_ARROWS,
	HEATMAP_ONLY
}

enum FieldLayer {
	PHYSICAL_SMALL,
	PHYSICAL_MEDIUM,
	PHYSICAL_LARGE,
	GHOST_SMALL,
	GHOST_MEDIUM,
	GHOST_LARGE
}

var mode: DisplayMode = DisplayMode.OFF:
	set(val):
		mode = val
		visible = (mode != DisplayMode.OFF)
		_update_badge_ui()
		queue_redraw()

var current_layer: FieldLayer = FieldLayer.PHYSICAL_SMALL:
	set(val):
		current_layer = val
		_update_badge_ui()
		queue_redraw()

# CanvasLayer HUD badge for visualizer status
var _badge_layer: CanvasLayer = null
var _badge_panel: PanelContainer = null
var _badge_label: Label = null


func setup() -> void:
	z_index = 50
	visible = false
	_create_badge_ui()
	_update_badge_ui()


func _ready() -> void:
	setup()
	SignalBus.flow_fields_updated.connect(queue_redraw)


func _create_badge_ui() -> void:
	_badge_layer = CanvasLayer.new()
	_badge_layer.name = "FlowFieldDebugLayer"
	_badge_layer.layer = 120
	add_child(_badge_layer)

	_badge_panel = PanelContainer.new()
	_badge_panel.theme = preload("res://src/misc/theme.tres")
	_badge_panel.theme_type_variation = &"StatusBadge"
	_badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge_panel.visible = false

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

	var layer_name: String = ""
	match current_layer:
		FieldLayer.PHYSICAL_SMALL: layer_name = "PHYSICAL (16PX - SMALL)"
		FieldLayer.PHYSICAL_MEDIUM: layer_name = "PHYSICAL (32PX - MEDIUM)"
		FieldLayer.PHYSICAL_LARGE: layer_name = "PHYSICAL (64PX - LARGE)"
		FieldLayer.GHOST_SMALL: layer_name = "GHOST (16PX - SMALL)"
		FieldLayer.GHOST_MEDIUM: layer_name = "GHOST (32PX - MEDIUM)"
		FieldLayer.GHOST_LARGE: layer_name = "GHOST (64PX - LARGE)"

	_badge_label.text = "FLOW FIELD: [%s] | MODE: %s (F2/F3: Mode, F4: Layer)" % [layer_name, mode_name]
	_badge_panel.reset_size()
	var sz: Vector2 = _badge_panel.get_combined_minimum_size()
	_badge_panel.position = Vector2((1080.0 - sz.x) * 0.5, 110.0)


func cycle_mode() -> void:
	var next_mode: int = (int(mode) + 1) % 4
	mode = next_mode as DisplayMode


func cycle_layer() -> void:
	var next_layer: int = (int(current_layer) + 1) % 6
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
	match current_layer:
		FieldLayer.PHYSICAL_SMALL: return FlowFieldManager.get_field("physical_small")
		FieldLayer.PHYSICAL_MEDIUM: return FlowFieldManager.get_field("physical_medium")
		FieldLayer.PHYSICAL_LARGE: return FlowFieldManager.get_field("physical_large")
		FieldLayer.GHOST_SMALL: return FlowFieldManager.get_field("ghost_small")
		FieldLayer.GHOST_MEDIUM: return FlowFieldManager.get_field("ghost_medium")
		FieldLayer.GHOST_LARGE: return FlowFieldManager.get_field("ghost_large")
	return FlowFieldManager.get_field("physical_small")


func _draw() -> void:
	if mode == DisplayMode.OFF:
		return

	var field: FlowField = _get_active_field()
	if not field or field.width == 0 or field.height == 0:
		return

	var w: int = field.width
	var h: int = field.height
	var origin: Vector2 = field.origin
	var cs: float = float(field.cell_size)
	var cs_vec: Vector2 = Vector2(cs, cs)
	var total_cells: int = w * h

	var max_cost: float = 1.0
	if mode == DisplayMode.HEATMAP_AND_ARROWS or mode == DisplayMode.HEATMAP_ONLY:
		for idx: int in range(total_cells):
			var c: float = field.integration_grid[idx]
			if c < float(FlowField.INTEGRATION_MAX) and c > max_cost:
				max_cost = c

	# 1. Draw Heatmaps
	if mode == DisplayMode.HEATMAP_AND_ARROWS or mode == DisplayMode.HEATMAP_ONLY:
		for gy: int in range(h):
			var row: int = gy * w
			var cell_y: float = origin.y + float(gy) * cs
			for gx: int in range(w):
				var idx: int = row + gx
				var cell_x: float = origin.x + float(gx) * cs
				var cell_rect: Rect2 = Rect2(Vector2(cell_x, cell_y), cs_vec)

				var base: float = field.cost_grid[idx]
				if base >= FlowField.COST_IMPASSABLE:
					draw_rect(cell_rect, Color(0.06, 0.06, 0.1, 0.65), true)
				elif base > FlowField.COST_DEFAULT:
					draw_rect(cell_rect, Color(0.9, 0.3, 0.1, 0.45), true)
				else:
					var cost: float = field.integration_grid[idx]
					if cost < float(FlowField.INTEGRATION_MAX):
						var t: float = clampf(cost / maxf(max_cost, 1.0), 0.0, 1.0)
						var col: Color = Color.from_hsv(lerp(0.5, 0.85, t), 0.75, 0.85, 0.35)
						draw_rect(cell_rect, col, true)

	# 2. Draw Vector Arrows
	if mode == DisplayMode.ARROWS or mode == DisplayMode.HEATMAP_AND_ARROWS:
		var lines: PackedVector2Array = []
		var colors: PackedColorArray = []

		var arrow_len: float = cs * 0.42
		var head_size: float = maxf(2.0, cs * 0.15)

		for gy: int in range(h):
			var center_y: float = origin.y + (float(gy) + 0.5) * cs
			for gx: int in range(w):
				var idx: int = gy * w + gx
				var v: Vector2 = field.field[idx]
				if v.length_squared() < 0.0001:
					continue

				var center_x: float = origin.x + (float(gx) + 0.5) * cs
				var center: Vector2 = Vector2(center_x, center_y)

				var start: Vector2 = center - v * (arrow_len * 0.4)
				var end: Vector2 = center + v * (arrow_len * 0.6)
				var perp: Vector2 = Vector2(-v.y, v.x)

				var head_left: Vector2 = end - v * head_size + perp * (head_size * 0.75)
				var head_right: Vector2 = end - v * head_size - perp * (head_size * 0.75)

				var col: Color
				if field.cost_grid[idx] > FlowField.COST_DEFAULT:
					col = Color(1.0, 0.55, 0.2, 0.8) # Tower orange
				else:
					col = Color(0.1, 0.95, 0.9, 0.85) # Open cyan

				# Shaft
				lines.append(start)
				lines.append(end)
				colors.append(col)

				# Head Left
				lines.append(end)
				lines.append(head_left)
				colors.append(col)

				# Head Right
				lines.append(end)
				lines.append(head_right)
				colors.append(col)

		if not lines.is_empty():
			draw_multiline_colors(lines, colors, 1.5)
