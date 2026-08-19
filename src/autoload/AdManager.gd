extends Node

## Signals
signal ads_enabled_changed(is_enabled: bool)
signal rewarded_ad_loaded()
signal rewarded_ad_failed_to_load(error_message: String)
signal rewarded_ad_opened()
signal rewarded_ad_closed()
signal rewarded_ad_reward_earned(amount: int)

signal interstitial_ad_loaded()
signal interstitial_ad_failed_to_load(error_message: String)
signal interstitial_ad_opened()
signal interstitial_ad_closed()

## Configuration
## Set to false to disable all ads globally for paid/premium builds.
@export var ads_enabled: bool = true

## Ad Unit IDs (Google AdMob Sample Test IDs)
const ANDROID_REWARDED_AD_UNIT_ID: String = "ca-app-pub-3940256099942544/5224354917"
const IOS_REWARDED_AD_UNIT_ID: String = "ca-app-pub-3940256099942544/1712485313"

const ANDROID_INTERSTITIAL_AD_UNIT_ID: String = "ca-app-pub-3940256099942544/1033173712"
const IOS_INTERSTITIAL_AD_UNIT_ID: String = "ca-app-pub-3940256099942544/4411468910"

const REWARD_CREDITS_AMOUNT: int = 100

## Ad Instances & Callbacks
var _rewarded_ad: RewardedAd = null
var _interstitial_ad: InterstitialAd = null

var _is_loading_rewarded: bool = false
var _is_loading_interstitial: bool = false

var _is_initialized: bool = false

var _reward_listener: OnUserEarnedRewardListener
var _rewarded_load_callback: RewardedAdLoadCallback
var _rewarded_content_callback: FullScreenContentCallback

var _interstitial_load_callback: InterstitialAdLoadCallback
var _interstitial_content_callback: FullScreenContentCallback

var _pending_reward_callback: Callable = Callable()
var _pending_interstitial_callback: Callable = Callable()


func _ready() -> void:
	_setup_listeners()
	SignalBus.stage_completed.connect(_on_stage_completed)
	
	if is_paid_version():
		print("[AdManager] Paid / Premium version active. All ads disabled.")
		return
	
	if is_mobile() or OS.has_feature("editor"):
		_initialize_mobile_ads()
	else:
		_is_initialized = true


func is_paid_version() -> bool:
	if not ads_enabled:
		return true
	if OS.has_feature("premium") or OS.has_feature("ad_free") or OS.has_feature("paid"):
		return true
	if not ProjectSettings.get_setting("admob/general/enabled", true):
		return true
	if SaveManager and SaveManager.has_method("is_ad_free") and SaveManager.is_ad_free():
		return true
	return false


func are_ads_enabled() -> bool:
	return not is_paid_version()


func _initialize_mobile_ads() -> void:
	var on_init_listener := OnInitializationCompleteListener.new()
	on_init_listener.on_initialization_complete = _on_initialization_complete
	print("[AdManager] Initializing MobileAds...")
	MobileAds.initialize(on_init_listener)


func _on_initialization_complete(_status: InitializationStatus) -> void:
	print("[AdManager] MobileAds initialized successfully.")
	_is_initialized = true
	load_rewarded_ad()
	load_interstitial_ad()


func is_mobile() -> bool:
	var os_name := OS.get_name()
	return os_name == "Android" or os_name == "iOS"


func get_rewarded_ad_unit_id() -> String:
	return ANDROID_REWARDED_AD_UNIT_ID if OS.get_name() == "Android" else IOS_REWARDED_AD_UNIT_ID


func get_interstitial_ad_unit_id() -> String:
	return ANDROID_INTERSTITIAL_AD_UNIT_ID if OS.get_name() == "Android" else IOS_INTERSTITIAL_AD_UNIT_ID


func _setup_listeners() -> void:
	# Rewarded listeners
	_reward_listener = OnUserEarnedRewardListener.new()
	_reward_listener.on_user_earned_reward = _on_user_earned_reward
	
	_rewarded_load_callback = RewardedAdLoadCallback.new()
	_rewarded_load_callback.on_ad_loaded = _on_rewarded_ad_loaded
	_rewarded_load_callback.on_ad_failed_to_load = _on_rewarded_ad_failed_to_load
	
	_rewarded_content_callback = FullScreenContentCallback.new()
	_rewarded_content_callback.on_ad_showed_full_screen_content = func() -> void:
		print("[AdManager] Rewarded ad displayed")
		rewarded_ad_opened.emit()
	_rewarded_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
		print("[AdManager] Rewarded ad dismissed")
		_destroy_rewarded_ad()
		rewarded_ad_closed.emit()
		load_rewarded_ad() # Automatically preload the next rewarded ad
	_rewarded_content_callback.on_ad_failed_to_show_full_screen_content = func(err: AdError) -> void:
		print("[AdManager] Rewarded ad failed to show: " + (err.message if err else "unknown"))
		_destroy_rewarded_ad()
		rewarded_ad_closed.emit()
		load_rewarded_ad()
	
	# Interstitial listeners
	_interstitial_load_callback = InterstitialAdLoadCallback.new()
	_interstitial_load_callback.on_ad_loaded = _on_interstitial_ad_loaded
	_interstitial_load_callback.on_ad_failed_to_load = _on_interstitial_ad_failed_to_load
	
	_interstitial_content_callback = FullScreenContentCallback.new()
	_interstitial_content_callback.on_ad_showed_full_screen_content = func() -> void:
		print("[AdManager] Interstitial ad displayed")
		interstitial_ad_opened.emit()
	_interstitial_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
		print("[AdManager] Interstitial ad dismissed")
		_destroy_interstitial_ad()
		interstitial_ad_closed.emit()
		if _pending_interstitial_callback.is_valid():
			_pending_interstitial_callback.call()
			_pending_interstitial_callback = Callable()
		load_interstitial_ad() # Automatically preload the next interstitial ad
	_interstitial_content_callback.on_ad_failed_to_show_full_screen_content = func(err: AdError) -> void:
		print("[AdManager] Interstitial ad failed to show: " + (err.message if err else "unknown"))
		_destroy_interstitial_ad()
		interstitial_ad_closed.emit()
		if _pending_interstitial_callback.is_valid():
			_pending_interstitial_callback.call()
			_pending_interstitial_callback = Callable()
		load_interstitial_ad()


#region Rewarded Ads

func is_rewarded_ad_ready() -> bool:
	if not is_mobile():
		return true # Always ready for simulation on desktop
	return _rewarded_ad != null


func load_rewarded_ad() -> void:
	if not _is_initialized:
		return
	if _is_loading_rewarded or _rewarded_ad != null:
		return
	
	if not is_mobile() and not OS.has_feature("editor"):
		return
	
	_is_loading_rewarded = true
	var unit_id := get_rewarded_ad_unit_id()
	print("[AdManager] Loading rewarded ad (%s)..." % unit_id)
	RewardedAdLoader.new().load(unit_id, AdRequest.new(), _rewarded_load_callback)


func show_rewarded(on_reward_earned: Callable = Callable()) -> bool:
	if not are_ads_enabled():
		print("[AdManager] Cannot show rewarded ad: Ads are disabled.")
		return false
		
	if on_reward_earned.is_valid():
		_pending_reward_callback = on_reward_earned
	
	if is_mobile():
		if _rewarded_ad != null:
			print("[AdManager] Showing rewarded ad...")
			_rewarded_ad.show(_reward_listener)
			return true
		else:
			print("[AdManager] Rewarded ad not ready yet. Preloading...")
			load_rewarded_ad()
			return false
	else:
		# Desktop / Editor fallback: simulate ad watch & grant reward
		print("[AdManager] [Desktop Fallback] Simulating rewarded ad (+%d Credits)" % REWARD_CREDITS_AMOUNT)
		_on_user_earned_reward(null)
		return true


func _on_rewarded_ad_loaded(ad: RewardedAd) -> void:
	_is_loading_rewarded = false
	_rewarded_ad = ad
	_rewarded_ad.full_screen_content_callback = _rewarded_content_callback
	print("[AdManager] Rewarded ad loaded successfully (UID: %s)" % str(ad._uid))
	rewarded_ad_loaded.emit()


func _on_rewarded_ad_failed_to_load(error: LoadAdError) -> void:
	_is_loading_rewarded = false
	_rewarded_ad = null
	var msg := error.message if error else "Unknown error"
	print("[AdManager] Rewarded ad failed to load: %s" % msg)
	rewarded_ad_failed_to_load.emit(msg)


func _on_user_earned_reward(_item: RewardedItem) -> void:
	var reward_amt := REWARD_CREDITS_AMOUNT
	
	print("[AdManager] User earned reward: +%d Credits!" % reward_amt)
	SaveManager.add_credits(reward_amt)
	SignalBus.rewarded_ad_reward_earned.emit(reward_amt)
	rewarded_ad_reward_earned.emit(reward_amt)
	
	if _pending_reward_callback.is_valid():
		_pending_reward_callback.call(reward_amt)
		_pending_reward_callback = Callable()


func _destroy_rewarded_ad() -> void:
	if _rewarded_ad:
		_rewarded_ad.destroy()
		_rewarded_ad = null

#endregion


#region Interstitial Ads

func is_interstitial_ad_ready() -> bool:
	if not is_mobile():
		return true # Always ready for simulation on desktop
	return _interstitial_ad != null


func load_interstitial_ad() -> void:
	if not _is_initialized or not are_ads_enabled():
		return
	if _is_loading_interstitial or _interstitial_ad != null:
		return
	
	if not is_mobile() and not OS.has_feature("editor"):
		return
	
	_is_loading_interstitial = true
	var unit_id := get_interstitial_ad_unit_id()
	print("[AdManager] Loading interstitial ad (%s)..." % unit_id)
	InterstitialAdLoader.new().load(unit_id, AdRequest.new(), _interstitial_load_callback)


func show_interstitial(on_closed: Callable = Callable()) -> bool:
	if not are_ads_enabled():
		if on_closed.is_valid():
			on_closed.call()
		return true
		
	if on_closed.is_valid():
		_pending_interstitial_callback = on_closed
	
	if is_mobile():
		if _interstitial_ad != null:
			print("[AdManager] Showing interstitial ad...")
			_interstitial_ad.show()
			return true
		else:
			print("[AdManager] Interstitial ad not ready yet. Preloading...")
			load_interstitial_ad()
			if _pending_interstitial_callback.is_valid():
				_pending_interstitial_callback.call()
				_pending_interstitial_callback = Callable()
			return false
	else:
		# Desktop / Editor fallback
		print("[AdManager] [Desktop Fallback] Interstitial ad triggered on stage complete")
		if _pending_interstitial_callback.is_valid():
			_pending_interstitial_callback.call()
			_pending_interstitial_callback = Callable()
		return true


func _on_interstitial_ad_loaded(ad: InterstitialAd) -> void:
	_is_loading_interstitial = false
	_interstitial_ad = ad
	_interstitial_ad.full_screen_content_callback = _interstitial_content_callback
	print("[AdManager] Interstitial ad loaded successfully (UID: %s)" % str(ad._uid))
	interstitial_ad_loaded.emit()


func _on_interstitial_ad_failed_to_load(error: LoadAdError) -> void:
	_is_loading_interstitial = false
	_interstitial_ad = null
	var msg := error.message if error else "Unknown error"
	print("[AdManager] Interstitial ad failed to load: %s" % msg)
	interstitial_ad_failed_to_load.emit(msg)


func _destroy_interstitial_ad() -> void:
	if _interstitial_ad:
		_interstitial_ad.destroy()
		_interstitial_ad = null

#endregion


func _on_stage_completed(stage_id: String = "") -> void:
	if not are_ads_enabled():
		return
	if stage_id == "stage_00" or stage_id.begins_with("tutorial"):
		print("[AdManager] Tutorial stage (%s) completed. Skipping interstitial ad." % stage_id)
		return
	print("[AdManager] Stage (%s) completed! Triggering post-stage interstitial ad..." % stage_id)
	show_interstitial()
