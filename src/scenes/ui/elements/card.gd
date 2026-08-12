class_name Card extends MarginContainer

signal pressed()

@export var image: Texture2D
@export var text: String
@export var margin: int = 8

@onready var texture_rect: TextureRect = %TextureRect
@onready var label: Label = %Label
@onready var button: Button = %Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	texture_rect.texture = image
	label.text = text
	
	add_theme_constant_override("margin_top", margin)
	add_theme_constant_override("margin_left", margin)
	add_theme_constant_override("margin_bottom", margin)
	add_theme_constant_override("margin_right", margin)

	button.pressed.connect(_on_pressed)

func _on_pressed() -> void:
	pressed.emit()
