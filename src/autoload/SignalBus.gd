extends Node

signal tower_placed()
signal tower_destroyed()

signal placement_mode_changed(is_active: bool)

signal enemy_spawned(enemy: Enemy)
signal enemy_died(enemy: Enemy)
signal enemy_exit(enemy: Enemy)

signal lives_changed(lives: int)
signal gold_changed(gold: int)

signal wave_changed(wave: int)
signal wave_started()
signal wave_completed()
signal stage_loaded()
signal stage_completed()
signal stage_failed()

signal score_changed(score: int)
signal stage_time_changed(formatted_time: String)

