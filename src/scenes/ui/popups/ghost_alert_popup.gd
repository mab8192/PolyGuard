class_name GhostAlertPopup extends CanvasLayer

@onready var acknowledge_button: Button = %AcknowledgeButton

func _ready() -> void:
	add_to_group(GameManager.BACK_CLOSABLE_GROUP)
	acknowledge_button.pressed.connect(close)

func open() -> void:
	show()

func close() -> void:
	hide()
	queue_free()
