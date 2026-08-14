# Ambush state for executing a high-damage first attack
extends CharacterState
class_name EnemyAmbushState

@export var ambush_duration: float = 0.8
@export var hitbox_enable_time: float = 0.0
@export var hitbox_disable_time: float = 0.5

@export var ambush_animation: String = "attack"

var ambush_damage: float = 25.0
var timer: float = 0.0
var hitbox_shape: CollisionShape2D = null
var hitbox: Hitbox = null
var original_damage: float = 0.0
var original_hitbox_pos: Vector2 = Vector2.ZERO
var original_collision_layer: int = 0
var original_collision_mask: int = 0

func enter() -> void:
	timer = 0.0
	
	# Determine direction to player and face them
	var enemy = character as Enemy
	var current_lunge_speed = 350.0
	
	if enemy:
		if "ambush_damage" in enemy:
			ambush_damage = enemy.ambush_damage
		if "ambush_lunge_speed" in enemy:
			current_lunge_speed = enemy.ambush_lunge_speed
			
		if enemy.target:
			var diff = enemy.target.global_position - enemy.global_position
			var dir_to_player = sign(diff.x)
			if dir_to_player != 0:
				character.input_direction.x = dir_to_player
				character.update_facing_direction()
			
			# Set 2D velocity towards target
			character.velocity = diff.normalized() * current_lunge_speed
		else:
			# Fallback to horizontal lunge
			character.velocity = Vector2(character.facing_direction * current_lunge_speed, 0.0)
	else:
		# Fallback to horizontal lunge
		character.velocity = Vector2(character.facing_direction * current_lunge_speed, 0.0)
	
	hitbox = character.find_child("Hitbox")
	if hitbox:
		original_damage = hitbox.damage
		hitbox.damage = ambush_damage
		
		for child in hitbox.get_children():
			if child is CollisionShape2D:
				hitbox_shape = child
				break
				
		hitbox.scale.x = character.facing_direction
		
		# Center and enlarge the Area2D hitbox for a dive bomb attack (scale Area2D, NOT CollisionShape2D)
		if hitbox_shape:
			original_hitbox_pos = hitbox_shape.position
			hitbox_shape.position = Vector2.ZERO
		
		hitbox.scale = Vector2(character.facing_direction * 1.5, 1.5)
			
	# Turn off physical collision with the Player layer (Layer 2) and our own physical layer (Layer 4)
	original_collision_mask = character.collision_mask
	original_collision_layer = character.collision_layer
	character.collision_mask = 1 # Only collide with World (Layer 1)
	character.collision_layer = 0 # Prevent the player from bumping into us
		
	if character.animation_manager:
		character.animation_manager.play_anim(ambush_animation, 2)
		
	if hitbox_shape:
		var should_be_disabled = (hitbox_enable_time > 0.0)
		hitbox_shape.set_deferred("disabled", should_be_disabled)

func exit() -> void:
	if character.animation_manager:
		character.animation_manager.current_priority = 0
		
	# Restore physical collisions
	character.collision_mask = original_collision_mask
	character.collision_layer = original_collision_layer
		
	if hitbox_shape:
		hitbox_shape.set_deferred("disabled", true)
		hitbox_shape.position = original_hitbox_pos
	
	if hitbox:
		hitbox.damage = original_damage
		hitbox.scale = Vector2(character.facing_direction, 1.0)
	
	var enemy = character as Enemy
	if enemy:
		enemy.attack_cooldown_timer = enemy.attack_cooldown

func physics_update(delta: float) -> void:
	timer += delta
	
	# Apply gravity and friction only AFTER the dive lunge phase is over
	if timer >= hitbox_disable_time:
		character.apply_gravity(delta)
		character.velocity = character.velocity.move_toward(Vector2.ZERO, character.friction * delta)
	
	character.move_and_slide()
	
	if hitbox_shape:
		if timer >= hitbox_enable_time and timer < hitbox_disable_time:
			if hitbox_shape.disabled:
				hitbox_shape.set_deferred("disabled", false)
		else:
			if not hitbox_shape.disabled:
				hitbox_shape.set_deferred("disabled", true)
			
	if timer >= ambush_duration:
		state_machine.change_state("walk")
