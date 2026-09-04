extends CharacterState
class_name IdleState

func enter() -> void:
	if character.animation_manager:
		character.animation_manager.play_anim("idle", 0)
	character.reset_jumps()
	
	# Stop horizontal movement completely or apply heavy friction
	character.velocity.x = move_toward(character.velocity.x, 0.0, character.friction * 0.1)

func physics_update(delta: float) -> void:
	# Apply gravity
	character.apply_gravity(delta)
	
	# Decelerate to zero speed-
	character.apply_horizontal_movement(delta, 0.0, character.acceleration, character.friction)
	
	character.move_and_slide()
	
	# Transition logic
	if character.wants_dash and character.can_dash:
		state_machine.change_state("dash")
		return
		
	if character.wants_jump:
		state_machine.change_state("jump")
		return
		
	if not character.is_grounded():
		state_machine.change_state("fall")
		return
		
	if character.input_direction.x != 0.0:
		state_machine.change_state("walk")
		return
		
	if "wants_hellforge_dive" in character and character.wants_hellforge_dive:
		if character.has_method("can_hellforge_dive") and not character.can_hellforge_dive():
			character.wants_hellforge_dive = false
			if "hellforge_dive_buffer_timer" in character:
				character.hellforge_dive_buffer_timer = 0.0
		else:
			state_machine.change_state("hellforge_dive")
			return

	if "wants_ignis_claw" in character and character.wants_ignis_claw:
		state_machine.change_state("ignis_claw")
		return

	if character.wants_skill:
		state_machine.change_state("skill")
		return
