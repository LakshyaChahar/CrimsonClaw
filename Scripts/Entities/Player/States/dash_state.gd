# DashState handles high-speed dash movement, cooldown, and smooth transition back to idle/walk
extends CharacterState
class_name DashState

@export_group("Dash Parameters")
## Speed of dash movement.
@export var dash_speed: float = 650.0

## Duration of active dash state in seconds.
@export var dash_duration: float = 0.18

## Minimum wait time between end of 1st dash and start of 2nd dash.
@export var dash_cooldown: float = 0.6

## Invincibility grace period after dash ends to prevent instant overlap damage.
@export var post_dash_iframe_duration: float = 0.15

## Minimum required bloodthirst to perform dash.
@export var min_required_bloodthirst: float = 0.0

var dash_timer: float = 0.0
var saved_collision_layer: int = 2
var saved_collision_mask: int = 9

func enter() -> void:
	character.wants_dash = false
	if "dash_buffer_timer" in character:
		character.dash_buffer_timer = 0.0

	if min_required_bloodthirst > 0.0:
		if "current_bloodthirst" in character and character.current_bloodthirst < min_required_bloodthirst:
			character.is_dashing = false
			state_machine.change_state("idle" if character.is_grounded() else "fall")
			return

	character.is_dashing = true
	character.can_dash = false
		
	# Save original collision layer & mask
	saved_collision_layer = character.collision_layer
	saved_collision_mask = character.collision_mask
	
	# Set Player collision layer to 0 and mask to TERRAIN ONLY (Layer 1) to pass through enemies completely
	character.collision_layer = 0
	character.collision_mask = 1
	
	# Enable Hurtbox Invincibility while dashing
	var hurtbox = character.find_child("Hurtbox", true, false) as Hurtbox
	if hurtbox:
		hurtbox.start_invincibility()
	
	if character.animation_manager:
		character.animation_manager.play_anim("dash", 2)
		
	# Enforce strictly horizontal dash (left or right)
	var horiz_dir: float = sign(character.input_direction.x) if character.input_direction.x != 0.0 else float(character.facing_direction)
	if horiz_dir == 0.0:
		horiz_dir = 1.0
	character.dash_direction = Vector2(horiz_dir, 0.0)
		
	character.velocity = character.dash_direction * dash_speed
	dash_timer = dash_duration

func exit() -> void:
	character.is_dashing = false
	character.wants_dash = false
	if "dash_buffer_timer" in character:
		character.dash_buffer_timer = 0.0
		
	# Set dash cooldown timer so dash cannot be spammed
	character.dash_cooldown_timer = dash_cooldown
	character.can_dash = false
		
	# Restore original physical collision layer & mask
	character.collision_layer = saved_collision_layer
	character.collision_mask = saved_collision_mask
	
	# Grant post-dash i-frame grace period so ending dash inside an enemy does not deal instant damage
	var hurtbox = character.find_child("Hurtbox", true, false) as Hurtbox
	if hurtbox:
		hurtbox.invincibility_duration = max(hurtbox.invincibility_duration, post_dash_iframe_duration)
		hurtbox.start_invincibility()
		
	# Smooth velocity transition out of dash
	if character.input_direction.x == 0.0:
		character.velocity.x = 0.0
	else:
		character.velocity.x = character.facing_direction * character.move_speed
		
	# Reset animation speed scale back to 1.0 and clear priority
	if character.animation_manager:
		if character.animation_manager.sprite:
			character.animation_manager.sprite.speed_scale = 1.0
		character.animation_manager.current_priority = 0

func physics_update(delta: float) -> void:
	dash_timer -= delta
	character.velocity.y = 0.0 # Maintain level horizontal dash
	character.move_and_slide()
	
	if dash_timer <= 0.0:
		if character.is_grounded():
			if character.input_direction.x != 0.0:
				state_machine.change_state("walk")
			else:
				state_machine.change_state("idle")
		else:
			state_machine.change_state("fall")
