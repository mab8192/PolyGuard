class_name TowerData extends Resource

@export_category("Info")
@export var tower_id: String = "" ## Unique identifier matching Registry.TOWERS
@export var display_name: String = "" ## The name to display for this tower in-game
@export var icon: Texture2D ## The icon to display when building and in the loadout scene
@export var scene: PackedScene ## The scene for this tower data
@export_multiline var description: String = "" ## The description to show in-game

@export_category("Meta Progression")
@export var unlock_cost: int = 0 ## 0 = starter tower, >0 = Credit cost to unlock
@export var max_level: int = 5 ## Maximum upgrade level
@export var choices: Array[TowerChoiceUpgrade] = [] ## Branching / Choice specializations

@export_category("Level Upgrade Scaling")
@export var damage_upgrade_per_level: float = 0.1 ## Damage increase per level above Lv 1
@export var cooldown_reduction_per_level: float = 0.05 ## Attack cooldown reduction per level
@export var health_upgrade_per_level: float = 0.1 ## Health increase per level above Lv 1
@export var min_cooldown_multiplier: float = 0.35 ## Lower limit clamp for attack cooldown multiplier

@export_category("Stats")
@export var is_solid: bool = true
@export var cost: int = 250 ## How much energy this tower costs to place

@export_category("Components")
@export var health: HealthData
@export var attack: AttackData
@export var targeting: TargetingData
@export var effect_applier: EffectApplierData

func get_upgrade_cost(target_level: int) -> int:
	match target_level:
		2: return 150
		3: return 300
		4: return 500
		5: return 750
		_: return 200 * (target_level - 1)

func get_choice(choice_id: String) -> TowerChoiceUpgrade:
	for c in choices:
		if c and c.id == choice_id:
			return c
	return null

func get_scaled_copy(level: int = 1, choice_id: String = "") -> TowerData:
	var copy: TowerData = self.duplicate(true)
	
	var lvl = clampi(level, 1, max_level)
	var dmg_mult = 1.0 + (lvl - 1) * damage_upgrade_per_level
	var cd_mult = maxf(min_cooldown_multiplier, 1.0 - (lvl - 1) * cooldown_reduction_per_level)
	var hp_mult = 1.0 + (lvl - 1) * health_upgrade_per_level
	
	var choice = copy.get_choice(choice_id)
	if choice:
		if choice.has_damage_type_override and copy.attack:
			copy.attack.damage_type = choice.damage_type_override
		dmg_mult *= choice.damage_multiplier
		cd_mult *= choice.cooldown_multiplier
		hp_mult *= choice.health_multiplier
		if copy.targeting:
			copy.targeting.max_targets += choice.extra_targets
	
	if copy.attack:
		copy.attack.damage *= dmg_mult
		copy.attack.cooldown *= cd_mult
	
	if copy.health:
		copy.health.max_health *= hp_mult
	
	return copy

func get_stat_summary(level: int = 1, choice_id: String = "") -> Dictionary:
	var scaled = get_scaled_copy(level, choice_id)
	var result = {
		"level": level,
		"cost": cost,
		"is_solid": is_solid,
		"damage": 0.0,
		"cooldown": 0.0,
		"dps": 0.0,
		"damage_type": AttackComponent.DamageType.PHYSICAL,
		"damage_type_str": "Physical",
		"max_health": 0.0,
		"max_targets": 1,
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
			AttackComponent.DamageType.PHYSICAL: result["damage_type_str"] = "Physical"
			AttackComponent.DamageType.MAGIC: result["damage_type_str"] = "Magic"
			AttackComponent.DamageType.TRUE: result["damage_type_str"] = "True"
			
	if scaled.health:
		result["has_health"] = true
		result["max_health"] = scaled.health.max_health
		
	if scaled.targeting:
		result["max_targets"] = scaled.targeting.max_targets
		
	return result

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
		
	tower.is_solid = is_solid

	if health:
		ComponentUtil.update_component(tower, HealthComponent, tower.data.health)

	if targeting:
		ComponentUtil.update_component(tower, TargetingComponent, tower.data.targeting)

	if attack:
		ComponentUtil.update_component(tower, AttackComponent, tower.data.attack)

	if effect_applier:
		ComponentUtil.update_component(tower, EffectApplierComponent, tower.data.effect_applier)
