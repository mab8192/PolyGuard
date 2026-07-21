class_name Stage extends Node2D

@export var data: StageData
@onready var tiles: TileMapLayer = $NavigationRegion2D/Tiles
@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	if data == null:
		push_error("Need to provide data file for stage")
		return

	data.load()

func get_map_pixel_rect() -> Rect2:
	var used_rect: Rect2i = tiles.get_used_rect()
	var tile_size: Vector2i = tiles.tile_set.tile_size
	
	var world_pos = Vector2(used_rect.position * tile_size)
	var world_size = Vector2(used_rect.size * tile_size)
	
	return Rect2(world_pos, world_size)

func _process(delta: float) -> void:
	var grid_size = Vector2(16, 16)
	var half_tile = grid_size / 2.0  # Vector2(16, 16)
	
	var touch_pos = get_global_mouse_position()

	# Shift back -> snap to corner -> shift forward to center
	var cell_center = (touch_pos - half_tile).snapped(grid_size) + half_tile
	color_rect.global_position = cell_center - half_tile
