class_name TowerData extends Resource

@export_category("Info")
@export var display_name: String = "" ## The name to display for this tower in-game
@export var icon: Texture2D ## The icon to display when building and in the loadout scene
@export var scene: PackedScene ## The scene for this tower data
@export_multiline var description: String = "" ## The description to show in-game

@export_category("Stats")
@export var is_solid: bool = true
@export var cost: int = 250 ## How much gold this tower costs to place

@export_category("Components")
@export var health: HealthData
@export var attack: AttackData
@export var targeting: TargetingData
@export var effect_applier: EffectApplierData

## TODO: Upgrade System

func create(is_preview: bool = true) -> Tower:
	var tower = scene.instantiate() as Tower
	if not tower:
		push_error("Scene must be a tower!")
		return null

	tower.data = self.duplicate(true)
	tower.is_preview = is_preview
	
	apply_to(tower)
	return tower

func apply_to(tower: Tower) -> void:
	if not is_instance_valid(tower):
		return
		
	tower.is_solid = is_solid

	if health:
		ComponentUtil.update_component(tower, HealthComponent, tower.data.health)

	if targeting:
		ComponentUtil.update_component(tower, TargetingComponent, tower.data.targeting)

	if attack:
		ComponentUtil.update_component(tower, AttackComponent, tower.data.attack)

	if effect_applier:
		ComponentUtil.update_component(tower, EffectApplierComponent, tower.data.effect_applier)
