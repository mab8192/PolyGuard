extends CanvasLayer

@onready var pause_menu: PauseMenu = $PauseMenu
@onready var victory = $Victory
@onready var defeat = $Defeat

func open_pause_menu() -> void:
	if pause_menu:
		pause_menu.open()
