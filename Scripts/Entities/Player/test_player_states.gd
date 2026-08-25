extends SceneTree

func _initialize() -> void:
	print("--- Starting Character State Machine Tests ---")
	
	# 1. Load scene
	var scene_path = "res://Scenes/Entities/Player/player.tscn"
	var player_scene = load(scene_path)
	if not player_scene:
		print("FAILED: Could not load player.tscn")
		quit(1)
		return
	print("SUCCESS: Loaded player.tscn")
	
	# 2. Instantiate player
	var player = player_scene.instantiate()
	if not player:
		print("FAILED: Could not instantiate player scene")
		quit(1)
		return
	print("SUCCESS: Instantiated player")
	
	# Enable mock floor contact initially
	player.force_on_floor = true
	
	# 3. Add to root and wait for frame so _ready() executes
	root.add_child(player)
	await process_frame
	print("SUCCESS: Added player to Scene Tree and processed frame")
	
	# 4. Verify initial state
	var sm = player.state_machine
	if not sm:
		print("FAILED: CharacterStateMachine not found on player")
		for child in player.get_children():
			print("Found child node: ", child.name, " class: ", child.get_class())
		quit(1)
		return
	print("SUCCESS: State machine found. Initial state: ", sm.current_state.name)
	
	if sm.current_state.name.to_lower() != "idle":
		print("FAILED: Expected initial state to be 'Idle', got: ", sm.current_state.name)
		quit(1)
		return
	print("SUCCESS: Initial state is Idle")
	
	# 5. Test Walk transition
	print("Testing transition: Idle -> Walk")
	player.input_direction = Vector2(1.0, 0.0)
	
	player._physics_process(0.016)
	sm._physics_process(0.016)
	
	print("Current state after moving: ", sm.current_state.name)
	if sm.current_state.name.to_lower() != "walk":
		print("FAILED: State did not transition to Walk")
		quit(1)
		return
	print("SUCCESS: Transitioned to Walk")
	
	# 6. Test Jump transition
	print("Testing transition: Walk -> Jump")
	player.wants_jump = true
	
	player._physics_process(0.016)
	sm._physics_process(0.016)
	
	print("Current state after jump request: ", sm.current_state.name)
	if sm.current_state.name.to_lower() != "jump":
		print("FAILED: State did not transition to Jump")
		quit(1)
		return
	print("SUCCESS: Transitioned to Jump")
	
	# We are now in the air
	player.force_on_floor = false
	
	# 7. Test Fall transition
	print("Testing transition: Jump -> Fall")
	# Simulate vertical velocity switching to falling
	player.velocity.y = 100.0
	
	player._physics_process(0.016)
	sm._physics_process(0.016)
	
	print("Current state after falling: ", sm.current_state.name)
	if sm.current_state.name.to_lower() != "fall":
		print("FAILED: State did not transition to Fall")
		quit(1)
		return
	print("SUCCESS: Transitioned to Fall")
	
	# 8. Test Fall -> Dash transition
	print("Testing transition: Fall -> Dash")
	player.wants_dash = true
	
	player._physics_process(0.016)
	sm._physics_process(0.016)
	
	print("Current state after dash request: ", sm.current_state.name)
	if sm.current_state.name.to_lower() != "dash":
		print("FAILED: State did not transition to Dash")
		quit(1)
		return
	print("SUCCESS: Transitioned to Dash")
	
	# 9. Test Dash -> Idle transition (when landing)
	print("Testing transition: Dash -> Idle (landing after dash timer expires)")
	player.input_direction = Vector2.ZERO
	player.force_on_floor = true
	var dash_state = sm.current_state
	dash_state.dash_timer = 0.0 # Force dash timer to expire immediately
	
	player._physics_process(0.016)
	sm._physics_process(0.016)
	
	print("Current state after dash expiration: ", sm.current_state.name)
	if sm.current_state.name.to_lower() != "idle":
		print("FAILED: State did not transition to Idle, got: ", sm.current_state.name)
		quit(1)
		return
	print("SUCCESS: Transitioned to Idle")
	
	# 10. Test Idle -> Skill transition
	print("Testing transition: Idle -> Skill")
	player.wants_skill = true
	
	player._physics_process(0.016)
	sm._physics_process(0.016)
	
	print("Current state after skill request: ", sm.current_state.name)
	if sm.current_state.name.to_lower() != "skill":
		print("FAILED: State did not transition to Skill")
		quit(1)
		return
	print("SUCCESS: Transitioned to Skill")
	
	# 11. Test Idle -> HellforgeDive transition
	print("Testing transition: Idle -> HellforgeDive")
	player.current_bloodthirst = 100.0
	player.wants_hellforge_dive = true
	sm.change_state("idle")
	
	player._physics_process(0.016)
	sm._physics_process(0.016)
	
	print("Current state after Hellforge Dive request: ", sm.current_state.name)
	if sm.current_state.name.to_lower() != "hellforgedive":
		print("FAILED: State did not transition to HellforgeDive, got: ", sm.current_state.name)
		quit(1)
		return
	print("SUCCESS: Transitioned to HellforgeDive")

	# 12. Test Death and Respawn
	print("Testing transition: Death -> Respawn")
	sm.change_state("idle")
	player.die()
	player._physics_process(0.016)
	sm._physics_process(0.016)
	
	if sm.current_state.name.to_lower() != "dead":
		print("FAILED: State did not transition to Dead, got: ", sm.current_state.name)
		quit(1)
		return
	print("SUCCESS: Transitioned to Dead state. Collision mask: ", player.collision_mask)
	if player.collision_mask != 1:
		print("FAILED: Expected collision_mask to be 1 to prevent falling through world, got: ", player.collision_mask)
		quit(1)
		return
		
	# Trigger respawn
	player.respawn()
	if sm.current_state.name.to_lower() != "idle":
		print("FAILED: State did not transition back to Idle after respawn, got: ", sm.current_state.name)
		quit(1)
		return
	if player.current_health != player.max_health:
		print("FAILED: Health was not restored upon respawn")
		quit(1)
		return
	print("SUCCESS: Respawned cleanly to Idle with full health!")

	print("--- All Tests Passed Successfully! ---")
	quit(0)

