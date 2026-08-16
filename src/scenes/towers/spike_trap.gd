class_name SpikeTrap extends Tower

@onready var spike_particles: CPUParticles2D = get_node_or_null("SpikeParticles")

func _ready() -> void:
	super._ready()
	if effect_applier:
		if not effect_applier.triggered.is_connected(_on_triggered):
			effect_applier.triggered.connect(_on_triggered)

func _on_triggered() -> void:
	if spike_particles and not is_preview:
		spike_particles.restart()
		spike_particles.emitting = true
