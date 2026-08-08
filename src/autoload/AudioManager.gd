extends Node

# --- Configuration Properties ---
@export_group("Music Crossfade")
@export var crossfade_duration: float = 1.0

@export_group("SFX Pool Settings")
@export var sfx_pool_size: int = 12

# --- Audio Resources ---
# Sound Effect Arrays (for randomized playback)
@export_group("SFX Resources")
@export var sfx_enemy_died: Array[AudioStream] = [
	preload("res://vendor/phoenix1291/SFX- The Ultimate 2017 16 bit Mini pack/Explosion/Wav/Explosion__006.wav"),
	preload("res://vendor/phoenix1291/SFX- The Ultimate 2017 16 bit Mini pack/Explosion/Wav/Explosion__007.wav"),
	preload("res://vendor/phoenix1291/SFX- The Ultimate 2017 16 bit Mini pack/Explosion3/Wav/Explosion3__002.wav")
]
@export var sfx_enemy_exit: Array[AudioStream] = [
	preload("res://vendor/phoenix1291/SFX- The Ultimate 2017 16 bit Mini pack/Teleport/Wav/Teleport__007.wav"),
	preload("res://vendor/phoenix1291/SFX- The Ultimate 2017 16 bit Mini pack/Pew/Wav/Pew__008.wav")
]

var sfx_stage_complete: AudioStream = preload("res://vendor/celestialghost8/Victory.mp3")

# Music Streams
@export_group("Music Tracks")
@export var music_menu: AudioStream = preload("res://vendor/Quitschie/8 Bit Background Music.wav")
@export var music_build: AudioStream = preload("res://vendor/Quitschie/8 Bit Background Music.wav")
@export var music_combat: AudioStream = preload("res://vendor/celestialghost8/newbattle.wav")
@export var music_victory: AudioStream = preload("res://vendor/Quitschie/8 Bit Background Music.wav")

# --- Node References ---
var _music_player_a: AudioStreamPlayer
var _music_player_b: AudioStreamPlayer
var _active_music_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []

var _crossfade_tween: Tween

func _ready() -> void:
	_setup_music_players()
	_setup_sfx_pool()
	_connect_signal_bus()

# ==============================================================================
# INITIALIZATION
# ==============================================================================

func _setup_music_players() -> void:
	_music_player_a = AudioStreamPlayer.new()
	_music_player_b = AudioStreamPlayer.new()
	
	# Set audio bus (ensure you have a "Music" bus configured in Godot)
	_music_player_a.bus = &"Music"
	_music_player_b.bus = &"Music"
	
	add_child(_music_player_a)
	add_child(_music_player_b)
	
	_active_music_player = _music_player_a

func _setup_sfx_pool() -> void:
	for i in range(sfx_pool_size):
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		_sfx_pool.append(player)

func _connect_signal_bus() -> void:
	SignalBus.wave_started.connect(_on_wave_started)
	SignalBus.wave_completed.connect(_on_wave_completed)
	SignalBus.stage_loaded.connect(_on_stage_loaded)
	SignalBus.stage_completed.connect(_on_stage_completed)
	SignalBus.enemy_died.connect(_on_enemy_died)
	SignalBus.enemy_exit.connect(_on_enemy_exit)

# ==============================================================================
# MUSIC CROSSFADING
# ==============================================================================

## Smoothly fades from the current active track to a new track.
func play_music(stream: AudioStream, duration: float = -1.0) -> void:
	if stream == null:
		return
		
	if _active_music_player.stream == stream and _active_music_player.playing:
		return # Already playing this track
	
	var fade_time = crossfade_duration if duration < 0 else duration
	var incoming_player = _music_player_b if _active_music_player == _music_player_a else _music_player_a
	
	# Setup incoming player
	incoming_player.stream = stream
	incoming_player.volume_db = -80.0 # Start silent
	incoming_player.play()
	
	# Kill existing crossfade tween if active
	if _crossfade_tween and _crossfade_tween.is_running():
		_crossfade_tween.kill()
		
	_crossfade_tween = create_tween().set_parallel(true)
	
	# Fade out current active player
	_crossfade_tween.tween_property(_active_music_player, "volume_db", -80.0, fade_time)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		
	# Fade in incoming player
	_crossfade_tween.tween_property(incoming_player, "volume_db", 0.0, fade_time)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	# Stop outgoing player when fade finishes
	_crossfade_tween.chain().tween_callback(_active_music_player.stop)
	
	# Swap active reference
	_active_music_player = incoming_player

# ==============================================================================
# SOUND EFFECTS POOLING & RANDOMIZATION
# ==============================================================================

## Plays a random stream from an Array of AudioStreams with optional pitch variance.
func play_random_sfx(streams: Array[AudioStream], pitch_min: float = 0.9, pitch_max: float = 1.1) -> void:
	if streams.is_empty():
		return
	var random_stream = streams.pick_random()
	play_sfx(random_stream, pitch_min, pitch_max)

## Finds an available AudioStreamPlayer from the pool and plays the requested sound.
func play_sfx(stream: AudioStream, pitch_min: float = 1.0, pitch_max: float = 1.0) -> void:
	if stream == null:
		return
		
	var player = _get_available_sfx_player()
	if player == null:
		push_warning("AudioManager: SFX pool exhausted!")
		return
		
	player.stream = stream
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.play()

func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.playing:
			return player
	return null

# ==============================================================================
# SIGNALBUS CALLBACKS
# ==============================================================================

func _on_wave_started() -> void:
	play_music(music_combat)

func _on_wave_completed() -> void:
	play_music(music_build)

func _on_stage_loaded() -> void:
	play_music(music_build)

func _on_stage_completed() -> void:
	play_music(music_victory)
	play_sfx(sfx_stage_complete)

func _on_enemy_died(enemy: Enemy) -> void:
	# Subtle pitch variation prevents repetitiveness when killing enemies rapidly
	play_random_sfx(sfx_enemy_died, 0.85, 1.15)

func _on_enemy_exit(enemy: Enemy) -> void:
	play_random_sfx(sfx_enemy_exit, 0.95, 1.05)
