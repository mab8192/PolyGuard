class_name Tower extends StaticBody2D

signal state_changed(is_active: bool)

## Gets assigned by the TowerData type
var data: TowerData

## Visual modulations for active vs inactive/recharging states
const ACTIVE_MODULATE: Color = Color(1.0, 1.0, 1.0, 1.0)
const INACTIVE_MODULATE: Color = Color(0.48, 0.48, 0.54, 0.75)
const SELL_REFUND_RATIO: float = 0.5

## Components that CAN be attached. Most are not required

var _health: HealthComponent
var health: HealthComponent:
	get:
		if _health: return _health
		_health = ComponentUtil.get_component(self, HealthComponent) as HealthComponent
		return _health
		
var _targeting: TargetingComponent
var targeting: TargetingComponent:
	get:
		if _targeting: return _targeting
		_targeting = ComponentUtil.get_component(self, TargetingComponent) as TargetingComponent
		return _targeting

var _attack: AttackComponent
var attack: AttackComponent:
	get:
		if _attack: return _attack
		_attack = ComponentUtil.get_component(self, AttackComponent) as AttackComponent
		return _attack

var _effect_applier: EffectApplierComponent
var effect_applier: EffectApplierComponent:
	get:
		if _effect_applier: return _effect_applier
		_effect_applier = ComponentUtil.get_component(self, EffectApplierComponent) as EffectApplierComponent
		return _effect_applier

var is_range_visible: bool = false:
	set(value):
		is_range_visible = value
		if targeting:
			targeting.is_range_visible = value
		if effect_applier:
			effect_applier.is_range_visible = value

var is_solid: bool = true:
	set(value):
		is_solid = value
		_update_solid_state() 

var is_active: bool = true:
	set(value):
		var changed = (is_active != value)
		is_active = value
		_update_active_state(changed and is_inside_tree())
		state_changed.emit(value)

var is_preview: bool = false:
	set(value):
		is_preview = value
		_update_preview_state()

var is_selected: bool = false:
	set(value):
		is_selected = value
		_update_selected_state()

func get_sell_value() -> int:
	if data:
		return maxi(1, int(data.cost * SELL_REFUND_RATIO))
	return 0

func activate() -> void:
	is_active = true

func deactivate() -> void:
	is_active = false

func set_active(val: bool) -> void:
	is_active = val

func _ready() -> void:
	if not data:
		push_error("Missing TowerData! %s" % get_path())
	
	if not is_in_group("towers"):
		add_to_group("towers")

	_update_solid_state()
	_update_preview_state()
	_update_active_state()

	if health:
		health.died.connect(_on_died)

	if effect_applier:
		effect_applier.cooldown_started.connect(_on_applier_cooldown_started)
		effect_applier.cooldown_finished.connect(_on_applier_cooldown_finished)

func _on_died() -> void:
	queue_free()
	SignalBus.tower_destroyed.emit()

func _process(_delta: float) -> void:
	# Preview or inactive towers do not process attacks
	if is_preview or not is_active:
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
	if is_preview:
		modulate.a = 0.5
		is_range_visible = true
	else:
		_update_active_state(false)
		is_range_visible = is_selected
	
	# Enable/disable components where applicable
	if effect_applier:
		if is_preview or not is_active:
			effect_applier.disable()
		else:
			effect_applier.enable()

func _update_active_state(animate: bool = false) -> void:
	if is_preview:
		return
	
	_set_visual_dimmed(!is_active, animate)
	
	if effect_applier:
		if is_active:
			effect_applier.enable()
		else:
			effect_applier.disable()

func _on_applier_cooldown_started() -> void:
	if not is_preview and is_active:
		_set_visual_dimmed(true, true)

func _on_applier_cooldown_finished() -> void:
	if not is_preview and is_active:
		_set_visual_dimmed(false, true)

func _set_visual_dimmed(dimmed: bool, animate: bool = false) -> void:
	if is_preview or not is_inside_tree():
		return
	var target_col = INACTIVE_MODULATE if dimmed else ACTIVE_MODULATE
	if animate:
		var tween = create_tween()
		tween.tween_property(self, "modulate", target_col, 0.3)
	else:
		modulate = target_col

func _update_selected_state() -> void:
	if not is_preview:
		is_range_visible = is_selected

func _set_controls_mouse_filter(node: Node, ignore: bool) -> void:
	var filter := Control.MOUSE_FILTER_IGNORE if ignore else Control.MOUSE_FILTER_STOP
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = filter
		_set_controls_mouse_filter(child, ignore)
