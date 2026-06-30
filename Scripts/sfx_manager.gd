extends Node

# Dictionary mapping sound names (String) to AudioStream resources (wav, ogg, mp3)
# Format in inspector:
# - Key: "jump"
# - Value: res://path/to/jump.wav
@export var sounds: Dictionary[String, AudioStream] = {}

## Plays a standard, non-spatial 2D sound (e.g., UI clicks, ambient music/sounds).
## Returns the spawned AudioStreamPlayer in case the caller wants to modify it further.
func play(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0, pitch_randomness: float = 0.0) -> AudioStreamPlayer:
	if not sounds.has(sound_name):
		push_warning("SFXManager: Sound name '" + sound_name + "' not found!")
		return null
	
	var player := AudioStreamPlayer.new()
	player.stream = sounds[sound_name]
	player.volume_db = volume_db
	
	# Apply pitch and optional slight randomization
	var final_pitch = pitch_scale
	if pitch_randomness > 0.0:
		final_pitch += randf_range(-pitch_randomness, pitch_randomness)
	player.pitch_scale = clampf(final_pitch, 0.1, 4.0)
	

	player.bus = &"SFX"
	
	add_child(player)
	player.play()
	
	# Connect to the finished signal to clean up automatically
	player.finished.connect(player.queue_free)
	
	return player

## Plays a spatial 2D sound at a specific position (e.g., explosions, enemy hits).
## The sound volume will automatically attenuate based on the camera distance.
func play_2d(sound_name: String, global_pos: Vector2, volume_db: float = 0.0, pitch_scale: float = 1.0, pitch_randomness: float = 0.0) -> AudioStreamPlayer2D:
	if not sounds.has(sound_name):
		push_warning("SFXManager: Sound name '" + sound_name + "' not found!")
		return null
	
	var player := AudioStreamPlayer2D.new()
	player.stream = sounds[sound_name]
	player.global_position = global_pos
	player.volume_db = volume_db
	

	var final_pitch = pitch_scale
	if pitch_randomness > 0.0:
		final_pitch += randf_range(-pitch_randomness, pitch_randomness)
	player.pitch_scale = clampf(final_pitch, 0.1, 4.0)
	
	player.bus = &"SFX"
	
	
	add_child(player)
	player.play()
	
	player.finished.connect(player.queue_free)
	
	return player
