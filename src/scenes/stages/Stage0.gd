class_name Stage0 extends Stage

const TUTORIAL_OVERLAY_SCENE: PackedScene = preload("res://src/scenes/ui/in_game/tutorial_overlay.tscn")

var _tutorial_overlay: TutorialOverlay = null

func _ready() -> void:
	super._ready()
	_setup_tutorial()

func _setup_tutorial() -> void:
	_tutorial_overlay = TUTORIAL_OVERLAY_SCENE.instantiate() as TutorialOverlay
	add_child(_tutorial_overlay)
	_tutorial_overlay.open()
