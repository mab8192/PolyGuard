class_name Projectile extends Node2D

@onready var polygon: Polygon2D = $Polygon2D
@onready var damage_component: DamageComponent = $DamageComponent
@onready var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

var direction: Vector2 = Vector2.ZERO:
	set(value):
		direction = value.normalized()

var target: Node2D
var speed: float = 0

func _ready() -> void:
	damage_component.hit.connect(_on_hit)
	visible_on_screen_notifier_2d.screen_exited.connect(_on_screen_exit)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if target and is_instance_valid(target):
		direction = global_position.direction_to(target.global_position)

	position += delta * direction * speed

func _on_hit(_target: Node2D) -> void:
	queue_free()

func _on_screen_exit() -> void:
	queue_free()
