class_name SoulLanternTower extends Tower

const RAMP_RATE_PER_SEC: float = 0.35 ## +35% damage per second focused
const MAX_RAMP_MULTIPLIER: float = 4.0

var _target_focus_time: Dictionary = {} ## Dictionary[Node2D, float]

func get_focus_time_for(target: Node2D) -> float:
	return _target_focus_time.get(target, 0.0)

func get_ramp_multiplier_for(target: Node2D) -> float:
	var t = get_focus_time_for(target)
	return minf(1.0 + t * RAMP_RATE_PER_SEC, MAX_RAMP_MULTIPLIER)

func _process(delta: float) -> void:
	if is_preview or not is_active:
		_target_focus_time.clear()
		return
	
	if not targeting or not attack:
		return
		
	var active_targets = targeting.get_targets()
	
	# Clean up targets that left range or died
	for t in _target_focus_time.keys():
		if not is_instance_valid(t) or not active_targets.has(t):
			_target_focus_time.erase(t)
	
	# Accumulate focus time for active targets
	for t in active_targets:
		if is_instance_valid(t):
			var current_time: float = _target_focus_time.get(t, 0.0)
			_target_focus_time[t] = current_time + delta
	
	# Deal ramping attack damage
	if attack.can_attack() and not active_targets.is_empty():
		attack.last_attack_time = attack._time
		for t in active_targets:
			if is_instance_valid(t):
				var mult = get_ramp_multiplier_for(t)
				_deal_ramping_damage(t, mult)
				attack.attacked.emit(t)

func _deal_ramping_damage(target: Node2D, multiplier: float) -> void:
	var h = ComponentUtil.get_component(target, HealthComponent) as HealthComponent
	if h and attack.data:
		var raw_damage = attack.data.damage * multiplier
		if attack.data.attack_mode == AttackData.AttackMode.CONTINUOUS:
			raw_damage *= get_process_delta_time()
		h.damage(raw_damage, attack.data.damage_type)
