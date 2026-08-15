class_name RadialMenuItem extends Control

signal item_clicked(item: RadialMenuItem)

@export var graphic_offset: Vector2 = Vector2.ZERO:
	set(val):
		graphic_offset = val
		_update_positions()

@export var label_offset: Vector2 = Vector2(0, 90):
	set(val):
		label_offset = val
		_update_positions()

@export var cost_offset: Vector2 = Vector2(0, 60):
	set(val):
		cost_offset = val
		_update_positions()

@export var icon_size: Vector2 = Vector2(100, 100):
	set(val):
		icon_size = val
		_update_positions()

var data: Variant = null
var is_highlighted: bool = false
var is_enabled: bool = true

@onready var bg_panel: Panel = $BGPanel
@onready var icon_rect: TextureRect = $IconRect
@onready var cost_badge: Panel = $CostBadge
@onready var cost_label: Label = $CostBadge/CostLabel
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
	
	var cost: int = item_data.get("cost", -1)
	if cost >= 0 and cost_label and cost_badge:
		cost_label.text = "%d" % cost
		cost_label.modulate = Color(0.22, 0.92, 1.0, 1.0) if is_enabled else Color(1.0, 0.45, 0.45)
		cost_badge.show()
	elif cost_badge:
		cost_badge.hide()
	
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
			tween.tween_property(bg_panel, "self_modulate", Color(0.4, 1.2, 1.4, 1.0), 0.12)
	else:
		tween.tween_property(self, "scale", Vector2.ONE, 0.12)
		if bg_panel:
			tween.tween_property(bg_panel, "self_modulate", Color.WHITE, 0.12)

func _update_positions() -> void:
	if not is_inside_tree():
		return
	
	if icon_rect:
		icon_rect.custom_minimum_size = icon_size
		icon_rect.offset_left = graphic_offset.x - (icon_size.x / 2.0)
		icon_rect.offset_right = graphic_offset.x + (icon_size.x / 2.0)
		icon_rect.offset_top = graphic_offset.y - (icon_size.y / 2.0)
		icon_rect.offset_bottom = graphic_offset.y + (icon_size.y / 2.0)
	
	if title_label:
		var half_lbl_w = max(title_label.size.x / 2.0, 50.0)
		var half_lbl_h = max(title_label.size.y / 2.0, 11.5)
		title_label.offset_left = label_offset.x - half_lbl_w
		title_label.offset_right = label_offset.x + half_lbl_w
		title_label.offset_top = label_offset.y - half_lbl_h
		title_label.offset_bottom = label_offset.y + half_lbl_h
	
	if cost_badge:
		var badge_width := 80.0
		var badge_height := 34.0
		cost_badge.offset_left = cost_offset.x - (badge_width / 2.0)
		cost_badge.offset_right = cost_offset.x + (badge_width / 2.0)
		cost_badge.offset_top = cost_offset.y - (badge_height / 2.0)
		cost_badge.offset_bottom = cost_offset.y + (badge_height / 2.0)

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
