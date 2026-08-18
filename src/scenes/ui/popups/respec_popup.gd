class_name RespecPopup extends CanvasLayer

signal respec_completed(refund_amount: int)

@onready var title_label: Label = %Title
@onready var subtitle_label: Label = %Subtitle
@onready var info_header_label: Label = %InfoHeader
@onready var info_body_label: Label = %InfoBody
@onready var status_badge_label: Label = %StatusBadgeLabel

@onready var paid_vbox: VBoxContainer = %PaidVBox
@onready var paid_confirm_button: Button = %PaidConfirmButton

@onready var free_vbox: VBoxContainer = %FreeVBox
@onready var free_ad_button: Button = %FreeAdButton
@onready var free_fee_button: Button = %FreeFeeButton

@onready var cancel_button: Button = %CancelButton

var _tower_id: String = ""
var _is_global: bool = false
var _spent_credits: int = 0


func _ready() -> void:
	paid_confirm_button.pressed.connect(_on_paid_confirm_pressed)
	free_ad_button.pressed.connect(_on_free_ad_pressed)
	free_fee_button.pressed.connect(_on_free_fee_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)


func open_for_tower(tower_id: String) -> void:
	_tower_id = tower_id
	_is_global = false
	_spent_credits = SaveManager.get_tower_spent_credits(tower_id)
	
	var tower_data := Registry.get_tower_data(tower_id)
	var tower_name := tower_data.display_name.to_upper() if tower_data else tower_id.to_upper()
	var current_level := SaveManager.get_tower_level(tower_id)
	var will_lock: bool = tower_data != null and tower_data.unlock_cost > 0 and not SaveManager.DEFAULT_UNLOCKED_TOWERS.has(tower_id)
	
	title_label.text = "RESPEC %s" % tower_name
	subtitle_label.text = "LEVEL %d • INVESTED: %d CREDITS" % [current_level, _spent_credits]
	info_header_label.text = "REFUND & RESET CONFIRMATION"
	
	if will_lock:
		info_body_label.text = "Resetting %s will lock the tower and refund all unlock, upgrade, and specialization credits spent on it." % tower_name
	else:
		info_body_label.text = "Resetting %s will restore it to Level 1 and lock any purchased specializations. All spent research credits will be refunded." % tower_name
	
	_update_ui()
	show()


func open_for_all() -> void:
	_tower_id = ""
	_is_global = true
	_spent_credits = SaveManager.get_total_spent_credits()
	
	title_label.text = "ARSENAL RESPEC"
	subtitle_label.text = "TOTAL INVESTED: %d CREDITS" % _spent_credits
	info_header_label.text = "COMPLETE ARSENAL RESET"
	info_body_label.text = "Resetting the entire arsenal will relock all purchased towers, restore base/earned towers to Level 1, lock all specializations, and refund your total spent research credits."
	
	_update_ui()
	show()


func _update_ui() -> void:
	var is_paid: bool = AdManager.is_paid_version()
	
	if is_paid:
		status_badge_label.text = "★ PREMIUM STATUS: 100% FREE RESPEC"
		paid_vbox.visible = true
		free_vbox.visible = false
		paid_confirm_button.text = "CONFIRM RESPEC (+%d CREDITS)" % _spent_credits
	else:
		status_badge_label.text = "CHOOSE RESPEC METHOD"
		paid_vbox.visible = false
		free_vbox.visible = true
		
		free_ad_button.text = "WATCH AD (100% REFUND)"
		
		var fee_refund := int(floor(float(_spent_credits) * 0.90))
		var fee_cost := _spent_credits - fee_refund
		free_fee_button.text = "RESPEC WITH 10%% FEE (+%d ¢, %d ¢ FEE)" % [fee_refund, fee_cost]


func _on_paid_confirm_pressed() -> void:
	_execute_respec(true)


func _on_free_ad_pressed() -> void:
	# Show rewarded ad, then grant 100% free refund on completion
	free_ad_button.disabled = true
	var shown = AdManager.show_rewarded(_on_ad_reward_earned)
	if not shown:
		# Fallback if ad failed to show
		free_ad_button.disabled = false


func _on_ad_reward_earned(_amount: int) -> void:
	_execute_respec(true)


func _on_free_fee_pressed() -> void:
	_execute_respec(false)


func _execute_respec(is_free: bool) -> void:
	var result: Dictionary
	if _is_global:
		result = SaveManager.respec_all_towers(is_free)
	else:
		result = SaveManager.respec_tower(_tower_id, is_free)
	
	var refund := int(result.get("refund", 0))
	respec_completed.emit(refund)
	close()


func _on_cancel_pressed() -> void:
	close()


func close() -> void:
	hide()
	queue_free()
