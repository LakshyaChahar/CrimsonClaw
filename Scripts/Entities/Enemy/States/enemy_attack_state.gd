# Attack state handling damage collision timing
extends CharacterState
class_name EnemyAttackState

@export var attack_duration: float = 0.6
@export var hitbox_enable_time: float = 0.1
@export var hitbox_disable_time: float = 0.5

var timer: float = 0.0
var hitbox_shape: CollisionShape2D = null
var hitbox: Hitbox = null

func enter() -> void:
	timer = 0.0
	character.velocity.x = 0.0
	
	var enemy = character as Enemy
	if enemy and enemy.target:
		var dir_to_target = sign(enemy.target.global_position.x - enemy.global_position.x)
		if dir_to_target != 0:
			character.facing_direction = int(dir_to_target)
			if character.animation_manager and character.animation_manager.sprite:
				character.animation_manager.sprite.flip_h = (character.facing_direction == -1)

	hitbox = character.find_child("Hitbox")
	if hitbox:
		for child in hitbox.get_children():
			if child is CollisionShape2D:
				hitbox_shape = child
				break
		hitbox.scale.x = character.facing_direction
		
	if character.animation_manager:
		character.animation_manager.play_anim("attack", 2)
		var sprite = character.animation_manager.sprite
		if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("attack"):
			var frames = sprite.sprite_frames.get_frame_count("attack")
			var fps = sprite.sprite_frames.get_animation_speed("attack")
			if fps > 0:
				var anim_len = float(frames) / fps
				sprite.speed_scale = anim_len / attack_duration
		
	if hitbox_shape:
		hitbox_shape.set_deferred("disabled", true)

func exit() -> void:
	if character.animation_manager and character.animation_manager.sprite:
		character.animation_manager.sprite.speed_scale = 1.0
		
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
