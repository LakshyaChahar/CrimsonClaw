# Ambush state for executing a high-damage first attack
extends CharacterState
class_name EnemyAmbushState

@export var ambush_duration: float = 0.8
@export var hitbox_enable_time: float = 0.2
@export var hitbox_disable_time: float = 0.5
@export var ambush_damage_multiplier: float = 2.5
@export var lunge_speed: float = 350.0
@export var ambush_animation: String = "attack"

var timer: float = 0.0
var hitbox_shape: CollisionShape2D = null
var hitbox: Hitbox = null
var original_damage: float = 0.0

func enter() -> void:
	timer = 0.0
	
	# Determine direction to player and face them
	var enemy = character as Enemy
	if enemy and enemy.target:
		var diff = enemy.target.global_position - enemy.global_position
		var dir_to_player = sign(diff.x)
		if dir_to_player != 0:
			character.input_direction.x = dir_to_player
			character.update_facing_direction()
		
		# Set 2D velocity towards target
		character.velocity = diff.normalized() * lunge_speed
	else:
		# Fallback to horizontal lunge
		character.velocity = Vector2(character.facing_direction * lunge_speed, 0.0)
	
	hitbox = character.find_child("Hitbox")
	if hitbox:
		original_damage = hitbox.damage
		hitbox.damage = original_damage * ambush_damage_multiplier
		
		for child in hitbox.get_children():
			if child is CollisionShape2D:
				hitbox_shape = child
				break
		hitbox.scale.x = character.facing_direction
		
	if character.animation_manager:
		character.animation_manager.play_anim(ambush_animation, 2)
		
	if hitbox_shape:
		hitbox_shape.set_deferred("disabled", true)

func exit() -> void:
	if hitbox_shape:
		hitbox_shape.set_deferred("disabled", true)
	
	# Restore original damage for subsequent attacks
	if hitbox:
		hitbox.damage = original_damage
	
	var enemy = character as Enemy
	if enemy:
		enemy.attack_cooldown_timer = enemy.attack_cooldown

func physics_update(delta: float) -> void:
	timer += delta
	
	# Apply gravity only after the active lunge phase is complete
	if timer >= hitbox_disable_time:
		character.apply_gravity(delta)
	
	# Gradually slow down the lunge velocity in all directions
	character.velocity = character.velocity.move_toward(Vector2.ZERO, character.friction * delta)
	character.move_and_slide()
	
	if hitbox_shape:
		if timer >= hitbox_enable_time and timer < hitbox_disable_time:
			hitbox_shape.set_deferred("disabled", false)
		else:
			hitbox_shape.set_deferred("disabled", true)
			
	if timer >= ambush_duration:
		state_machine.change_state("walk")
