# Initial phase fly state: swoops cleanly through player's chest level once, dealing damage on contact
extends CharacterState
class_name BatPhaseFlyState

@export var phase_duration: float = 1.2
@export var chest_offset_y: float = -20.0

var timer: float = 0.0
var phase_direction: Vector2 = Vector2.ZERO
var original_layer: int = 8
var original_mask: int = 3
var hitbox_shape: CollisionShape2D = null

func enter() -> void:
	timer = 0.0
	
	var bat = character as Bat
	if bat:
		if "phase_duration" in bat:
			phase_duration = bat.phase_duration
			
	# Phase mode: turn off physical layer (0) and physical mask (1 for environment only)
	# This ensures the player character body CANNOT block or bump the bat at all!
	original_layer = character.collision_layer
	original_mask = character.collision_mask
	character.collision_layer = 0
	character.collision_mask = 1
	
	# Determine initial target chest position and lock in phase direction
	var target_chest = _get_target_chest()
	phase_direction = (target_chest - character.global_position).normalized()
	if phase_direction == Vector2.ZERO:
		phase_direction = Vector2(character.facing_direction, 0.0).normalized()
		
	# Enable Hitbox during phase pass
	var hitbox = character.find_child("Hitbox")
	if hitbox:
		for child in hitbox.get_children():
			if child is CollisionShape2D:
				hitbox_shape = child
				hitbox_shape.set_deferred("disabled", false)
				break

	if character.animation_manager:
		character.animation_manager.play_anim("walk", 0)

func exit() -> void:
	# Restore normal physical collisions
	character.collision_layer = original_layer if original_layer != 0 else 8
	character.collision_mask = original_mask if original_mask != 0 else 3
	
	# Disable phase hitbox (normal attack state handles its own hitbox timing)
	if hitbox_shape:
		hitbox_shape.set_deferred("disabled", true)
		
	# Reset velocity on exit so high phase speed doesn't coast into player body
	character.velocity = Vector2.ZERO
	
	var enemy = character as Enemy
	if enemy:
		enemy.attack_cooldown_timer = enemy.attack_cooldown

func physics_update(delta: float) -> void:
	timer += delta
	var bat = character as Bat
	if not bat or bat.is_dead:
		return
		
	# Dynamically adjust fly vector towards player chest while approaching,
	# but maintain forward momentum to pass cleanly through!
	if bat.target:
		var target_chest = _get_target_chest()
		var to_chest = (target_chest - bat.global_position)
		
		# Adjust trajectory toward chest while approaching
		if to_chest.length() > 15.0 and timer < (phase_duration * 0.6):
			phase_direction = to_chest.normalized()
			
		if phase_direction.x != 0.0:
			bat.input_direction.x = sign(phase_direction.x)
			bat.update_facing_direction()

	var speed = bat.phase_fly_speed if "phase_fly_speed" in bat else 280.0
	bat.velocity = phase_direction * speed
	bat.move_and_slide()
	
	if timer >= phase_duration:
		state_machine.change_state("walk")

func _get_target_chest() -> Vector2:
	var bat = character as Bat
	if bat and bat.target:
		return bat.target.global_position + Vector2(0.0, chest_offset_y)
	return character.global_position + Vector2(character.facing_direction * 100.0, chest_offset_y)
