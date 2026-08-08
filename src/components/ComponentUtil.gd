class_name ComponentUtil

## Mobile-optimized component retriever with O(1) metadata caching.
static func get_component(node: Node, type: Script) -> Node:
	if not is_instance_valid(node):
		return null
	
	# Unique StringName key for this script type
	var key: StringName = type.get_global_name()

	# 1. FAST PATH: Instant O(1) lookup from metadata cache
	if node.has_meta(key):
		var cached = node.get_meta(key)
		if is_instance_valid(cached):
			return cached as Node

	# 2. SLOW PATH (Executed only ONCE per node instance): Search children
	for child in node.get_children():
		if is_instance_valid(child) and is_instance_of(child, type):
			node.set_meta(key, child) # Cache for future calls!
			return child

	return null

## Type-safe shorthand helpers for frequent components
static func get_health(node: Node) -> HealthComponent:
	return get_component(node, HealthComponent) as HealthComponent

static func get_attack(node: Node) -> AttackComponent:
	return get_component(node, AttackComponent) as AttackComponent
