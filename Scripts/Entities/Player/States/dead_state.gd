# DeadState handles player death, visual knockdown, and level restart
extends CharacterState
class_name DeadState

@export var restart_delay: float = 1.5

func enter() -> void:
	character.velocity.x = 0.0
	character.is_dead = true
	
	# Disable combat collision (0) but keep world floor mask (1) so player stays on ground!
	character.collision_layer = 0
	character.collision_mask = 1
	
	var hurtbox = character.find_child("Hurtbox")
	if hurtbox:
		for child in hurtbox.get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", true)
	
	if character.animation_manager and character.animation_manager.sprite:
		var sprite_frames = character.animation_manager.sprite.sprite_frames
		var sprite = character.animation_manager.sprite
		if sprite_frames and sprite_frames.has_animation("die"):
			character.animation_manager.play_anim("die", 100, true)
		elif sprite_frames and sprite_frames.has_animation("death"):
			character.animation_manager.play_anim("death", 100, true)
		else:
			character.animation_manager.play_anim("idle", 100, true)
			sprite.modulate = Color(0.4, 0.1, 0.1, 1.0)
			
	print("[Combat] Player died! Respawning in ", restart_delay, " seconds...")
	
	get_tree().create_timer(restart_delay).timeout.connect(_on_respawn_timer_timeout)

func _on_respawn_timer_timeout() -> void:
	if character and character.has_method("respawn"):
		character.respawn()
	elif character and character.is_inside_tree() and character.get_tree():
		character.get_tree().reload_current_scene()

func physics_update(delta: float) -> void:
	character.velocity.x = move_toward(character.velocity.x, 0.0, delta * 3000.0)
	character.apply_gravity(delta)
	character.move_and_slide()
