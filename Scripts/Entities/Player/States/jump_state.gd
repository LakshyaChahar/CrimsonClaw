extends CharacterState
class_name JumpState

func enter() -> void:
	if character.animation_manager:
		character.animation_manager.play_anim("jump", 1)
	character.velocity.y = character.jump_force
	character.consume_jump_buffer()
	if character.jumps_left > 0:
		character.jumps_left -= 1

func physics_update(delta: float) -> void:
	# Check mid-air jump (double jump while rising)
	if character.wants_jump and character.jumps_left > 0:
		character.consume_jump_buffer()
		character.jumps_left -= 1
		character.velocity.y = character.jump_force
		if character.animation_manager:
			character.animation_manager.play_anim("jump", 1)
			
	character.apply_gravity(delta)
	
	var target_speed = character.input_direction.x * character.move_speed
	character.apply_horizontal_movement(delta, target_speed, character.acceleration, character.friction)
	
	character.update_facing_direction()
	character.move_and_slide()
	
	if character.wants_dash and character.can_dash:
		state_machine.change_state("dash")
		return
		
	if character.velocity.y >= 0.0:
		state_machine.change_state("fall")
		return
		
	if character.is_grounded():
		if character.input_direction.x != 0.0:
			state_machine.change_state("walk")
		else:
			state_machine.change_state("idle")
		return
		
	if "wants_hellforge_dive" in character and character.wants_hellforge_dive:
		state_machine.change_state("hellforge_dive")
		return

	if "wants_ignis_claw" in character and character.wants_ignis_claw:
		state_machine.change_state("ignis_claw")
		return

	if character.wants_skill:
		state_machine.change_state("skill")
		return

