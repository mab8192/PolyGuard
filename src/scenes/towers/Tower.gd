class_name Tower extends StaticBody2D

## Gets assigned by the TowerData type
var data: TowerData

## Components that CAN be attached. Most are not required

var health: HealthComponent:
	get:
		return ComponentUtil.get_component(self, HealthComponent) as HealthComponent
		
var targeting: TargetingComponent: ## Can be null
	get:
		return ComponentUtil.get_component(self, TargetingComponent) as TargetingComponent
		
var attack: AttackComponent: ## Can be null
	get:
		return ComponentUtil.get_component(self, AttackComponent) as AttackComponent
		
var effect_applier: EffectApplierComponent: ## Can be null
	get:
		return ComponentUtil.get_component(self, EffectApplierComponent) as EffectApplierComponent

var is_solid: bool = true:
	set(value):
		is_solid = value
		_update_solid_state() 

var is_preview: bool = false:
	set(value):
		is_preview = value
		_update_preview_state()

func _ready() -> void:
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
	set_collision_layer_value(1, is_solid)
	set_collision_mask_value(1, is_solid)

func _update_preview_state() -> void:
	# Disable collision shapes while previewing
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.disabled = is_preview
	
	# Semi-transparent ghost look when previewing
	modulate.a = 0.5 if is_preview else 1.0
