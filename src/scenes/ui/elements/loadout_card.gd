class_name LoadoutCard extends Control

signal card_clicked(card: LoadoutCard)

var tower_data: TowerData = null
var is_equipped: bool = false
var is_card_selected: bool = false
var is_unlocked: bool = true

@onready var bg_panel: Panel = %BGPanel
@onready var icon_rect: TextureRect = %IconRect
@onready var cost_badge: PanelContainer = %CostBadge
@onready var cost_label: Label = %CostLabel
@onready var name_label: Label = %NameLabel
@onready var status_badge: PanelContainer = %StatusBadge
@onready var status_label: Label = %StatusLabel
@onready var locked_overlay: Control = %LockedOverlay
@onready var selection_ring: Panel = %SelectionRing
@onready var click_button: Button = %ClickButton

func _ready() -> void:
	click_button.pressed.connect(func(): card_clicked.emit(self))
	_update_ui()

func setup_as_available(data: TowerData, equipped: bool = false) -> void:
	tower_data = data
	is_equipped = equipped
	if is_inside_tree():
		_update_ui()

func set_card_selected(selected: bool) -> void:
	is_card_selected = selected
	if selection_ring:
		selection_ring.visible = selected

func _update_ui() -> void:
	if not is_inside_tree() or not tower_data:
		return
		
	var t_id = Registry.get_tower_id(tower_data)
	is_unlocked = SaveManager.is_tower_unlocked(t_id)
	
	icon_rect.texture = tower_data.icon
	name_label.text = tower_data.display_name
	cost_label.text = "%d Energy" % tower_data.cost
	
	if selection_ring:
		selection_ring.visible = is_card_selected
		
	if not is_unlocked:
		locked_overlay.show()
		cost_badge.show()
		status_badge.hide()
		name_label.show()
		bg_panel.self_modulate = Color(0.6, 0.6, 0.6, 0.7)
		icon_rect.modulate = Color(0.5, 0.5, 0.5, 0.6)
	elif is_equipped:
		locked_overlay.hide()
		cost_badge.show()
		name_label.hide()
		status_badge.show()
		status_badge.theme_type_variation = &"StatusBadge"
		status_label.text = "EQUIPPED"
		bg_panel.self_modulate = Color(0.4, 0.7, 0.85, 1.0)
		icon_rect.modulate = Color.WHITE
	else:
		locked_overlay.hide()
		cost_badge.show()
		status_badge.hide()
		name_label.show()
		bg_panel.self_modulate = Color.WHITE
		icon_rect.modulate = Color.WHITE
