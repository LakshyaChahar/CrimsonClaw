# Attack state handling damage collision timing
extends CharacterState
class_name EnemyAttackState

@export var attack_duration: float = 0.6
@export var hitbox_enable_time: float = 0.2
@export var hitbox_disable_time: float = 0.4

var timer: float = 0.0
var hitbox_shape: CollisionShape2D = null
var hitbox: Hitbox = null

func enter() -> void:
	timer = 0.0
	character.velocity.x = 0.0
	
	hitbox = character.find_child("Hitbox")
	if hitbox:
		for child in hitbox.get_children():
			if child is CollisionShape2D:
				hitbox_shape = child
				break
		hitbox.scale.x = character.facing_direction
		
	if character.animation_manager:
		character.animation_manager.play_anim("attack", 2)
		
	if hitbox_shape:
		hitbox_shape.set_deferred("disabled", true)

func exit() -> void:
	if hitbox_shape:
		hitbox_shape.set_deferred("disabled", true)
	
	var enemy = character as Enemy
	if enemy:
		enemy.attack_cooldown_timer = enemy.attack_cooldown

func physics_update(delta: float) -> void:
	timer += delta
	character.apply_gravity(delta)
	character.move_and_slide()
	
	if hitbox_shape:
		if timer >= hitbox_enable_time and timer < hitbox_disable_time:
			hitbox_shape.set_deferred("disabled", false)
		else:
			hitbox_shape.set_deferred("disabled", true)
			
	if timer >= attack_duration:
		state_machine.change_state("walk")
