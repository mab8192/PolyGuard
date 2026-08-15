class_name SafeAreaMarginContainer extends MarginContainer

@export var apply_left: bool = true
@export var apply_top: bool = true
@export var apply_right: bool = true
@export var apply_bottom: bool = true

@export var min_margin_left: int = 32
@export var min_margin_top: int = 24
@export var min_margin_right: int = 32
@export var min_margin_bottom: int = 24

func _ready() -> void:
	# Capture initial scene constants if defined and not set by export
	if has_theme_constant_override("margin_left"):
		min_margin_left = get_theme_constant("margin_left")
	if has_theme_constant_override("margin_top"):
		min_margin_top = get_theme_constant("margin_top")
	if has_theme_constant_override("margin_right"):
		min_margin_right = get_theme_constant("margin_right")
	if has_theme_constant_override("margin_bottom"):
		min_margin_bottom = get_theme_constant("margin_bottom")
		
	update_safe_area()
	if get_viewport():
		get_viewport().size_changed.connect(update_safe_area)

func update_safe_area() -> void:
	if not is_inside_tree():
		return
		
	# On non-mobile platforms (desktop/editor/web), DisplayServer.get_display_safe_area()
	# returns global virtual desktop bounds which offsets windowed rendering.
	if not OS.has_feature("mobile"):
		_apply_margins(min_margin_left, min_margin_top, min_margin_right, min_margin_bottom)
		return
		
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	var screen_size: Vector2i = DisplayServer.screen_get_size()
	
	if screen_size.x <= 0 or screen_size.y <= 0 or safe_area.size.x <= 0 or safe_area.size.y <= 0:
		_apply_margins(min_margin_left, min_margin_top, min_margin_right, min_margin_bottom)
		return
	
	var vp = get_viewport()
	var viewport_size: Vector2 = vp.get_visible_rect().size if vp else Vector2(1080, 1920)
	var scale_x: float = viewport_size.x / float(screen_size.x)
	var scale_y: float = viewport_size.y / float(screen_size.y)
	
	var safe_top: int = int(round(safe_area.position.y * scale_y))
	var safe_left: int = int(round(safe_area.position.x * scale_x))
	var safe_right: int = int(round((screen_size.x - safe_area.end.x) * scale_x))
	var safe_bottom: int = int(round((screen_size.y - safe_area.end.y) * scale_y))
	
	# Sanity clamp to prevent runaway margins on unconventional screen reports
	safe_top = clampi(safe_top, 0, int(viewport_size.y * 0.25))
	safe_bottom = clampi(safe_bottom, 0, int(viewport_size.y * 0.25))
	safe_left = clampi(safe_left, 0, int(viewport_size.x * 0.25))
	safe_right = clampi(safe_right, 0, int(viewport_size.x * 0.25))
	
	var final_left = maxi(min_margin_left, safe_left) if apply_left else min_margin_left
	var final_top = maxi(min_margin_top, safe_top) if apply_top else min_margin_top
	var final_right = maxi(min_margin_right, safe_right) if apply_right else min_margin_right
	var final_bottom = maxi(min_margin_bottom, safe_bottom) if apply_bottom else min_margin_bottom
	
	_apply_margins(final_left, final_top, final_right, final_bottom)

func _apply_margins(l: int, t: int, r: int, b: int) -> void:
	add_theme_constant_override("margin_left", l)
	add_theme_constant_override("margin_top", t)
	add_theme_constant_override("margin_right", r)
	add_theme_constant_override("margin_bottom", b)
