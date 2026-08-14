@tool
extends EditorPlugin

const OUTPUT_DIR := "res://src/textures/stages/"
const STAGES_DIR := "res://src/data/stages/"
const THUMBNAIL_WIDTH := 640
const THUMBNAIL_HEIGHT := 400

func _enter_tree() -> void:
	add_tool_menu_item("Generate Stage Thumbnails", _on_generate_thumbnails)

func _exit_tree() -> void:
	remove_tool_menu_item("Generate Stage Thumbnails")

func _on_generate_thumbnails() -> void:
	generate_all_thumbnails()

func generate_all_thumbnails() -> void:
	print("[StageThumbnailGenerator] Starting batch thumbnail generation...")
	
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	var dir := DirAccess.open(STAGES_DIR)
	if not dir:
		printerr("[StageThumbnailGenerator] Failed to open stages directory: ", STAGES_DIR)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	var stage_resources: Array[String] = []

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			stage_resources.append(STAGES_DIR.path_join(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()

	stage_resources.sort()
	var generated_maps: Dictionary = {} # res_path -> out_png_path

	# Step 1: Render and save compressed PNG images to disk
	for res_path in stage_resources:
		var stage_data: StageData = load(res_path) as StageData
		if not stage_data or not stage_data.scene:
			continue

		var out_png_path = await _render_stage_to_png(stage_data, res_path)
		if not out_png_path.is_empty():
			generated_maps[res_path] = out_png_path

	print("[StageThumbnailGenerator] Rendered %d stage image files." % generated_maps.size())

	# Step 2: Trigger editor filesystem scan so Godot imports the PNGs as Texture2D resources
	var editor_interface = get_editor_interface() if Engine.is_editor_hint() else null
	if editor_interface and editor_interface.get_resource_filesystem():
		var fs = editor_interface.get_resource_filesystem()
		fs.scan()
		while fs.is_scanning():
			var tree = Engine.get_main_loop() as SceneTree
			if tree:
				await tree.process_frame
			else:
				break

	# Step 3: Link the imported external Texture2D files to StageData resources (avoids inlining megabytes of raw bytes)
	var linked_count = 0
	for res_path in generated_maps:
		var png_path = generated_maps[res_path]
		var stage_data: StageData = load(res_path) as StageData
		if not stage_data:
			continue

		var tex = ResourceLoader.load(png_path, "Texture2D")
		if tex:
			stage_data.icon = tex
			ResourceSaver.save(stage_data, res_path)
			linked_count += 1
		else:
			push_warning("[StageThumbnailGenerator] Could not load imported texture: %s (will link on next editor scan)" % png_path)

	print("[StageThumbnailGenerator] Successfully linked %d stage thumbnails as lightweight external resources!" % linked_count)

func _render_stage_to_png(stage_data: StageData, res_path: String) -> String:
	var tree = Engine.get_main_loop() as SceneTree
	var root = tree.root if tree else null
	if not root:
		printerr("[StageThumbnailGenerator] No SceneTree root found!")
		return ""

	var stage_node = stage_data.scene.instantiate() as Node2D
	if not stage_node:
		printerr("[StageThumbnailGenerator] Could not instantiate scene for: ", stage_data.stage_name)
		return ""

	# Create offscreen SubViewport with isolated 2D world
	var viewport := SubViewport.new()
	viewport.size = Vector2i(THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT)
	viewport.world_2d = World2D.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS

	# Fixed screen-space dark background
	var canvas_layer := CanvasLayer.new()
	canvas_layer.layer = -100
	var bg := ColorRect.new()
	bg.color = Color(0.035, 0.04, 0.08, 1.0)
	bg.size = Vector2(THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT)
	canvas_layer.add_child(bg)
	viewport.add_child(canvas_layer)

	viewport.add_child(stage_node)

	# Calculate bounding box of stage
	var tilemap = _find_tilemap(stage_node)
	var min_pos = Vector2(INF, INF)
	var max_pos = Vector2(-INF, -INF)

	if tilemap and not tilemap.get_used_cells().is_empty():
		var used_cells = tilemap.get_used_cells()
		var tile_size = Vector2(tilemap.tile_set.tile_size) * tilemap.scale if tilemap.tile_set else Vector2(64, 64)
		var half_size = tile_size / 2.0
		
		for cell in used_cells:
			var g_pos = tilemap.to_global(tilemap.map_to_local(cell))
			min_pos.x = minf(min_pos.x, g_pos.x - half_size.x)
			min_pos.y = minf(min_pos.y, g_pos.y - half_size.y)
			max_pos.x = maxf(max_pos.x, g_pos.x + half_size.x)
			max_pos.y = maxf(max_pos.y, g_pos.y + half_size.y)

	for child in stage_node.find_children("*", "Area2D", true, false):
		if child is Node2D:
			var g_pos = child.global_position
			min_pos.x = minf(min_pos.x, g_pos.x - 48)
			min_pos.y = minf(min_pos.y, g_pos.y - 48)
			max_pos.x = maxf(max_pos.x, g_pos.x + 48)
			max_pos.y = maxf(max_pos.y, g_pos.y + 48)

	var stage_rect: Rect2
	if min_pos.x == INF:
		stage_rect = Rect2(-300, -300, 600, 600)
	else:
		stage_rect = Rect2(min_pos, max_pos - min_pos)

	var center = stage_rect.get_center()

	# Add Camera2D to frame stage
	var camera := Camera2D.new()
	camera.position = center
	
	var margin_ratio = 1.15
	var target_w = maxf(stage_rect.size.x * margin_ratio, 200.0)
	var target_h = maxf(stage_rect.size.y * margin_ratio, 200.0)
	
	var zoom_x = float(THUMBNAIL_WIDTH) / target_w
	var zoom_y = float(THUMBNAIL_HEIGHT) / target_h
	var zoom_val = minf(zoom_x, zoom_y)
	camera.zoom = Vector2(zoom_val, zoom_val)
	viewport.add_child(camera)

	# Attach to scene tree root
	root.add_child(viewport)
	camera.make_current()

	# Await frames for TileMapLayer rendering and GPU composition
	await tree.process_frame
	await tree.process_frame
	await RenderingServer.frame_post_draw

	var img: Image = viewport.get_texture().get_image()

	root.remove_child(viewport)
	viewport.queue_free()

	if not img or img.is_empty():
		printerr("[StageThumbnailGenerator] Failed to capture image for: ", stage_data.stage_name)
		return ""

	# Save to PNG file matching the stage naming (e.g. Stage1.png, Stage5.png, etc.)
	var scene_base = stage_data.scene.resource_path.get_file().get_basename()
	var out_png_path = OUTPUT_DIR.path_join("%s.png" % scene_base)
	var global_out_path = ProjectSettings.globalize_path(out_png_path)
	
	var err = img.save_png(global_out_path)
	if err != OK:
		printerr("[StageThumbnailGenerator] Failed to save PNG: ", out_png_path)
		return ""

	print("[StageThumbnailGenerator] Saved PNG -> %s" % out_png_path)
	return out_png_path

func _find_tilemap(node: Node) -> TileMapLayer:
	if node is TileMapLayer:
		return node
	if "tiles" in node and node.tiles is TileMapLayer:
		return node.tiles
	for child in node.get_children():
		var found = _find_tilemap(child)
		if found:
			return found
	return null
