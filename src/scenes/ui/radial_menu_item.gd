class_name RadialMenuItem extends Control

signal item_clicked(item: RadialMenuItem)

@export var graphic_offset: Vector2 = Vector2.ZERO:
	set(val):
		graphic_offset = val
		_update_positions()

@export var label_offset: Vector2 = Vector2(0, 36):
	set(val):
		label_offset = val
		_update_positions()

@export var icon_size: Vector2 = Vector2(40, 40):
	set(val):
		icon_size = val
		_update_positions()

var data: Variant = null
var is_highlighted: bool = false
var is_enabled: bool = true

@onready var bg_panel: Panel = $BGPanel
@onready var icon_rect: TextureRect = $IconRect
@onready var title_label: Label = $TitleLabel

func _ready() -> void:
	# Keep pivot centered for clean scaling animations
	pivot_offset = size / 2.0
	resized.connect(func(): pivot_offset = size / 2.0; _update_positions())
	_update_positions()
	
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup(item_data: Dictionary) -> void:
	data = item_data.get("payload", item_data)
	
	var title_text: String = item_data.get("title", item_data.get("name", ""))
	var icon_tex: Texture2D = item_data.get("icon", null)
	is_enabled = item_data.get("enabled", true)
	
	if title_label:
		title_label.text = title_text
	
	if icon_rect and icon_tex:
		icon_rect.texture = icon_tex
		icon_rect.show()
	elif icon_rect:
		# Fallback if no texture provided
		icon_rect.texture = null
	
	modulate = Color.WHITE if is_enabled else Color(0.5, 0.5, 0.5, 0.6)
	_update_positions()

func set_highlighted(highlight: bool) -> void:
	if is_highlighted == highlight:
		return
	is_highlighted = highlight
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if is_highlighted:
		tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.12)
		if bg_panel:
			tween.tween_property(bg_panel, "self_modulate", Color(1.3, 1.3, 0.5, 1.0), 0.12)
	else:
		tween.tween_property(self, "scale", Vector2.ONE, 0.12)
		if bg_panel:
			tween.tween_property(bg_panel, "self_modulate", Color.WHITE, 0.12)

func _update_positions() -> void:
	if not is_inside_tree():
		return
	
	var center = size / 2.0
	
	if icon_rect:
		icon_rect.custom_minimum_size = icon_size
		icon_rect.size = icon_size
		icon_rect.position = center + graphic_offset - (icon_size / 2.0)
	
	if title_label:
		title_label.position = center + label_offset - Vector2(title_label.size.x / 2.0, title_label.size.y / 2.0)

func _on_gui_input(event: InputEvent) -> void:
	if not is_enabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		item_clicked.emit(self)

func _on_mouse_entered() -> void:
	if is_enabled:
		set_highlighted(true)

func _on_mouse_exited() -> void:
	set_highlighted(false)
