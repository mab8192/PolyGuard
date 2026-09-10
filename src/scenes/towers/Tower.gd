class_name Tower extends StaticBody2D

signal state_changed(is_active: bool)

## Gets assigned by the TowerData type
@export var data: TowerData

## Visual modulations for active vs inactive/recharging states
const ACTIVE_MODULATE: Color = Color(1.0, 1.0, 1.0, 1.0)
const INACTIVE_MODULATE: Color = Color(0.48, 0.48, 0.54, 0.75)
const SELL_REFUND_RATIO: float = 0.75

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

func get_repair_cost() -> int:
	if not health or not health.data or health.data.max_health <= 0 or not data:
		return 0
	var missing = health.data.max_health - health.get_health()
	if missing <= 0.001:
		return 0
	var ratio = missing / health.data.max_health
	return maxi(1, int(ceil(data.cost * 0.5 * ratio)))

func repair() -> bool:
	if not health or not health.data or not data:
		return false
	var missing = health.data.max_health - health.get_health()
	if missing <= 0.001:
		return false
	health.heal(missing)
	return true

func get_stats() -> Dictionary:
	if not data:
		return {}
	var current_level: int = 1
	var active_choice: String = ""
	var t_id = Registry.get_tower_id(data)
	if not t_id.is_empty() and SaveManager.is_tower_unlocked(t_id):
		current_level = SaveManager.get_tower_level(t_id)
		active_choice = SaveManager.get_tower_choice(t_id)
		
	var base_stats = data.get_stats(current_level, active_choice)
	
	if health:
		base_stats["current_health"] = health.get_health()
		base_stats["max_health"] = health.get_max_health()
	if targeting:
		base_stats["strategy_name"] = targeting.get_strategy_name()
		base_stats["strategy_desc"] = targeting.get_strategy_description()
		
	var lines: Array[String] = []
	if base_stats.get("has_attack", false):
		var cd_str = "%.2fs" % base_stats["cooldown"] if base_stats["cooldown"] > 0 else "Continuous"
		lines.append("DMG: %.0f (%s)  •  SPD: %s  •  DPS: %.1f" % [base_stats["damage"], base_stats["damage_type_str"], cd_str, base_stats["dps"]])
	if health and health.data:
		lines.append("HEALTH: %d / %d" % [int(health.get_health()), int(health.data.max_health)])
	if targeting and targeting.data:
		lines.append("TARGETING: %s" % [targeting.get_strategy_name()])
	if base_stats.get("max_targets", 1) > 1:
		lines.append("TARGETS: %d Enemies" % base_stats["max_targets"])
	if base_stats.get("targets_ghosts", false):
		lines.append("GHOST DETECTION: ENABLED")
	if base_stats.get("blocks_ghosts", false):
		lines.append("GHOST BARRIER: ACTIVE")
	if data.tower_id == "soul_lantern":
		lines.append("TRAIT: Damage Ramps Up While Focused (+35%/s)")
		
	base_stats["runtime_lines"] = lines
	return base_stats

func activate() -> void:
	is_active = true

func deactivate() -> void:
	is_active = false

func set_active(val: bool) -> void:
	is_active = val

func _enter_tree() -> void:
	if not data:
		var scene_name := scene_file_path.get_file().get_basename()
		var tower_data := Registry.get_tower_data(scene_name)
		if tower_data:
			var level := SaveManager.get_tower_level(scene_name)
			var choice := SaveManager.get_tower_choice(scene_name)
			data = tower_data.get_scaled_copy(level, choice)
			data.apply_to(self)
		else:
			push_error("No TowerData!")

func _ready() -> void:
	if not data:
		push_error("No TowerData!")
		return
	
	if not is_in_group("towers"):
		add_to_group("towers")

	_update_solid_state()
	_update_preview_state()
	_update_active_state()

	if health:
		health.died.connect(_on_died)
		health.took_damage.connect(_on_hit)

	if effect_applier:
		effect_applier.cooldown_started.connect(_on_applier_cooldown_started)
		effect_applier.cooldown_finished.connect(_on_applier_cooldown_finished)

func _on_died() -> void:
	queue_free()
	SignalBus.tower_destroyed.emit()
	AudioManager.play_random_sfx(AudioManager.sfx_enemy_died)
	if GameManager.current_stage:
		GameManager.current_stage.effect_manager.explosion(global_position)

func _on_hit(_dmg: float) -> void:
	AudioManager.play_random_sfx(AudioManager.sfx_tower_hit)

func _physics_process(_delta: float) -> void:
	_process_attacks()

func _process_attacks() -> void:
	# Preview or inactive towers do not process attacks
	if is_preview or not is_active:
		return

	if targeting and attack:
		var targets := targeting.get_targets()
		if not targets.is_empty():
			attack.attack_targets(targets)

func _update_solid_state() -> void:
	if data:
		collision_layer = data.collision_layer
		collision_mask = data.collision_mask
	elif collision_layer == 0:
		collision_layer = 2

func get_default_z_index() -> int:
	if data and data.requires_wall_behind:
		return 2
	return 0

func _update_preview_state() -> void:
	# Disable collision shapes while previewing
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.disabled = is_preview
		elif is_preview and (child is CPUParticles2D or child is GPUParticles2D):
			child.emitting = false
	
	# Let placement input pass through preview visuals to the stage
	_set_controls_mouse_filter(self, is_preview)
	
	# Semi-transparent ghost look when previewing
	if is_preview:
		z_index = 15
		modulate.a = 0.5
		is_range_visible = true
	else:
		z_index = get_default_z_index()
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

	if not is_active:
		for child in get_children():
			if child is CPUParticles2D or child is GPUParticles2D:
				child.emitting = false
	
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
