class_name TowerChoiceUpgrade extends Resource

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""

@export_group("Requirements & Cost")
@export var unlock_cost: int = 300 ## Credit cost to purchase this specialization
@export var required_level: int = 4 ## Minimum tower level required to unlock (e.g. Level 4 = 3 base upgrades)

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
