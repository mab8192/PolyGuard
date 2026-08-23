extends Node

## ============================================================================
## FlowFieldManager
## ----------------------------------------------------------------------------
## Autoload singleton that owns named FlowField instances so multiple systems
## (spawners, agents, debug tools) can create, retrieve, and bake shared fields.
## ============================================================================

signal flow_fields_updated()

var fields: Dictionary = {} # String id -> FlowField


func create_field(id: String, p_width: int, p_height: int, p_cell_size: float,
		p_origin: Vector2 = Vector2.ZERO) -> FlowField:
	var field: FlowField = FlowField.new(p_width, p_height, p_cell_size, p_origin)
	fields[id] = field
	return field


func register_field(id: String, field: FlowField) -> void:
	fields[id] = field


func get_field(id: String) -> FlowField:
	if fields.has(id):
		return fields[id] as FlowField
	return null


func has_field(id: String) -> bool:
	return fields.has(id)


func remove_field(id: String) -> void:
	fields.erase(id)


func clear() -> void:
	fields.clear()


func bake_field(id: String) -> void:
	var field: FlowField = get_field(id)
	if field == null:
		push_warning("FlowFieldManager: no field registered with id '%s'" % id)
		return
	field.rebuild()


func bake_all() -> void:
	for id: String in fields:
		bake_field(id)


func notify_fields_updated() -> void:
	flow_fields_updated.emit()
	SignalBus.flow_fields_updated.emit()
