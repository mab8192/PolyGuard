class_name NavBar extends Panel

enum Tab { CAMPAIGN, INVENTORY, CODEX, SETTINGS }

signal tab_select(tab: Tab)

const ACTIVE_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)
const INACTIVE_COLOR: Color = Color(1.0, 1.0, 1.0, 0.4)

const Y_UNSELECTED: float = 44.0
const Y_SELECTED: float = 14.0

@onready var campaign_button: TextureButton = %CampaignButton
@onready var campaign_label: Label = %CampaignLabel
@onready var campaign_arrow_left: TextureRect = %CampaignArrowLeft
@onready var campaign_arrow_right: TextureRect = %CampaignArrowRight

@onready var inventory_button: TextureButton = %InventoryButton
@onready var inventory_label: Label = %InventoryLabel
@onready var inventory_arrow_right: TextureRect = %InventoryArrowRight

@onready var codex_button: TextureButton = %CodexButton
@onready var codex_label: Label = %CodexLabel
@onready var codex_arrow_left: TextureRect = %CodexArrowLeft

@onready var _selected: BaseButton = campaign_button

var _tabs: Dictionary = {}
var _tweens: Dictionary = {}

func _ready() -> void:
	_tabs = {
		campaign_button: {
			"tab": Tab.CAMPAIGN,
			"button": campaign_button,
			"label": campaign_label,
			"arrow_left": campaign_arrow_left,
			"arrow_right": campaign_arrow_right
		},
		inventory_button: {
			"tab": Tab.INVENTORY,
			"button": inventory_button,
			"label": inventory_label,
			"arrow_left": null,
			"arrow_right": inventory_arrow_right
		},
		codex_button: {
			"tab": Tab.CODEX,
			"button": codex_button,
			"label": codex_label,
			"arrow_left": codex_arrow_left,
			"arrow_right": null
		}
	}
	
	for btn in _tabs.keys():
		var button := btn as TextureButton
		button.pivot_offset = button.custom_minimum_size / 2.0
		button.pressed.connect(func(): _on_select(button))
	
	_update_style(false)

func _on_select(btn: BaseButton) -> void:
	if btn == _selected:
		return
	
	var tab_info: Dictionary = _tabs.get(btn, {})
	var tab: Tab = tab_info.get("tab", Tab.CAMPAIGN)
	
	_selected = btn
	_update_style(true)
	tab_select.emit(tab)

func _update_style(animate: bool = true) -> void:
	for entry in _tabs.values():
		var btn: TextureButton = entry.button
		var lbl: Label = entry.label
		var arrow_l: TextureRect = entry.arrow_left
		var arrow_r: TextureRect = entry.arrow_right
		var is_active: bool = (btn == _selected)
		
		# Stop existing tween
		if _tweens.has(btn) and _tweens[btn].is_valid():
			_tweens[btn].kill()
		
		if not animate:
			btn.scale = Vector2.ONE
			if is_active:
				btn.position.y = Y_SELECTED
				btn.modulate = ACTIVE_COLOR
				lbl.show()
				lbl.modulate = ACTIVE_COLOR
				if arrow_l:
					arrow_l.show()
					arrow_l.modulate = ACTIVE_COLOR
				if arrow_r:
					arrow_r.show()
					arrow_r.modulate = ACTIVE_COLOR
			else:
				btn.position.y = Y_UNSELECTED
				btn.modulate = INACTIVE_COLOR
				lbl.hide()
				if arrow_l:
					arrow_l.hide()
				if arrow_r:
					arrow_r.hide()
			continue
		
		var tween := create_tween().set_parallel(true)
		_tweens[btn] = tween
		
		if is_active:
			btn.scale = Vector2.ONE
			if arrow_l:
				arrow_l.show()
				arrow_l.modulate = Color(1.0, 1.0, 1.0, 0.0)
				tween.tween_property(arrow_l, "modulate:a", 1.0, 0.2)
			if arrow_r:
				arrow_r.show()
				arrow_r.modulate = Color(1.0, 1.0, 1.0, 0.0)
				tween.tween_property(arrow_r, "modulate:a", 1.0, 0.2)
			
			lbl.show()
			lbl.modulate = Color(1.0, 1.0, 1.0, 0.0)
			tween.tween_property(lbl, "modulate:a", 1.0, 0.2)
			
			# Animate icon button smoothly moving UP to make room for text
			tween.tween_property(btn, "position:y", Y_SELECTED, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(btn, "modulate", ACTIVE_COLOR, 0.2).set_ease(Tween.EASE_OUT)
		else:
			# Animate icon button smoothly moving DOWN to center
			btn.scale = Vector2.ONE
			tween.tween_property(btn, "position:y", Y_UNSELECTED, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(btn, "modulate", INACTIVE_COLOR, 0.2).set_ease(Tween.EASE_OUT)
			
			if arrow_l:
				tween.tween_property(arrow_l, "modulate:a", 0.0, 0.15)
			if arrow_r:
				tween.tween_property(arrow_r, "modulate:a", 0.0, 0.15)
			tween.tween_property(lbl, "modulate:a", 0.0, 0.15)
			
			# Hide elements after fade-out finishes
			var captured_l := arrow_l
			var captured_r := arrow_r
			var captured_lbl := lbl
			var captured_btn := btn
			tween.chain().tween_callback(func():
				if captured_btn != _selected:
					if captured_l: captured_l.hide()
					if captured_r: captured_r.hide()
					captured_lbl.hide()
			)
