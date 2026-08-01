class_name TargetingComponent extends Area2D

enum Strategy { FIRST, LAST, CLOSEST, STRONGEST }

@export var strategy: Strategy = Strategy.FIRST

var targets: Array[Enemy] = []
var target: Enemy = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(_delta: float) -> void:
	_select_target()

## Assign a target from `targets` to `target` according to `strategy`
func _select_target() -> void:
	target = null

	match strategy:
		Strategy.FIRST:
			var best_score = INF
			for t in targets:
				var distance = t.nav.distance_to_goal()
				if distance < best_score:
					target = t
					best_score = distance
		Strategy.LAST:
			var best_score = 0
			for t in targets:
				var distance = t.nav.distance_to_goal()
				if distance > best_score:
					target = t
					best_score = distance
		Strategy.CLOSEST:
			var best_score = INF
			for t in targets:
				var distance = (t.global_position - global_position).length()
				if distance < best_score:
					target = t
					best_score = distance
		Strategy.STRONGEST:
			var best_score = 0
			for t in targets:
				var health = t.health.health
				if health > best_score:
					target = t
					best_score = health

func _on_body_entered(body: Node2D) -> void:
	if body is Enemy:
		targets.append(body)

func _on_body_exited(body: Node2D) -> void:
	if body is Enemy:
		targets.erase(body)
