class_name WindWallTower extends Tower

@onready var wind_particles: CPUParticles2D = $"Wind Effect"
@onready var gust_particles: CPUParticles2D = $"Gust Effect"

func _ready() -> void:
	super._ready()
	if effect_applier:
		if not effect_applier.applied_effect.is_connected(_on_applied_effect):
			effect_applier.applied_effect.connect(_on_applied_effect)
		if not effect_applier.triggered.is_connected(_on_triggered):
			effect_applier.triggered.connect(_on_triggered)
		if not effect_applier.deactivated.is_connected(_on_deactivated):
			effect_applier.deactivated.connect(_on_deactivated)

func _process(_delta: float) -> void:
	if is_preview or not is_active:
		if wind_particles and wind_particles.emitting:
			wind_particles.emitting = false
		if gust_particles and gust_particles.emitting:
			gust_particles.emitting = false
		return

	if effect_applier:
		var has_receivers: bool = effect_applier._has_valid_overlapping_receivers()
		if wind_particles:
			if has_receivers and not wind_particles.emitting:
				wind_particles.emitting = true
			elif not has_receivers and wind_particles.emitting:
				wind_particles.emitting = false

func _on_applied_effect(_target: Node2D) -> void:
	if wind_particles and not is_preview and is_active:
		wind_particles.emitting = true

func _on_triggered() -> void:
	if gust_particles and not is_preview and is_active:
		gust_particles.restart()
		gust_particles.emitting = true

func _on_deactivated() -> void:
	if wind_particles:
		wind_particles.emitting = false
