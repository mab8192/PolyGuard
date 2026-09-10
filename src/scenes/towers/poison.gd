extends Tower

@onready var gas_effect: CPUParticles2D = $"Gas Effect"

func _ready() -> void:
	super._ready()
	if gas_effect:
		gas_effect.one_shot = false
		gas_effect.emitting = false
	if effect_applier:
		if not effect_applier.triggered.is_connected(_on_triggered):
			effect_applier.triggered.connect(_on_triggered)
		if not effect_applier.deactivated.is_connected(_on_deactivated):
			effect_applier.deactivated.connect(_on_deactivated)

func _on_triggered() -> void:
	if is_preview:
		return
	if gas_effect:
		gas_effect.emitting = true

func _on_deactivated() -> void:
	if gas_effect:
		gas_effect.emitting = false
