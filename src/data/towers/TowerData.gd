class_name TowerData extends Resource

@export_category("Info")
@export var display_name: String = "" ## The name to display for this tower in-game
@export var icon: Texture2D ## The icon to display when building and in the loadout scene
@export var scene: PackedScene ## The scene for this tower data
@export_multiline var description: String = "" ## The description to show in-game

@export_category("Stats")
@export var is_solid: bool = true
@export var can_target_physical: bool = true
@export var can_target_ghost: bool = false
@export var cost: int = 50 ## How much gold this tower costs to place
@export var damage: float = 10 ## How much damage per "shot" this tower does
@export var damage_type: AttackComponent.DamageType = AttackComponent.DamageType.PHYSICAL
@export var attack_cooldown: float = 1000 ## Milliseconds between attacks
@export var projectile_speed: float = 400 ## How fast this towers projectiles move, if applicable
@export var health: int = 100 ## How much hp this tower has
@export var armor: float = 10 ## How much armor this tower has

## TODO: Upgrade System

func create(is_preview: bool = true) -> Tower:
	var tower = scene.instantiate() as Tower
	if not tower:
		push_error("Scene must be a tower!")
		return null

	tower.data = self.duplicate()
	
	tower.is_preview = is_preview
	
	# Assign properties based on this tower data
	if tower.health:
		tower.health.armor = armor
		tower.health.max_health = health
	
	if not is_solid:
		tower.set_collision_layer_value(1, false)
		tower.set_collision_mask_value(1, false)
	
	if tower.attack:
		tower.attack.projectile_speed = projectile_speed
		tower.attack.cooldown = attack_cooldown
		tower.attack.damage = damage
		tower.attack.damage_type = damage_type

	return tower
