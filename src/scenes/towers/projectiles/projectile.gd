class_name Projectile extends Node2D

@onready var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

var damage_component: DamageComponent

var direction: Vector2 = Vector2.ZERO:
	set(value):
		direction = value.normalized()
		if direction != Vector2.ZERO:
			rotation = direction.angle()

var target: Node2D:
	set(value):
		target = value
		if is_instance_valid(target):
			direction = global_position.direction_to(target.global_position)

var projectile_speed: float = 0.0
var follow_target: bool = true

var _secs_alive: float = 0
const MAX_LIFETIME: float = 10
const SWEEP_MIN_STEP: float = 4.0 ## Steps shorter than the smallest enemy hitbox can't jump past it between physics frames

var _hitbox: CollisionShape2D = null
var _sweep_query: PhysicsShapeQueryParameters2D = null

func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if not damage_component:
		damage_component = ComponentUtil.get_component(self, DamageComponent) as DamageComponent
	if damage_component:
		damage_component.hit.connect(_on_hit)
		_hitbox = damage_component.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if visible_on_screen_notifier_2d:
		visible_on_screen_notifier_2d.screen_exited.connect(_on_screen_exit)

func _physics_process(delta: float) -> void:
	if follow_target and is_instance_valid(target):
		direction = global_position.direction_to(target.global_position)

	var motion: Vector2 = delta * direction * projectile_speed
	if _sweep_for_hit(motion):
		return
	global_position += motion
	_secs_alive += delta
	if _secs_alive >= MAX_LIFETIME:
		queue_free()

## Fast shots can jump past small enemies between physics frames, so cast the hitbox along this frame's motion first
func _sweep_for_hit(motion: Vector2) -> bool:
	if not _hitbox or not _hitbox.shape or damage_component.piercing:
		return false
	if motion.length_squared() < SWEEP_MIN_STEP * SWEEP_MIN_STEP:
		return false
	if not _sweep_query:
		_sweep_query = PhysicsShapeQueryParameters2D.new()
		_sweep_query.shape = _hitbox.shape
	_sweep_query.collision_mask = damage_component.collision_mask
	_sweep_query.transform = _hitbox.global_transform
	_sweep_query.motion = motion

	var space := get_world_2d().direct_space_state
	var fractions := space.cast_motion(_sweep_query)
	if fractions.size() < 2 or fractions[1] >= 1.0:
		return false

	var contact_offset: Vector2 = motion * fractions[1]
	_sweep_query.transform = _sweep_query.transform.translated(contact_offset)
	_sweep_query.motion = Vector2.ZERO
	var hits := space.intersect_shape(_sweep_query, 1)
	var body: Node2D = hits[0].get("collider") as Node2D if not hits.is_empty() else null
	if not body:
		return false
	global_position += contact_offset
	damage_component._on_body_entered(body)
	return true

func _on_hit(_target: Node2D) -> void:
	queue_free()

func _on_screen_exit() -> void:
	# The camera can be zoomed in, so leaving the screen doesn't mean leaving the playfield.
	var stage := GameManager.current_stage
	if stage and stage.get_map_pixel_rect().grow(64.0).has_point(global_position):
		return
	queue_free()
