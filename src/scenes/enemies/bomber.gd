class_name Bomber extends Enemy

const EXPLOSION_RADIUS: float = 64.0
const EXPLOSION_DAMAGE: float = 150.0
const DETONATION_DIST_SQ: float = 36.0 * 36.0

var _has_detonated: bool = false

func _physics_process(delta: float) -> void:
	if _has_detonated or is_queued_for_deletion():
		return

	# Detonate immediately upon contact with any solid tower
	if targeting and not targeting.get_targets().is_empty():
		detonate()
		return

	super._physics_process(delta)

func detonate() -> void:
	if _has_detonated or is_queued_for_deletion():
		return
	_has_detonated = true
	set_physics_process(false)
	
	# Spawn visual explosion via stage EffectManager
	if GameManager and GameManager.current_stage and GameManager.current_stage.effect_manager:
		GameManager.current_stage.effect_manager.explosion(global_position, Color(1.0, 0.35, 0.15))
	
	var base_damage: float = attack.data.damage if (attack and attack.data) else EXPLOSION_DAMAGE
	
	# Deal AoE damage to all solid towers within explosion radius
	var tree = get_tree()
	if tree:
		var towers = tree.get_nodes_in_group("towers")
		for node in towers:
			if is_instance_valid(node) and node is Tower and not node.is_queued_for_deletion() and not node.is_preview:
				if node.collision_layer > 0 and node.health != null:
					var dist = global_position.distance_to(node.global_position)
					if dist <= EXPLOSION_RADIUS:
						# Falloff damage
						var falloff = clampf(1.0 - (dist / EXPLOSION_RADIUS) * 0.4, 0.4, 1.0)
						node.health.damage(base_damage * falloff, AttackData.DamageType.PHYSICAL)
	
	_on_died()
