class_name LoadoutSlot extends Control

signal slot_clicked(slot: LoadoutSlot)
signal remove_clicked(slot: LoadoutSlot)

var slot_index: int = 0
var tower_data: TowerData = null
var is_slot_selected: bool = false
var is_empty: bool = true

@onready var bg_panel: Panel = %BGPanel
@onready var empty_box: CenterContainer = %EmptyBox
@onready var empty_label: Label = %EmptyLabel
@onready var content_box: Control = %ContentBox
@onready var icon_rect: TextureRect = %IconRect
@onready var remove_button: Button = %RemoveButton
@onready var selection_ring: Panel = %SelectionRing
@onready var click_button: Button = %ClickButton

func _ready() -> void:
	click_button.pressed.connect(func(): slot_clicked.emit(self))
	remove_button.pressed.connect(func(): remove_clicked.emit(self))
	_update_display()

func setup(index: int, data: TowerData = null) -> void:
	slot_index = index
	tower_data = data
	is_empty = (data == null)
	if is_inside_tree():
		_update_display()

func set_selected(selected: bool) -> void:
	is_slot_selected = selected
	if selection_ring:
		selection_ring.visible = selected

func _update_display() -> void:
	if not is_inside_tree():
		return
	
	if selection_ring:
		selection_ring.visible = is_slot_selected
		
	if is_empty or not tower_data:
		bg_panel.theme_type_variation = &"SlotEmptyPanel"
		empty_box.show()
		empty_label.text = "+"
		content_box.hide()
		remove_button.hide()
	else:
		bg_panel.theme_type_variation = &"SlotEquippedPanel"
		empty_box.hide()
		content_box.show()
		remove_button.show()
		icon_rect.texture = tower_data.icon
