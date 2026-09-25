class_name DevCheatMenu extends CanvasLayer

static var instance: DevCheatMenu = null

@onready var status_label: Label = %StatusLabel
@onready var close_button: Button = %CloseButton
@onready var dim_overlay: Panel = %DimOverlay

# Economy buttons
@onready var add_10k_credits_button: Button = %Add10kCreditsButton
@onready var add_100k_credits_button: Button = %Add100kCreditsButton
@onready var max_credits_button: Button = %MaxCreditsButton
@onready var zero_credits_button: Button = %ZeroCreditsButton

# Tower buttons
@onready var unlock_all_towers_button: Button = %UnlockAllTowersButton
@onready var max_all_towers_button: Button = %MaxAllTowersButton

# Stage buttons
@onready var unlock_all_stages_button: Button = %UnlockAllStagesButton
@onready var complete_all_stages_button: Button = %CompleteAllStagesButton
@onready var complete_all_stages_button_2: Button = %CompleteAllStagesButton2
@onready var complete_next_stage_button: Button = %CompleteNextStageButton

# In-Game battle buttons
@onready var add_1k_energy_button: Button = %Add1kEnergyButton
@onready var add_10k_energy_button: Button = %Add10kEnergyButton
@onready var add_50_lives_button: Button = %Add50LivesButton
@onready var kill_enemies_button: Button = %KillEnemiesButton
@onready var win_stage_button: Button = %WinStageButton
@onready var godmode_button: Button = %GodmodeButton
@onready var toggle_flow_field_button: Button = %ToggleFlowFieldButton
@onready var cycle_flow_layer_button: Button = %CycleFlowLayerButton

var is_godmode_active: bool = false
var _previous_pause_state: bool = false

func _ready() -> void:
	instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	add_to_group(GameManager.BACK_CLOSABLE_GROUP)
	
	close_button.pressed.connect(close)
	
	# Economy connections
	add_10k_credits_button.pressed.connect(func():
		SaveManager.cheat_add_credits(10000)
		_notify("Added +10,000 Credits! Total: %d" % SaveManager.get_credits())
	)
	add_100k_credits_button.pressed.connect(func():
		SaveManager.cheat_add_credits(100000)
		_notify("Added +100,000 Credits! Total: %d" % SaveManager.get_credits())
	)
	max_credits_button.pressed.connect(func():
		SaveManager.cheat_set_credits(999999)
		_notify("Set Credits to 999,999 Max!")
	)
	zero_credits_button.pressed.connect(func():
		SaveManager.cheat_set_credits(0)
		_notify("Set Credits to 0.")
	)
	
	# Tower connections
	unlock_all_towers_button.pressed.connect(func():
		SaveManager.cheat_unlock_all_towers()
		_notify("Unlocked all %d towers!" % Registry.TOWERS.size())
	)
	max_all_towers_button.pressed.connect(func():
		SaveManager.cheat_max_all_towers()
		_notify("Maxed all towers to Level 5 + Unlocked all Specializations!")
	)
	
	# Stage connections
	unlock_all_stages_button.pressed.connect(func():
		SaveManager.cheat_unlock_all_stages()
		_notify("Unlocked all %d campaign stages!" % Registry.STAGES.size())
	)
	complete_all_stages_button.pressed.connect(func():
		SaveManager.cheat_complete_all_stages(3)
		_notify("Completed all campaign stages with 3 Stars & High Scores!")
	)
	complete_all_stages_button_2.pressed.connect(func():
		SaveManager.cheat_complete_all_stages(1)
		_notify("Completed all campaign stages with 1 star")
	)
	complete_next_stage_button.pressed.connect(func():
		var stages := Registry.get_all_stages()
		for stage in stages:
			var stage_id := stage.stage_id
			if SaveManager.is_stage_completed(stage_id): continue
			SaveManager.record_stage_clear(stage_id, 10000, stage.starting_lives, stage.starting_lives)
			break
	)
	
	# In-game battle connections
	add_1k_energy_button.pressed.connect(func(): _cheat_add_energy(1000))
	add_10k_energy_button.pressed.connect(func(): _cheat_add_energy(10000))
	add_50_lives_button.pressed.connect(func(): _cheat_add_lives(50))
	kill_enemies_button.pressed.connect(_cheat_kill_all_enemies)
	win_stage_button.pressed.connect(_cheat_win_stage)
	godmode_button.pressed.connect(_cheat_toggle_godmode)
	toggle_flow_field_button.pressed.connect(_cheat_toggle_flow_field)
	cycle_flow_layer_button.pressed.connect(_cheat_cycle_flow_layer)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_F1 or event.keycode == KEY_QUOTELEFT:
			toggle()
			get_viewport().set_input_as_handled()
		elif visible and event.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()

func toggle() -> void:
	if visible:
		close()
	else:
		open()

func open() -> void:
	_previous_pause_state = get_tree().paused
	_update_in_game_button_states()
	_notify("Developer Cheats Ready (F1 / ~ to toggle)")
	show()

func close() -> void:
	hide()
	# Restore pause state if we paused during gameplay
	if not _previous_pause_state and get_tree().paused:
		var pause_menu = get_tree().root.find_child("PauseMenu", true, false)
		if not pause_menu or not pause_menu.visible:
			get_tree().paused = false

func _notify(message: String) -> void:
	if status_label:
		status_label.text = message

func _get_current_stage() -> Stage:
	if GameManager and GameManager.stage_root:
		return GameManager.stage_root.current_stage
	var stage_node = get_tree().root.find_child("Stage", true, false)
	if stage_node is Stage:
		return stage_node
	return null

func _update_in_game_button_states() -> void:
	var stage = _get_current_stage()
	var in_battle = (stage != null and is_instance_valid(stage))
	
	add_1k_energy_button.disabled = not in_battle
	add_10k_energy_button.disabled = not in_battle
	add_50_lives_button.disabled = not in_battle
	kill_enemies_button.disabled = not in_battle
	win_stage_button.disabled = not in_battle
	godmode_button.disabled = not in_battle
	toggle_flow_field_button.disabled = not in_battle
	cycle_flow_layer_button.disabled = not in_battle
	
	if in_battle:
		godmode_button.text = "GODMODE: %s" % ("ON (Infinite Lives)" if is_godmode_active else "OFF")
		godmode_button.theme_type_variation = &"PrimaryButton" if is_godmode_active else &"SecondaryButton"

		if stage and "flow_field_visualizer" in stage and stage.flow_field_visualizer:
			var vis: FlowFieldVisualizer = stage.flow_field_visualizer
			var mode_str = "OFF"
			match vis.mode:
				FlowFieldVisualizer.DisplayMode.ARROWS: mode_str = "ARROWS"
				FlowFieldVisualizer.DisplayMode.HEATMAP_AND_ARROWS: mode_str = "HEATMAP+ARROWS"
				FlowFieldVisualizer.DisplayMode.HEATMAP_ONLY: mode_str = "HEATMAP"

			var layer_str = "PHYS (< 16PX)"
			match vis.current_layer:
				FlowFieldVisualizer.FieldLayer.PHYSICAL_SMALL: layer_str = "PHYS (< 16PX)"
				FlowFieldVisualizer.FieldLayer.PHYSICAL_MEDIUM: layer_str = "PHYS (16-32PX)"
				FlowFieldVisualizer.FieldLayer.PHYSICAL_LARGE: layer_str = "PHYS (32-64PX)"
				FlowFieldVisualizer.FieldLayer.GHOST_SMALL: layer_str = "GHOST (< 16PX)"
				FlowFieldVisualizer.FieldLayer.GHOST_MEDIUM: layer_str = "GHOST (16-32PX)"
				FlowFieldVisualizer.FieldLayer.GHOST_LARGE: layer_str = "GHOST (32-64PX)"

			toggle_flow_field_button.text = "FLOW FIELD: %s" % mode_str
			toggle_flow_field_button.theme_type_variation = &"PrimaryButton" if vis.mode != FlowFieldVisualizer.DisplayMode.OFF else &"SecondaryButton"
			cycle_flow_layer_button.text = "LAYER: %s" % layer_str

func _cheat_toggle_flow_field() -> void:
	var stage = _get_current_stage()
	if stage and "flow_field_visualizer" in stage and stage.flow_field_visualizer:
		stage.flow_field_visualizer.cycle_mode()
		_update_in_game_button_states()
		_notify("Flow Field visualizer mode changed (F2/F3)")

func _cheat_cycle_flow_layer() -> void:
	var stage = _get_current_stage()
	if stage and "flow_field_visualizer" in stage and stage.flow_field_visualizer:
		stage.flow_field_visualizer.cycle_layer()
		_update_in_game_button_states()
		_notify("Flow Field layer changed (F4)")

func _cheat_add_energy(amount: int) -> void:
	var stage = _get_current_stage()
	if stage:
		stage.add_energy(amount)
		_notify("Added +%d Energy! Current: %d" % [amount, stage.energy])
	else:
		_notify("No active battle stage found.")

func _cheat_add_lives(amount: int) -> void:
	var stage = _get_current_stage()
	if stage:
		stage.lives += amount
		SignalBus.lives_changed.emit(stage.lives)
		_notify("Added +%d Lives! Current: %d" % [amount, stage.lives])
	else:
		_notify("No active battle stage found.")

func _cheat_kill_all_enemies() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var count = 0
	for enemy in enemies:
		if is_instance_valid(enemy):
			var hc = ComponentUtil.get_component(enemy, HealthComponent) as HealthComponent
			if hc:
				hc.damage(99999.0, AttackData.DamageType.MAGIC)
				count += 1
	_notify("Eliminated %d active enemies!" % count)

func _cheat_win_stage() -> void:
	var stage = _get_current_stage()
	if stage and stage.wave_manager:
		_cheat_kill_all_enemies()
		SignalBus.stage_completed.emit(stage.data.stage_id if stage.data else "")
		_notify("Triggered Instant Stage Victory!")
		close()
	else:
		_notify("No active battle stage found.")

func _cheat_toggle_godmode() -> void:
	is_godmode_active = not is_godmode_active
	var stage = _get_current_stage()
	if is_godmode_active and stage:
		stage.lives = maxi(stage.lives, 999)
		SignalBus.lives_changed.emit(stage.lives)
	_update_in_game_button_states()
	_notify("Godmode %s!" % ("ENABLED" if is_godmode_active else "DISABLED"))
