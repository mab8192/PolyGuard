class_name EffectApplierData extends Resource

@export var delay: float = 0 ## Delay in seconds from the enemy entering the area that the effect is applied
@export var cooldown: float = 0 ## Cooldown in seconds between times this effect applier can trigger
@export var effects: Array[EffectData]
@export_flags_2d_physics var targeting_mask: int = 4
