class_name Tower extends StaticBody2D

@export var tower_name: String = "Tower"
@export var cost: float = 50.0
@export var size: Vector2i = Vector2i(1, 1)

var is_preview: bool = false:
	set(value):
		is_preview = value
		_update_preview_state()

func _ready() -> void:
	_update_preview_state()

func _update_preview_state() -> void:
	# Disable collision shapes while previewing
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = is_preview
	
	# Semi-transparent ghost look when previewing
	modulate.a = 0.5 if is_preview else 1.0
