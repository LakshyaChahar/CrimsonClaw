# Ranged attack state handling projectile instantiation timing
extends CharacterState
class_name EnemyRangedAttackState

@export var attack_duration: float = 0.8
@export var projectile_spawn_time: float = 0.3

var timer: float = 0.0
var has_spawned_projectile: bool = false

func enter() -> void:
	timer = 0.0
	has_spawned_projectile = false
	character.velocity.x = 0.0
	
	var enemy = character as RangedEnemy
	if enemy and enemy.target:
		# Face target before attacking
		var dir_to_target = sign(enemy.target.global_position.x - enemy.global_position.x)
		if dir_to_target != 0:
			character.facing_direction = int(dir_to_target)
			if character.animation_manager and character.animation_manager.sprite:
				character.animation_manager.sprite.flip_h = (character.facing_direction == -1)

	if character.animation_manager:
		character.animation_manager.play_anim("attack", 2)

func exit() -> void:
	if character.animation_manager and character.animation_manager.sprite:
		character.animation_manager.sprite.speed_scale = 1.0
		
	var enemy = character as RangedEnemy
	if enemy:
		enemy.attack_cooldown_timer = enemy.attack_cooldown

func physics_update(delta: float) -> void:
	timer += delta
	character.apply_gravity(delta)
	character.move_and_slide()
	
	var enemy = character as RangedEnemy
	if enemy and not has_spawned_projectile and timer >= projectile_spawn_time:
		has_spawned_projectile = true
		enemy.fire_projectile()

	if timer >= attack_duration:
		state_machine.change_state("walk")
