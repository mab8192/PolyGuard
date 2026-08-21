class_name EffectData extends Resource

@export_category("Info")
@export var name: String = "" ## Name of the effect
@export var duration: float = INF ## How long the effect lasts
@export var remove_on_exit: bool = true
@export var icon: Texture2D ## Icon to show

@export_category("Damage")
@export var damage: float = 0.0 ## Instant damage applied on hit
@export var initial_damage: float = 0.0 ## Initial damage applied on hit (e.g. burn ignition)
@export var damage_per_second: float = 0.0 ## Damage per second while active
@export var lambda: float = 1.0 ## Multiplier applied to damage_per_second per second (e.g. 0.9 = 10% reduction per second, 1.0 = steady)
@export var damage_type: AttackData.DamageType = AttackData.DamageType.PHYSICAL

@export_category("Modifiers")
@export var speed_multiplier: float = 1.0
@export var acceleration_multiplier: float = 1.0
@export var armor_reduction: float = 0.0
@export var magic_resistance_reduction: float = 0.0

@export_category("Displacement")
@export var displace_distance: float = 0.0 ## Path displacement distance along recorded travel history

func create_instance() -> ActiveEffect:
	return ActiveEffect.new(self.duplicate())
