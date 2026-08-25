# Dead state for managing enemy death and despawning
extends CharacterState
class_name EnemyDeadState

@export var despawn_time: float = 2.0
var despawn_timer: float = 0.0

func enter() -> void:
	despawn_timer = despawn_time
	character.velocity = Vector2.ZERO
	character.is_dead = true
	
	# Disable entity collision layer so player and other entities pass through corpse
	character.collision_layer = 0
	# Retain World environment collision mask (Layer 1) so enemy rests on floor and does not fall through world
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
		var sprite_frames = character.animation_manager.sprite.sprite_frames
		if sprite_frames:
			if sprite_frames.has_animation("die"):
				character.animation_manager.play_anim("die", 100, true)
			elif sprite_frames.has_animation("death"):
				character.animation_manager.play_anim("death", 100, true)
			elif sprite_frames.has_animation("hurt"):
				character.animation_manager.play_anim("hurt", 100, true)
			else:
				character.animation_manager.play_anim("idle", 100, true)

func physics_update(delta: float) -> void:
	character.velocity.x = move_toward(character.velocity.x, 0.0, delta * 3000.0)
	character.apply_gravity(delta)
	character.move_and_slide()
	
	despawn_timer -= delta
	
	# Smoothly dissolve/fade out sprite over the last 0.5 seconds before despawning
	if despawn_timer <= 0.5 and character.animation_manager and character.animation_manager.sprite:
		var sprite = character.animation_manager.sprite
		sprite.modulate.a = move_toward(sprite.modulate.a, 0.0, delta * 2.0)

	if despawn_timer <= 0.0:
		character.queue_free()
