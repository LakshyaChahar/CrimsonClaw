extends CharacterState
class_name MeleeAttackState

## Duration of the attack state. Used as a fallback if animation signals are not received.
@export var attack_duration: float = 0.4

var timer: float = 0.0
var anim_finished: bool = false
var hitbox_shape: CollisionShape2D = null

func enter() -> void:
	anim_finished = false
	timer = attack_duration
	character.wants_skill = false # Reset the input register
	
	# Find the sword hitbox collision shape dynamically
	var hitbox = character.find_child("SwordHitbox")
	if hitbox:
		# Search for any CollisionShape2D child node
		for child in hitbox.get_children():
			if child is CollisionShape2D:
				hitbox_shape = child
				break
		# Option A: Flip the hitbox's scale.x depending on the character's facing direction
		hitbox.scale.x = character.facing_direction
	
	# Play attack animation
	if character.animation_manager:
		character.animation_manager.play_anim("attack", 2)
		var sprite = character.animation_manager.sprite
		if sprite:
			sprite.animation_finished.connect(_on_animation_finished)
			sprite.frame_changed.connect(_on_frame_changed)
			
			# Handle placeholder/short animations by enabling hitbox immediately
			if hitbox_shape and sprite.sprite_frames and sprite.sprite_frames.has_animation("attack") and sprite.sprite_frames.get_frame_count("attack") <= 2:
				hitbox_shape.set_deferred("disabled", false)
			
	# Halt horizontal movement during melee swing
	character.velocity.x = 0.0

func exit() -> void:
	# Clean up connections
	if character.animation_manager and character.animation_manager.sprite:
		var sprite = character.animation_manager.sprite
		if sprite.animation_finished.is_connected(_on_animation_finished):
			sprite.animation_finished.disconnect(_on_animation_finished)
		if sprite.frame_changed.is_connected(_on_frame_changed):
			sprite.frame_changed.disconnect(_on_frame_changed)
			
	# Always turn off the hitbox shape when leaving the attack state
	if hitbox_shape:
		hitbox_shape.set_deferred("disabled", true)

func physics_update(delta: float) -> void:
	timer -= delta
	character.apply_gravity(delta)
	character.move_and_slide()
	
	# Transition out when the animation or backup timer finishes
	if anim_finished or timer <= 0.0:
		if character.is_grounded():
			if character.input_direction.x != 0.0:
				state_machine.change_state("walk")
			else:
				state_machine.change_state("idle")
		else:
			state_machine.change_state("fall")

func _on_frame_changed() -> void:
	var sprite = character.animation_manager.sprite
	if not sprite or not hitbox_shape:
		return
		
	# --- HITBOX TIMING CONFIGURATION ---
	# We enable the hitbox only on specific "active swing" frames of the animation.
	if sprite.animation == "attack":
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("attack") and sprite.sprite_frames.get_frame_count("attack") <= 2:
			hitbox_shape.set_deferred("disabled", false)
		elif sprite.frame in [2, 3]:
			hitbox_shape.set_deferred("disabled", false) # Enable hitbox
		else:
			hitbox_shape.set_deferred("disabled", true)  # Disable hitbox

func _on_animation_finished() -> void:
	anim_finished = true
