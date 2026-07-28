class_name TowerData extends Resource

@export var name: String # The name of the tower
@export var cost: float # The cost of the tower
@export var size: Vector2i # The size of the tower in grid cells
@export var preview: Texture2D # A Texture2D used to preview the tower (build menu, loadout, etc.)

# TODO: Upgrades between levels?
