class_name EnemyData extends Resource

enum EnemyType { PHYSICAL, GHOST }

@export_category("Info")
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var scene: PackedScene
@export var icon: Texture2D = preload("res://vendor/HAMMA.png")

@export_category("Stats")
@export var lives_penalty: int = 1
@export var energy_reward: int = 1
var gold_reward: int:
	get: return energy_reward
	set(v): energy_reward = v
@export var type: EnemyType = EnemyType.PHYSICAL
@export var nav_strategy: NavigationData.NavStrategy = NavigationData.NavStrategy.CLOSEST

@export_category("Components")
@export var health: HealthData
@export var movement: MovementData
@export var nav: NavigationData
@export var attack: AttackData
@export var targeting: TargetingData
@export var splitter: SplitterData
@export var effect_applier: EffectApplierData

func duplicate_data() -> EnemyData:
	var copy: EnemyData = self.duplicate(true)
	if health:
		copy.health = health.duplicate(true)
	if movement:
		copy.movement = movement.duplicate(true)
	if nav:
		copy.nav = nav.duplicate(true)
	if attack:
		copy.attack = attack.duplicate(true)
	if targeting:
		copy.targeting = targeting.duplicate(true)
	if splitter:
		copy.splitter = splitter.duplicate(true)
	if effect_applier:
		copy.effect_applier = effect_applier.duplicate(true)
		var dup_effects: Array[EffectData] = []
		for eff in copy.effect_applier.effects:
			if eff:
				dup_effects.append(eff.duplicate(true))
		copy.effect_applier.effects = dup_effects
	return copy

func create() -> Enemy:
	if not scene:
		push_error("EnemyData (%s) has no scene assigned!" % resource_path)
		return null

	var enemy = scene.instantiate() as Enemy
	if not enemy:
		push_error("Scene in EnemyData must inherit from Enemy!")
		return null

	var copy := duplicate_data()
	enemy.data = copy
	copy.apply_to(enemy)
	return enemy

func apply_to(enemy: Enemy) -> void:
	if not is_instance_valid(enemy):
		return

	if health:
		ComponentUtil.update_component(enemy, HealthComponent, health)

	if movement:
		ComponentUtil.update_component(enemy, MovementComponent, movement)

	if nav:
		if nav_strategy != NavigationData.NavStrategy.CLOSEST and nav.strategy == NavigationData.NavStrategy.CLOSEST:
			nav.strategy = nav_strategy
		ComponentUtil.update_component(enemy, NavigationComponent, nav)
		
	if splitter:
		ComponentUtil.update_component(enemy, SplitterComponent, splitter)
		
	if attack:
		ComponentUtil.update_component(enemy, AttackComponent, attack)
		
	if targeting:
		ComponentUtil.update_component(enemy, TargetingComponent, targeting)

	if effect_applier:
		ComponentUtil.update_component(enemy, EffectApplierComponent, effect_applier)

func get_stats() -> Dictionary:
	var hp_val = health.max_health if health else 0.0
	var armor_val = health.armor if health else 0.0
	var mr_val = health.magic_resistance if health else 0.0
	var speed_val = movement.max_speed if movement else 0.0
	
	var phys_red = (1.0 - (50.0 / (50.0 + armor_val))) * 100.0 if armor_val > 0 else 0.0
	var magic_red = (1.0 - (50.0 / (50.0 + mr_val))) * 100.0 if mr_val > 0 else 0.0
	
	var is_ghost = (type == EnemyType.GHOST)
	var type_str = "GHOST UNIT" if is_ghost else "PHYSICAL UNIT"
	
	var traits: Array[String] = []
	if is_ghost:
		traits.append("Ethereal (Phases through solid towers)")
	if nav and nav.targets_towers:
		traits.append("Aggressor (Targets solid towers over exits)")
	if splitter:
		traits.append("Divides into %d on destruction" % splitter.number_of_copies)
	if display_name == "Bomber":
		traits.append("Suicide Detonation (Deals 150 AoE damage on impact)")
	elif display_name == "Healer":
		traits.append("Restorative Pulse (Heals nearby allies for 25 HP)")
	elif display_name == "Booster":
		traits.append("Acceleration Aura (+35% speed to nearby allies)")
	elif display_name == "Sniper":
		traits.append("Long-Range Ballistics (Attacks towers outside standard range)")
		if attack and attack.initial_delay > 0.0:
			traits.append("Aims for %.0fs before its first shot" % attack.initial_delay)
		
	var grid_stats: Array[Dictionary] = []
	
	# 1. Health
	grid_stats.append({"label": "HEALTH", "value": "%d HP" % int(hp_val)})
	
	# 2. Armor / Physical Defense
	if is_ghost:
		grid_stats.append({"label": "ARMOR", "value": "None"})
	elif armor_val > 0:
		grid_stats.append({"label": "ARMOR", "value": "%d" % int(armor_val)})
	else:
		grid_stats.append({"label": "ARMOR", "value": "0"})
		
	# 3. Magic Resistance
	if mr_val > 0:
		grid_stats.append({"label": "MAGIC RES", "value": "%d" % int(mr_val)})
	else:
		grid_stats.append({"label": "MAGIC RES", "value": "0"})
		
	# 4. Speed
	grid_stats.append({"label": "SPEED", "value": "%d px/s" % int(speed_val)})
	
	# 5. Attack Damage (if unit attacks)
	if attack and attack.damage > 0:
		grid_stats.append({"label": "DAMAGE", "value": "%.0f" % attack.damage})
		if attack.cooldown > 0:
			grid_stats.append({"label": "FIRE RATE", "value": "%.1fs" % attack.cooldown})
		if attack.initial_delay > 0.0:
			grid_stats.append({"label": "AIM TIME", "value": "%.1fs" % attack.initial_delay})
			
	# 6. Lives Penalty
	grid_stats.append({"label": "PENALTY", "value": "%d %s" % [lives_penalty, "Life" if lives_penalty == 1 else "Lives"]})
	
	# 7. Splitter copies (if applicable)
	if splitter:
		grid_stats.append({"label": "SPLITS", "value": "%dx" % splitter.number_of_copies})
		
	var lines: Array[String] = []
	lines.append("HP: %d" % int(hp_val))
	if not is_ghost:
		lines.append("Armor: %d (%.0f%% Phys. Red.)" % [int(armor_val), phys_red])
	if mr_val > 0:
		lines.append("Magic Res: %d (%.0f%% Mag. Red.)" % [int(mr_val), magic_red])
	lines.append("Speed: %d px/s" % int(speed_val))
	lines.append("Penalty: %d Lives   •   Bounty: +%d Energy" % [lives_penalty, energy_reward])
	if attack:
		var attack_line := "Attack: %.0f dmg every %.1fs" % [attack.damage, attack.cooldown]
		if attack.initial_delay > 0.0:
			attack_line += " (aims %.0fs first)" % attack.initial_delay
		lines.append(attack_line)
	if not traits.is_empty():
		lines.append("Traits: %s" % " • ".join(traits))
		
	return {
		"name": display_name,
		"type": type_str,
		"hp": hp_val,
		"armor": armor_val,
		"magic_resistance": mr_val,
		"speed": speed_val,
		"lives_penalty": lives_penalty,
		"energy_reward": energy_reward,
		"grid_stats": grid_stats,
		"traits": traits,
		"stat_lines": lines
	}
