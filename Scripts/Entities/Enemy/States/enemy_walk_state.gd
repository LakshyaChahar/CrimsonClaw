# Walk state for chasing the player
extends CharacterState
class_name EnemyWalkState

func enter() -> void:
	if character.animation_manager:
		character.animation_manager.play_anim("walk", 0)

func physics_update(delta: float) -> void:
	character.apply_gravity(delta)
	
	var enemy = character as Enemy
	if not enemy or not enemy.target:
		state_machine.change_state("idle")
		return
		
	var dist = enemy.global_position.distance_to(enemy.target.global_position)
	if dist > enemy.detection_range:
		state_machine.change_state("idle")
		return
		
	if dist <= enemy.attack_range and enemy.attack_cooldown_timer <= 0.0:
		state_machine.change_state("attack")
		return
		
	var dir_to_player = sign(enemy.target.global_position.x - enemy.global_position.x)
	if dir_to_player == 0:
		dir_to_player = 1
		
	character.input_direction.x = dir_to_player
	character.update_facing_direction()
	
	var target_speed = dir_to_player * character.move_speed
	character.apply_horizontal_movement(delta, target_speed, character.acceleration, character.friction)
	character.move_and_slide()
