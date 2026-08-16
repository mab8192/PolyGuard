class_name Card extends Control

signal pressed()
signal card_clicked(card: Card)

@export var image: Texture2D:
	set(val):
		image = val
		if is_inside_tree() and texture_rect:
			texture_rect.texture = val

@export var text: String = "":
	set(val):
		text = val
		if is_inside_tree() and label:
			label.text = val

@export var badge_text: String = "":
	set(val):
		badge_text = val
		if is_inside_tree() and badge_label and badge_container:
			badge_label.text = val
			badge_container.visible = not val.is_empty()

@export var is_selected: bool = false:
	set(val):
		is_selected = val
		if is_inside_tree() and selection_ring:
			selection_ring.visible = val

@export var is_locked: bool = false:
	set(val):
		is_locked = val
		_update_locked_state()

@export var is_unavailable: bool = false:
	set(val):
		is_unavailable = val
		_update_locked_state()

var data: Variant = null

@onready var bg_panel: Panel = %BGPanel
@onready var texture_rect: TextureRect = %TextureRect
@onready var label: Label = %Label
@onready var badge_container: MarginContainer = %BadgeContainer
@onready var badge_panel: PanelContainer = %BadgePanel
@onready var badge_label: Label = %BadgeLabel
@onready var selection_ring: Panel = %SelectionRing
@onready var click_button: Button = %ClickButton

func _ready() -> void:
	if image:
		texture_rect.texture = image
	if not text.is_empty():
		label.text = text
	if badge_label and not badge_text.is_empty():
		badge_label.text = badge_text
		badge_container.visible = true
	elif badge_container:
		badge_container.visible = false
		
	if selection_ring:
		selection_ring.visible = is_selected
		
	_update_locked_state()
	click_button.pressed.connect(_on_pressed)
	gui_input.connect(_on_gui_input)

func setup(p_image: Texture2D, p_text: String, p_badge: String = "", p_data: Variant = null, p_locked: bool = false, p_unavailable: bool = false) -> void:
	image = p_image
	text = p_text
	badge_text = p_badge
	data = p_data
	is_locked = p_locked
	is_unavailable = p_unavailable
	if is_inside_tree():
		if texture_rect:
			texture_rect.texture = image
		if label:
			label.text = text
		if badge_container and badge_label:
			badge_label.text = badge_text
			badge_container.visible = not badge_text.is_empty()
		_update_locked_state()

func set_card_selected(selected: bool) -> void:
	is_selected = selected
	if selection_ring:
		selection_ring.visible = selected

func set_card_locked(locked: bool) -> void:
	is_locked = locked

func set_card_unavailable(unavailable: bool) -> void:
	is_unavailable = unavailable

func _update_locked_state() -> void:
	if not is_inside_tree():
		return
	if is_unavailable:
		if texture_rect:
			texture_rect.modulate = Color(0.35, 0.38, 0.45, 0.45)
		if label:
			label.modulate = Color(0.45, 0.5, 0.6, 0.65)
		if bg_panel:
			bg_panel.self_modulate = Color(0.42, 0.45, 0.52, 0.6)
		if badge_panel:
			badge_panel.theme_type_variation = &"UnavailableBadge"
	elif is_locked:
		if texture_rect:
			texture_rect.modulate = Color(0.4, 0.45, 0.52, 0.55)
		if label:
			label.modulate = Color(0.5, 0.55, 0.62, 0.7)
		if bg_panel:
			bg_panel.self_modulate = Color(0.6, 0.65, 0.72, 0.75)
		if badge_panel:
			badge_panel.theme_type_variation = &"LockedBadge"
	else:
		if texture_rect:
			texture_rect.modulate = Color.WHITE
		if label:
			label.modulate = Color.WHITE
		if bg_panel:
			bg_panel.self_modulate = Color.WHITE
		if badge_panel:
			badge_panel.theme_type_variation = &"CostBadge"

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			_on_pressed()

func _on_pressed() -> void:
	if DragScrollContainer.is_globally_dragging:
		return
	pressed.emit()
	card_clicked.emit(self)
