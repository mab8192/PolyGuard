class_name CarouselItem extends Control

signal pressed(payload: Variant)

@onready var button: TextureButton = %TextureButton
@onready var label: Label = %Label

var texture: Texture2D
var text: String
var payload: Variant

func _ready() -> void:
	button.texture_normal = texture
	label.text = text

	button.pressed.connect(func(): pressed.emit(payload))
