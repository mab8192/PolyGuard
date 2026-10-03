extends Node

func _ready() -> void:
	var failed := false
	for n in range(21, 41):
		var id := "stage_%02d" % n
		var data: StageData = load("res://src/data/stages/%s.tres" % id) as StageData
		if data == null:
			push_error("Failed to load %s" % id)
			failed = true
			continue
		var waves := data.get_waves()
		if waves.is_empty():
			push_error("%s has no waves" % id)
			failed = true
			continue
		var stage := data.create()
		if stage == null:
			push_error("Failed to instance %s" % id)
			failed = true
			continue
		add_child(stage)
		var spawner_names: Dictionary = {}
		for node in stage.find_children("*", "Spawner", true, false):
			spawner_names[str(node.name)] = true
		var tiles := stage.get_node_or_null("NavigationRegion2D/Tiles") as TileMapLayer
		if tiles == null or tiles.get_used_cells().is_empty():
			push_error("%s has no tiles" % id)
			failed = true
		for wave in waves:
			for spawn in wave.spawns:
				if not spawner_names.has(spawn.spawner_id):
					push_error("%s wave %d uses missing spawner %s" % [id, wave.wave_number, spawn.spawner_id])
					failed = true
				if Registry.get_enemy_data(spawn.enemy_type) == null:
					push_error("%s unknown enemy %s" % [id, spawn.enemy_type])
					failed = true
		print("%s | %s | waves=%d spawners=%s slots=%d pack=%s" % [id, data.stage_name, waves.size(), spawner_names.keys(), data.loadout_size, data.pack_name])
		stage.queue_free()
	var packs := Registry.get_level_packs()
	for pack in packs:
		print("PACK %s order=%s count=%d" % [pack.name, pack.order, (pack.stages as Array).size()])
	if packs.size() != 4:
		push_error("Expected 4 campaign groups, got %d" % packs.size())
		failed = true
	for pack in packs:
		var count := (pack.stages as Array).size()
		if count < 10 or count > 11:
			push_error("Group %s has %d stages" % [pack.name, count])
			failed = true
		print("GROUP %s | %s | %d" % [pack.series, pack.name, count])
	var campaign_scene := load("res://src/scenes/ui/views/campaign.tscn") as PackedScene
	if campaign_scene == null:
		push_error("Campaign scene failed to load")
		failed = true
	else:
		var campaign := campaign_scene.instantiate()
		add_child(campaign)
		var list := campaign.find_child("StageListContainer", true, false)
		var cards := list.get_child_count() if list else 0
		print("Campaign group cards: ", cards)
		if cards != packs.size():
			push_error("Campaign showed %d group cards" % cards)
			failed = true
	get_tree().quit(1 if failed else 0)
