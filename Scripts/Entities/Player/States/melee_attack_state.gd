extends CharacterState
class_name MeleeAttackState

@export_group("Melee Attack Parameters")
## Damage dealt by basic sword swing.
@export var damage: float = 10.0

## Knockback force pushing targets back.
@export var knockback_force: float = 150.0

## Stun duration applied to target on hit.
@export var stun_duration: float = 0.2

## Minimum required bloodthirst to perform basic attack.
@export var min_required_bloodthirst: float = 0.0

@export_group("State & Hitbox Settings")
## The exact name of the Hitbox Node in the Scene Tree that this attack uses.
@export var hitbox_node_name: String = "SwordHitbox"

## Duration of the attack state. Used as a fallback if animation signals are not received.
@export var attack_duration: float = 0.4

## The specific frame indices of the "attack" animation where the hitbox should be active.
@export var active_frames: Array[int] = [2, 3]

var timer: float = 0.0
var anim_finished: bool = false
var hitbox_shape: CollisionShape2D = null

func enter() -> void:
	character.wants_skill = false # Reset input register early
	
	if min_required_bloodthirst > 0.0:
		if "current_bloodthirst" in character and character.current_bloodthirst < min_required_bloodthirst:
			state_machine.change_state("idle" if character.is_grounded() else "fall")
			return
				
	anim_finished = false
	timer = attack_duration
	
	# Find the sword hitbox collision shape dynamically
	var hitbox = character.find_child(hitbox_node_name) as Hitbox
	if hitbox:
		hitbox.damage = damage
		hitbox.knockback_force = knockback_force
		hitbox.stun_duration = stun_duration
		
		# Search for any CollisionShape2D child node
		for child in hitbox.get_children():
			if child is CollisionShape2D:
				hitbox_shape = child
				break
		# --- Professional Directional Hitbox Positioning (Explicit Offsets & Rotation) ---
		var attack_dir = character.input_direction
		
		# Prevent downward/diagonal-down attacks while grounded
		if character.is_grounded() and attack_dir.y > 0.0:
			attack_dir.y = 0.0
			
		# Default to facing direction if no valid input is given (e.g. standing still)
		if attack_dir == Vector2.ZERO:
			attack_dir = Vector2(character.facing_direction if character.facing_direction != 0 else 1.0, 0.0)
			
		var offset = Vector2(48, -22)
		var rot_angle = 0.0
		
		if attack_dir.y < 0.0:
			if attack_dir.x > 0.0: # UP-RIGHT (-45°): Pushed OUTWARD (42px) & UPWARD (-48px)
				offset = Vector2(42, -48)
				rot_angle = -PI / 4.0
			elif attack_dir.x < 0.0: # UP-LEFT (-135°): Pushed OUTWARD (-42px) & UPWARD (-48px)
				offset = Vector2(-42, -48)
				rot_angle = -3.0 * PI / 4.0
			else: # STRAIGHT UP (-90°)
				offset = Vector2(0, -60)
				rot_angle = -PI / 2.0
		elif attack_dir.y > 0.0: # IN-AIR DOWNWARD ATTACKS
			if attack_dir.x > 0.0: # DOWN-RIGHT (45°)
				offset = Vector2(42, 10)
				rot_angle = PI / 4.0
			elif attack_dir.x < 0.0: # DOWN-LEFT (135°)
				offset = Vector2(-42, 10)
				rot_angle = 3.0 * PI / 4.0
			else: # STRAIGHT DOWN (90°)
				offset = Vector2(0, 20)
				rot_angle = PI / 2.0
		else: # HORIZONTAL ATTACKS
			if attack_dir.x < 0.0: # LEFT (180°)
				offset = Vector2(-48, -22)
				rot_angle = PI
			else: # RIGHT (0°)
				offset = Vector2(48, -22)
				rot_angle = 0.0
				
		if hitbox_shape:
			hitbox_shape.position = offset
			hitbox_shape.rotation = rot_angle
			hitbox_shape.set_deferred("disabled", false)
			hitbox.call_deferred("check_overlapping_hits")
	
	# Play attack animation
	if character.animation_manager:
		character.animation_manager.play_anim("attack", 2)
		var sprite = character.animation_manager.sprite
		if sprite:
			if sprite.sprite_frames and sprite.sprite_frames.has_animation("attack"):
				var frames = sprite.sprite_frames.get_frame_count("attack")
				var fps = sprite.sprite_frames.get_animation_speed("attack")
				if fps > 0:
					var anim_len = float(frames) / fps
					sprite.speed_scale = anim_len / attack_duration
					
			sprite.animation_finished.connect(_on_animation_finished)
			
	# Halt horizontal movement during melee swing
	character.velocity.x = 0.0

func exit() -> void:
	# Clean up connections
	if character.animation_manager and character.animation_manager.sprite:
		var sprite = character.animation_manager.sprite
		sprite.speed_scale = 1.0
		if sprite.animation_finished.is_connected(_on_animation_finished):
			sprite.animation_finished.disconnect(_on_animation_finished)
			
	# Always turn off and reset the hitbox shape when leaving the attack state
	if hitbox_shape:
		hitbox_shape.set_deferred("disabled", true)
		hitbox_shape.position = Vector2(48, -22)
		hitbox_shape.rotation = 0.0

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

func _on_animation_finished() -> void:
	anim_finished = true
