class_name TutorialOverlay extends CanvasLayer

signal tutorial_completed()

const ICON_LIVES = preload("res://src/textures/icons/lives.png")
const ICON_ENERGY = preload("res://src/textures/icons/energy.png")
const ICON_BUILD = preload("res://src/textures/icons/build.png")
const ICON_STAR = preload("res://vendor/Kenney/Kenney_gameIcons/PNG/White/2x/star.png")
const ICON_CHECK = preload("res://vendor/Kenney/Kenney_gameIcons/PNG/White/2x/checkmark.png")
const ICON_ROTATE = preload("res://vendor/Kenney/Kenney_gameIcons/PNG/White/2x/return.png")
const ICON_TRASH = preload("res://vendor/Kenney/Kenney_gameIcons/PNG/White/2x/trashcan.png")
const ICON_ARCHER = preload("res://src/textures/towers/archer_tower.png")
const ICON_TAR = preload("res://src/textures/towers/tar_trap.png")
const ICON_SPIKE = preload("res://src/textures/towers/spike_trap.png")
const ICON_SPAWNER = preload("res://src/textures/utility/spawner.png")
const ICON_EXIT = preload("res://src/textures/utility/exit.png")

@onready var overlay_panel: Panel = %OverlayBackground
@onready var modal_container: PanelContainer = %ModalContainer
@onready var category_badge: Label = %CategoryBadge
@onready var title_label: Label = %TitleLabel
@onready var items_container: VBoxContainer = %ItemsContainer
@onready var tip_label: Label = %TipLabel
@onready var prev_button: Button = %PrevButton
@onready var next_button: Button = %NextButton
@onready var skip_button: Button = %SkipButton

var current_page: int = 0

const TUTORIAL_PAGES: Array[Dictionary] = [
	{
		"category": "COMMAND HUD",
		"title": "LIVES & ENERGY ECONOMY",
		"items": [
			{
				"icon": ICON_LIVES,
				"modulate": Color(1.0, 0.35, 0.45),
				"headline": "LIVES",
				"body": "Located in the top bar. If enemies escape through the exit and lives drop to 0, the stage is lost. Some enemies reduce this by more than 1 if they get through!"
			},
			{
				"icon": ICON_ENERGY,
				"modulate": Color(0.0, 0.95, 0.9),
				"headline": "ENERGY",
				"body": "Your construction currency. Used to build towers and place traps. You start with energy at the beginning of each stage and earn bonuses between waves."
			}
		],
		"tip": "Tip: Killing enemies gives you additional energy. Plan ahead!"
	},
	{
		"category": "BATTLEFIELD",
		"title": "SPAWNERS & EXITS",
		"items": [
			{
				"icon": ICON_SPAWNER,
				"headline": "ENEMY SPAWNERS",
				"body": "Red portal zones on the perimeter where enemy waves appear. Active spawners pulse with an 'INCOMING' badge showing where attacks originate. Enemies chart their paths from here."
			},
			{
				"icon": ICON_EXIT,
				"headline": "DEFENSE EXITS",
				"body": "Cyan glowing portal zones that enemies march toward. If an enemy reaches an active exit, they escape and deplete your Lives. Defend all active exits to survive!"
			}
		],
		"tip": "Tip: Solid towers redirect enemy routes from spawners to exits. Build winding mazes to give your towers more time to attack!"
	},
	{
		"category": "ARMORY",
		"title": "STARTING DEFENSES",
		"items": [
			{
				"icon": ICON_ARCHER,
				"headline": "ARCHER TOWER",
				"body": "Fires swift single-target arrows at physical ground enemies. Solid towers block walking paths, letting you guide enemy movement."
			},
			{
				"icon": ICON_TAR,
				"headline": "TAR TRAP",
				"body": "A floor trap that coats passing ground enemies in thick tar, slowing them so nearby towers can land more attacks."
			},
			{
				"icon": ICON_SPIKE,
				"headline": "SPIKE TRAP",
				"body": "A floor trap that arms and impales enemies walking above it, dealing high instant physical burst damage to all targets on the trap."
			}
		],
		"tip": "Tip: Place Tar Traps right before Spike Traps to bunch enemies up into lethal burst zones!"
	},
	{
		"category": "STAR RATING",
		"title": "STARS & CREDITS",
		"items": [
			{
				"icon": ICON_STAR,
				"modulate": Color(1.0, 0.85, 0.25),
				"headline": "STAR THRESHOLDS",
				"body": "• 3 Stars: Flawless defense with all of your base lives intact.\n• 2 Stars: Solid defense with 50%+ base lives remaining.\n• 1 Star: Successfully repelling all waves with at least 1 life."
			},
			{
				"icon": ICON_ENERGY,
				"headline": "CREDIT REWARDS",
				"body": "Each newly achieved star awards +100 Credits, plus +300 Credits on your initial stage clear. Spend credits in the Armory to unlock new towers and permanent specialization branches."
			}
		],
		"tip": "Tip: Star bonuses are one-time awards. Beating previously-cleared stages awards +50 credits."
	},
	{
		"category": "BUILDING TOWERS",
		"title": "BUILDING & PLACING TOWERS",
		"items": [
			{
				"icon": ICON_BUILD,
				"headline": "RADIAL LOADOUT WHEEL",
				"body": "Tap the BUILD button at the bottom center to open your equipped tower selection wheel. Selecting any tower enters real-time placement mode."
			},
			{
				"icon": ICON_CHECK,
				"modulate": Color(0.3, 1.0, 0.4),
				"headline": "POSITIONING & CONFIRMATION",
				"body": "Drag or tap anywhere on the battlefield grid to move the preview.\n• Green: Valid placement zone.\n• Red: Obstructed (cannot block spawners, exits, or existing walls).\nTap the Checkmark (✓) to build, or Rotate (↺) for directional towers."
			}
		],
		"tip": "Tip: Solid towers alter enemy pathfinding. Build winding chokepoints to maximize range!"
	},
	{
		"category": "SELLING TOWERS",
		"title": "SELECTING & SELLING TOWERS",
		"items": [
			{
				"icon": ICON_ARCHER,
				"headline": "INSPECTING TOWER ATTRIBUTES",
				"body": "Tap or click any constructed tower on the map to open the Tower Action Panel. View DPS, attack cooldown, current durability, and more!"
			},
			{
				"icon": ICON_TRASH,
				"modulate": Color(1.0, 0.4, 0.3),
				"headline": "50% ENERGY REFUND",
				"body": "Need to reshape your chokepoint or pivot to magic weapons? Tap the SELL button in the action panel to dismantle the tower and instantly recover 50% of its cost."
			}
		],
		"tip": "Tip: Selling allows you to dynamically adapt your defense when armored or ghost enemies appear!"
	}
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	skip_button.pressed.connect(_on_skip_pressed)
	_show_page(0)

func open() -> void:
	show()
	_show_page(0)

func close() -> void:
	hide()
	tutorial_completed.emit()

func _show_page(index: int) -> void:
	current_page = clampi(index, 0, TUTORIAL_PAGES.size() - 1)
	var data: Dictionary = TUTORIAL_PAGES[current_page]
	
	if category_badge:
		category_badge.text = data["category"]
	if title_label:
		title_label.text = data["title"]
	if tip_label:
		tip_label.text = data["tip"]
	
	# Render structured item blocks with real icons
	_render_items(data.get("items", []))
	
	if prev_button:
		prev_button.disabled = (current_page == 0)
		prev_button.text = "← BACK"
	if next_button:
		if current_page == TUTORIAL_PAGES.size() - 1:
			next_button.text = "START DEFENDING"
			next_button.theme_type_variation = &"PrimaryButton"
		else:
			next_button.text = "NEXT →"
			next_button.theme_type_variation = &"PrimaryButton"

func _render_items(items: Array) -> void:
	for child in items_container.get_children():
		child.queue_free()
	
	for item in items:
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(840, 0)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.theme_type_variation = &"CardPanel"
		items_container.add_child(card)
		
		var card_margin = MarginContainer.new()
		var card_v_margin = 12 if items.size() > 2 else 18
		card_margin.add_theme_constant_override("margin_left", 20)
		card_margin.add_theme_constant_override("margin_top", card_v_margin)
		card_margin.add_theme_constant_override("margin_right", 20)
		card_margin.add_theme_constant_override("margin_bottom", card_v_margin)
		card.add_child(card_margin)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 22)
		card_margin.add_child(hbox)
		
		# Icon Badge
		var icon_badge = PanelContainer.new()
		icon_badge.custom_minimum_size = Vector2(72, 72)
		icon_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon_badge.theme_type_variation = &"DetailPanel"
		hbox.add_child(icon_badge)
		
		var icon_margin = MarginContainer.new()
		icon_margin.add_theme_constant_override("margin_left", 8)
		icon_margin.add_theme_constant_override("margin_top", 8)
		icon_margin.add_theme_constant_override("margin_right", 8)
		icon_margin.add_theme_constant_override("margin_bottom", 8)
		icon_badge.add_child(icon_margin)
		
		var tex_rect = TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(48, 48)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.texture = item.get("icon", null)
		tex_rect.modulate = item.get("modulate", Color.WHITE)
		icon_margin.add_child(tex_rect)
		
		# Text VBox
		var text_vbox = VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_vbox.custom_minimum_size = Vector2(680, 0)
		text_vbox.add_theme_constant_override("separation", 6)
		hbox.add_child(text_vbox)
		
		var head_label = Label.new()
		head_label.theme_type_variation = &"SubHeaderText"
		head_label.custom_minimum_size = Vector2(680, 0)
		head_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		head_label.text = item.get("headline", "")
		text_vbox.add_child(head_label)
		
		var desc_label = Label.new()
		desc_label.theme_type_variation = &"BodyText"
		desc_label.custom_minimum_size = Vector2(680, 0)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.text = item.get("body", "")
		text_vbox.add_child(desc_label)

func _on_prev_pressed() -> void:
	if current_page > 0:
		_show_page(current_page - 1)

func _on_next_pressed() -> void:
	if current_page < TUTORIAL_PAGES.size() - 1:
		_show_page(current_page + 1)
	else:
		close()

func _on_skip_pressed() -> void:
	close()
