# DashState handles high-speed dash movement, cooldown, and smooth transition back to idle/walk
extends CharacterState
class_name DashState

var dash_timer: float = 0.0

func enter() -> void:
	character.is_dashing = true
	character.can_dash = false
	character.wants_dash = false
	if "dash_buffer_timer" in character:
		character.dash_buffer_timer = 0.0
	
	if character.animation_manager:
		character.animation_manager.play_anim("dash", 2)
		
	if character.input_direction != Vector2.ZERO:
		character.dash_direction = character.input_direction.normalized()
	else:
		character.dash_direction = Vector2(character.facing_direction, 0.0)
		
	character.velocity = character.dash_direction * character.dash_speed
	dash_timer = character.dash_duration

func exit() -> void:
	character.is_dashing = false
	character.wants_dash = false
	if "dash_buffer_timer" in character:
		character.dash_buffer_timer = 0.0
		
	# Smooth velocity transition out of dash
	if character.input_direction.x == 0.0:
		character.velocity.x = 0.0
	else:
		character.velocity.x = character.facing_direction * character.move_speed
		
	# Reset animation speed scale back to 1.0 and clear priority
	if character.animation_manager:
		if character.animation_manager.sprite:
			character.animation_manager.sprite.speed_scale = 1.0
		character.animation_manager.current_priority = 0
	
	# Start cooldown timer safely
	get_tree().create_timer(character.dash_cooldown).timeout.connect(
		func(): 
			if is_instance_valid(character): 
				character.can_dash = true
	)

func physics_update(delta: float) -> void:
	dash_timer -= delta
	character.move_and_slide()
	
	if dash_timer <= 0.0:
		character.is_dashing = false
		if character.is_grounded():
			if character.input_direction.x != 0.0:
				state_machine.change_state("walk")
			else:
				state_machine.change_state("idle")
		else:
			state_machine.change_state("fall")
