extends CharacterState
class_name StunState

func enter() -> void:
	# Clear player input wishes so they don't execute automatically when stun ends
	character.wants_jump = false
	character.wants_dash = false
	character.wants_skill = false
	
	# Play the stun or hurt animation if it exists
	if character.animation_manager and character.animation_manager.sprite:
		var sprite_frames = character.animation_manager.sprite.sprite_frames
		if sprite_frames:
			if sprite_frames.has_animation("stun"):
				character.animation_manager.play_anim("stun", 80, true)
			elif sprite_frames.has_animation("hurt"):
				character.animation_manager.play_anim("hurt", 80, true)
			else:
				# Fallback if no specific stun or hurt animation is defined yet
				character.animation_manager.play_anim("idle", 80, true)

func physics_update(delta: float) -> void:
	# Apply gravity while stunned in case we are in mid-air
	character.apply_gravity(delta)
	
	# Apply deceleration so knockback naturally wears off
	character.apply_horizontal_movement(delta, 0.0, character.acceleration, character.friction)
	
	character.move_and_slide()
	
	# Tick down the stun duration
	character.stun_timer -= delta
	
	# When the stun duration ends, transition back to the correct state
	if character.stun_timer <= 0.0:
		if character.is_grounded() or not state_machine.states.has("fall"):
			state_machine.change_state("idle")
		else:
			state_machine.change_state("fall")

func exit() -> void:
	if character and character.animation_manager:
		character.animation_manager.current_priority = 0

