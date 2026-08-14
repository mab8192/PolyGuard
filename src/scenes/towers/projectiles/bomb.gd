extends Projectile


func explode() -> void:
	# Get all targets in explosion radius and deal damage to them, weakened as you get further away
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	damage_component.hit.connect(explode)
