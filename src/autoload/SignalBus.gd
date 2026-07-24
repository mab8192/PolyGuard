extends Node

signal tower_placed()
signal tower_destroyed()

signal enemy_spawned(enemy: Enemy)
signal enemy_died(enemy: Enemy)
signal enemy_exit(enemy: Enemy)

signal lives_changed(lives: int)
signal gold_changed(gold: int)

signal wave_changed(wave: int)
signal wave_started()
signal wave_completed()
