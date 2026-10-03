extends Node

## One-time Play product. Must match the product id in Play Console.
const PRODUCT_ID := "remove_ads"
const CACHE_PATH := "user://premium.cfg"
const LAUNCH_QUERY_TIMEOUT_SEC := 12.0

## Fired once, when this launch first decides premium or not.
signal entitlement_resolved(is_premium: bool)
## Fired when premium changes after the launch decision.
signal entitlement_changed(is_premium: bool)
## Price, error text, or busy state changed.
signal store_state_changed

var is_premium: bool = false
var entitlement_known: bool = false
var price_text: String = ""
var status_message: String = ""
var purchase_busy: bool = false

var _billing: BillingClient
var _purchase_option_id: String = ""
var _product_loaded: bool = false
var _acknowledged_tokens: Dictionary = {}


func _ready() -> void:
	if _has_feature_override():
		print("[PurchaseManager] Export feature override. Premium forced on.")
		_set_premium(true)
		return
	if not is_store_supported():
		_set_premium(_read_cached_owned())
		return
	_billing = BillingClient.new()
	add_child(_billing)
	_billing.connected.connect(_on_connected)
	_billing.disconnected.connect(_on_disconnected)
	_billing.connect_error.connect(_on_connect_error)
	_billing.query_product_details_response.connect(_on_product_details)
	_billing.query_purchases_response.connect(_on_query_purchases)
	_billing.on_purchase_updated.connect(_on_purchase_updated)
	_billing.acknowledge_purchase_response.connect(_on_acknowledge_response)
	_billing.start_connection()
	get_tree().create_timer(LAUNCH_QUERY_TIMEOUT_SEC).timeout.connect(_on_launch_timeout)


func is_store_supported() -> bool:
	return OS.get_name() == "Android" and Engine.has_singleton("GodotGooglePlayBilling")


func is_store_ready() -> bool:
	return _billing != null and _billing.is_ready()


func can_debug_toggle() -> bool:
	return OS.is_debug_build() and not is_store_supported()


func purchase_remove_ads() -> void:
	if is_premium or purchase_busy:
		return
	if not is_store_ready():
		_set_status("The store is unavailable.")
		return
	if not _product_loaded:
		_set_status("The store is still loading. Try again in a moment.")
		_query_store()
		return
	purchase_busy = true
	store_state_changed.emit()
	var result := _billing.purchase(PRODUCT_ID, _purchase_option_id)
	if result.has("response_code") and int(result["response_code"]) != BillingClient.BillingResponseCode.OK:
		purchase_busy = false
		_set_status(_message_for_code(int(result["response_code"])))
		print("[PurchaseManager] purchase() rejected: ", result)


func restore_purchases() -> void:
	if is_premium or purchase_busy:
		return
	if not is_store_ready():
		_set_status("The store is unavailable.")
		return
	_set_status("Checking purchases...")
	_billing.query_purchases(BillingClient.ProductType.INAPP)


func debug_toggle_premium() -> void:
	if not can_debug_toggle():
		return
	_write_cache(not is_premium)
	_set_premium(not is_premium)


func _has_feature_override() -> bool:
	return (
		OS.has_feature("premium")
		or OS.has_feature("ad_free")
		or OS.has_feature("paid")
	)


func _on_connected() -> void:
	print("[PurchaseManager] Billing connected.")
	_query_store()


func _on_disconnected() -> void:
	print("[PurchaseManager] Billing disconnected.")


func _on_connect_error(response_code: int, debug_message: String) -> void:
	print("[PurchaseManager] Billing connect error %s: %s" % [response_code, debug_message])
	if not entitlement_known:
		_set_premium(_read_cached_owned())
	_set_status("The store is unavailable.")


func _on_launch_timeout() -> void:
	if entitlement_known:
		return
	print("[PurchaseManager] Billing check timed out. Using the last verified purchase.")
	_set_premium(_read_cached_owned())


func _query_store() -> void:
	if not is_store_ready():
		return
	_billing.query_product_details(PackedStringArray([PRODUCT_ID]), BillingClient.ProductType.INAPP)
	_billing.query_purchases(BillingClient.ProductType.INAPP)


func _on_product_details(response: Dictionary) -> void:
	var code := int(response.get("response_code", -1))
	if code != BillingClient.BillingResponseCode.OK:
		print("[PurchaseManager] Product details failed: ", response.get("debug_message", ""))
		return
	var details: Variant = response.get("product_details", [])
	if not (details is Array):
		return
	for product in details:
		if not product is Dictionary:
			continue
		if str(product.get("product_id", "")) != PRODUCT_ID:
			continue
		var offers: Variant = product.get("one_time_purchase_offer_details_list", [])
		if offers is Array and not offers.is_empty() and offers[0] is Dictionary:
			price_text = str(offers[0].get("formatted_price", ""))
			_purchase_option_id = str(offers[0].get("purchase_option_id", ""))
		_product_loaded = true
		store_state_changed.emit()
		return
	print("[PurchaseManager] remove_ads was not returned by Play. Unfetched: ", response.get("unfetched_products", []))


func _on_query_purchases(response: Dictionary) -> void:
	var code := int(response.get("response_code", -1))
	if code != BillingClient.BillingResponseCode.OK:
		print("[PurchaseManager] Purchase query failed: ", response.get("debug_message", ""))
		if not entitlement_known:
			_set_premium(_read_cached_owned())
		if status_message == "Checking purchases...":
			_set_status(_message_for_code(code))
		return
	var owned := false
	var purchases: Variant = response.get("purchases", [])
	if purchases is Array:
		for purchase in purchases:
			if purchase is Dictionary and _is_owned_remove_ads(purchase):
				owned = true
				_acknowledge_if_needed(purchase)
	# A successful query is the authority, including a refund that drops the product.
	_write_cache(owned)
	_set_premium(owned)
	if owned:
		_set_status("")
	elif status_message == "Checking purchases...":
		_set_status("No purchase found for this account.")


func _on_purchase_updated(response: Dictionary) -> void:
	purchase_busy = false
	var code := int(response.get("response_code", -1))
	if code == BillingClient.BillingResponseCode.OK:
		var granted := false
		var purchases: Variant = response.get("purchases", [])
		if purchases is Array:
			for purchase in purchases:
				if purchase is Dictionary and _is_owned_remove_ads(purchase):
					granted = true
					_acknowledge_if_needed(purchase)
		if granted:
			_write_cache(true)
			_set_premium(true)
			_set_status("")
		elif is_store_ready():
			_billing.query_purchases(BillingClient.ProductType.INAPP)
		store_state_changed.emit()
		return
	if code == BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED:
		_set_status("")
		if is_store_ready():
			_billing.query_purchases(BillingClient.ProductType.INAPP)
		return
	print("[PurchaseManager] Purchase update %s: %s" % [code, response.get("debug_message", "")])
	_set_status(_message_for_code(code))


func _on_acknowledge_response(response: Dictionary) -> void:
	var code := int(response.get("response_code", -1))
	if code != BillingClient.BillingResponseCode.OK:
		var token := str(response.get("token", ""))
		_acknowledged_tokens.erase(token)
		print("[PurchaseManager] Acknowledge failed: ", response.get("debug_message", ""))


func _is_owned_remove_ads(purchase: Dictionary) -> bool:
	if int(purchase.get("purchase_state", -1)) != BillingClient.PurchaseState.PURCHASED:
		return false
	var ids: Variant = purchase.get("product_ids", [])
	if not (ids is Array) and not (ids is PackedStringArray):
		return false
	for product_id in ids:
		if str(product_id) == PRODUCT_ID:
			return true
	return false


func _acknowledge_if_needed(purchase: Dictionary) -> void:
	if bool(purchase.get("is_acknowledged", false)):
		return
	var token := str(purchase.get("purchase_token", ""))
	if token.is_empty() or _acknowledged_tokens.has(token) or _billing == null:
		return
	_acknowledged_tokens[token] = true
	print("[PurchaseManager] Acknowledging remove_ads purchase.")
	_billing.acknowledge_purchase(token)


func _set_premium(owned: bool) -> void:
	var changed := is_premium != owned
	is_premium = owned
	if not entitlement_known:
		entitlement_known = true
		entitlement_resolved.emit(is_premium)
	elif changed:
		entitlement_changed.emit(is_premium)
	if changed:
		print("[PurchaseManager] Premium is now %s." % is_premium)
	store_state_changed.emit()


func _set_status(message: String) -> void:
	status_message = message
	store_state_changed.emit()


func _message_for_code(code: int) -> String:
	match code:
		BillingClient.BillingResponseCode.USER_CANCELED:
			return "Purchase canceled."
		BillingClient.BillingResponseCode.ITEM_UNAVAILABLE:
			return "This item isn't available yet. Install the game from Play and try again later."
		BillingClient.BillingResponseCode.SERVICE_UNAVAILABLE, \
		BillingClient.BillingResponseCode.BILLING_UNAVAILABLE, \
		BillingClient.BillingResponseCode.NETWORK_ERROR, \
		BillingClient.BillingResponseCode.SERVICE_DISCONNECTED, \
		BillingClient.BillingResponseCode.SERVICE_TIMEOUT:
			return "The store is unavailable."
		_:
			return "Purchase failed. Try again."


func _read_cached_owned() -> bool:
	var config := ConfigFile.new()
	if config.load(CACHE_PATH) != OK:
		return false
	return bool(config.get_value("entitlement", "owned", false))


func _write_cache(owned: bool) -> void:
	var config := ConfigFile.new()
	config.set_value("entitlement", "owned", owned)
	config.set_value("entitlement", "verified_unix", int(Time.get_unix_time_from_system()))
	config.save(CACHE_PATH)
