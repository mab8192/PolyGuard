extends Control

var lives_label: Label

func _ready() -> void:
	lives_label = $MarginContainer/Control/TopMenu.find_child("LivesLabel")
	SignalBus.lives_changed.connect(_on_lives_changed)
	
func _on_lives_changed(lives: int) -> void:
	lives_label.text = "Lives: " + str(lives)
