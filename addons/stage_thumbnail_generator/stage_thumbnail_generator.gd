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
	var fs: EditorFileSystem = null
	if Engine.is_editor_hint():
		if ClassDB.class_exists("EditorInterface"):
			fs = EditorInterface.get_resource_filesystem()
		elif has_method("get_editor_interface") and get_editor_interface():
			fs = get_editor_interface().get_resource_filesystem()

	if fs:
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

	const SSAA_SCALE := 2
	var render_w := THUMBNAIL_WIDTH * SSAA_SCALE
	var render_h := THUMBNAIL_HEIGHT * SSAA_SCALE

	var viewport := SubViewport.new()
	viewport.size = Vector2i(render_w, render_h)
	viewport.world_2d = World2D.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.msaa_2d = Viewport.MSAA_4X

	# Color palettes for thumbnail schematic view
	var biome_palettes = {
		0: {"bg": Color(0.024, 0.035, 0.06), "floor": Color(0.055, 0.086, 0.14), "wall": Color(0.0, 0.96, 0.83)},    # Core Cyan
		1: {"bg": Color(0.043, 0.027, 0.016), "floor": Color(0.125, 0.07, 0.04), "wall": Color(1.0, 0.62, 0.0)},      # Solar Amber
		2: {"bg": Color(0.031, 0.016, 0.063), "floor": Color(0.1, 0.047, 0.157), "wall": Color(0.85, 0.27, 0.94)},   # Void Magenta
		3: {"bg": Color(0.016, 0.039, 0.024), "floor": Color(0.047, 0.125, 0.078), "wall": Color(0.06, 0.73, 0.51)}, # Toxic Emerald
		4: {"bg": Color(0.047, 0.016, 0.024), "floor": Color(0.133, 0.039, 0.059), "wall": Color(0.96, 0.25, 0.37)}, # Apex Crimson
	}

	var spawner_color := Color(1.0, 0.16, 0.43, 1.0) # Bright neon pink
	var exit_color := Color(0.0, 0.9, 1.0, 1.0)      # Bright neon cyan

	# Add stage_node to viewport to resolve any scene transforms
	viewport.add_child(stage_node)

	# Extract stage elements
	var tilemaps = stage_node.find_children("*", "TileMapLayer", true, false)
	var used_cells: Array[Vector2i] = []
	var primary_tm: TileMapLayer = null
	var biome_row: int = 0

	for tm in tilemaps:
		if tm is TileMapLayer and not tm.get_used_cells().is_empty():
			primary_tm = tm
			used_cells = tm.get_used_cells()
			break

	var min_pos := Vector2(INF, INF)
	var max_pos := Vector2(-INF, -INF)
	var tile_size := Vector2(64, 64)
	var half_size := tile_size / 2.0

	if primary_tm:
		for cell in used_cells:
			var g_pos = primary_tm.to_global(primary_tm.map_to_local(cell))
			min_pos.x = minf(min_pos.x, g_pos.x - half_size.x)
			min_pos.y = minf(min_pos.y, g_pos.y - half_size.y)
			max_pos.x = maxf(max_pos.x, g_pos.x + half_size.x)
			max_pos.y = maxf(max_pos.y, g_pos.y + half_size.y)
			var atlas_coords = primary_tm.get_cell_atlas_coords(cell)
			if atlas_coords.y >= 0 and atlas_coords.y <= 4:
				biome_row = atlas_coords.y

	var spawners: Array[Vector2] = []
	var exits: Array[Vector2] = []
	for child in stage_node.find_children("*", "Node2D", true, false):
		if child.is_in_group("spawners") or "Spawner" in child.name:
			var s_pos = child.global_position
			spawners.append(s_pos)
			min_pos.x = minf(min_pos.x, s_pos.x - half_size.x)
			min_pos.y = minf(min_pos.y, s_pos.y - half_size.y)
			max_pos.x = maxf(max_pos.x, s_pos.x + half_size.x)
			max_pos.y = maxf(max_pos.y, s_pos.y + half_size.y)
		elif child.is_in_group("exits") or "Exit" in child.name:
			var e_pos = child.global_position
			exits.append(e_pos)
			min_pos.x = minf(min_pos.x, e_pos.x - half_size.x)
			min_pos.y = minf(min_pos.y, e_pos.y - half_size.y)
			max_pos.x = maxf(max_pos.x, e_pos.x + half_size.x)
			max_pos.y = maxf(max_pos.y, e_pos.y + half_size.y)

	var pal: Dictionary = biome_palettes.get(biome_row, biome_palettes[0])

	# Hide default rendering of stage_node children so only schematic draws
	stage_node.visible = false

	# Create schematic drawing node
	var schematic_canvas := Node2D.new()
	schematic_canvas.draw.connect(func():
		if primary_tm:
			for cell in used_cells:
				var g_pos = primary_tm.to_global(primary_tm.map_to_local(cell))
				var atlas_coords = primary_tm.get_cell_atlas_coords(cell)
				var rect := Rect2(g_pos - half_size, tile_size)
				if atlas_coords.x == 1: # Wall
					schematic_canvas.draw_rect(rect, pal["wall"], true)
				else: # Floor
					schematic_canvas.draw_rect(rect, pal["floor"], true)
		
		# Draw exact solid spawners and exits
		for s_pos in spawners:
			var s_rect := Rect2(s_pos - half_size + Vector2(8, 8), tile_size - Vector2(16, 16))
			schematic_canvas.draw_rect(s_rect, spawner_color, true)
		
		for e_pos in exits:
			var e_rect := Rect2(e_pos - half_size + Vector2(8, 8), tile_size - Vector2(16, 16))
			schematic_canvas.draw_rect(e_rect, exit_color, true)
	)

	var canvas_layer := CanvasLayer.new()
	canvas_layer.layer = -100
	var bg := ColorRect.new()
	bg.color = pal["bg"]
	bg.size = Vector2(render_w, render_h)
	canvas_layer.add_child(bg)
	viewport.add_child(canvas_layer)
	viewport.add_child(schematic_canvas)

	var stage_rect: Rect2
	if min_pos.x == INF:
		stage_rect = Rect2(-300, -300, 600, 600)
	else:
		stage_rect = Rect2(min_pos, max_pos - min_pos)

	var camera := Camera2D.new()
	camera.position = stage_rect.get_center()

	var margin_ratio = 1.15
	var target_w = maxf(stage_rect.size.x * margin_ratio, 200.0)
	var target_h = maxf(stage_rect.size.y * margin_ratio, 200.0)

	var zoom_x = float(render_w) / target_w
	var zoom_y = float(render_h) / target_h
	camera.zoom = Vector2(minf(zoom_x, zoom_y), minf(zoom_x, zoom_y))
	viewport.add_child(camera)

	root.add_child(viewport)
	camera.make_current()

	await tree.process_frame
	await tree.process_frame
	await RenderingServer.frame_post_draw

	var img: Image = viewport.get_texture().get_image()

	root.remove_child(viewport)
	viewport.queue_free()
	stage_node.queue_free()

	if not img or img.is_empty():
		printerr("[StageThumbnailGenerator] Failed to capture image for: ", stage_data.stage_name)
		return ""

	img.resize(THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT, Image.INTERPOLATE_LANCZOS)

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
