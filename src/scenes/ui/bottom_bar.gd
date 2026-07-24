extends MarginContainer

@onready var build_button: Button = %BuildButton
@onready var next_wave_button: Button = %NextWaveButton

func _ready() -> void:
	next_wave_button.pressed.connect(_on_next_wave_pressed)
	
	SignalBus.wave_started.connect(func (): next_wave_button.hide())
	SignalBus.wave_completed.connect(func(): next_wave_button.show())

func _on_next_wave_pressed() -> void:
	GameManager.current_stage.start_next_wave()
