# Bat normal chase state: flies towards player chest while maintaining stopping distance in front
extends CharacterState
class_name BatChaseState

@export var chest_offset_y: float = -20.0
@export var stopping_distance: float = 30.0

func enter() -> void:
	if character.animation_manager:
		character.animation_manager.play_anim("walk", 0)

func physics_update(delta: float) -> void:
	var bat = character as Bat
	if not bat or bat.is_dead:
		return
		
	if not bat.target:
		bat._find_target()
		if not bat.target:
			state_machine.change_state("idle")
			return
			
	var target_chest = bat.target.global_position + Vector2(0.0, chest_offset_y)
	var dist_to_chest = bat.global_position.distance_to(target_chest)
	
	if dist_to_chest > bat.detection_range:
		state_machine.change_state("idle")
		return
		
	# Update facing direction towards player
	var dir_x = sign(target_chest.x - bat.global_position.x)
	if dir_x != 0:
		bat.input_direction.x = dir_x
		bat.update_facing_direction()

	# If within attack range, stop movement and attack
	if dist_to_chest <= bat.attack_range:
		bat.velocity = bat.velocity.move_toward(Vector2.ZERO, 400.0 * delta)
		bat.move_and_slide()
		if bat.attack_cooldown_timer <= 0.0:
			state_machine.change_state("attack")
		return

	# Target a position in front of the player's chest to prevent clipping into/behind player body
	var target_offset = Vector2(-bat.facing_direction * stopping_distance, 0.0)
	var desired_pos = target_chest + target_offset
	
	var diff = desired_pos - bat.global_position
	var dir = diff.normalized()
	var speed = bat.move_speed
	
	bat.velocity = bat.velocity.move_toward(dir * speed, bat.acceleration * delta)
	bat.move_and_slide()
