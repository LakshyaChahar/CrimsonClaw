# DeadState handles player death, visual knockdown, and level restart
extends CharacterState
class_name DeadState

@export var restart_delay: float = 1.5

func enter() -> void:
	# 1. Stop horizontal movement, apply a small "death hop", and flag death
	character.velocity.x = 0.0
	character.velocity.y = character.jump_force * 0.7 # Pop up slightly before falling
	character.is_dead = true
	
	# 2. Disable world collision so the player falls completely through the floor
	character.collision_layer = 0
	character.collision_mask = 0
	
	# 3. Disable Player Hurtbox so enemy attacks stop registering on corpse
	var hurtbox = character.find_child("Hurtbox")
	if hurtbox:
		for child in hurtbox.get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", true)
	
	# 4. Play visual death effect (dark red tint and falling animation)
	if character.animation_manager and character.animation_manager.sprite:
		var sprite = character.animation_manager.sprite
		# Keep them upright but looking like they're falling
		character.animation_manager.play_anim("fall", 1)
		sprite.modulate = Color(0.4, 0.1, 0.1, 1.0) # Dark red tint
			
	print("[Combat] Player died! Falling through world... Restarting level in ", restart_delay, " seconds.")
	
	# 5. Automatically reload the scene after delay
	get_tree().create_timer(restart_delay).timeout.connect(_on_restart_timer_timeout)

func _on_restart_timer_timeout() -> void:
	if character and character.is_inside_tree() and character.get_tree():
		character.get_tree().reload_current_scene()

func physics_update(delta: float) -> void:
	# Gravity pulls the player down forever because collision_mask is 0!
	character.apply_gravity(delta)
	character.move_and_slide()
