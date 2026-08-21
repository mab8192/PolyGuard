extends Tower

@onready var freeze_effect: GPUParticles2D = $"Freeze Effect"

func _ready() -> void:
	super._ready()
	if effect_applier:
		if not effect_applier.triggered.is_connected(_on_triggered):
			effect_applier.triggered.connect(_on_triggered)

func _process(_delta: float) -> void:
	if is_preview:
		if freeze_effect and freeze_effect.emitting:
			freeze_effect.emitting = false
		return

func _on_triggered() -> void:
	freeze_effect.emitting = true
