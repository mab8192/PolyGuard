class_name ArmorReductionEffect extends ActiveEffect

var _applied_reduction: float = 0.0

func _init(effect_data: EffectData):
	super._init(effect_data)
	data = effect_data as ArmorReductionEffectData
	if not data:
		push_error("ArmorReductionEffect must receive an ArmorReductionEffectData")

func apply(target: Node2D) -> void:
	super.apply(target)
	if is_instance_valid(target) and target is Enemy and target.health:
		var reduction = (data as ArmorReductionEffectData).armor_reduction
		_applied_reduction = reduction
		target.health.armor_reduction += reduction

func remove() -> void:
	if is_instance_valid(_target) and _target is Enemy and _target.health:
		_target.health.armor_reduction -= _applied_reduction
