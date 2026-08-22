class_name EndlessWaveGenerator
extends RefCounted

# ==============================================================================
# ENDLESS MODE TUNING CONSTANTS (Easily tweakable)
# ==============================================================================

# --- Round Completion Rewards ---
const WAVE_REWARD_BASE: int = 250
const WAVE_REWARD_MIN: int = 50
const WAVE_REWARD_DECAY_PER_WAVE: float = 8.0 # Tapers round reward down to ~50 max
const WAVE_REWARD_MILESTONE_BONUS: int = 50   # Bonus on waves divisible by 5/10

# --- Enemy Kill Bounty Scaling ---
const ENEMY_BOUNTY_BASE_MULTIPLIER: float = 1.0
const ENEMY_BOUNTY_MIN_MULTIPLIER: float = 0.25 # Floor so kills still grant minimal energy
const ENEMY_BOUNTY_DECAY_PER_WAVE: float = 0.015 # Bounty scales down over time as waves advance

# --- Enemy Stat Scaling ---
const HP_SCALE_BASE: float = 1.0
const HP_SCALE_PER_WAVE: float = 0.08
const HP_SCALE_EXPONENT_WAVE_START: int = 15
const HP_SCALE_EXPONENT_FACTOR: float = 0.03
const SPEED_SCALE_PER_WAVE: float = 0.004
const MAX_SPEED_MULTIPLIER: float = 1.25

# --- Wave Budget & Composition ---
const BUDGET_BASE: float = 60.0
const BUDGET_GROWTH_PER_WAVE: float = 25.0
const BUDGET_EXPONENT_WAVE_START: int = 10
const BUDGET_EXPONENT_FACTOR: float = 15.0

# --- Enemy Cost Table ---
const ENEMY_COSTS: Dictionary = {
	"light": 6,
	"grunt": 10,
	"speeder": 14,
	"light_ghost": 20,
	"bomber": 24,
	"heavy": 30,
	"splitter": 35,
	"ghost": 35,
	"healer": 40,
	"booster": 45,
	"sniper": 50,
	"heavy_ghost": 60,
	"tank": 70,
	"citadel": 160
}

# ==============================================================================
# PUBLIC MULTIPLIER & REWARD CALCULATORS
# ==============================================================================

## Returns energy awarded upon completing wave_index (0-based)
static func get_wave_reward_energy(wave_index: int) -> int:
	var wave_num: int = wave_index + 1
	var decay: float = float(wave_index) * WAVE_REWARD_DECAY_PER_WAVE
	var reward: int = int(round(float(WAVE_REWARD_BASE) - decay))
	reward = maxi(WAVE_REWARD_MIN, reward)
	
	if wave_num % 5 == 0:
		reward += WAVE_REWARD_MILESTONE_BONUS
	if wave_num % 10 == 0:
		reward += WAVE_REWARD_MILESTONE_BONUS
		
	return reward

## Returns the HP scaling multiplier for a given 1-based wave number
static func get_wave_hp_multiplier(wave_number: int) -> float:
	var mult: float = HP_SCALE_BASE + float(wave_number - 1) * HP_SCALE_PER_WAVE
	if wave_number > HP_SCALE_EXPONENT_WAVE_START:
		var excess: float = float(wave_number - HP_SCALE_EXPONENT_WAVE_START)
		mult += pow(excess, 1.25) * HP_SCALE_EXPONENT_FACTOR
	return mult

## Returns the movement speed multiplier for a given 1-based wave number
static func get_wave_speed_multiplier(wave_number: int) -> float:
	var mult: float = 1.0 + float(wave_number - 1) * SPEED_SCALE_PER_WAVE
	return minf(MAX_SPEED_MULTIPLIER, mult)

## Returns the enemy energy bounty multiplier (decays down to ENEMY_BOUNTY_MIN_MULTIPLIER)
static func get_wave_bounty_multiplier(wave_number: int) -> float:
	var mult: float = ENEMY_BOUNTY_BASE_MULTIPLIER - float(wave_number - 1) * ENEMY_BOUNTY_DECAY_PER_WAVE
	return maxf(ENEMY_BOUNTY_MIN_MULTIPLIER, mult)

## Returns the point budget for procedural wave generation
static func get_wave_budget(wave_number: int) -> float:
	var budget: float = BUDGET_BASE + float(wave_number) * BUDGET_GROWTH_PER_WAVE
	if wave_number > BUDGET_EXPONENT_WAVE_START:
		var excess: float = float(wave_number - BUDGET_EXPONENT_WAVE_START)
		budget += pow(excess, 1.35) * BUDGET_EXPONENT_FACTOR
	return budget

# ==============================================================================
# PROCEDURAL WAVE GENERATION
# ==============================================================================

## Builds a dynamic WaveData instance for the given wave index
static func generate_wave(stage: Stage, wave_index: int, spawners: Array[Spawner]) -> WaveData:
	var wave_data := WaveData.new()
	var wave_num: int = wave_index + 1
	wave_data.wave_number = wave_num
	wave_data.reward_energy = get_wave_reward_energy(wave_index)
	
	# Determine ghost spawners from original stage configuration
	var ghost_spawners: Array[Spawner] = []
	var physical_spawners: Array[Spawner] = []
	var ghost_spawner_ids: Array[String] = _get_stage_ghost_spawner_ids(stage)
	
	for s in spawners:
		if is_instance_valid(s):
			if ghost_spawner_ids.has(s.spawner_id) or ghost_spawner_ids.has(s.name):
				ghost_spawners.append(s)
			else:
				physical_spawners.append(s)
				
	# If stage has no distinct physical spawners, fallback to all spawners for physical units
	if physical_spawners.is_empty():
		physical_spawners = spawners.duplicate()

	var has_ghosts: bool = not ghost_spawners.is_empty()
	var total_budget: float = get_wave_budget(wave_num)
	
	# Select wave archetype
	var groups_plan: Array[Dictionary] = _create_wave_plan(wave_num, total_budget, has_ghosts)
	
	# Build SpawnGroup instances
	var current_delay: float = 0.5
	var phys_idx: int = 0
	var ghost_idx: int = 0
	
	for plan in groups_plan:
		var enemy_type: String = plan.get("type", "grunt")
		var count: int = plan.get("count", 1)
		var interval: float = plan.get("interval", 1.0)
		var is_ghost: bool = enemy_type.contains("ghost")
		
		if count <= 0:
			continue
			
		var group := SpawnGroup.new()
		group.enemy_type = enemy_type
		group.count = count
		group.interval = interval
		group.delay = current_delay
		
		# Assign target spawner according to unit type and stage spawner capabilities
		if is_ghost and not ghost_spawners.is_empty():
			var target_spawner: Spawner = ghost_spawners[ghost_idx % ghost_spawners.size()]
			group.spawner_id = target_spawner.spawner_id
			ghost_idx += 1
		elif not physical_spawners.is_empty():
			var target_spawner: Spawner = physical_spawners[phys_idx % physical_spawners.size()]
			group.spawner_id = target_spawner.spawner_id
			phys_idx += 1
			
		wave_data.spawns.append(group)
		current_delay += plan.get("delay_gap", 2.0)
		
	return wave_data

# ==============================================================================
# INTERNAL HELPERS
# ==============================================================================

## Returns an array of spawner IDs that were originally used to spawn ghosts in this stage
static func _get_stage_ghost_spawner_ids(stage: Stage) -> Array[String]:
	var result: Array[String] = []
	if not stage or not stage.data:
		return result
		
	var waves = stage.data.get_waves()
	for w in waves:
		for sp in w.spawns:
			if sp.enemy_type.contains("ghost") and not sp.spawner_id.is_empty():
				if not result.has(sp.spawner_id):
					result.append(sp.spawner_id)
					
	return result

## Creates a list of spawn group parameters based on wave archetype and budget
static func _create_wave_plan(wave_num: int, total_budget: float, has_ghosts: bool) -> Array[Dictionary]:
	var plan: Array[Dictionary] = []
	
	if wave_num % 10 == 0:
		# --- TITAN / BOSS WAVE ---
		var citadel_count: int = maxi(1, int(floor(float(wave_num) / 10.0)))
		var citadel_cost: float = float(citadel_count * ENEMY_COSTS["citadel"])
		var rem_budget: float = maxf(50.0, total_budget - citadel_cost)
		
		plan.append({ "type": "citadel", "count": citadel_count, "interval": 4.0, "delay_gap": 3.0 })
		plan.append({ "type": "booster", "count": maxi(1, int(rem_budget * 0.15 / ENEMY_COSTS["booster"])), "interval": 2.0, "delay_gap": 2.0 })
		plan.append({ "type": "healer", "count": maxi(1, int(rem_budget * 0.20 / ENEMY_COSTS["healer"])), "interval": 1.5, "delay_gap": 2.0 })
		plan.append({ "type": "tank", "count": maxi(2, int(rem_budget * 0.35 / ENEMY_COSTS["tank"])), "interval": 2.0, "delay_gap": 2.5 })
		if has_ghosts:
			plan.append({ "type": "heavy_ghost", "count": maxi(1, int(rem_budget * 0.30 / ENEMY_COSTS["heavy_ghost"])), "interval": 1.8, "delay_gap": 2.0 })
		else:
			plan.append({ "type": "heavy", "count": maxi(2, int(rem_budget * 0.30 / ENEMY_COSTS["heavy"])), "interval": 1.2, "delay_gap": 2.0 })
			
	elif wave_num % 5 == 0:
		# --- ELITE / MINI-BOSS WAVE ---
		var tank_count: int = maxi(2, int((total_budget * 0.35) / ENEMY_COSTS["tank"]))
		var split_count: int = maxi(2, int((total_budget * 0.25) / ENEMY_COSTS["splitter"]))
		var sniper_count: int = maxi(1, int((total_budget * 0.20) / ENEMY_COSTS["sniper"]))
		var rem: float = total_budget * 0.20
		
		plan.append({ "type": "tank", "count": tank_count, "interval": 1.8, "delay_gap": 2.5 })
		plan.append({ "type": "splitter", "count": split_count, "interval": 1.2, "delay_gap": 2.0 })
		plan.append({ "type": "sniper", "count": sniper_count, "interval": 1.5, "delay_gap": 2.0 })
		if has_ghosts:
			plan.append({ "type": "ghost", "count": maxi(2, int(rem / ENEMY_COSTS["ghost"])), "interval": 1.0, "delay_gap": 2.0 })
		else:
			plan.append({ "type": "heavy", "count": maxi(2, int(rem / ENEMY_COSTS["heavy"])), "interval": 1.2, "delay_gap": 2.0 })
			
	else:
		# --- STANDARD ARCHETYPES ---
		var archetype: int = (wave_num % 4)
		match archetype:
			0:
				# Fast Swarm Rush
				var light_count: int = maxi(6, int((total_budget * 0.45) / ENEMY_COSTS["light"]))
				var speeder_count: int = maxi(4, int((total_budget * 0.35) / ENEMY_COSTS["speeder"]))
				var bomber_count: int = maxi(1, int((total_budget * 0.20) / ENEMY_COSTS["bomber"]))
				plan.append({ "type": "light", "count": light_count, "interval": 0.5, "delay_gap": 1.5 })
				plan.append({ "type": "speeder", "count": speeder_count, "interval": 0.4, "delay_gap": 1.5 })
				plan.append({ "type": "bomber", "count": bomber_count, "interval": 1.0, "delay_gap": 2.0 })
			1:
				# Ghost Infiltration or Rapid Patrol
				if has_ghosts:
					var l_ghost: int = maxi(3, int((total_budget * 0.40) / ENEMY_COSTS["light_ghost"]))
					var ghost: int = maxi(2, int((total_budget * 0.35) / ENEMY_COSTS["ghost"]))
					var h_ghost: int = maxi(1, int((total_budget * 0.25) / ENEMY_COSTS["heavy_ghost"]))
					plan.append({ "type": "light_ghost", "count": l_ghost, "interval": 0.7, "delay_gap": 1.8 })
					plan.append({ "type": "ghost", "count": ghost, "interval": 1.0, "delay_gap": 2.0 })
					plan.append({ "type": "heavy_ghost", "count": h_ghost, "interval": 1.8, "delay_gap": 2.0 })
				else:
					var grunt_count: int = maxi(5, int((total_budget * 0.40) / ENEMY_COSTS["grunt"]))
					var speeder_count: int = maxi(4, int((total_budget * 0.30) / ENEMY_COSTS["speeder"]))
					var sniper_count: int = maxi(2, int((total_budget * 0.30) / ENEMY_COSTS["sniper"]))
					plan.append({ "type": "grunt", "count": grunt_count, "interval": 0.7, "delay_gap": 1.5 })
					plan.append({ "type": "speeder", "count": speeder_count, "interval": 0.4, "delay_gap": 1.5 })
					plan.append({ "type": "sniper", "count": sniper_count, "interval": 1.2, "delay_gap": 2.0 })
			2:
				# Demolition & Splitter Assault
				var split_count: int = maxi(3, int((total_budget * 0.40) / ENEMY_COSTS["splitter"]))
				var bomber_count: int = maxi(2, int((total_budget * 0.30) / ENEMY_COSTS["bomber"]))
				var booster_count: int = maxi(1, int((total_budget * 0.30) / ENEMY_COSTS["booster"]))
				plan.append({ "type": "splitter", "count": split_count, "interval": 1.1, "delay_gap": 2.0 })
				plan.append({ "type": "bomber", "count": bomber_count, "interval": 1.0, "delay_gap": 2.0 })
				plan.append({ "type": "booster", "count": booster_count, "interval": 1.8, "delay_gap": 2.0 })
			3:
				# Heavy Siege Brigade
				var heavy_count: int = maxi(3, int((total_budget * 0.40) / ENEMY_COSTS["heavy"]))
				var healer_count: int = maxi(1, int((total_budget * 0.25) / ENEMY_COSTS["healer"]))
				var tank_count: int = maxi(1, int((total_budget * 0.35) / ENEMY_COSTS["tank"]))
				plan.append({ "type": "heavy", "count": heavy_count, "interval": 1.2, "delay_gap": 2.0 })
				plan.append({ "type": "healer", "count": healer_count, "interval": 1.8, "delay_gap": 2.0 })
				plan.append({ "type": "tank", "count": tank_count, "interval": 2.2, "delay_gap": 2.5 })
				
	return plan
