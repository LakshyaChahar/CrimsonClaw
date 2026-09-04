# Dead state for managing enemy death and despawning
extends CharacterState
class_name EnemyDeadState

@export var despawn_time: float = 2.0
var despawn_timer: float = 0.0

func enter() -> void:
	despawn_timer = despawn_time
	character.velocity.x = 0.0
	
	# Disable combat layer (0) but keep world floor mask (1) so enemy rests on floor!
	character.collision_layer = 0
	character.collision_mask = 1
	
	var hurtbox = character.find_child("Hurtbox")
	if hurtbox:
		for child in hurtbox.get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", true)
				
	var hitbox = character.find_child("Hitbox")
	if hitbox:
		for child in hitbox.get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", true)
	
	if character.animation_manager and character.animation_manager.sprite:
		var sprite = character.animation_manager.sprite
		var sprite_frames = sprite.sprite_frames
		if sprite_frames:
			if sprite_frames.has_animation("die"):
				character.animation_manager.play_anim("die", 100, true)
			elif sprite_frames.has_animation("death"):
				character.animation_manager.play_anim("death", 100, true)
			else:
				character.animation_manager.play_anim("idle", 100, true)
				
		var ash_particles = character.find_child("AshParticles", true, false) as GPUParticles2D
		if ash_particles:
			ash_particles.emitting = true

		if sprite.material:
			var tween = create_tween()
			tween.tween_property(sprite.material, "shader_parameter/dissolve_amount", 1.0, despawn_time)

func physics_update(delta: float) -> void:
	character.velocity.x = move_toward(character.velocity.x, 0.0, delta * 3000.0)
	character.apply_gravity(delta)
	character.move_and_slide()
	
	despawn_timer -= delta
	if despawn_timer <= 0.0:
		if character and character.has_method("despawn_for_respawn"):
			character.despawn_for_respawn()
		elif character:
			character.queue_free()
