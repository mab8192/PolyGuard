extends Tower

@onready var gas_effect: GPUParticles2D = $"Gas Effect"

func _ready() -> void:
	effect_applier.applied_effect.connect(_on_effect_applied)
	
func _on_effect_applied() -> void:
	gas_effect.emitting = true
