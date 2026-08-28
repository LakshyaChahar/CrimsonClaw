@tool
extends SceneTree

func _init() -> void:
	print("--- TESTING STALKER FACING DIRECTION SIMULATION WITH FULL READY ---")
	var stalker_scene = load("res://Scenes/Entities/Enemy/Stalkerghoul.tscn") as PackedScene
	var stalker = stalker_scene.instantiate() as StalkerGhoul
	
	root.add_child(stalker)
	stalker._ready()
	if stalker.animation_manager:
		stalker.animation_manager._ready()
	
	print("Initial facing_direction: ", stalker.facing_direction)
	print("Initial sprite_faces_left: ", stalker.sprite_faces_left)
	if stalker.animation_manager and stalker.animation_manager.sprite:
		print("Initial sprite.flip_h: ", stalker.animation_manager.sprite.flip_h)
	
	# Simulate Player to the RIGHT of Stalker (input_direction = Vector2(1, 0))
	print("\n--- Test 1: Player is to the RIGHT (input_direction.x = 1) ---")
	stalker.input_direction.x = 1.0
	stalker.update_facing_direction()
	print("facing_direction: ", stalker.facing_direction)
	if stalker.animation_manager and stalker.animation_manager.sprite:
		print("sprite.flip_h: ", stalker.animation_manager.sprite.flip_h)
		var visually_facing = "RIGHT" if (stalker.animation_manager.sprite.flip_h if stalker.sprite_faces_left else not stalker.animation_manager.sprite.flip_h) else "LEFT"
		print("Visual Facing Direction: ", visually_facing)

	# Simulate Player to the LEFT of Stalker (input_direction = Vector2(-1, 0))
	print("\n--- Test 2: Player is to the LEFT (input_direction.x = -1) ---")
	stalker.input_direction.x = -1.0
	stalker.update_facing_direction()
	print("facing_direction: ", stalker.facing_direction)
	if stalker.animation_manager and stalker.animation_manager.sprite:
		print("sprite.flip_h: ", stalker.animation_manager.sprite.flip_h)
		var visually_facing = "LEFT" if (not stalker.animation_manager.sprite.flip_h if stalker.sprite_faces_left else stalker.animation_manager.sprite.flip_h) else "RIGHT"
		print("Visual Facing Direction: ", visually_facing)

	stalker.queue_free()
	quit()
