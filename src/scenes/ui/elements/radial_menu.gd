class_name RadialMenu extends Control

signal item_selected(item_data: Variant)
signal menu_closed()

@export var radius: float = 280.0
@export var arc_angle_degrees: float = 240.0
@export var center_angle_degrees: float = -90.0 # -90 deg points straight UP
@export var max_items: int = 6
@export var deadzone_radius: float = 50.0
@export var max_select_distance: float = 460.0

@export var graphic_offset: Vector2 = Vector2.ZERO:
	set(val):
		graphic_offset = val
		_apply_item_offsets()

@export var label_offset: Vector2 = Vector2(0, 90):
	set(val):
		label_offset = val
		_apply_item_offsets()

@export var icon_size: Vector2 = Vector2(100, 100):
	set(val):
		icon_size = val
		_apply_item_offsets()

@export var item_scene: PackedScene = preload("res://src/scenes/ui/elements/radial_menu_item.tscn")

var _items: Array[RadialMenuItem] = []
var _hovered_item: RadialMenuItem = null
var _center_pos: Vector2 = Vector2.ZERO
var _is_open: bool = false
var _is_drag_mode: bool = false
var _press_start_pos: Vector2 = Vector2.ZERO

@onready var items_container: Control = $ItemsContainer
@onready var bg_dim: ColorRect = $BGDim

func _ready() -> void:
	top_level = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	hide()
	bg_dim.gui_input.connect(_on_bg_dim_gui_input)

func is_open() -> bool:
	return _is_open

func open(item_data_list: Array, center_global_pos: Vector2) -> void:
	_center_pos = center_global_pos
	_clear_items()
	
	_is_open = true
	_is_drag_mode = false # Start in tap mode; switches to drag mode if mouse moves > 15px
	_press_start_pos = center_global_pos
	_hovered_item = null
	
	show()
	bg_dim.show()
	bg_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	bg_dim.modulate.a = 0.0
	
	var count = min(item_data_list.size(), max_items)
	if count == 0:
		close()
		return
	
	# Spawn item nodes
	for i in range(count):
		var data = item_data_list[i]
		var item_inst: RadialMenuItem = item_scene.instantiate() as RadialMenuItem
		items_container.add_child(item_inst)
		_items.append(item_inst)
		
		item_inst.graphic_offset = graphic_offset
		item_inst.label_offset = label_offset
		item_inst.icon_size = icon_size
		item_inst.setup(data)
		item_inst.item_clicked.connect(_on_item_clicked)
	
	_layout_items_in_arc()
	_animate_open()

func close() -> void:
	if not _is_open:
		return
	_is_open = false
	_set_hovered_item(null)
	bg_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if is_inside_tree() and get_viewport():
		get_viewport().gui_release_focus()
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(bg_dim, "modulate:a", 0.0, 0.1)
	
	for item in _items:
		if is_instance_valid(item):
			tween.tween_property(item, "scale", Vector2.ZERO, 0.1)
			tween.tween_property(item, "modulate:a", 0.0, 0.1)
	
	tween.finished.connect(func():
		_clear_items()
		hide()
		menu_closed.emit()
	)

func _clear_items() -> void:
	for item in _items:
		if is_instance_valid(item):
			item.queue_free()
	_items.clear()
	_hovered_item = null

func _apply_item_offsets() -> void:
	for item in _items:
		if is_instance_valid(item):
			item.graphic_offset = graphic_offset
			item.label_offset = label_offset
			item.icon_size = icon_size

func _layout_items_in_arc() -> void:
	var count = _items.size()
	if count == 0:
		return
	
	var start_angle = center_angle_degrees - (arc_angle_degrees / 2.0)
	var step_angle = 0.0
	if count > 1:
		step_angle = arc_angle_degrees / float(count - 1)
	else:
		start_angle = center_angle_degrees
	
	for i in range(count):
		var angle_deg = start_angle + (i * step_angle)
		var angle_rad = deg_to_rad(angle_deg)
		var target_offset = Vector2(cos(angle_rad), sin(angle_rad)) * radius
		var target_global_pos = _center_pos + target_offset
		
		var item = _items[i]
		item.global_position = _center_pos - (item.size / 2.0)
		item.set_meta("target_global_pos", target_global_pos)

func _animate_open() -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(bg_dim, "modulate:a", 0.25, 0.15)
	
	for i in range(_items.size()):
		var item = _items[i]
		var target_pos: Vector2 = item.get_meta("target_global_pos")
		var target_item_pos = target_pos - (item.size / 2.0)
		
		item.scale = Vector2(0.2, 0.2)
		item.modulate.a = 0.0
		
		var delay = i * 0.02
		tween.tween_property(item, "global_position", target_item_pos, 0.2).set_delay(delay)
		tween.tween_property(item, "scale", Vector2.ONE, 0.2).set_delay(delay)
		tween.tween_property(item, "modulate:a", 1.0, 0.15).set_delay(delay)

func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		var mouse_pos = get_global_mouse_position()
		if mouse_pos.distance_to(_press_start_pos) > 15.0:
			_is_drag_mode = true
		_update_hover_from_position(mouse_pos)
	
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed: # Button released
			if _is_drag_mode:
				get_viewport().set_input_as_handled()
				if _hovered_item and _hovered_item.is_enabled:
					_select_item(_hovered_item)
				else:
					close()

func _update_hover_from_position(pos: Vector2) -> void:
	var dist = pos.distance_to(_center_pos)
	if dist < deadzone_radius or dist > max_select_distance:
		_set_hovered_item(null)
		return
	
	var closest_item: RadialMenuItem = null
	var min_dist: float = INF
	
	for item in _items:
		if not item.is_enabled:
			continue
		var item_center = item.global_position + (item.size / 2.0)
		var item_dist = pos.distance_to(item_center)
		if item_dist < min_dist:
			min_dist = item_dist
			closest_item = item
	
	if min_dist < 150.0:
		_set_hovered_item(closest_item)
	else:
		_set_hovered_item(null)

func _set_hovered_item(item: RadialMenuItem) -> void:
	if _hovered_item == item:
		return
	if is_instance_valid(_hovered_item):
		_hovered_item.set_highlighted(false)
	
	_hovered_item = item
	if is_instance_valid(_hovered_item):
		_hovered_item.set_highlighted(true)

func _on_item_clicked(item: RadialMenuItem) -> void:
	get_viewport().set_input_as_handled()
	if item and item.is_enabled:
		_select_item(item)

func _select_item(item: RadialMenuItem) -> void:
	var payload = item.data
	item_selected.emit(payload)
	close()

func _on_bg_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_viewport().set_input_as_handled()
		close()
