class_name Tower extends StaticBody2D

@export_group("Basic Info")
@export var tower_name: String = "Tower"
@export var cost: int = 50

@export_group("Components")
@export var health: HealthComponent
@export var hitbox: HitboxComponent
@export var targeting: TargetingComponent ## Can be null

var is_preview: bool = false:
	set(value):
		is_preview = value
		_update_preview_state()

func _ready() -> void:
	_update_preview_state()

func _process(_delta: float) -> void:
	# Preview towers do not process anything
	if is_preview: return
	
	if targeting and targeting.target:
		print("Targeting! ", targeting.target.global_position)

func _update_preview_state() -> void:
	# Disable collision shapes while previewing
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = is_preview
	
	# Semi-transparent ghost look when previewing
	modulate.a = 0.5 if is_preview else 1.0
