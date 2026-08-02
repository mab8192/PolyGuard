extends MarginContainer

@onready var build_button: Button = %BuildButton
@onready var next_wave_button: TextureButton = %NextWaveButton

@export var radial_menu_scene: PackedScene = preload("res://src/scenes/ui/radial_menu.tscn")
var radial_menu: RadialMenu = null

func open_build_radial_menu() -> void:
	var items: Array[Dictionary] = []
	
	var tower_map: Dictionary = Registry.TOWERS
	var item_titles = ["Archer", "Barricade", "Cannon", "Frost", "Lightning", "Bomb"]
	var default_icon = preload("res://vendor/HAMMA.png")
	
	for i in range(min(item_titles.size(), 6)):
		var t_name = item_titles[i]
		var payload: Variant = null
		
		if tower_map.has(t_name):
			payload = tower_map[t_name]
		elif tower_map.has(t_name + " Tower"):
			payload = tower_map[t_name + " Tower"]
		else:
			var keys = tower_map.keys()
			payload = tower_map[keys[i % keys.size()]]
		
		items.append({
			"title": t_name,
			"payload": payload,
			"icon": default_icon,
			"enabled": true
		})
	
	var button_center = build_button.global_position + (build_button.size / 2.0)
	radial_menu.open(items, button_center)

func _ready() -> void:
	build_button.focus_mode = Control.FOCUS_NONE
	next_wave_button.focus_mode = Control.FOCUS_NONE
	
	radial_menu.item_selected.connect(_on_radial_item_selected)
	
	build_button.gui_input.connect(_on_build_button_gui_input)
	next_wave_button.pressed.connect(_on_next_wave_pressed)
	
	SignalBus.wave_started.connect(func (): next_wave_button.hide())
	SignalBus.wave_completed.connect(func(): next_wave_button.show())

func _on_next_wave_pressed() -> void:
	if GameManager.current_stage:
		GameManager.current_stage.start_next_wave()

func _on_build_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_viewport().gui_release_focus()
		build_button.release_focus()
		if radial_menu and radial_menu.is_open():
			radial_menu.close()
		else:
			open_build_radial_menu()

func _on_radial_item_selected(payload: Variant) -> void:
	if payload is PackedScene and GameManager.current_stage:
		GameManager.current_stage.enter_placement_mode(payload)
