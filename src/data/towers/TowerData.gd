class_name TowerData extends Resource

@export_category("Info")
@export var tower_id: String = "" ## Unique identifier matching Registry.TOWERS
@export var display_name: String = "" ## The name to display for this tower in-game
@export var icon: Texture2D ## The icon to display when building and in the loadout scene
@export var scene: PackedScene ## The scene for this tower data
@export_multiline var description: String = "" ## The description to show in-game

@export_category("Meta Progression")
@export var unlock_cost: int = 0 ## 0 = starter tower, >0 = Credit cost to unlock
@export var required_stage_id: String = "" ## Stage ID (e.g. stage_01) required to be cleared before this tower becomes available to unlock
@export var max_level: int = 3 ## Maximum upgrade level
@export var choices: Array[TowerChoiceUpgrade] = [] ## Branching / Choice specializations

@export_category("Level Upgrade Scaling")
@export var damage_upgrade_per_level: float = 0.1 ## Damage increase per level above Lv 1
@export var cooldown_reduction_per_level: float = 0.05 ## Attack cooldown reduction per level
@export var health_upgrade_per_level: float = 0.1 ## Health increase per level above Lv 1
@export var min_cooldown_multiplier: float = 0.35 ## Lower limit clamp for attack cooldown multiplier

@export_category("Stats")
@export var cost: int = 250 ## How much energy this tower costs to place

@export_category("Placement")
@export var can_rotate: bool = true ## Whether this tower/trap can be rotated during placement
@export var rotation_step_degrees: float = 90.0 ## Rotation increment angle in degrees (e.g., 90 for square/rect, 45 for cone/directional)
@export var requires_wall_behind: bool = false ## Whether this tower/trap can only be placed with a solid wall or tower directly behind it

@export_category("Physics Collision")
@export_flags_2d_physics var collision_layer: int = 2 ## Physics layer this tower occupies (0 = non-solid trap, 2 = physical tower, 18 = blocks ghosts too)
@export_flags_2d_physics var collision_mask: int = 0 ## Physics mask for tower collision

@export_category("Components")
@export var health: HealthData
@export var attack: AttackData
@export var targeting: TargetingData
@export var effect_applier: EffectApplierData

func is_available() -> bool:
	if required_stage_id.is_empty():
		return true
	return SaveManager.is_stage_completed(required_stage_id)

func get_requirement_description() -> String:
	if required_stage_id.is_empty():
		return ""
	var stage = Registry.get_stage_data(required_stage_id)
	if stage and not stage.stage_name.is_empty():
		return "Requires %s Clear" % stage.stage_name
	return "Requires Stage Clear"

func get_upgrade_cost(target_level: int) -> int:
	return 300 * (target_level - 1)

func get_placement_cost(choice_id: String = "") -> int:
	var choice = get_choice(choice_id)
	return maxi(0, cost - choice.cost_reduction) if choice else cost

func get_choice(choice_id: String) -> TowerChoiceUpgrade:
	for c in choices:
		if c and c.id == choice_id:
			return c
	return null

func get_display_icon(choice_id: String = "") -> Texture2D:
	var choice = get_choice(choice_id)
	if choice and choice.icon:
		return choice.icon
	return icon

func duplicate_data() -> TowerData:
	var copy: TowerData = self.duplicate(true)
	if health:
		copy.health = health.duplicate(true)
	if attack:
		copy.attack = attack.duplicate(true)
	if targeting:
		copy.targeting = targeting.duplicate(true)
	if effect_applier:
		copy.effect_applier = effect_applier.duplicate(true)
		var dup_effects: Array[EffectData] = []
		for eff in copy.effect_applier.effects:
			if eff:
				dup_effects.append(eff.duplicate(true))
		copy.effect_applier.effects = dup_effects
	return copy

func get_scaled_copy(level: int = 1, choice_id: String = "") -> TowerData:
	var copy: TowerData = duplicate_data()
	
	var lvl = clampi(level, 1, max_level)
	var strength_mult = 1.0 + (lvl - 1) * damage_upgrade_per_level
	var cd_mult = maxf(min_cooldown_multiplier, 1.0 - (lvl - 1) * cooldown_reduction_per_level)
	var hp_mult = 1.0 + (lvl - 1) * health_upgrade_per_level
	
	var choice = copy.get_choice(choice_id)
	if choice:
		if choice.has_damage_type_override and copy.attack:
			copy.attack.damage_type = choice.damage_type_override
		if choice.has_targeting_mask_override:
			if copy.targeting:
				copy.targeting.targeting_mask = choice.targeting_mask_override
			if copy.effect_applier:
				copy.effect_applier.targeting_mask = choice.targeting_mask_override
		if choice.extra_targets != 0 and copy.effect_applier:
			if copy.effect_applier.max_targets > 0:
				copy.effect_applier.max_targets = maxi(1, copy.effect_applier.max_targets + choice.extra_targets)
			else:
				push_error("Attempted to increase max targets on a trap that has no limit!")
		copy.cost = get_placement_cost(choice_id)
		if choice.has_collision_layer_override:
			copy.collision_layer = choice.collision_layer_override
		if choice.has_collision_mask_override:
			copy.collision_mask = choice.collision_mask_override
		if choice.icon:
			copy.icon = choice.icon
		if not choice.added_effects.is_empty() and copy.effect_applier:
			for eff in choice.added_effects:
				if eff:
					copy.effect_applier.effects.append(eff.duplicate(true))
		strength_mult *= choice.strength_multiplier
		cd_mult *= choice.cooldown_multiplier
		hp_mult *= choice.health_multiplier
		if copy.targeting:
			copy.targeting.max_targets += choice.extra_targets
		if copy.attack and not is_equal_approx(choice.projectile_speed_multiplier, 1.0):
			copy.attack.projectile_speed *= choice.projectile_speed_multiplier
	
	if copy.attack:
		copy.attack.damage *= strength_mult
		copy.attack.cooldown *= cd_mult
	
	if copy.health:
		copy.health.max_health *= hp_mult
	
	if copy.effect_applier:
		copy.effect_applier.cooldown *= cd_mult
		for eff in copy.effect_applier.effects:
			if "damage" in eff:
				eff.damage *= strength_mult
			if "initial_damage" in eff:
				eff.initial_damage *= strength_mult
			if "damage_per_second" in eff:
				eff.damage_per_second *= strength_mult
			if "armor_reduction" in eff and eff.armor_reduction > 0.0:
				eff.armor_reduction *= strength_mult
			if "magic_resistance_reduction" in eff and eff.magic_resistance_reduction > 0.0:
				eff.magic_resistance_reduction *= strength_mult
			if "displace_distance" in eff:
				eff.displace_distance *= strength_mult
			if "push_force" in eff:
				eff.push_force *= strength_mult
			if "impulse_force" in eff:
				eff.impulse_force *= strength_mult
			if "speed_multiplier" in eff and eff.speed_multiplier < 1.0:
				var slow_pct = (1.0 - eff.speed_multiplier) * strength_mult
				eff.speed_multiplier = clampf(1.0 - slow_pct, 0.0, 0.95)
			if "acceleration_multiplier" in eff and eff.acceleration_multiplier < 1.0:
				eff.acceleration_multiplier = clampf(eff.acceleration_multiplier / maxf(strength_mult, 0.01), 0.01, 1.0)
			if "duration" in eff and eff.duration != INF:
				eff.duration *= strength_mult

	return copy

func get_stat_summary(level: int = 1, choice_id: String = "") -> Dictionary:
	var scaled = get_scaled_copy(level, choice_id)
	var result = {
		"level": level,
		"cost": cost,
		"icon": scaled.icon,
		"is_solid": scaled.collision_layer > 0,
		"collision_layer": scaled.collision_layer,
		"damage": 0.0,
		"initial_damage": 0.0,
		"cooldown": 0.0,
		"dps": 0.0,
		"damage_type": AttackData.DamageType.PHYSICAL,
		"damage_type_str": "Physical",
		"max_health": 0.0,
		"max_targets": 1,
		"targets_ghosts": false,
		"blocks_ghosts": false,
		"has_attack": false,
		"has_health": false,
		"has_dot": false,
		"dot_dps": 0.0,
		"dot_duration": 0.0,
		"slow_pct": 0.0,
		"has_freeze": false,
		"freeze_duration": 0.0,
		"armor_reduction": 0.0,
		"magic_resistance_reduction": 0.0,
		"energy_reward_bonus": 0.0,
		"active_duration": 0.0
	}
	
	if scaled.attack:
		result["has_attack"] = true
		result["damage"] = scaled.attack.damage
		if scaled.attack.attack_mode == AttackData.AttackMode.CONTINUOUS:
			result["dps"] = scaled.attack.damage
		else:
			result["cooldown"] = scaled.attack.cooldown
			result["dps"] = scaled.attack.damage / maxf(scaled.attack.cooldown, 0.05)
		result["damage_type"] = scaled.attack.damage_type
		match scaled.attack.damage_type:
			AttackData.DamageType.PHYSICAL: result["damage_type_str"] = "Physical"
			AttackData.DamageType.MAGIC: result["damage_type_str"] = "Magic"
			AttackData.DamageType.TRUE: result["damage_type_str"] = "True"
			
	if scaled.effect_applier:
		result["cooldown"] = scaled.effect_applier.cooldown
		result["active_duration"] = scaled.effect_applier.active_duration if scaled.effect_applier.mode == EffectApplierData.Mode.TRIGGERED_CONTINUOUS else 0.0
		result["max_targets"] = scaled.effect_applier.max_targets
		result["targets_ghosts"] = (scaled.effect_applier.targeting_mask & 8) != 0
		
		for eff in scaled.effect_applier.effects:
			if not eff:
				continue
			if eff.damage > 0.0:
				result["has_attack"] = true
				result["initial_damage"] += eff.damage
				result["damage"] += eff.damage
				result["damage_type"] = eff.damage_type
			if eff.initial_damage > 0.0:
				result["has_attack"] = true
				result["initial_damage"] += eff.initial_damage
				result["damage"] += eff.initial_damage
				result["damage_type"] = eff.damage_type
			if eff.damage_per_second > 0.0:
				result["has_attack"] = true
				result["has_dot"] = true
				result["dot_dps"] += eff.damage_per_second
				var dur = eff.duration if not is_inf(eff.duration) else 0.0
				result["dot_duration"] = maxf(result["dot_duration"], dur)
				result["damage_type"] = eff.damage_type
			if eff.speed_multiplier < 1.0 and eff.speed_multiplier > 0.0:
				var s = (1.0 - eff.speed_multiplier) * 100.0
				result["slow_pct"] = maxf(result["slow_pct"], s)
			elif eff.speed_multiplier == 0.0:
				result["has_freeze"] = true
				result["freeze_duration"] = maxf(result["freeze_duration"], eff.duration if not is_inf(eff.duration) else 2.0)
			if eff.armor_reduction > 0.0:
				result["armor_reduction"] += eff.armor_reduction
			if eff.magic_resistance_reduction > 0.0:
				result["magic_resistance_reduction"] += eff.magic_resistance_reduction
			if eff.energy_reward_multiplier > 1.0:
				result["energy_reward_bonus"] += (eff.energy_reward_multiplier - 1.0) * 100.0

		match result["damage_type"]:
			AttackData.DamageType.PHYSICAL: result["damage_type_str"] = "Physical"
			AttackData.DamageType.MAGIC: result["damage_type_str"] = "Magic"
			AttackData.DamageType.TRUE: result["damage_type_str"] = "True"
			
		if result["dot_dps"] > 0.0 and result["damage"] == 0.0:
			result["dps"] = result["dot_dps"]
		elif result["damage"] > 0.0:
			var cd = maxf(scaled.effect_applier.cooldown, 0.05) if scaled.effect_applier.cooldown > 0 else 0.05
			result["dps"] = result["damage"] / cd + result["dot_dps"]
			
	if scaled.health:
		result["has_health"] = true
		result["max_health"] = scaled.health.max_health
		
	if scaled.targeting:
		result["max_targets"] = scaled.targeting.max_targets
		result["targets_ghosts"] = (scaled.targeting.targeting_mask & 8) != 0
	elif scaled.attack:
		result["targets_ghosts"] = (scaled.attack.damage_type == AttackData.DamageType.MAGIC or scaled.attack.damage_type == AttackData.DamageType.TRUE)
	elif scaled.effect_applier:
		result["targets_ghosts"] = (scaled.effect_applier.targeting_mask & 8) != 0
	else:
		result["targets_ghosts"] = false

	result["blocks_ghosts"] = (scaled.collision_layer > 0) and ((scaled.collision_layer & 16) != 0)
		
	return result

func get_stats(level: int = 1, choice_id: String = "") -> Dictionary:
	var summary = get_stat_summary(level, choice_id)
	var scaled = get_scaled_copy(level, choice_id)
	
	var type_str = "Ground Trap"
	if scaled.requires_wall_behind:
		type_str = "Wall Trap"
	elif scaled.collision_layer > 0:
		if (scaled.collision_layer & 16) != 0:
			type_str = "Spectral Barrier"
		else:
			type_str = "%s Defense" % summary["damage_type_str"]
			
	var stats_dict = {
		"name": display_name,
		"type": type_str,
		"cost": cost,
		"level": level,
		"damage": summary["damage"],
		"initial_damage": summary["initial_damage"],
		"cooldown": summary["cooldown"],
		"dps": summary["dps"],
		"damage_type_str": summary["damage_type_str"],
		"has_attack": summary["has_attack"],
		"has_health": summary["has_health"],
		"has_dot": summary["has_dot"],
		"dot_dps": summary["dot_dps"],
		"dot_duration": summary["dot_duration"],
		"max_health": summary["max_health"],
		"max_targets": summary["max_targets"],
		"targets_ghosts": summary["targets_ghosts"],
		"blocks_ghosts": summary["blocks_ghosts"],
		"is_solid": summary["is_solid"],
		"grid_stats": [],
		"traits": [],
		"stat_lines": []
	}
	
	var grid_stats: Array[Dictionary] = []
	var traits: Array[String] = []
	var lines: Array[String] = []
	
	# Primary combat stats
	if summary["damage"] > 0.0:
		var dmg_type = summary["damage_type_str"].left(4) if summary["damage_type_str"] != "Normal" else ""
		var dmg_val = "%.0f (%s)" % [summary["damage"], dmg_type] if not dmg_type.is_empty() else "%.0f" % summary["damage"]
		var label = "INIT DMG" if summary["has_dot"] else "DAMAGE"
		grid_stats.append({"label": label, "value": dmg_val})
		
		if summary["cooldown"] > 0.0 and not summary["has_dot"]:
			grid_stats.append({"label": "FIRE RATE", "value": "%.2fs" % summary["cooldown"]})
			grid_stats.append({"label": "DPS", "value": "%.1f" % summary["dps"]})
		elif summary["dps"] > 0.0 and not summary["has_dot"]:
			grid_stats.append({"label": "FIRE RATE", "value": "Cont."})
			grid_stats.append({"label": "DPS", "value": "%.1f" % summary["dps"]})
		
		lines.append("%s: %.0f (%s)" % ["Initial Damage" if summary["has_dot"] else "Damage", summary["damage"], summary["damage_type_str"]])

	if summary["dot_dps"] > 0.0:
		grid_stats.append({"label": "DoT DPS", "value": "%.0f/s" % summary["dot_dps"]})
		if summary["dot_duration"] > 0.0:
			grid_stats.append({"label": "DURATION", "value": "%.1fs" % summary["dot_duration"]})
		if summary["cooldown"] > 0.0:
			grid_stats.append({"label": "CYCLE", "value": "%.1fs" % summary["cooldown"]})
		if summary["dps"] > 0.0:
			grid_stats.append({"label": "DPS", "value": "%.1f" % summary["dps"]})
		lines.append("DoT: %.0f/s for %.1fs (%s)" % [summary["dot_dps"], summary["dot_duration"], summary["damage_type_str"]] if summary["dot_duration"] > 0.0 else "DoT: %.0f/s (%s)" % [summary["dot_dps"], summary["damage_type_str"]])
	elif summary["damage"] > 0.0 and summary["cooldown"] > 0.0:
		var cd_str = "%.2fs" % summary["cooldown"]
		lines.append("Rate: %s   •   DPS: %.1f" % [cd_str, summary["dps"]])
		
	# Status debuffs & specialized trap metrics
	if summary["slow_pct"] > 0.0:
		grid_stats.append({"label": "SLOW", "value": "-%.0f%%" % summary["slow_pct"]})
		lines.append("Slow: -%.0f%% Movement Speed" % summary["slow_pct"])
		
	if summary["has_freeze"]:
		grid_stats.append({"label": "FREEZE", "value": "%.1fs" % summary["freeze_duration"]})
		if summary["cooldown"] > 0.0 and summary["has_attack"] == false and summary["dot_dps"] == 0.0:
			grid_stats.append({"label": "CYCLE", "value": "%.1fs" % summary["cooldown"]})
		lines.append("Freeze Duration: %.1fs" % summary["freeze_duration"])
		
	if summary["armor_reduction"] > 0.0:
		grid_stats.append({"label": "ARMOR", "value": "-%.0f" % summary["armor_reduction"]})
		lines.append("Armor Shred: -%.0f" % summary["armor_reduction"])
		
	if summary["magic_resistance_reduction"] > 0.0:
		grid_stats.append({"label": "MAGIC RES", "value": "-%.0f" % summary["magic_resistance_reduction"]})
		lines.append("Magic Resistance Shred: -%.0f" % summary["magic_resistance_reduction"])
		
	if summary["energy_reward_bonus"] > 0.0:
		grid_stats.append({"label": "ENERGY", "value": "+%.0f%%" % summary["energy_reward_bonus"]})
		lines.append("Energy Reward: +%.0f%%" % summary["energy_reward_bonus"])
		
	if summary["active_duration"] > 0.0:
		grid_stats.append({"label": "ACTIVE", "value": "%.1fs" % summary["active_duration"]})
		
	if summary["has_health"]:
		grid_stats.append({"label": "HEALTH", "value": "%.0f HP" % summary["max_health"]})
		lines.append("Structure HP: %.0f" % summary["max_health"])
		
	if summary["max_targets"] > 1:
		grid_stats.append({"label": "CAPACITY", "value": "%d Units" % summary["max_targets"]})
		lines.append("Target Capacity: %d Enemies" % summary["max_targets"])
		
	if summary["targets_ghosts"]:
		grid_stats.append({"label": "GHOSTS", "value": "Detect"})
		lines.append("Ghost Detection: Active")
		
	if summary["blocks_ghosts"]:
		grid_stats.append({"label": "BARRIER", "value": "Active"})
		lines.append("Ghost Barrier: Active")
		
	# Traits & Placement rules
	var t_id = tower_id if not tower_id.is_empty() else Registry.get_tower_id(self)
	if scaled.requires_wall_behind:
		traits.append("Placement: Requires Solid Wall/Tower Support")
		lines.append("Placement: Requires Solid Wall/Tower Support")
		
	if t_id == "soul_lantern":
		traits.append("Trait: Ramping Focus Damage (+35%/s)")
		lines.append("Trait: Ramping Focus Damage (+35%/s)")
	elif t_id == "tesla_tower":
		traits.append("Trait: Arc Lightning Chain")
		lines.append("Trait: Arc Lightning Chain")
	elif t_id == "flamethrower":
		traits.append("Trait: Continuous Thermal Cone")
		lines.append("Trait: Continuous Thermal Cone")
	elif t_id == "wind_wall":
		traits.append("Trait: Continuous & Burst Wind Pushback")
		lines.append("Trait: Continuous & Burst Wind Pushback (Physics Force)")
		
	if not choice_id.is_empty():
		var choice = get_choice(choice_id)
		if choice:
			var spec_details = choice.get_upgrade_details()
			if not spec_details.is_empty():
				traits.append("Spec (%s): %s" % [choice.title, ", ".join(spec_details)])
				lines.append("Spec (%s): %s" % [choice.title, ", ".join(spec_details)])
			else:
				traits.append("Spec: %s" % choice.title)
				lines.append("Spec: %s" % choice.title)
		
	stats_dict["grid_stats"] = grid_stats
	stats_dict["traits"] = traits
	stats_dict["stat_lines"] = lines
	return stats_dict

func create(is_preview: bool = true) -> Tower:
	var tower = scene.instantiate() as Tower
	if not tower:
		push_error("Scene must be a tower!")
		return null

	var copy := duplicate_data()
	tower.data = copy
	tower.is_preview = is_preview
	
	copy.apply_to(tower)
	return tower

func apply_to(tower: Tower) -> void:
	if not is_instance_valid(tower):
		return
		
	tower.collision_layer = collision_layer
	tower.collision_mask = collision_mask

	if icon:
		var sprite = tower.get_node_or_null("Sprite2D") as Sprite2D
		if not sprite:
			for child in tower.get_children():
				if child is Sprite2D:
					sprite = child
					break
		if sprite:
			sprite.texture = icon

	if health:
		ComponentUtil.update_component(tower, HealthComponent, health)

	if targeting:
		ComponentUtil.update_component(tower, TargetingComponent, targeting)

	if attack:
		ComponentUtil.update_component(tower, AttackComponent, attack)

	if effect_applier:
		ComponentUtil.update_component(tower, EffectApplierComponent, effect_applier)
