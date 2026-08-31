extends Node

# Dictionary mapping sound names (String) to AudioStream resources (wav, ogg, mp3)
# Format in inspector:
# - Key: "jump"
# - Value: res://path/to/jump.wav
@export var sounds: Dictionary[String, AudioStream] = {}

var music_player: AudioStreamPlayer = null
var current_music_key: String = ""

func _ready() -> void:
	_setup_music_player()
	call_deferred("_check_auto_bgm")
	if get_tree():
		get_tree().tree_changed.connect(func(): call_deferred("_check_auto_bgm"))

func _setup_music_player() -> void:
	if music_player and is_instance_valid(music_player):
		return
	music_player = AudioStreamPlayer.new()
	music_player.name = "BGMPlayer"
	var bus_name: StringName = &"Music" if AudioServer.get_bus_index(&"Music") != -1 else &"Master"
	music_player.bus = bus_name
	add_child(music_player)
	music_player.finished.connect(_on_music_finished)

func _get_sound_stream(sound_name: String) -> AudioStream:
	if sounds.has(sound_name) and sounds[sound_name] != null:
		return sounds[sound_name]
		
	# Case-insensitive, space/underscore normalized, and trimmed fallback search
	var target = sound_name.strip_edges().to_lower().replace("_", " ")
	for key in sounds.keys():
		var norm_key = key.strip_edges().to_lower().replace("_", " ")
		if norm_key == target and sounds[key] != null:
			return sounds[key]
			
	return null

## Plays a standard, non-spatial 2D sound (e.g., UI clicks, ambient music/sounds).
## Returns the spawned AudioStreamPlayer in case the caller wants to modify it further.
func play(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0, pitch_randomness: float = 0.0) -> AudioStreamPlayer:
	var stream = _get_sound_stream(sound_name)
	if not stream:
		push_warning("SFXManager: Sound name '" + sound_name + "' not found or AudioStream is null!")
		return null
	
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	
	# Apply pitch and optional slight randomization
	var final_pitch = pitch_scale
	if pitch_randomness > 0.0:
		final_pitch += randf_range(-pitch_randomness, pitch_randomness)
	player.pitch_scale = clampf(final_pitch, 0.1, 4.0)
	
	var bus_name: StringName = &"SFX" if AudioServer.get_bus_index(&"SFX") != -1 else &"Master"
	player.bus = bus_name
	
	add_child(player)
	player.play()
	
	# Connect to the finished signal to clean up automatically
	player.finished.connect(player.queue_free)
	
	return player

## Plays a spatial 2D sound at a specific position (e.g., explosions, enemy hits).
## The sound volume will automatically attenuate based on the camera distance.
func play_2d(sound_name: String, global_pos: Vector2, volume_db: float = 0.0, pitch_scale: float = 1.0, pitch_randomness: float = 0.0) -> AudioStreamPlayer2D:
	var stream = _get_sound_stream(sound_name)
	if not stream:
		push_warning("SFXManager: Sound name '" + sound_name + "' not found or AudioStream is null!")
		return null
	
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.global_position = global_pos
	player.volume_db = volume_db
	
	var final_pitch = pitch_scale
	if pitch_randomness > 0.0:
		final_pitch += randf_range(-pitch_randomness, pitch_randomness)
	player.pitch_scale = clampf(final_pitch, 0.1, 4.0)
	
	var bus_name: StringName = &"SFX" if AudioServer.get_bus_index(&"SFX") != -1 else &"Master"
	player.bus = bus_name
	
	add_child(player)
	player.play()
	
	player.finished.connect(player.queue_free)
	
	return player

## Plays background music by key name, looping automatically.
func play_music(sound_name: String, volume_db: float = 0.0) -> void:
	var stream = _get_sound_stream(sound_name)
	if not stream:
		push_warning("SFXManager: Music sound name '" + sound_name + "' not found or AudioStream is null!")
		return
		
	_setup_music_player()
	
	if music_player.stream == stream and music_player.is_playing():
		return # Already playing
		
	current_music_key = sound_name
	music_player.stream = stream
	music_player.volume_db = volume_db
	music_player.play()

## Alias for play_music.
func play_bgm(sound_name: String, volume_db: float = 0.0) -> void:
	play_music(sound_name, volume_db)

## Stops current background music.
func stop_music() -> void:
	if music_player and music_player.is_playing():
		music_player.stop()
		current_music_key = ""

func _on_music_finished() -> void:
	if music_player and music_player.stream:
		music_player.play() # Replay to loop background music

func _check_auto_bgm() -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	var scene_path = tree.current_scene.scene_file_path.to_lower()
	var scene_name = tree.current_scene.name.to_lower()

	if "start" in scene_path or "start" in scene_name or "menu" in scene_path or "levels" in scene_path or "levels" in scene_name:
		play_music("level 1")
	elif "combat_demo" in scene_path or "level0" in scene_name or "level_0" in scene_path:
		play_music("level 1")
	elif "level 1" in scene_path or "level 1" in scene_name or "level1" in scene_name:
		play_music("level 1")
	elif "level2" in scene_path or "level 2" in scene_name or "level2" in scene_name or "level3" in scene_path or "level 3" in scene_name or "level3" in scene_name:
		var stream2 = _get_sound_stream("level 2")
		if stream2:
			play_music("level 2")
		else:
			play_music("level 1")
	else:
		# Fallback BGM for any other level scene
		play_music("level 1")


