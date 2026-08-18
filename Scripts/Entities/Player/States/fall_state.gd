extends CharacterState
class_name FallState

@export var coyote_duration: float = 0.15
var coyote_timer: float = 0.0

func enter() -> void:
	if character.animation_manager:
		character.animation_manager.play_anim("fall", 1)
	
	var prev_state = state_machine.current_state
	if prev_state and (prev_state.name.to_lower() == "walk" or prev_state.name.to_lower() == "idle"):
		coyote_timer = coyote_duration
	else:
		coyote_timer = 0.0

func physics_update(delta: float) -> void:
	coyote_timer = max(0.0, coyote_timer - delta)
	
	if character.wants_jump and coyote_timer > 0.0:
		state_machine.change_state("jump")
		return
		
	character.apply_gravity(delta)
	
	var target_speed = character.input_direction.x * character.move_speed
	character.apply_horizontal_movement(delta, target_speed, character.acceleration, character.friction)
	
	character.update_facing_direction()
	character.move_and_slide()
	
	if character.wants_dash and character.can_dash:
		state_machine.change_state("dash")
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
