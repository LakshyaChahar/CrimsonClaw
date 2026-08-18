extends CharacterState
class_name JumpState

func enter() -> void:
	if character.animation_manager:
		character.animation_manager.play_anim("jump", 1)
	character.velocity.y = character.jump_force
	character.wants_jump = false

func physics_update(delta: float) -> void:
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
		
	if "wants_ignis_claw" in character and character.wants_ignis_claw:
		state_machine.change_state("ignis_claw")
		return

	if character.wants_skill:
		state_machine.change_state("skill")
		return
