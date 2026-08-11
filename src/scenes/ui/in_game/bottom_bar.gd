extends MarginContainer

@onready var build_button: Button = %BuildButton
@onready var next_wave_button: TextureButton = %NextWaveButton
@onready var placement_buttons: Control = %PlacementButtons
@onready var cancel_button: Button = %CancelPlacementButton
@onready var confirm_button: Button = %ConfirmPlacementButton

@export var radial_menu_scene: PackedScene = preload("res://src/scenes/ui/elements/radial_menu.tscn")
@onready var radial_menu: RadialMenu = $DockContainer/BuildButton/RadialMenu

func _ready() -> void:
	build_button.focus_mode = Control.FOCUS_NONE
	next_wave_button.focus_mode = Control.FOCUS_NONE
	cancel_button.focus_mode = Control.FOCUS_NONE
	confirm_button.focus_mode = Control.FOCUS_NONE

	placement_buttons.hide()

	radial_menu.arc_angle_degrees = 180

	radial_menu.item_selected.connect(_on_radial_item_selected)
	
	build_button.gui_input.connect(_on_build_button_gui_input)
	next_wave_button.pressed.connect(_on_next_wave_pressed)
	cancel_button.pressed.connect(_on_cancel_placement_pressed)
	confirm_button.pressed.connect(_on_confirm_placement_pressed)
	SignalBus.placement_mode_changed.connect(_on_placement_mode_changed)
	
	SignalBus.wave_started.connect(func(): next_wave_button.hide())
	SignalBus.wave_completed.connect(func(): next_wave_button.show())

func _process(_delta: float) -> void:
	if not placement_buttons.visible:
		return
	
	var stage := GameManager.current_stage
	if stage and stage.is_in_placement_mode():
		confirm_button.disabled = not stage.can_place_preview()

func open_build_radial_menu() -> void:
	var items: Array[Dictionary] = []
	
	var towers: Array[TowerData] = GameManager.selected_loadouta
	var current_gold: int = GameManager.current_stage.gold if GameManager.current_stage else 999
	
	# Populate menu entries directly from TowerData resources (up to 6 items)
	for tower_data in towers:
		items.append({
			"title": tower_data.display_name,
			"payload": tower_data,
			"icon": tower_data.icon,
			"cost": tower_data.cost,
			"enabled": (current_gold >= tower_data.cost)
		})
	
	var button_center = build_button.global_position + (build_button.size / 2.0)
	radial_menu.open(items, button_center)

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

func _on_radial_item_selected(payload: TowerData) -> void:
	if GameManager.current_stage:
		GameManager.current_stage.enter_placement_mode(payload)

func _on_placement_mode_changed(is_active: bool) -> void:
	placement_buttons.visible = is_active

func _on_cancel_placement_pressed() -> void:
	if GameManager.current_stage:
		GameManager.current_stage.exit_placement_mode()

func _on_confirm_placement_pressed() -> void:
	if GameManager.current_stage:
		GameManager.current_stage.place_preview()
