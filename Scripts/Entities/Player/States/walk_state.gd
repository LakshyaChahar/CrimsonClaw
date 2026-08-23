extends CharacterState
class_name WalkState

func enter() -> void:
	if character.animation_manager:
		character.animation_manager.play_anim("walk", 0)

func physics_update(delta: float) -> void:
	# Apply gravity in case we step off a ledge
	character.apply_gravity(delta)
	
	# Apply movement speed based on input
	var target_speed = character.input_direction.x * character.move_speed
	character.apply_horizontal_movement(delta, target_speed, character.acceleration, character.friction)
	
	# Update sprite flip direction
	character.update_facing_direction()
	
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
		
	if character.input_direction.x == 0.0 and is_equal_approx(character.velocity.x, 0.0):
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

