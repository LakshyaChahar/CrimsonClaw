# Idle state for the enemy AI
extends CharacterState
class_name EnemyIdleState

func enter() -> void:
	if character.animation_manager:
		character.animation_manager.play_anim("idle", 0)

func physics_update(delta: float) -> void:
	character.apply_gravity(delta)
	character.apply_horizontal_movement(delta, 0.0, character.acceleration, character.friction)
	character.move_and_slide()
	
	var enemy = character as Enemy
	if enemy and enemy.target:
		if enemy.is_stealth and not enemy.is_revealed:
			return
			
		var dist = enemy.global_position.distance_to(enemy.target.global_position)
		if dist <= enemy.detection_range:
			state_machine.change_state("walk")
