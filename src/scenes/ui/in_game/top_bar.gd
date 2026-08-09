extends MarginContainer

@onready var lives_label: Label = %LivesLabel
@onready var gold_label: Label = %GoldLabel
@onready var wave_label: Label = %WaveLabel
@onready var fast_forward_button: Button = %FastForwardButton
@onready var pause_button: Button = %PauseButton

func _ready() -> void:
	SignalBus.lives_changed.connect(_on_lives_changed)
	SignalBus.gold_changed.connect(_on_gold_changed)
	SignalBus.wave_changed.connect(_on_wave_changed)
	SignalBus.stage_loaded.connect(_on_stage_loaded)
	
	fast_forward_button.toggled.connect(_on_ff_pressed)
	pause_button.pressed.connect(_on_pause_pressed)

func _on_lives_changed(lives: int) -> void:
	lives_label.text = str(lives)

func _on_gold_changed(gold: int) -> void:
	gold_label.text = str(gold)

func _on_stage_loaded() -> void:
	wave_label.text = "1 / " + str(GameManager.current_stage.data.get_waves().size())

func _on_wave_changed(wave: int) -> void:
	wave_label.text = str(wave) + " / " + str(GameManager.current_stage.data.get_waves().size())

func _on_pause_pressed() -> void:
	var hud = find_parent("HUD")
	if hud and hud.has_method("open_pause_menu"):
		hud.open_pause_menu()


func _on_ff_pressed(toggled_on: bool) -> void:
	Engine.time_scale = 2 if toggled_on else 1
	fast_forward_button.text = "2x" if toggled_on else "1x"
