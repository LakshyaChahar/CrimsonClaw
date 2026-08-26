extends SceneTree

func _init() -> void:
	print("--- TESTING WITCH LINEAR PROJECTILE + RANGED ENEMY PARABOLIC PROJECTILE ---")
	
	# 1. Test Witch Linear Projectile
	var sorc_scene = load("res://Scenes/Entities/Enemy/Sorceress.tscn")
	assert(sorc_scene != null, "Sorceress.tscn failed to load!")
	var sorceress = sorc_scene.instantiate() as Sorceress
	root.add_child(sorceress)
	sorceress.global_position = Vector2(100, 100)
	sorceress.facing_direction = 1
	sorceress.execute_attack()
	
	var linear_proj_found = false
	for child in root.get_children():
		if "direction" in child and child.has_method("explode"):
			linear_proj_found = true
			print("Witch Linear Projectile active at: ", child.global_position, " Direction: ", child.direction)
	assert(linear_proj_found, "Witch Linear Projectile was not spawned!")
	
	# 2. Test Ranged Enemy Parabolic Projectile
	var lob_scene = load("res://Scenes/Entities/Enemy/lobbed_projectile.tscn")
	assert(lob_scene != null, "lobbed_projectile.tscn failed to load!")
	var lobbed_proj = lob_scene.instantiate() as LobbedProjectile
	root.add_child(lobbed_proj)
	lobbed_proj.setup(Vector2(500, 200), Vector2(650, 200), 200.0)
	print("Ranged Enemy Parabolic Lobbed Projectile setup from (500, 200) to (650, 200)")
	assert(lobbed_proj.is_flying, "Lobbed projectile is not flying!")
	
	print("--- BOTH PROJECTILE TESTS PASSED SUCCESSFULLY ---")
	quit(0)
