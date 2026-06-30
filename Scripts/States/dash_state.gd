extends CharacterState
class_name DashState

var dash_timer: float = 0.0

func enter() -> void:
	if character.animation_manager:
		character.animation_manager.play_anim("dash", 2)
		
	character.is_dashing = true
	character.can_dash = false
	character.wants_dash = false
	
	if character.input_direction != Vector2.ZERO:
		character.dash_direction = character.input_direction.normalized()
	else:
		character.dash_direction = Vector2(character.facing_direction, 0.0)
		
	character.velocity = character.dash_direction * character.dash_speed
	dash_timer = character.dash_duration

func exit() -> void:
	character.is_dashing = false
	character.velocity = character.velocity * 0.5
	
	get_tree().create_timer(character.dash_cooldown).timeout.connect(
		func(): character.can_dash = true
	)

func physics_update(delta: float) -> void:
	dash_timer -= delta
	character.move_and_slide()
	
	if dash_timer <= 0.0:
		if character.is_grounded():
			if character.input_direction.x != 0.0:
				state_machine.change_state("walk")
			else:
				state_machine.change_state("idle")
		else:
			state_machine.change_state("fall")
