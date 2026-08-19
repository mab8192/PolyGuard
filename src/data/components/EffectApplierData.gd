class_name EffectApplierData extends Resource

enum Mode {CONTINUOUS, BURST, TRIGGERED_CONTINUOUS}

@export var mode: Mode = Mode.CONTINUOUS ## Operating mode determining how and when effects are applied (continuous aura, burst on trigger, or triggered duration)
@export var delay: float = 0.0 ## Delay in seconds from enemy entering area until the applier triggers
@export var active_duration: float = 3.0 ## Active duration in seconds while area effect persists after trigger (for TRIGGERED_CONTINUOUS)
@export var cooldown: float = 0.0 ## Cooldown in seconds after triggering / active phase before applier can fire again
@export var max_targets: int = 0 ## Max enemies affected before entering cooldown (0 = unlimited)
@export var effects: Array[EffectData] ## List of status effect configurations applied to targets within range
@export_flags_2d_physics var targeting_mask: int = 4 ## Physics collision layer mask for filtering valid target bodies (e.g. physical vs ghost enemies)
