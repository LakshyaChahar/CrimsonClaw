extends Node
class_name LevelAudio

## Sound key in SfxManager to play when this level loads (e.g. "level 1" or "level 2")
@export var music_key: String = ""

func _ready() -> void:
	if music_key != "":
		var sfx_mgr = get_node_or_null("/root/SfxManager")
		if sfx_mgr and sfx_mgr.has_method("play_music"):
			sfx_mgr.play_music(music_key)
