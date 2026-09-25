class_name CreditsPopup extends CanvasLayer

@onready var close_button: Button = %CloseButton
@onready var credits_container: VBoxContainer = %CreditsContainer

## Curated and cross-referenced list of third-party vendor assets actually used in the game.
## The author username corresponds to the directory under res://vendor/
const VENDOR_CREDITS: Array[Dictionary] = [
	{
		"author": "AlexandrZhelanov",
		"type": "Music",
		"assets": "Battle Themes 1, 2, 3, 4, and 5",
		"notes": "Stage combat encounter soundtracks"
	},
	{
		"author": "celestialghost8",
		"type": "Sound Effects",
		"assets": "Victory Fanfare",
		"notes": "Stage victory audio"
	},
	{
		"author": "DeusLower",
		"type": "Music",
		"assets": "Medieval Ambient Track",
		"notes": "Main menu background music"
	},
	{
		"author": "Kenney",
		"type": "Icons",
		"assets": "Game Icons Pack",
		"notes": "Interface, settings, navigation bar, controls, and tutorial icons"
	},
	{
		"author": "mrpoly",
		"type": "Music",
		"assets": "Awesomeness Theme",
		"notes": "Main menu background music"
	},
	{
		"author": "phoenix1291",
		"type": "Sound Effects",
		"assets": "The Ultimate 2017 16-Bit Mini Pack",
		"notes": "Explosions, enemy escapes, tower placement, and tower hit sounds"
	},
	{
		"author": "Severin Meyer",
		"type": "Typography",
		"assets": "Oxanium Font Family",
		"notes": "Primary game typography used across all UI, HUD, and menus"
	},
	{
		"author": "Zefz",
		"type": "Music",
		"assets": "The Looming Battle",
		"notes": "Inter-wave preparation and building phase soundtrack"
	}
]

func _ready() -> void:
	hide()
	add_to_group(GameManager.BACK_CLOSABLE_GROUP)
	close_button.pressed.connect(close)
	_populate_credits()

func open() -> void:
	show()

func close() -> void:
	hide()

func _populate_credits() -> void:
	if not credits_container:
		return
		
	for child in credits_container.get_children():
		child.queue_free()

	for cred in VENDOR_CREDITS:
		_create_credit_card(cred["author"], cred["type"], cred["assets"], cred.get("notes", ""))

func _create_credit_card(author_name: String, asset_type: String, asset_details: String, notes: String) -> void:
	var card = PanelContainer.new()
	card.theme_type_variation = &"CardPanel"
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	card.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)
	
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(header_hbox)
	
	var author_label = Label.new()
	author_label.theme_type_variation = &"TitleText"
	author_label.text = author_name
	author_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(author_label)
	
	var type_badge = PanelContainer.new()
	type_badge.theme_type_variation = &"TypeBadge"
	type_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var type_label = Label.new()
	type_label.theme_type_variation = &"BadgeText"
	type_label.text = asset_type
	type_badge.add_child(type_label)
	header_hbox.add_child(type_badge)
	
	var details_label = Label.new()
	details_label.theme_type_variation = &"BodyText"
	details_label.text = asset_details
	details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(details_label)
	
	if not notes.is_empty():
		var notes_label = Label.new()
		notes_label.theme_type_variation = &"SmallText"
		notes_label.text = notes
		notes_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(notes_label)
		
	credits_container.add_child(card)
