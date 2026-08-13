class_name EffectApplierData extends Resource

enum Mode {CONTINUOUS, BURST, TRIGGERED_CONTINUOUS}

@export var mode: Mode = Mode.CONTINUOUS
@export var delay: float = 0.0 ## Delay in seconds from enemy entering until applier triggers
@export var active_duration: float = 3.0 ## Active duration in seconds while area effect persists after trigger (for TRIGGERED_CONTINUOUS)
@export var cooldown: float = 0.0 ## Cooldown in seconds after triggering / active phase before applier can fire again
@export var effects: Array[EffectData]
@export_flags_2d_physics var targeting_mask: int = 4
