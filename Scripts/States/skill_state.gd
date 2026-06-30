extends CharacterState
class_name SkillState

@export var skill_duration: float = 0.4
var timer: float = 0.0
var anim_finished: bool = false

func enter() -> void:
	anim_finished = false
	timer = skill_duration
	character.wants_skill = false
	
	if character.animation_manager:
		character.animation_manager.play_anim("attack", 2)
		if character.animation_manager.sprite:
			character.animation_manager.sprite.animation_finished.connect(_on_animation_finished)
			
	character.velocity.x = 0.0

func exit() -> void:
	if character.animation_manager and character.animation_manager.sprite:
		if character.animation_manager.sprite.animation_finished.is_connected(_on_animation_finished):
			character.animation_manager.sprite.animation_finished.disconnect(_on_animation_finished)

func physics_update(delta: float) -> void:
	timer -= delta
	character.apply_gravity(delta)
	character.move_and_slide()
	
	if anim_finished or timer <= 0.0:
		if character.is_grounded():
			if character.input_direction.x != 0.0:
				state_machine.change_state("walk")
			else:
				state_machine.change_state("idle")
		else:
			state_machine.change_state("fall")

func _on_animation_finished() -> void:
	anim_finished = true
