extends MarginContainer

@onready var build_button: Button = %BuildButton
@onready var next_wave_button: TextureButton = %NextWaveButton

func _ready() -> void:
	build_button.pressed.connect(_on_build_pressed)
	next_wave_button.pressed.connect(_on_next_wave_pressed)
	
	SignalBus.wave_started.connect(func (): next_wave_button.hide())
	SignalBus.wave_completed.connect(func(): next_wave_button.show())

func _on_next_wave_pressed() -> void:
	GameManager.current_stage.start_next_wave()

func _on_build_pressed() -> void:
	if GameManager.current_stage:
		GameManager.current_stage.enter_placement_mode(Registry.TOWERS["Archer Tower"])
