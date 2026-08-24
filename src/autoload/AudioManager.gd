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
@export var sfx_tower_placed: Array[AudioStream] = [
	preload("res://vendor/phoenix1291/SFX- The Ultimate 2017 16 bit Mini pack/Pickup/Wav/Pickup__003.wav")
]
var sfx_tower_hit: Array[AudioStream] = [
	preload("res://vendor/phoenix1291/SFX- The Ultimate 2017 16 bit Mini pack/Punch2/Wav/Punch2__001.wav"),
	preload("res://vendor/phoenix1291/SFX- The Ultimate 2017 16 bit Mini pack/Punch2/Wav/Punch2__003.wav"),
	preload("res://vendor/phoenix1291/SFX- The Ultimate 2017 16 bit Mini pack/Punch2/Wav/Punch2__007.wav")
]

var sfx_stage_complete: AudioStream = preload("res://vendor/celestialghost8/Victory.mp3")

# Music Streams
@export_group("Music Tracks")
@export var music_menu: Array[AudioStream] = [
	preload("res://vendor/mrpoly/awesomeness.ogg"),
	preload("res://vendor/DeusLower/deuslower-medieval-ambient-236809.mp3")
]
@export var music_build: AudioStream = preload("res://vendor/Zefz/TheLoomingBattle.ogg")
@export var music_combat: Array[AudioStream] = [
	preload("res://vendor/AlexandrZhelanov/Battle Themes/Battle Theme 1.mp3"),
	preload("res://vendor/AlexandrZhelanov/Battle Themes/Battle Theme 2.mp3"),
	preload("res://vendor/AlexandrZhelanov/Battle Themes/Battle Theme 3.mp3"),
	preload("res://vendor/AlexandrZhelanov/Battle Themes/Battle Theme 4.mp3"),
	preload("res://vendor/AlexandrZhelanov/Battle Themes/Battle Theme 5.mp3")
]

# --- Node References ---
var _music_player_a: AudioStreamPlayer
var _music_player_b: AudioStreamPlayer
var _active_music_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []

var _crossfade_tween: Tween
var _current_playlist: Array[AudioStream] = []
var _current_track_index: int = 0
var _is_music_playing: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	
	_music_player_a.finished.connect(_on_music_player_finished.bind(_music_player_a))
	_music_player_b.finished.connect(_on_music_player_finished.bind(_music_player_b))
	
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
	SignalBus.tower_placed.connect(_on_tower_placed)

# ==============================================================================
# MUSIC CROSSFADING & PLAYLIST LOOPING
# ==============================================================================

## Plays a track or playlist of tracks, smoothly crossfading from the current active track.
## If a playlist is provided, it cycles through all tracks and loops when reaching the end.
func play_music(music: Variant, duration: float = -1.0, start_index: int = -1) -> void:
	if music == null:
		return
		
	var target_playlist: Array[AudioStream] = []
	var target_index: int = 0
	
	if music is Array:
		for item in music:
			if item is AudioStream:
				target_playlist.append(item)
		if target_playlist.is_empty():
			return
		
		# If currently playing this exact playlist and no specific different track was requested, do not interrupt
		if _is_music_playing and _active_music_player and _active_music_player.playing and _are_playlists_equal(_current_playlist, target_playlist):
			if start_index < 0 or start_index == _current_track_index:
				return
		
		if start_index >= 0 and start_index < target_playlist.size():
			target_index = start_index
		else:
			target_index = randi() % target_playlist.size()
	elif music is AudioStream:
		var stream: AudioStream = music
		# If the active player is already playing this exact stream, do nothing
		if _is_music_playing and _active_music_player and _active_music_player.playing and _active_music_player.stream == stream:
			return

		# Preserve full list looping if a single stream belongs to one of the predefined playlists
		if music_combat.has(stream):
			target_playlist = music_combat.duplicate()
			target_index = music_combat.find(stream)
		elif music_menu.has(stream):
			target_playlist = music_menu.duplicate()
			target_index = music_menu.find(stream)
		else:
			target_playlist = [stream]
			target_index = 0

		if _is_music_playing and _active_music_player and _active_music_player.playing and _are_playlists_equal(_current_playlist, target_playlist) and _current_track_index == target_index:
			return
	else:
		return

	var target_stream: AudioStream = target_playlist[target_index]
	
	# If already playing this playlist and the active track matches, do not interrupt
	if _is_music_playing and _active_music_player and _active_music_player.playing and _active_music_player.stream == target_stream and _are_playlists_equal(_current_playlist, target_playlist):
		_current_playlist = target_playlist
		_current_track_index = target_index
		return
	
	_current_playlist = target_playlist
	_current_track_index = target_index
	_is_music_playing = true
	
	_crossfade_to_stream(target_stream, duration)

func _are_playlists_equal(list_a: Array[AudioStream], list_b: Array[AudioStream]) -> bool:
	if list_a.size() != list_b.size():
		return false
	for i in range(list_a.size()):
		if list_a[i] != list_b[i]:
			return false
	return true

func _crossfade_to_stream(stream: AudioStream, duration: float = -1.0) -> void:
	var fade_time = crossfade_duration if duration < 0 else duration
	var incoming_player = _music_player_b if _active_music_player == _music_player_a else _music_player_a
	var outgoing_player = _active_music_player
	
	# Setup incoming player
	incoming_player.stream = stream
	incoming_player.volume_db = -80.0 # Start silent
	incoming_player.play()
	
	# Kill existing crossfade tween if active
	if _crossfade_tween and _crossfade_tween.is_running():
		_crossfade_tween.kill()
		
	_crossfade_tween = create_tween().set_parallel(true)
	
	# Fade out current active player
	_crossfade_tween.tween_property(outgoing_player, "volume_db", -80.0, fade_time)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		
	# Fade in incoming player
	_crossfade_tween.tween_property(incoming_player, "volume_db", 0.0, fade_time)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	# Stop outgoing player when fade finishes
	_crossfade_tween.chain().tween_callback(outgoing_player.stop)
	
	# Swap active reference
	_active_music_player = incoming_player

func _on_music_player_finished(player: AudioStreamPlayer) -> void:
	# Only the active player reaching its end triggers the next track in the playlist
	if player != _active_music_player:
		return
		
	if not _is_music_playing or _current_playlist.is_empty():
		return
		
	# Advance to next track in the playlist, wrapping around to the beginning
	_current_track_index = (_current_track_index + 1) % _current_playlist.size()
	var next_stream: AudioStream = _current_playlist[_current_track_index]
	if next_stream == null:
		return
		
	if _crossfade_tween and _crossfade_tween.is_running():
		_crossfade_tween.kill()
		
	_active_music_player.stream = next_stream
	_active_music_player.volume_db = 0.0
	_active_music_player.play()

## Smoothly stops current music playback.
func stop_music(duration: float = -1.0) -> void:
	_is_music_playing = false
	_current_playlist.clear()
	_current_track_index = 0
	
	if not _active_music_player or not _active_music_player.playing:
		return
		
	var fade_time = crossfade_duration if duration < 0 else duration
	if fade_time <= 0:
		_active_music_player.stop()
		return
		
	if _crossfade_tween and _crossfade_tween.is_running():
		_crossfade_tween.kill()
		
	_crossfade_tween = create_tween()
	_crossfade_tween.tween_property(_active_music_player, "volume_db", -80.0, fade_time)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_crossfade_tween.tween_callback(_active_music_player.stop)

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

func _on_stage_completed(_stage_id: String = "") -> void:
	play_sfx(sfx_stage_complete)

func _on_enemy_died(_enemy: Enemy) -> void:
	# Subtle pitch variation prevents repetitiveness when killing enemies rapidly
	play_random_sfx(sfx_enemy_died, 0.85, 1.15)

func _on_enemy_exit(_enemy: Enemy) -> void:
	play_random_sfx(sfx_enemy_exit, 0.95, 1.05)

func _on_tower_placed() -> void:
	play_random_sfx(sfx_tower_placed, 1.1, 1.3)
