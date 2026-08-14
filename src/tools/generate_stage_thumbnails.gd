@tool
extends EditorScript

## Run this script in the Godot Script Editor via File -> Run (or Ctrl+Shift+X)
## to batch-generate thumbnails for all stage scenes and assign them to StageData resources.

func _run() -> void:
	var script = preload("res://addons/stage_thumbnail_generator/stage_thumbnail_generator.gd")
	var generator = script.new()
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		tree.root.add_child(generator)
		await generator.generate_all_thumbnails()
		generator.queue_free()
