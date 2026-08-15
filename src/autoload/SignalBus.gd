extends Node

signal tower_placed()
signal tower_destroyed()
signal tower_selected(tower: Tower)
signal tower_deselected()
signal tower_sold(tower: Tower, refund: int)
signal navmesh_updated()
signal exits_updated()
signal spawners_updated()


signal placement_mode_changed(is_active: bool)

signal enemy_spawned(enemy: Enemy)
signal enemy_died(enemy: Enemy)
signal enemy_exit(enemy: Enemy)

signal lives_changed(lives: int)
signal energy_changed(energy: int)

signal wave_changed(wave: int)
signal wave_started()
signal wave_completed()
signal stage_loaded()
signal stage_completed()
signal stage_failed()

signal score_changed(score: int)
signal stage_time_changed(formatted_time: String)

signal credits_changed(credits: int)
signal tower_unlocked(tower_id: String)
signal tower_upgraded(tower_id: String, new_level: int)
signal specialization_unlocked(tower_id: String, choice_id: String)
signal tower_choice_changed(tower_id: String, choice_id: String)
signal stage_unlocked(stage_id: String)
