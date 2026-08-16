class_name CorrosiveVaporTrap extends Tower

@onready var gas_effect: GPUParticles2D = $"Gas Effect"

func _ready() -> void:
	super._ready()
	if effect_applier:
		if not effect_applier.triggered.is_connected(_on_triggered):
			effect_applier.triggered.connect(_on_triggered)
		if not effect_applier.deactivated.is_connected(_on_deactivated):
			effect_applier.deactivated.connect(_on_deactivated)

func _process(_delta: float) -> void:
	if is_preview:
		if gas_effect and gas_effect.emitting:
			gas_effect.emitting = false
		return
	if gas_effect and not gas_effect.emitting:
		gas_effect.emitting = true

func _on_triggered() -> void:
	if gas_effect:
		gas_effect.emitting = true

func _on_deactivated() -> void:
	if gas_effect and not is_preview:
		gas_effect.emitting = true
