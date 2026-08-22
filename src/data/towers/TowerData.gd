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

func get_choice(choice_id: String) -> TowerChoiceUpgrade:
	for c in choices:
		if c and c.id == choice_id:
			return c
	return null

func get_scaled_copy(level: int = 1, choice_id: String = "") -> TowerData:
	var copy: TowerData = self.duplicate(true)
	
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
				if copy.effect_applier.max_targets > 0:
					copy.effect_applier.max_targets += choice.extra_targets
				else:
					push_error("Attempted to increase max targets on a trap that has no limit!")
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
		"cooldown": 0.0,
		"dps": 0.0,
		"damage_type": AttackData.DamageType.PHYSICAL,
		"damage_type_str": "Physical",
		"max_health": 0.0,
		"max_targets": 1,
		"targets_ghosts": false,
		"blocks_ghosts": false,
		"has_attack": false,
		"has_health": false
	}
	
	if scaled.attack:
		result["has_attack"] = true
		result["damage"] = scaled.attack.damage
		result["cooldown"] = scaled.attack.cooldown
		result["dps"] = scaled.attack.damage / maxf(scaled.attack.cooldown, 0.05)
		result["damage_type"] = scaled.attack.damage_type
		match scaled.attack.damage_type:
			AttackData.DamageType.PHYSICAL: result["damage_type_str"] = "Physical"
			AttackData.DamageType.MAGIC: result["damage_type_str"] = "Magic"
			AttackData.DamageType.TRUE: result["damage_type_str"] = "True"
	elif scaled.effect_applier:
		var total_dmg = 0.0
		for eff in scaled.effect_applier.effects:
			if "damage" in eff:
				total_dmg += eff.damage
				result["damage_type"] = eff.damage_type
			elif "initial_damage" in eff:
				total_dmg += eff.initial_damage
				result["damage_type"] = eff.damage_type
			elif "damage_per_second" in eff:
				total_dmg += eff.damage_per_second * eff.duration
				result["damage_type"] = eff.damage_type
		if total_dmg > 0.0:
			result["has_attack"] = true
			result["damage"] = total_dmg
			result["cooldown"] = scaled.effect_applier.cooldown
			result["dps"] = total_dmg / maxf(scaled.effect_applier.cooldown, 0.05) if scaled.effect_applier.cooldown > 0 else total_dmg
			match result["damage_type"]:
				AttackData.DamageType.PHYSICAL: result["damage_type_str"] = "Physical"
				AttackData.DamageType.MAGIC: result["damage_type_str"] = "Magic"
				AttackData.DamageType.TRUE: result["damage_type_str"] = "True"
		result["max_targets"] = scaled.effect_applier.max_targets
		result["targets_ghosts"] = (scaled.effect_applier.targeting_mask & 8) != 0
			
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
	if scaled.collision_layer > 0:
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
		"cooldown": summary["cooldown"],
		"dps": summary["dps"],
		"damage_type_str": summary["damage_type_str"],
		"has_attack": summary["has_attack"],
		"has_health": summary["has_health"],
		"max_health": summary["max_health"],
		"max_targets": summary["max_targets"],
		"targets_ghosts": summary["targets_ghosts"],
		"blocks_ghosts": summary["blocks_ghosts"],
		"is_solid": summary["is_solid"],
		"stat_lines": []
	}
	
	var lines: Array[String] = []
	if summary["has_attack"]:
		var cd_str = "%.2fs" % summary["cooldown"] if summary["cooldown"] > 0 else "Continuous"
		lines.append("Damage: %.0f (%s)" % [summary["damage"], summary["damage_type_str"]])
		lines.append("Rate: %s   •   DPS: %.1f" % [cd_str, summary["dps"]])
	if summary["has_health"]:
		lines.append("Structure HP: %.0f" % summary["max_health"])
	if summary["max_targets"] > 1:
		lines.append("Target Capacity: %d Enemies" % summary["max_targets"])
	if summary["targets_ghosts"]:
		lines.append("Ghost Detection: Active")
	if summary["blocks_ghosts"]:
		lines.append("Ghost Barrier: Active")
	if tower_id == "soul_lantern":
		lines.append("Trait: Ramping Focus Damage (+35%/s)")
	elif tower_id == "tesla_tower":
		lines.append("Trait: Arc Lightning Chain")
	elif tower_id == "flamethrower":
		lines.append("Trait: Continuous Thermal Cone")
	elif tower_id == "tar_trap":
		lines.append("Effect: Reduces Enemy Speed by 50%")
	elif tower_id == "freeze_trap":
		lines.append("Trait: Freezes Enemies in Place (Burst)")
	elif tower_id == "siphon":
		lines.append("Effect: Increase Enemy Energy Reward by 50%")
		
	if not choice_id.is_empty():
		var choice = get_choice(choice_id)
		if choice:
			var spec_details = choice.get_upgrade_details()
			if not spec_details.is_empty():
				lines.append("Spec (%s): %s" % [choice.title, ", ".join(spec_details)])
			else:
				lines.append("Spec: %s" % choice.title)
		
	if lines.is_empty():
		lines.append("Defensive Tactical Installation")
		
	stats_dict["stat_lines"] = lines
	return stats_dict

func create(is_preview: bool = true) -> Tower:
	var tower = scene.instantiate() as Tower
	if not tower:
		push_error("Scene must be a tower!")
		return null

	tower.data = self.duplicate(true)
	tower.is_preview = is_preview
	
	apply_to(tower)
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
		ComponentUtil.update_component(tower, HealthComponent, tower.data.health)

	if targeting:
		ComponentUtil.update_component(tower, TargetingComponent, tower.data.targeting)

	if attack:
		ComponentUtil.update_component(tower, AttackComponent, tower.data.attack)

	if effect_applier:
		ComponentUtil.update_component(tower, EffectApplierComponent, tower.data.effect_applier)
