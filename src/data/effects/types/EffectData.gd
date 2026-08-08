class_name EffectData extends Resource

@export var name: String = "" ## Name of the effect
@export var duration: float = INF ## How long the effect lasts
@export var icon: Texture2D ## Icon to show

func create_instance() -> ActiveEffect:
	push_error("create_instance() not implemented in %s" % resource_path)
	return null
