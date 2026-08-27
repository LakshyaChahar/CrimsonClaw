@tool
extends SceneTree

func _init() -> void:
	print("--- TESTING STALKER GHOUL LOAD ---")
	var stalker_scene = load("res://Scenes/Entities/Enemy/Stalkerghoul.tscn") as PackedScene
	if stalker_scene:
		print("Stalkerghoul.tscn loaded successfully!")
		var instance = stalker_scene.instantiate() as StalkerGhoul
		if instance:
			print("StalkerGhoul instantiated successfully! sprite_faces_left = ", instance.sprite_faces_left)
			instance.queue_free()
		else:
			print("FAILED to cast instantiated scene to StalkerGhoul")
	else:
		print("FAILED to load Stalkerghoul.tscn")
	quit()
