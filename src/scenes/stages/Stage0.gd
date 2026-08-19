class_name Stage0 extends Stage

const TUTORIAL_OVERLAY_SCENE: PackedScene = preload("res://src/scenes/ui/in_game/tutorial_overlay.tscn")

var _tutorial_overlay: TutorialOverlay = null

func _ready() -> void:
	super._ready()
	_setup_tutorial()
	_spawn_initial_sample_tower()

func _setup_tutorial() -> void:
	_tutorial_overlay = TUTORIAL_OVERLAY_SCENE.instantiate() as TutorialOverlay
	add_child(_tutorial_overlay)
	_tutorial_overlay.open()

func _spawn_initial_sample_tower() -> void:
	# Pre-place an initial Archer Tower so the player can immediately inspect and test selling
	var archer_data = Registry.get_tower_data("archer_tower")
	if archer_data and towers:
		var initial_tower: Tower = archer_data.create(false)
		if initial_tower:
			towers.add_child(initial_tower)
			initial_tower.global_position = Vector2(0, 160)
			if flow_field_manager:
				flow_field_manager.rebuild_tower_fields()
