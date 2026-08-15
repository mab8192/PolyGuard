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
		
	click_button.pressed.connect(_on_pressed)

func setup(p_image: Texture2D, p_text: String, p_badge: String = "", p_data: Variant = null) -> void:
	image = p_image
	text = p_text
	badge_text = p_badge
	data = p_data
	if is_inside_tree():
		if texture_rect:
			texture_rect.texture = image
		if label:
			label.text = text
		if badge_container and badge_label:
			badge_label.text = badge_text
			badge_container.visible = not badge_text.is_empty()

func set_card_selected(selected: bool) -> void:
	is_selected = selected
	if selection_ring:
		selection_ring.visible = selected

func _on_pressed() -> void:
	pressed.emit()
	card_clicked.emit(self)
