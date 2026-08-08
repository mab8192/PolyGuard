class_name TowerData extends Resource

@export_category("Info")
@export var display_name: String = "" ## The name to display for this tower in-game
@export var icon: Texture2D ## The icon to display when building and in the loadout scene
@export var scene: PackedScene ## The scene for this tower data
@export_multiline var description: String = "" ## The description to show in-game

@export_category("Stats")
@export var is_solid: bool = true
@export var cost: int = 50 ## How much gold this tower costs to place

@export_category("Components")
@export var health: HealthData
@export var attack: AttackData
@export var targeting: TargetingData

## TODO: Upgrade System

func create(is_preview: bool = true) -> Tower:
	var tower = scene.instantiate() as Tower
	if not tower:
		push_error("Scene must be a tower!")
		return null

	tower.data = self.duplicate()
	tower.is_preview = is_preview
	
	apply_to(tower)

	return tower

func apply_to(tower: Tower) -> void:
	if not is_instance_valid(tower):
		return
		
	tower.is_solid = is_solid

	if health and tower.health:
		health.apply_to(tower.health)

	if targeting and tower.targeting:
		targeting.apply_to(tower.targeting)

	if attack and tower.attack:
		attack.apply_to(tower.attack)

	if tower.effect_applier:
		if targeting:
			tower.effect_applier.can_target_physical = targeting.can_target_physical
			tower.effect_applier.can_target_ghost = targeting.can_target_ghost
		elif attack:
			tower.effect_applier.can_target_physical = attack.can_target_physical
			tower.effect_applier.can_target_ghost = attack.can_target_ghost
