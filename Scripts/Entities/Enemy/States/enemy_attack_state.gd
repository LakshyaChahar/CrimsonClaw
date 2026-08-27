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
	character.velocity = Vector2.ZERO
	
	var enemy = character as Enemy
	if enemy and enemy.target:
		var diff_x = enemy.target.global_position.x - enemy.global_position.x
		var dir_to_target = sign(diff_x) if diff_x != 0 else character.facing_direction
		character.facing_direction = int(dir_to_target)
		character.update_sprite_facing()

	hitbox = character.find_child("Hitbox")
	if hitbox:
		if enemy:
			hitbox.damage = enemy.contact_damage
			hitbox.knockback_force = enemy.attack_knockback_force
			hitbox.stun_duration = enemy.attack_stun_duration
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
	if character.animation_manager:
		character.animation_manager.current_priority = 0
		if character.animation_manager.sprite:
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
			if hitbox_shape.disabled:
				hitbox_shape.set_deferred("disabled", false)
		else:
			if not hitbox_shape.disabled:
				hitbox_shape.set_deferred("disabled", true)
			
	if timer >= attack_duration:
		state_machine.change_state("walk")
