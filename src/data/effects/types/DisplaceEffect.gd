class_name DisplaceEffect extends ActiveEffect

func _init(effect_data: EffectData = null):
	super._init(effect_data)

func apply(target: Node2D) -> void:
	super.apply(target)
	expired.emit()
