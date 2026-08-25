# DeadState handles player death, die animation, and player respawning
extends CharacterState
class_name DeadState

@export var respawn_delay: float = 1.5

func enter() -> void:
	# 1. Stop horizontal movement, apply a small death reaction pop, and flag death
	character.velocity.x = 0.0
	character.velocity.y = character.jump_force * 0.35 # Pop up slightly before settling
	character.is_dead = true
	
	# 2. Disable entity collision layer so enemies pass through corpse,
	#    BUT retain World environment collision mask (Layer 1) so player lands on floor and doesn't fall through world!
	character.collision_layer = 0
	character.collision_mask = 1
	
	# 3. Disable Player Hurtbox so enemy attacks stop registering on corpse
	var hurtbox = character.find_child("Hurtbox")
	if hurtbox:
		for child in hurtbox.get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", true)
	
	# 4. Play visual death animation & tint
	if character.animation_manager and character.animation_manager.sprite:
		var sprite = character.animation_manager.sprite
		var sprite_frames = sprite.sprite_frames
		if sprite_frames:
			if sprite_frames.has_animation("die"):
				character.animation_manager.play_anim("die", 100, true)
			elif sprite_frames.has_animation("death"):
				character.animation_manager.play_anim("death", 100, true)
			elif sprite_frames.has_animation("hurt"):
				character.animation_manager.play_anim("hurt", 100, true)
			else:
				character.animation_manager.play_anim("fall", 100, true)
		sprite.modulate = Color(0.8, 0.25, 0.25, 1.0) # Dark red tint on death
			
	print("[Combat] Player died! Playing die animation... Respawning in ", respawn_delay, " seconds.")
	
	# 5. Automatically respawn the player after delay
	get_tree().create_timer(respawn_delay).timeout.connect(_on_respawn_timer_timeout)

func _on_respawn_timer_timeout() -> void:
	if character and character.is_inside_tree():
		if character.has_method("respawn"):
			character.respawn()
		elif state_machine:
			character.is_dead = false
			character.current_health = character.max_health
			character.collision_layer = 2
			character.collision_mask = 9
			if character.animation_manager and character.animation_manager.sprite:
				character.animation_manager.sprite.modulate = Color.WHITE
			state_machine.change_state("idle")

func physics_update(delta: float) -> void:
	# Gravity pulls the player down to rest safely on the floor while halting horizontal sliding
	character.velocity.x = move_toward(character.velocity.x, 0.0, delta * 3000.0)
	character.apply_gravity(delta)
	character.move_and_slide()
