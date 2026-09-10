extends Tower

@onready var freeze_effect: CPUParticles2D = $"Freeze Effect"

func _ready() -> void:
	super._ready()
	if effect_applier:
		if not effect_applier.triggered.is_connected(_on_triggered):
			effect_applier.triggered.connect(_on_triggered)

func _on_triggered() -> void:
	freeze_effect.emitting = true
