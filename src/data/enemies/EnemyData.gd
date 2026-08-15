class_name EnemyData extends Resource

@export_category("Info")
@export var display_name: String = ""
@export var scene: PackedScene
@export var icon: Texture2D = preload("res://vendor/HAMMA.png")

@export_category("Stats")
@export var lives_penalty: int = 1
@export var energy_reward: int = 1
var gold_reward: int:
	get: return energy_reward
	set(v): energy_reward = v
@export var type: Enemy.EnemyType = Enemy.EnemyType.PHYSICAL
@export var nav_strategy: NavigationComponent.NavStrategy = NavigationComponent.NavStrategy.CLOSEST

@export_category("Components")
@export var health: HealthData
@export var movement: MovementData
@export var nav: NavigationData
@export var attack: AttackData
@export var targeting: TargetingData
@export var splitter: SplitterData

func create() -> Enemy:
	if not scene:
		push_error("EnemyData (%s) has no scene assigned!" % resource_path)
		return null

	var enemy = scene.instantiate() as Enemy
	if not enemy:
		push_error("Scene in EnemyData must inherit from Enemy!")
		return null

	enemy.data = self.duplicate(true)
	apply_to(enemy)
	return enemy

func apply_to(enemy: Enemy) -> void:
	if not is_instance_valid(enemy):
		return

	if health:
		ComponentUtil.update_component(enemy, HealthComponent, enemy.data.health)

	if movement:
		ComponentUtil.update_component(enemy, MovementComponent, enemy.data.movement)

	if nav:
		ComponentUtil.update_component(enemy, NavigationComponent, enemy.data.nav)
		
	if splitter:
		ComponentUtil.update_component(enemy, SplitterComponent, enemy.data.splitter)
		
	if attack:
		ComponentUtil.update_component(enemy, AttackComponent, enemy.data.attack)
		
	if targeting:
		ComponentUtil.update_component(enemy, TargetingComponent, enemy.data.targeting)
