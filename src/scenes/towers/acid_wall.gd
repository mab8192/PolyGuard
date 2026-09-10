class_name AcidWallTower extends Tower

@onready var acid_effect: CPUParticles2D = $"Acid Effect"

func _ready() -> void:
	super._ready()
	if effect_applier:
		if not effect_applier.triggered.is_connected(_on_triggered):
			effect_applier.triggered.connect(_on_triggered)
		if not effect_applier.deactivated.is_connected(_on_deactivated):
			effect_applier.deactivated.connect(_on_deactivated)

func _on_triggered() -> void:
	if acid_effect and not is_preview:
		acid_effect.emitting = true

func _on_deactivated() -> void:
	if acid_effect:
		acid_effect.emitting = false
