class_name Projectile extends Node2D

@onready var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

var damage_component: DamageComponent

var direction: Vector2 = Vector2.ZERO:
	set(value):
		direction = value.normalized()

var target: Node2D:
	set(value):
		target = value
		if is_instance_valid(target):
			direction = global_position.direction_to(target.global_position)

var projectile_speed: float = 0.0
var follow_target: bool = true

var _secs_alive: float = 0
const MAX_LIFETIME: float = 10

func _ready() -> void:
	if not damage_component:
		damage_component = ComponentUtil.get_component(self, DamageComponent) as DamageComponent
	if damage_component:
		damage_component.hit.connect(_on_hit)
	if visible_on_screen_notifier_2d:
		visible_on_screen_notifier_2d.screen_exited.connect(_on_screen_exit)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if follow_target and target and is_instance_valid(target):
		direction = global_position.direction_to(target.global_position)

	global_position += delta * direction * projectile_speed
	_secs_alive += delta
	if _secs_alive >= MAX_LIFETIME:
		queue_free()

func _on_hit(_target: Node2D) -> void:
	queue_free()

func _on_screen_exit() -> void:
	queue_free()
