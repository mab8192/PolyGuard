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

func create() -> Enemy:
	if not scene:
		push_error("EnemyData (%s) has no scene assigned!" % resource_path)
		return null

	var enemy = scene.instantiate() as Enemy
	if not enemy:
		push_error("Scene in EnemyData must inherit from Enemy!")
		return null

	enemy.data = self.duplicate(true)
	apply_to(enemy)
	return enemy

func apply_to(enemy: Enemy) -> void:
	if not is_instance_valid(enemy):
		return

	if health:
		ComponentUtil.update_component(enemy, HealthComponent, enemy.data.health)

	if movement:
		ComponentUtil.update_component(enemy, MovementComponent, enemy.data.movement)

	if nav:
		ComponentUtil.update_component(enemy, NavigationComponent, enemy.data.nav)
		
	if splitter:
		ComponentUtil.update_component(enemy, SplitterComponent, enemy.data.splitter)
		
	if attack:
		ComponentUtil.update_component(enemy, AttackComponent, enemy.data.attack)
		
	if targeting:
		ComponentUtil.update_component(enemy, TargetingComponent, enemy.data.targeting)

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
		
	var lines: Array[String] = []
	lines.append("HP: %d" % int(hp_val))
	if not is_ghost:
		lines.append("Armor: %d (%.0f%% Phys. Red.)" % [int(armor_val), phys_red])
	if mr_val > 0:
		lines.append("Magic Res: %d (%.0f%% Mag. Red.)" % [int(mr_val), magic_red])
	lines.append("Speed: %d px/s" % int(speed_val))
	lines.append("Penalty: %d Lives   •   Bounty: +%d Energy" % [lives_penalty, energy_reward])
	if attack:
		lines.append("Attack: %.0f dmg every %.1fs" % [attack.damage, attack.cooldown])
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
		"traits": traits,
		"stat_lines": lines
	}
