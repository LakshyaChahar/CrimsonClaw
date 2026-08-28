extends CharacterState
class_name IgnisClawState

@export_group("Ignis Claw Parameters")
## Initial hit damage dealt when Ignis Claw strikes.
@export var initial_damage: float = 25.0

## Knockback force pushing enemies back.
@export var knockback_force: float = 400.0

## Duration of fire burn effect in seconds.
@export var fire_duration: float = 3.0

## Damage per second inflicted while target is on fire.
@export var fire_dps: float = 8.0

## Duration of stun applied on hit.
@export var stun_duration: float = 0.3

## Bloodthirst cost to execute Ignis Claw skill.
@export var bloodthirst_cost: float = 6.0

## Minimum required bloodthirst to perform Ignis Claw skill.
@export var min_required_bloodthirst: float = 6.0

@export_group("State & Hitbox Settings")
## The exact name of the Hitbox Node in the Scene Tree.
@export var hitbox_node_name: String = "IgnisClawHitbox"

## Duration of the attack state.
@export var attack_duration: float = 0.45

## Specific animation frame indices where the hitbox shape is active.
@export var active_frames: Array[int] = [1, 2, 3, 4]

var timer: float = 0.0
var anim_finished: bool = false
var hitbox_shape: CollisionShape2D = null

func enter() -> void:
	if "wants_ignis_claw" in character:
		character.wants_ignis_claw = false

	# Deduct bloodthirst cost
	var cost_to_check = bloodthirst_cost if bloodthirst_cost > 0.0 else min_required_bloodthirst
	if cost_to_check > 0.0 and character.has_method("consume_bloodthirst"):
		if not character.consume_bloodthirst(cost_to_check):
			push_warning("IgnisClawState: Insufficient bloodthirst! Required: " + str(cost_to_check) + ", Current: " + str(character.current_bloodthirst if "current_bloodthirst" in character else 0.0))
			state_machine.change_state("idle" if character.is_grounded() else "fall")
			return
				
	anim_finished = false
	timer = attack_duration
	
	var sfx_mgr = character.get_node_or_null("/root/SfxManager")
	if sfx_mgr and sfx_mgr.has_method("play_2d"):
		sfx_mgr.play_2d("ignis_claw", character.global_position, 0.0, 1.0, 0.05)
		
	var hitbox = character.find_child(hitbox_node_name) as Hitbox
	if hitbox:
		# Pass exported parameters directly into the Hitbox properties
		hitbox.damage = initial_damage
		hitbox.knockback_force = knockback_force
		hitbox.inflicts_fire = true
		hitbox.fire_dps = fire_dps
		hitbox.fire_duration = fire_duration
		hitbox.stun_duration = stun_duration
		
		# Find CollisionShape2D child node
		for child in hitbox.get_children():
			if child is CollisionShape2D:
				hitbox_shape = child
				break
				
		# Non-directional attack: Always strikes horizontally in the character's facing direction
		var facing_dir = Vector2(character.facing_direction if character.facing_direction != 0 else 1.0, 0.0)
		hitbox.rotation = facing_dir.angle()
		
	# Play attack or ignis_claw animation (with fallback)
	if character.animation_manager:
		var sprite = character.animation_manager.sprite
		var anim_to_play = "ignis_claw"
		if sprite and sprite.sprite_frames and not sprite.sprite_frames.has_animation("ignis_claw"):
			anim_to_play = "attack"

		character.animation_manager.play_anim(anim_to_play, 2)
		if sprite:
			if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_to_play):
				var frames = sprite.sprite_frames.get_frame_count(anim_to_play)
				var fps = sprite.sprite_frames.get_animation_speed(anim_to_play)
				if fps > 0 and frames > 0:
					var anim_len = float(frames) / fps
					sprite.speed_scale = anim_len / attack_duration
					
			if not sprite.animation_finished.is_connected(_on_animation_finished):
				sprite.animation_finished.connect(_on_animation_finished)
			if not sprite.frame_changed.is_connected(_on_frame_changed):
				sprite.frame_changed.connect(_on_frame_changed)
				
	if hitbox_shape:
		hitbox_shape.set_deferred("disabled", false)
				
	character.velocity.x = 0.0

func exit() -> void:
	if character.animation_manager and character.animation_manager.sprite:
		var sprite = character.animation_manager.sprite
		sprite.speed_scale = 1.0
		if sprite.animation_finished.is_connected(_on_animation_finished):
			sprite.animation_finished.disconnect(_on_animation_finished)
		if sprite.frame_changed.is_connected(_on_frame_changed):
			sprite.frame_changed.disconnect(_on_frame_changed)
			
	if hitbox_shape:
		hitbox_shape.set_deferred("disabled", true)
		
	var hitbox = character.find_child(hitbox_node_name)
	if hitbox:
		hitbox.rotation_degrees = 0.0

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

func _on_frame_changed() -> void:
	var sprite = character.animation_manager.sprite
	if not sprite or not hitbox_shape:
		return
		
	if sprite.animation == "attack" or sprite.animation == "ignis_claw":
		if sprite.sprite_frames and sprite.sprite_frames.has_animation(sprite.animation) and sprite.sprite_frames.get_frame_count(sprite.animation) <= 2:
			hitbox_shape.set_deferred("disabled", false)
		elif sprite.frame in active_frames:
			hitbox_shape.set_deferred("disabled", false)
		else:
			hitbox_shape.set_deferred("disabled", true)

func _on_animation_finished() -> void:
	anim_finished = true
