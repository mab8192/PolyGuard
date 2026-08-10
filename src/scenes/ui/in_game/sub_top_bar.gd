extends MarginContainer

@onready var score_label: Label = %ScoreLabel
@onready var timer_label: Label = %TimerLabel

func _ready() -> void:
	SignalBus.score_changed.connect(_on_score_changed)
	SignalBus.stage_time_changed.connect(_on_stage_time_changed)
	SignalBus.stage_loaded.connect(_on_stage_loaded)

func _on_score_changed(score: int) -> void:
	score_label.text = _format_number(score)

func _on_stage_time_changed(formatted_time: String) -> void:
	timer_label.text = formatted_time

func _on_stage_loaded() -> void:
	score_label.text = "0"
	timer_label.text = "00:00"

func _format_number(val: int) -> String:
	var s = str(val)
	var result = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result
