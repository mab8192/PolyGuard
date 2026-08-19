class_name InGameTopBar extends SafeAreaMarginContainer

@onready var lives_label: Label = %LivesLabel
@onready var energy_label: Label = %EnergyLabel
@onready var wave_label: Label = %WaveLabel
@onready var fast_forward_button: Button = %FastForwardButton
@onready var pause_button: Button = %PauseButton

func _ready() -> void:
	super._ready()
	Engine.time_scale = 1.0
	fast_forward_button.button_pressed = false
	_update_ff_button_ui(false)
	
	SignalBus.lives_changed.connect(_on_lives_changed)
	SignalBus.energy_changed.connect(_on_energy_changed)
	SignalBus.wave_changed.connect(_on_wave_changed)
	SignalBus.stage_loaded.connect(_on_stage_loaded)
	SignalBus.stage_completed.connect(_on_stage_complete)
	SignalBus.stage_failed.connect(_on_stage_failed)
	
	fast_forward_button.toggled.connect(_on_ff_pressed)
	pause_button.pressed.connect(_on_pause_pressed)

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _on_lives_changed(lives: int) -> void:
	lives_label.text = str(lives)

func _on_energy_changed(energy: int) -> void:
	energy_label.text = str(energy)

func _on_stage_loaded() -> void:
	wave_label.text = "1 / " + str(GameManager.current_stage.data.get_waves().size())

func _on_wave_changed(wave: int) -> void:
	wave_label.text = str(wave) + " / " + str(GameManager.current_stage.data.get_waves().size())

func _on_pause_pressed() -> void:
	var hud = find_parent("HUD") as HUD
	if hud:
		hud.open_pause_menu()

func _on_ff_pressed(toggled_on: bool) -> void:
	Engine.time_scale = 2.0 if toggled_on else 1.0
	_update_ff_button_ui(toggled_on)

func _update_ff_button_ui(is_fast: bool) -> void:
	fast_forward_button.theme_type_variation = &"PrimaryButton" if is_fast else &"SecondaryButton"

func _on_stage_complete(_stage_id: String = "") -> void:
	Engine.time_scale = 1.0
	fast_forward_button.button_pressed = false
	_update_ff_button_ui(false)

func _on_stage_failed() -> void:
	Engine.time_scale = 1.0
	fast_forward_button.button_pressed = false
	_update_ff_button_ui(false)
