class_name FlamethrowerTower extends Tower

@onready var flame_effect: GPUParticles2D = $"Flame Effect"

func _ready() -> void:
	super._ready()
	if effect_applier:
		if not effect_applier.triggered.is_connected(_on_triggered):
			effect_applier.triggered.connect(_on_triggered)
		if not effect_applier.deactivated.is_connected(_on_deactivated):
			effect_applier.deactivated.connect(_on_deactivated)

func _on_triggered() -> void:
	if flame_effect and not is_preview:
		flame_effect.emitting = true

func _on_deactivated() -> void:
	if flame_effect:
		flame_effect.emitting = false
