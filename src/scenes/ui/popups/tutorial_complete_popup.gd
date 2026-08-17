class_name TutorialCompletePopup extends CanvasLayer

@onready var inventory_button: Button = %InventoryButton
@onready var continue_button: Button = %ContinueButton

func _ready() -> void:
	inventory_button.pressed.connect(_on_inventory_pressed)
	continue_button.pressed.connect(_on_continue_pressed)

func open() -> void:
	show()

func _on_inventory_pressed() -> void:
	GameManager.target_main_menu_tab = 1 # NavBar.Tab.INVENTORY
	GameManager.load_view(GameManager.View.MAIN_MENU)
	close()

func _on_continue_pressed() -> void:
	close()

func close() -> void:
	hide()
	queue_free()
