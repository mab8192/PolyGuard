class_name ActiveEffect extends RefCounted

signal expired()

var data: EffectData
var _target: Node2D
var _visual_node: Node2D = null

var _counting_time: bool = false
var _elapsed_time_counted: float = 0 ## Elapsed time since _counting_time was set
var _elapsed_time_total: float = 0 ## Elapsed time since the effect first applied

func _init(effect_data: EffectData):
	data = effect_data

func count_time() -> void:
	_counting_time = true
	_elapsed_time_counted = 0.0

func stop_counting_time() -> void:
	_counting_time = false
	_elapsed_time_counted = 0.0

func apply(target: Node2D) -> void:
	_target = target

func tick(delta: float) -> void:
	if _counting_time:
		_elapsed_time_counted += delta
	_elapsed_time_total += delta
	
	if data and data.duration != INF and _elapsed_time_counted >= data.duration:
		_counting_time = false
		expired.emit()

func remove() -> void:
	if is_instance_valid(_visual_node):
		_visual_node.queue_free()
		_visual_node = null
