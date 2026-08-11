class_name Tower extends StaticBody2D

## Gets assigned by the TowerData type
var data: TowerData

## Components that CAN be attached. Most are not required

var health: HealthComponent
var targeting: TargetingComponent
var attack: AttackComponent
var effect_applier: EffectApplierComponent

var is_solid: bool = true:
	set(value):
		is_solid = value
		_update_solid_state() 

var is_preview: bool = false:
	set(value):
		is_preview = value
		_update_preview_state()

func _ready() -> void:
	health = ComponentUtil.get_component(self, HealthComponent) as HealthComponent
	targeting = ComponentUtil.get_component(self, TargetingComponent) as TargetingComponent
	attack = ComponentUtil.get_component(self, AttackComponent) as AttackComponent
	effect_applier = ComponentUtil.get_component(self, EffectApplierComponent) as EffectApplierComponent

	if not data:
		push_error("Missing TowerData! %s" % get_path())
	
	_update_solid_state()
	_update_preview_state()

func _process(_delta: float) -> void:
	# Preview towers do not process anything
	if is_preview:
		return
	
	if targeting and attack:
		attack.attack_targets(targeting.get_targets())

func _update_solid_state() -> void:
	if is_solid:
		collision_layer = 2
	else:
		collision_layer = 0

func _update_preview_state() -> void:
	# Disable collision shapes while previewing
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.disabled = is_preview
	
	# Let placement input pass through preview visuals to the stage
	_set_controls_mouse_filter(self, is_preview)
	
	# Semi-transparent ghost look when previewing
	modulate.a = 0.5 if is_preview else 1.0

func _set_controls_mouse_filter(node: Node, ignore: bool) -> void:
	var filter := Control.MOUSE_FILTER_IGNORE if ignore else Control.MOUSE_FILTER_STOP
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = filter
		_set_controls_mouse_filter(child, ignore)
