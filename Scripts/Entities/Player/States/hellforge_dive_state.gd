extends CharacterState
class_name HellforgeDiveState

enum Phase { RISE, FALL, IMPACT }

@export_group("Hellforge Dive Mechanics")
## Upward force launching the player into the dive rise phase.
@export var rise_force: float = 500.0

## Downward speed when slamming down to the ground.
@export var slam_speed: float = 900.0

## Maximum duration of the rising phase in seconds.
@export var max_rise_duration: float = 0.25

## Duration of ground impact recovery state.
@export var impact_duration: float = 0.35

@export_group("Damage & Fire Status")
## Base physical damage dealt on ground slam.
@export var impact_damage: float = 30.0

## Radial knockback force pushing targets away from player.
@export var knockback_force: float = 450.0

## Stun duration applied to victims hit by slam.
@export var stun_duration: float = 0.4

## Whether ground impact causes targets to catch fire.
@export var inflicts_fire: bool = true

## Damage per second inflicted on burning targets.
@export var fire_dps: float = 10.0

## Duration of the fire burn effect in seconds.
@export var fire_duration: float = 4.0

## Bloodthirst cost to execute Hellforge Dive skill.
@export var bloodthirst_cost: float = 7.0

## Minimum required bloodthirst to execute skill.
@export var min_required_bloodthirst: float = 7.0

@export_group("Hitbox & Screen Shake")
## Name of the Hitbox Node in Scene Tree.
@export var hitbox_node_name: String = "HellforgeHitbox"

## Camera shake strength on ground impact.
@export var shake_intensity: float = 8.0

## Camera shake duration on ground impact.
@export var shake_duration: float = 0.25

@export_group("Shockwave Projectile")
## Scene for the traveling ground shockwave projectile.
@export var shockwave_scene: PackedScene = preload("res://Scenes/Entities/Enemy/ground_shockwave.tscn")

var current_phase: Phase = Phase.RISE
var rise_timer: float = 0.0
var impact_timer: float = 0.0
var hitbox_shape: CollisionShape2D = null
var anim_finished: bool = false

func enter() -> void:
	if "wants_hellforge_dive" in character:
		character.wants_hellforge_dive = false

	# Deduct bloodthirst cost
	var cost_to_check = bloodthirst_cost if bloodthirst_cost > 0.0 else min_required_bloodthirst
	if cost_to_check > 0.0 and character.has_method("consume_bloodthirst"):
		if not character.consume_bloodthirst(cost_to_check):
			push_warning("HellforgeDiveState: Insufficient bloodthirst! Required: " + str(cost_to_check) + ", Current: " + str(character.current_bloodthirst if "current_bloodthirst" in character else 0.0))
			state_machine.change_state("idle" if character.is_grounded() else "fall")
			return

	# Start Phase 1: RISE
	current_phase = Phase.RISE
	rise_timer = max_rise_duration
	anim_finished = false

	# Initial upward leap impulse
	character.velocity.y = -rise_force

	# Disable hitbox shape initially
	_setup_hitbox()
	if hitbox_shape:
		hitbox_shape.set_deferred("disabled", true)

	# Play rise animation (with fallback)
	_play_phase_animation("hellforge_rise", "jump")

func physics_update(delta: float) -> void:
	match current_phase:
		Phase.RISE:
			rise_timer -= delta
			character.apply_gravity(delta * 0.5)
			character.move_and_slide()

			# Transition to FALL when peak of leap is reached or timer expires
			if rise_timer <= 0.0 or character.velocity.y >= 0.0:
				current_phase = Phase.FALL
				character.velocity.y = slam_speed
				_play_phase_animation("hellforge_fall", "fall")

		Phase.FALL:
			# Maintain fast downward slam speed
			character.velocity.y = max(character.velocity.y, slam_speed)
			character.move_and_slide()

			# Touchdown check
			if character.is_grounded():
				_trigger_impact()

		Phase.IMPACT:
			impact_timer -= delta
			character.velocity.x = move_toward(character.velocity.x, 0.0, character.friction * delta)
			character.move_and_slide()

			if impact_timer <= 0.0 or anim_finished:
				_finish_dive()

func _trigger_impact() -> void:
	current_phase = Phase.IMPACT
	impact_timer = impact_duration
	character.velocity = Vector2.ZERO

	# Play impact landing animation
	_play_phase_animation("hellforge_land", "attack")

	# Activate AOE Hitbox
	_setup_hitbox()
	if hitbox_shape:
		hitbox_shape.set_deferred("disabled", false)

	# Trigger camera shake effect
	if character.has_method("trigger_screen_shake"):
		character.trigger_screen_shake(shake_intensity, shake_duration)

	# Play Hellforge Dive impact sound effect
	var sfx_mgr = character.get_node_or_null("/root/SfxManager")
	if sfx_mgr and sfx_mgr.has_method("play_2d"):
		sfx_mgr.play_2d("hellforgedive", character.global_position, 0.0, 1.0, 0.05)
		
	# Spawn the dual traveling projectiles

	_spawn_dual_shockwaves()

func _spawn_dual_shockwaves() -> void:
	if not shockwave_scene:
		push_warning("HellforgeDiveState: No shockwave_scene assigned!")
		return
		
	# Extract collision layers from the player's hitbox so the projectile only hits enemies
	var reference_hitbox = character.find_child(hitbox_node_name) as Hitbox
	var c_layer = reference_hitbox.collision_layer if reference_hitbox else 0
	var c_mask = reference_hitbox.collision_mask if reference_hitbox else 0
	
	# Spawn Left Shockwave (-1.0 direction)
	var wave_left = shockwave_scene.instantiate() as GroundShockwave
	wave_left.owner = character # Assigns player as owner to prevent self-damage
	wave_left.collision_layer = c_layer
	wave_left.collision_mask = c_mask
	character.get_parent().add_child(wave_left)
	wave_left.setup(character.global_position + Vector2(-15, 0), -1.0, -1.0, impact_damage)
	if wave_left.has_method("set_fire_theme"):
		wave_left.set_fire_theme(fire_dps, fire_duration)
	
	# Spawn Right Shockwave (1.0 direction)
	var wave_right = shockwave_scene.instantiate() as GroundShockwave
	wave_right.owner = character # Assigns player as owner to prevent self-damage
	wave_right.collision_layer = c_layer
	wave_right.collision_mask = c_mask
	character.get_parent().add_child(wave_right)
	wave_right.setup(character.global_position + Vector2(15, 0), 1.0, -1.0, impact_damage)
	if wave_right.has_method("set_fire_theme"):
		wave_right.set_fire_theme(fire_dps, fire_duration)

func _finish_dive() -> void:
	if hitbox_shape:
		hitbox_shape.set_deferred("disabled", true)

	_disconnect_animation_signals()

	if character.is_grounded():
		if character.input_direction.x != 0.0:
			state_machine.change_state("walk")
		else:
			state_machine.change_state("idle")
	else:
		state_machine.change_state("fall")

func exit() -> void:
	_disconnect_animation_signals()
	if hitbox_shape:
		hitbox_shape.set_deferred("disabled", true)

func _setup_hitbox() -> void:
	var hitbox = character.find_child(hitbox_node_name) as Hitbox
	if hitbox:
		hitbox.damage = impact_damage
		hitbox.knockback_force = knockback_force
		hitbox.stun_duration = stun_duration
		hitbox.inflicts_fire = inflicts_fire
		hitbox.fire_dps = fire_dps
		hitbox.fire_duration = fire_duration

		# Find child collision shape
		for child in hitbox.get_children():
			if child is CollisionShape2D:
				hitbox_shape = child
				break

func _play_phase_animation(anim_name: String, fallback_anim: String) -> void:
	if not character.animation_manager:
		return

	var sprite = character.animation_manager.sprite
	var chosen_anim = anim_name
	if sprite and sprite.sprite_frames:
		var has_primary = sprite.sprite_frames.has_animation(anim_name) and sprite.sprite_frames.get_frame_count(anim_name) > 0
		if not has_primary:
			var has_fallback = sprite.sprite_frames.has_animation(fallback_anim) and sprite.sprite_frames.get_frame_count(fallback_anim) > 0
			if has_fallback:
				chosen_anim = fallback_anim
			elif sprite.sprite_frames.has_animation("attack") and sprite.sprite_frames.get_frame_count("attack") > 0:
				chosen_anim = "attack"
			elif sprite.sprite_frames.has_animation("idle") and sprite.sprite_frames.get_frame_count("idle") > 0:
				chosen_anim = "idle"

	character.animation_manager.play_anim(chosen_anim, 2)

	if sprite:
		_disconnect_animation_signals()
		if not sprite.animation_finished.is_connected(_on_animation_finished):
			sprite.animation_finished.connect(_on_animation_finished)

func _disconnect_animation_signals() -> void:
	if character.animation_manager and character.animation_manager.sprite:
		var sprite = character.animation_manager.sprite
		if sprite.animation_finished.is_connected(_on_animation_finished):
			sprite.animation_finished.disconnect(_on_animation_finished)

func _on_animation_finished() -> void:
	if current_phase == Phase.IMPACT:
		anim_finished = true
