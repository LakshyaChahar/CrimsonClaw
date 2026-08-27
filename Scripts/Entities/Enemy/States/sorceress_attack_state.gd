# Attack state handling Sorceress bat summoning timing and animation
extends CharacterState
class_name SorceressAttackState

@export var attack_duration: float = 1.0
@export var summon_time: float = 0.4

var timer: float = 0.0
var has_summoned: bool = false

func enter() -> void:
	timer = 0.0
	has_summoned = false
	character.velocity.x = 0.0
	
	var sorceress = character as Sorceress
	if sorceress and sorceress.target:
		# Face target before summoning
		var dir_to_target = sign(sorceress.target.global_position.x - sorceress.global_position.x)
		if dir_to_target != 0:
			character.facing_direction = int(dir_to_target)
			character.update_sprite_facing()

	if character.animation_manager:
		character.animation_manager.play_anim("attack", 2)

func exit() -> void:
	if character.animation_manager and character.animation_manager.sprite:
		character.animation_manager.sprite.speed_scale = 1.0
		
	var enemy = character as Enemy
	if enemy:
		enemy.attack_cooldown_timer = enemy.attack_cooldown

func physics_update(delta: float) -> void:
	timer += delta
	character.apply_gravity(delta)
	character.move_and_slide()
	
	var sorceress = character as Sorceress
	if sorceress and not has_summoned and timer >= summon_time:
		has_summoned = true
		sorceress.execute_attack()

	if timer >= attack_duration:
		state_machine.change_state("walk")
