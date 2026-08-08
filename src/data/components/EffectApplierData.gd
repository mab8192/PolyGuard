class_name EffectApplierData extends Resource

@export var delay: float = 0 ## Delay in seconds from the enemy entering the area that the effect is applied
@export var effects: Array[EffectData]
@export var can_target_physical: bool = true
@export var can_target_ghost: bool = false
