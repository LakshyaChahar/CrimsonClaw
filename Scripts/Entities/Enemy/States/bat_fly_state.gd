# Fly state for bat homing and phasing through the player
extends CharacterState
class_name BatFlyState

func enter() -> void:
	if character.animation_manager:
		character.animation_manager.play_anim("walk", 0)

func physics_update(delta: float) -> void:
	var bat = character as Bat
	if not bat or bat.is_dead:
		return
		
	if not bat.target:
		bat._find_target()
		
	if bat.target:
		var diff = bat.target.global_position - bat.global_position
		var dir = diff.normalized()
		bat.velocity = dir * bat.fly_speed
		
		if dir.x != 0.0:
			bat.input_direction.x = sign(dir.x)
			bat.update_facing_direction()
	else:
		bat.velocity = Vector2(bat.facing_direction * bat.fly_speed, 0.0)
		
	# Move and phase cleanly through player physical body
	bat.move_and_slide()
