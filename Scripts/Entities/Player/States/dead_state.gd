extends CharacterState
class_name DeadState

func enter() -> void:
	# Stop the character horizontally immediately
	character.velocity.x = 0.0
	
	# Play the death animation if it exists
	if character.animation_manager and character.animation_manager.sprite:
		var sprite_frames = character.animation_manager.sprite.sprite_frames
		if sprite_frames:
			if sprite_frames.has_animation("die"):
				character.animation_manager.play_anim("die", 100, true)
			elif sprite_frames.has_animation("death"):
				character.animation_manager.play_anim("death", 100, true)
			else:
				# Fallback if no death animation is defined yet
				character.animation_manager.play_anim("idle", 100, true)

func physics_update(delta: float) -> void:
	# Apply gravity in case the character dies in the air
	character.apply_gravity(delta)
	character.move_and_slide()
	
	# No transition conditions because once dead, the character cannot leave this state.
