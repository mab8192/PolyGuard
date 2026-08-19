class_name TowerChoiceUpgrade extends Resource

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""

@export_group("Requirements & Cost")
@export var unlock_cost: int = 300 ## Credit cost to purchase this specialization
@export var required_level: int = 3 ## Minimum tower level required to unlock (e.g. Level 4 = 3 base upgrades)

@export_group("Cost")
@export var cost_reduction: int = 0

@export_group("Damage Type & Attack")
@export var has_damage_type_override: bool = false
@export var damage_type_override: AttackData.DamageType = AttackData.DamageType.PHYSICAL
@export var damage_multiplier: float = 1.0
@export var cooldown_multiplier: float = 1.0

@export_group("Defensive & Targets")
@export var health_multiplier: float = 1.0
@export var extra_targets: int = 0

@export_group("Targeting & Collision Masks")
@export var has_targeting_mask_override: bool = false
@export_flags_2d_physics var targeting_mask_override: int = 12 ## e.g. 12 = Layer 3 Physical (4) + Layer 4 Ghost (8)
@export var has_collision_layer_override: bool = false
@export_flags_2d_physics var collision_layer_override: int = 18 ## e.g. 18 = Layer 2 Solid Tower (2) + Layer 5 Spectral Tower (16)
@export var has_collision_mask_override: bool = false
@export_flags_2d_physics var collision_mask_override: int = 0

@export_group("Effects")
@export var added_effects: Array[EffectData] = []

@export_group("Visuals")
@export var icon: Texture2D ## Texture variant when this specialization is active

func get_upgrade_details() -> Array[String]:
	var details: Array[String] = []
	if has_damage_type_override:
		match damage_type_override:
			AttackData.DamageType.PHYSICAL:
				details.append("Damage Type: Physical")
			AttackData.DamageType.MAGIC:
				details.append("Damage Type: Magic")
			AttackData.DamageType.TRUE:
				details.append("Damage Type: True (Bypasses Armor/Resist)")
	if not is_equal_approx(damage_multiplier, 1.0):
		var pct = int(round((damage_multiplier - 1.0) * 100.0))
		details.append("Damage: %+d%%" % pct)
	if not is_equal_approx(cooldown_multiplier, 1.0):
		var pct = int(round((1.0 - cooldown_multiplier) * 100.0))
		if pct > 0:
			details.append("Attack Speed: +%d%% faster" % pct)
		else:
			details.append("Attack Speed: %d%% slower" % -pct)
	if not is_equal_approx(health_multiplier, 1.0):
		var pct = int(round((health_multiplier - 1.0) * 100.0))
		details.append("Structure Health: %+d%%" % pct)
	if extra_targets > 0:
		details.append("Target Capacity: +%d" % extra_targets)
	if cost_reduction > 0:
		details.append("Placement Cost: -%d Energy" % cost_reduction)
	if has_targeting_mask_override and (targeting_mask_override & 8) != 0:
		details.append("Targeting: Can hit Ghost / Spectral")
	if has_collision_layer_override and (collision_layer_override & 16) != 0:
		details.append("Barrier: Physically blocks Ghosts")
	for eff in added_effects:
		if eff:
			if eff is ArmorReductionEffectData:
				details.append("Effect: Strips %d Armor" % int(eff.armor_reduction))
			elif eff is MagicResistanceReductionEffectData:
				details.append("Effect: Strips %d Magic Resist" % int(eff.magic_resistance_reduction))
			elif eff is SlowEffectData:
				details.append("Effect: Slows enemies by %d%%" % int((1.0 - eff.speed_multiplier) * 100))
			elif eff is BurnEffectData:
				details.append("Effect: Thermal Burn (%.0f DPS)" % eff.damage_per_second)
			elif not eff.name.is_empty():
				details.append("Effect: %s" % eff.name)
	return details
