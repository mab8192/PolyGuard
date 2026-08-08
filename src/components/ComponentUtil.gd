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

const DEFAULT_PROPERTY_ALIASES: Dictionary = {
	"attack_cooldown": "cooldown",
	"health": "max_health",
	"projectile_speed": "speed",
	"damage": "damage_amount",
}

## Top-down property syncing engine: copies matching script properties from source to target and its sub-nodes.
static func sync_properties(source: Object, target: Node, custom_aliases: Dictionary = {}) -> void:
	if not is_instance_valid(source) or not is_instance_valid(target):
		return

	var props: Dictionary = _get_script_properties(source)
	if props.is_empty():
		return

	var aliases: Dictionary = DEFAULT_PROPERTY_ALIASES.duplicate()
	aliases.merge(custom_aliases, true)

	_apply_properties_to_tree(target, props, aliases)

static func _get_script_properties(source: Object) -> Dictionary:
	var props: Dictionary = {}
	if not is_instance_valid(source):
		return props

	for prop in source.get_property_list():
		var p_name: String = prop.name
		var usage: int = prop.usage
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0:
			if not p_name.begins_with("_") and p_name != "script" and p_name != "scene":
				props[p_name] = source.get(p_name)
	return props

static func _apply_properties_to_tree(node: Node, props: Dictionary, aliases: Dictionary) -> void:
	if not is_instance_valid(node):
		return

	for src_prop in props:
		var val = props[src_prop]
		if val == null:
			continue

		# Direct property match
		if src_prop in node:
			_set_property_if_type_matches(node, src_prop, val)

		# Property alias match
		if src_prop in aliases:
			var alias_prop: String = aliases[src_prop]
			if alias_prop in node:
				_set_property_if_type_matches(node, alias_prop, val)

	for child in node.get_children():
		if is_instance_valid(child):
			_apply_properties_to_tree(child, props, aliases)

static func _set_property_if_type_matches(target_obj: Object, prop_name: String, val) -> void:
	for p in target_obj.get_property_list():
		if p.name == prop_name:
			if p.type == TYPE_OBJECT and typeof(val) != TYPE_OBJECT and val != null:
				return
			break
	target_obj.set(prop_name, val)
