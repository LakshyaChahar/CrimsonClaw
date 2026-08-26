extends SceneTree

func _init() -> void:
	print("--- TESTING WITCH LINEAR BEAM ATTACK + BATS ---")
	var sorc_scene = load("res://Scenes/Entities/Enemy/Sorceress.tscn")
	assert(sorc_scene != null, "Sorceress.tscn failed to load!")
	
	var sorceress = sorc_scene.instantiate() as Sorceress
	assert(sorceress != null, "Failed to instantiate Sorceress!")
	
	root.add_child(sorceress)
	sorceress._ready()
	
	sorceress.global_position = Vector2(100, 100)
	sorceress.facing_direction = 1
	
	# Execute attack wave
	sorceress.execute_attack()
	
	var bat_count = 0
	var beam_count = 0
	for child in root.get_children():
		if child is Bat:
			bat_count += 1
			print("Found spawned Bat at: ", child.global_position)
		elif "beam_length" in child and child.has_method("_end_beam"):
			beam_count += 1
			print("Found spawned WitchLinearBeam at: ", child.global_position, " Length: ", child.beam_length)
			
	print("Spawned Bats: ", bat_count, " | Spawned Linear Beams: ", beam_count)
	assert(bat_count == sorceress.number_of_bats, "Bat count mismatch!")
	assert(beam_count == 1, "Linear beam count mismatch!")
	
	print("--- WITCH LINEAR BEAM ATTACK TEST PASSED SUCCESSFULLY ---")
	quit(0)
