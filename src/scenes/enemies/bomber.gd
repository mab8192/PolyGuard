class_name Bomber extends Enemy

const EXPLOSION_RADIUS: float = 64.0
const EXPLOSION_DAMAGE: float = 150.0
const DETONATION_DIST_SQ: float = 36.0 * 36.0

var _has_detonated: bool = false

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if _has_detonated or is_queued_for_deletion():
		return

	# Check for proximity to any solid tower
	var target_tower = _find_nearest_solid_tower()
	if target_tower and global_position.distance_squared_to(target_tower.global_position) <= DETONATION_DIST_SQ:
		detonate()

func _find_nearest_solid_tower() -> Tower:
	var tree = get_tree()
	if not tree:
		return null
	var towers = tree.get_nodes_in_group("towers")
	var best: Tower = null
	var min_dist_sq: float = INF
	for node in towers:
		if is_instance_valid(node) and node is Tower and not node.is_queued_for_deletion() and not node.is_preview:
			if node.collision_layer > 0 and node.health != null:
				var d_sq = global_position.distance_squared_to(node.global_position)
				if d_sq < min_dist_sq:
					min_dist_sq = d_sq
					best = node
	return best

func detonate() -> void:
	if _has_detonated:
		return
	_has_detonated = true
	
	# Spawn visual explosion via stage EffectManager
	if GameManager and GameManager.current_stage and GameManager.current_stage.effect_manager:
		GameManager.current_stage.effect_manager.explosion(global_position, Color(1.0, 0.35, 0.15))
	
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
						node.health.damage(EXPLOSION_DAMAGE * falloff, AttackData.DamageType.PHYSICAL)
	
	_on_died()
