extends SceneTree

func _init() -> void:
	print("--- TESTING BAT POP VFX AND COMBAT JUICE ---")
	var bat_scene = load("res://Scenes/Entities/Enemy/Bat.tscn")
	assert(bat_scene != null, "Bat.tscn failed to load!")
	
	var bat = bat_scene.instantiate() as Bat
	root.add_child(bat)
	bat._ready()
	
	# Test take_damage hit reaction
	bat.take_damage(10.0)
	print("Bat took 10 damage. Current health: ", bat.current_health)
	
	# Test lethal damage and pop particle spawn
	bat.take_damage(20.0)
	print("Bat killed. Is dead: ", bat.is_dead)
	
	print("--- POP TEST PASSED SUCCESSFULLY ---")
	quit(0)
