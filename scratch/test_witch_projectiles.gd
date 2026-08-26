extends SceneTree

func _init() -> void:
	print("--- TESTING WITCH DUAL ATTACK (BATS + PROJECTILES) ---")
	var sorc_scene = load("res://Scenes/Entities/Enemy/Sorceress.tscn")
	assert(sorc_scene != null, "Sorceress.tscn failed to load!")
	
	var sorceress = sorc_scene.instantiate() as Sorceress
	assert(sorceress != null, "Failed to instantiate Sorceress!")
	
	root.add_child(sorceress)
	sorceress._ready()
	
	sorceress.global_position = Vector2(100, 100)
	sorceress.facing_direction = 1
	
	# Trigger attack execution
	sorceress.execute_attack()
	
	var bat_count = 0
	var proj_count = 0
	for child in root.get_children():
		if child is Bat:
			bat_count += 1
			print("Found spawned Bat at: ", child.global_position)
		elif "direction" in child and child.has_method("explode"):
			proj_count += 1
			print("Found spawned WitchProjectile at: ", child.global_position, " Direction: ", child.direction)
			
	print("Spawned Bats: ", bat_count, " | Spawned Projectiles: ", proj_count)
	assert(bat_count == sorceress.number_of_bats, "Bat count mismatch!")
	assert(proj_count == sorceress.number_of_projectiles, "Projectile count mismatch!")
	
	print("--- WITCH DUAL ATTACK TEST PASSED SUCCESSFULLY ---")
	quit(0)
