class_name EnemyData extends Resource

@export_category("Info")
@export var display_name: String = ""
@export var scene: PackedScene

@export_category("Stats")
@export var lives_penalty: int = 1
@export var gold_reward: int = 1
@export var type: Enemy.EnemyType = Enemy.EnemyType.PHYSICAL

@export var max_health: float = 100.0
@export var armor: float = 0.0
@export var magic_resistance: float = 0.0

@export var max_speed: float = 100.0
@export var acceleration: float = 1200.0
@export var friction: float = 1000.0

func create() -> Enemy:
	if not scene:
		push_error("EnemyData (%s) has no scene assigned!" % resource_path)
		return null

	var enemy = scene.instantiate() as Enemy
	if not enemy:
		push_error("Scene in EnemyData must inherit from Enemy!")
		return null

	enemy.data = self.duplicate()
	ComponentUtil.sync_properties(self, enemy)
	return enemy
