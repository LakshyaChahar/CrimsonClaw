# Walk state for chasing the player with modular special attack state transitions
extends CharacterState
class_name EnemyWalkState

func enter() -> void:
	if character.animation_manager:
		character.animation_manager.play_anim("walk", 0)

func physics_update(delta: float) -> void:
	var enemy = character as Enemy
	if not enemy or not enemy.target:
		state_machine.change_state("idle")
		return
		
	if character.gravity_scale > 0.0:
		character.apply_gravity(delta)
		
	var fly_offset = Vector2(0.0, enemy.fly_offset_y) if "fly_offset_y" in enemy else (Vector2(0.0, -25.0) if character.gravity_scale == 0.0 else Vector2.ZERO)
	var target_pos = enemy.target.global_position + fly_offset
	var dist = enemy.global_position.distance_to(target_pos)
	
	if dist > enemy.detection_range:
		state_machine.change_state("idle")
		return
		
	# Check for special boss attack states with Coordinator token check (prevents dogpiling!)
	if enemy.has_method("can_perform_special_attack") and enemy.can_perform_special_attack():
		if SubBossCoordinator.can_attack(enemy):
			if "next_special_attack" in enemy:
				if enemy.next_special_attack == "slam" and state_machine.has_node("Slam"):
					state_machine.change_state("slam")
					return
				elif enemy.next_special_attack == "charge" and state_machine.has_node("Charge"):
					state_machine.change_state("charge")
					return
			if state_machine.has_node("Snipe"):
				state_machine.change_state("snipe")
				return
			elif state_machine.has_node("PhaseStrike"):
				state_machine.change_state("phasestrike")
				return

	var allows_basic_attack = not ("disable_basic_attack" in enemy and enemy.disable_basic_attack) and not (enemy is PyroArchonBoss)

	if allows_basic_attack and enemy.attack_range > 0.0 and dist <= enemy.attack_range and enemy.attack_cooldown_timer <= 0.0:
		if enemy.is_visible_in_screen():
			state_machine.change_state("attack")
			return
		
	var diff_x = target_pos.x - enemy.global_position.x
	var dir_to_player = sign(diff_x)
	if dir_to_player == 0:
		dir_to_player = character.facing_direction
		
	var desired_stop_range = 0.0
	if "keep_distance" in enemy:
		desired_stop_range = enemy.keep_distance
	elif enemy is PyroArchonBoss:
		desired_stop_range = 280.0

	if desired_stop_range > 0.0 and dist <= desired_stop_range:
		character.input_direction.x = 0.0
		character.facing_direction = int(dir_to_player)
		character.update_facing_direction()
		if character.animation_manager:
			character.animation_manager.play_anim("idle", 0)
		if character.gravity_scale == 0.0:
			character.velocity = character.velocity.move_toward(Vector2.ZERO, character.friction * delta)
		else:
			character.apply_horizontal_movement(delta, 0.0, character.acceleration, character.friction)
	else:
		character.input_direction.x = dir_to_player
		character.update_facing_direction()
		if character.animation_manager:
			character.animation_manager.play_anim("walk", 0)
		if character.gravity_scale == 0.0:
			var dir_2d = (target_pos - enemy.global_position).normalized()
			character.velocity = character.velocity.move_toward(dir_2d * character.move_speed, character.acceleration * delta)
		else:
			var target_speed = dir_to_player * character.move_speed
			character.apply_horizontal_movement(delta, target_speed, character.acceleration, character.friction)

	character.move_and_slide()
