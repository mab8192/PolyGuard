class_name LoadoutCard extends Control

signal card_clicked(card: LoadoutCard)
signal remove_clicked(card: LoadoutCard)

enum Mode { LOADOUT_SLOT, AVAILABLE_TOWER }

var mode: Mode = Mode.AVAILABLE_TOWER
var tower_data: TowerData = null
var slot_index: int = -1
var is_equipped: bool = false
var is_card_selected: bool = false
var is_empty_slot: bool = false

@onready var bg_panel: Panel = %BGPanel
@onready var content_box: VBoxContainer = %ContentBox
@onready var icon_rect: TextureRect = %IconRect
@onready var name_label: Label = %NameLabel
@onready var cost_badge: PanelContainer = %CostBadge
@onready var cost_label: Label = %CostLabel
@onready var status_badge: PanelContainer = %StatusBadge
@onready var status_label: Label = %StatusLabel
@onready var remove_button: Button = %RemoveButton
@onready var click_button: Button = %ClickButton
@onready var empty_indicator: VBoxContainer = %EmptyIndicator
@onready var empty_slot_label: Label = %EmptySlotLabel
@onready var selection_ring: Panel = %SelectionRing

func _ready() -> void:
	click_button.pressed.connect(_on_click_pressed)
	remove_button.pressed.connect(_on_remove_pressed)
	_update_ui()

func setup_as_slot(index: int, data: TowerData = null) -> void:
	mode = Mode.LOADOUT_SLOT
	slot_index = index
	tower_data = data
	is_empty_slot = (data == null)
	is_equipped = false
	if is_inside_tree():
		_update_ui()

func setup_as_available(data: TowerData, equipped: bool = false) -> void:
	mode = Mode.AVAILABLE_TOWER
	tower_data = data
	is_empty_slot = false
	is_equipped = equipped
	slot_index = -1
	if is_inside_tree():
		_update_ui()

func set_card_selected(selected: bool) -> void:
	is_card_selected = selected
	if selection_ring:
		selection_ring.visible = selected

func _update_ui() -> void:
	if not is_inside_tree():
		return
		
	selection_ring.visible = is_card_selected

	if mode == Mode.LOADOUT_SLOT:
		if is_empty_slot:
			content_box.hide()
			empty_indicator.show()
			empty_slot_label.text = "SLOT %d\n+ EMPTY" % (slot_index + 1)
			remove_button.hide()
			status_badge.hide()
			bg_panel.self_modulate = Color(1, 1, 1, 0.4)
		else:
			content_box.show()
			empty_indicator.hide()
			remove_button.show()
			status_badge.show()
			bg_panel.self_modulate = Color(1, 1, 1, 1.0)
			
			if tower_data:
				var t_id = Registry.get_tower_id(tower_data)
				var lvl = SaveManager.get_tower_level(t_id)
				icon_rect.texture = tower_data.icon
				name_label.text = tower_data.display_name
				cost_label.text = "%dg" % tower_data.cost
				cost_badge.show()
				status_label.text = "LV %d" % lvl
	else:
		# Mode.AVAILABLE_TOWER
		empty_indicator.hide()
		content_box.show()
		remove_button.hide()
		
		if tower_data:
			var t_id = Registry.get_tower_id(tower_data)
			var is_unlocked = SaveManager.is_tower_unlocked(t_id)
			var lvl = SaveManager.get_tower_level(t_id)
			
			icon_rect.texture = tower_data.icon
			name_label.text = tower_data.display_name
			cost_label.text = "%dg" % tower_data.cost
			cost_badge.show()
			
			if not is_unlocked:
				status_badge.show()
				status_badge.theme_type_variation = &"LockedBadge"
				status_label.text = "LOCKED"
				bg_panel.self_modulate = Color(0.5, 0.5, 0.5, 0.6)
				icon_rect.modulate = Color(0.6, 0.6, 0.6, 0.7)
			elif is_equipped:
				status_badge.show()
				status_badge.theme_type_variation = &"StatusBadge"
				status_label.text = "EQUIPPED (LV %d)" % lvl
				bg_panel.self_modulate = Color(0.45, 0.6, 0.7, 0.8)
				icon_rect.modulate = Color(0.7, 0.7, 0.7, 0.8)
			else:
				status_badge.show()
				status_badge.theme_type_variation = &"StatusBadge"
				status_label.text = "LV %d" % lvl
				bg_panel.self_modulate = Color(1, 1, 1, 1.0)
				icon_rect.modulate = Color.WHITE

func _on_click_pressed() -> void:
	card_clicked.emit(self)

func _on_remove_pressed() -> void:
	remove_clicked.emit(self)
