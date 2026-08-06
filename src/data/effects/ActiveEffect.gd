class_name ActiveEffect extends RefCounted

var data: EffectData
var _target: Node2D

func _init(effect_data: EffectData):
	data = effect_data

func apply(target: Node2D) -> void:
	_target = target

func tick(delta: float) -> void:
	pass
	
func remove() -> void:
	pass
