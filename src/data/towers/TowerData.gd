class_name TowerData extends Resource

@export var name: String # The name of the tower
@export var cost: float # The cost of the tower
@export var size: Vector2i # The size of the tower in grid cells
@export var scene: PackedScene # The scene to instantiate/preview with

# TODO: Upgrades between levels?
