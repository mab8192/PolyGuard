class_name EffectData extends Resource

@export_category("Info")
@export var name: String = "" ## Name of the effect
@export var duration: float = INF ## How long the effect lasts
@export var remove_on_exit: bool = true
@export var icon: Texture2D ## Icon to show

@export_category("Modifiers")
@export var speed_multiplier: float = 1.0
@export var acceleration_multiplier: float = 1.0
@export var armor_reduction: float = 0.0
@export var magic_resistance_reduction: float = 0.0

func create_instance() -> ActiveEffect:
	push_error("create_instance() not implemented in %s" % resource_path)
	return null
