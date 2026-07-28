extends Node

# Map of enemy types to scenes
const ENEMY_MAP: Dictionary = {
	"speeder": "res://src/scenes/enemies/speeder.tscn",
	"tank": "res://src/scenes/enemies/tank.tscn"
}

# Array of paths to stage scenes
const STAGES: Array[String] = [
	"res://src/scenes/stages/Stage1.tscn"
]

const TOWERS: Dictionary[String, PackedScene] = {
	"Archer Tower": preload("res://src/scenes/towers/archer_tower.tscn"),
	"Barricade": preload("res://src/scenes/towers/barricade.tscn")
}
