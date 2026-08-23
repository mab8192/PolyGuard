class_name WindWallTower extends Tower

@onready var gust_particles: CPUParticles2D = $"Gust Effect"

func _ready() -> void:
	super._ready()
	if effect_applier:
		if not effect_applier.triggered.is_connected(_on_triggered):
			effect_applier.triggered.connect(_on_triggered)
		if not effect_applier.deactivated.is_connected(_on_deactivated):
			effect_applier.deactivated.connect(_on_deactivated)

func _process(_delta: float) -> void:
	if is_preview or not is_active:

		if gust_particles and gust_particles.emitting:
			gust_particles.emitting = false
		return


func _on_triggered() -> void:
	if gust_particles and not is_preview and is_active:
		gust_particles.restart()
		gust_particles.emitting = true

func _on_deactivated() -> void:
	if gust_particles and not is_preview and is_active:
		gust_particles.emitting = false
