# Special Phase Strike State for Veil-Walker Sub-Boss with Full Engine VFX & Guaranteed Torso Swept Hit Detection
extends CharacterState
class_name VeilWalkerPhaseStrikeState

enum Phase { RISE_TELEGRAPH, STRIKE, RECOVERY }

@export var rise_force: float = 450.0
@export var telegraph_duration: float = 0.45
@export var strike_speed: float = 800.0
@export var strike_damage: float = 40.0
@export var strike_knockback_force: float = 300.0
@export var strike_stun_duration: float = 0.3
@export var recovery_duration: float = 0.4
@export var max_strike_duration: float = 0.5
@export var telegraph_line_color: Color = Color(1.0, 0.15, 0.15, 0.8)
@export var telegraph_line_width: float = 4.0

var current_phase: Phase = Phase.RISE_TELEGRAPH
var phase_timer: float = 0.0
var strike_direction: Vector2 = Vector2.ZERO
var prev_position: Vector2 = Vector2.ZERO
var is_aim_locked: bool = false

# VFX Nodes & Timers
var target_laser: Line2D = null
var target_reticle: Node2D = null
var particle_emitter: CPUParticles2D = null
var ghost_spawn_timer: float = 0.0
var ghost_spawn_interval: float = 0.04 # Spawn afterimage ghost copy every 0.04s

var hitbox: Hitbox = null
var hitbox_shape: CollisionShape2D = null
var original_hitbox_damage: float = 0.0
var original_hitbox_pos: Vector2 = Vector2.ZERO
var original_collision_layer: int = 0
var original_collision_mask: int = 0
var hit_targets: Array[Hurtbox] = []

func enter() -> void:
	var boss = character as VeilWalkerBoss
	if boss:
		rise_force = boss.rise_force
		telegraph_duration = boss.telegraph_duration
		strike_speed = boss.strike_speed
		strike_damage = boss.strike_damage
		strike_knockback_force = boss.strike_knockback_force
		strike_stun_duration = boss.strike_stun_duration
		recovery_duration = boss.recovery_duration
		telegraph_line_color = boss.telegraph_line_color
		telegraph_line_width = boss.telegraph_line_width

	SubBossCoordinator.request_attack(character)
	_spawn_overhead_warning(telegraph_duration, Color(1.0, 0.2, 0.35, 0.9))

	current_phase = Phase.RISE_TELEGRAPH
	phase_timer = 0.0
	is_aim_locked = false
	ghost_spawn_timer = 0.0
	hit_targets.clear()

	# 1. Turn off physical body collisions with Player so boss phases straight through player
	original_collision_mask = character.collision_mask
	original_collision_layer = character.collision_layer
	character.collision_mask = 1 # Collide only with World/Environment (Layer 1)
	character.collision_layer = 0 # Prevent player from physically bumping into boss

	# 2. Setup Hitbox & position it at Torso Height (Vector2(0, -18)) instead of ground level
	hitbox = character.find_child("Hitbox")
	if hitbox:
		hitbox.monitoring = true
		original_hitbox_damage = hitbox.damage
		hitbox.damage = strike_damage
		hitbox.knockback_force = strike_knockback_force
		hitbox.stun_duration = strike_stun_duration

		for child in hitbox.get_children():
			if child is CollisionShape2D:
				hitbox_shape = child
				break

		if hitbox_shape:
			original_hitbox_pos = hitbox_shape.position
			# Elevate hitbox shape to torso height for reliable hit registration
			hitbox_shape.position = Vector2(0, -18)
			if hitbox_shape.shape is CircleShape2D:
				(hitbox_shape.shape as CircleShape2D).radius = 35.0
			hitbox_shape.set_deferred("disabled", true)

	# 3. Setup VFX Nodes (Laser, Reticle, Particles)
	_setup_laser_line()
	_setup_target_reticle()
	_setup_particle_emitter()

	# Start floating shadow particle emission
	if particle_emitter:
		particle_emitter.emitting = true

	# 4. Launch into air
	character.velocity.y = -rise_force
	character.velocity.x = 0.0

	if character.animation_manager:
		character.animation_manager.play_anim("phase_strike", 2)

func physics_update(delta: float) -> void:
	phase_timer += delta

	match current_phase:
		Phase.RISE_TELEGRAPH:
			# Decelerate upward launch speed to float in air
			character.velocity.y = move_toward(character.velocity.y, 0.0, rise_force * 3.0 * delta)
			character.move_and_slide()

			# Update Red Laser Line & Target Lock Reticle with 2-Phase Aiming!
			var boss = character as Enemy
			if boss and boss.target:
				var target_torso = boss.target.global_position + Vector2(0, -21)
				var time_left = telegraph_duration - phase_timer
				var lock_threshold = 0.12 # Tighter tracking window so slight movement doesn't cause complete miss!

				if time_left > lock_threshold:
					# Phase 1: Dynamic tracking towards current player position
					strike_direction = (target_torso - (character.global_position + Vector2(0, -18))).normalized()
					if target_reticle:
						target_reticle.global_position = target_torso
					var start_pos = Vector2.ZERO
					var end_pos = target_laser.to_local(target_torso)
					target_laser.points = PackedVector2Array([start_pos, end_pos])
				else:
					# Phase 2: Lock aiming line for final 0.12s
					var start_pos = Vector2.ZERO
					var end_pos = target_laser.to_local(character.global_position + Vector2(0, -18) + strike_direction * 400.0)
					target_laser.points = PackedVector2Array([start_pos, end_pos])

				target_laser.visible = true

				# Position Reticle & shrink scale as attack prepares to release
				if target_reticle:
					target_reticle.visible = true
					var progress = clamp(phase_timer / telegraph_duration, 0.0, 1.0)
					var reticle_scale = lerp(2.0, 0.8, progress)
					target_reticle.scale = Vector2(reticle_scale, reticle_scale)

				# Rapid flash line when AIM IS LOCKED
				if time_left <= lock_threshold:
					if not is_aim_locked:
						is_aim_locked = true
						_trigger_aim_lock_event()

					var flash = (sin(phase_timer * 40.0) + 1.0) * 0.5
					target_laser.default_color = lerp(Color(1.0, 0.2, 0.35, 1.0), Color.WHITE, flash)
					target_laser.width = lerp(4.0, 8.0, flash * 0.5)
				else:
					target_laser.default_color = telegraph_line_color
					target_laser.width = telegraph_line_width
			else:
				strike_direction = Vector2(character.facing_direction, 0.5).normalized()

			# Transition to STRIKE when telegraph timer finishes
			if phase_timer >= telegraph_duration:
				_start_strike()

		Phase.STRIKE:
			var frame_start_pos = character.global_position + Vector2(0, -18)
			character.velocity = strike_direction * strike_speed
			character.move_and_slide()
			var frame_end_pos = character.global_position + Vector2(0, -18)

			# 100% Guaranteed Hit Check (Direct Overlap + Swept Trajectory Check)
			_check_strike_hits(frame_start_pos, frame_end_pos)

			# Spawn Ghost Afterimages along dash trail
			ghost_spawn_timer += delta
			if ghost_spawn_timer >= ghost_spawn_interval:
				ghost_spawn_timer = 0.0
				_spawn_ghost_afterimage()

			# Touchdown or timeout check
			if character.is_grounded() or phase_timer >= max_strike_duration:
				_start_recovery()

		Phase.RECOVERY:
			character.velocity = character.velocity.move_toward(Vector2.ZERO, character.friction * delta)
			character.move_and_slide()

			if phase_timer >= recovery_duration:
				_finish_state()

func _start_strike() -> void:
	current_phase = Phase.STRIKE
	phase_timer = 0.0
	prev_position = character.global_position + Vector2(0, -18)
	hit_targets.clear()

	# Enable Hitbox shape directly for the strike pass
	if hitbox:
		hitbox.monitoring = true
	if hitbox_shape:
		hitbox_shape.disabled = false

	if target_laser:
		target_laser.visible = false
	if target_reticle:
		target_reticle.visible = false

	# Face strike direction
	if strike_direction.x != 0.0:
		character.input_direction.x = sign(strike_direction.x)
		character.update_facing_direction()

func _check_strike_hits(segment_start: Vector2, segment_end: Vector2) -> void:
	var boss = character as Enemy
	if not boss or not boss.target:
		return
		
	var hurtbox = boss.target.find_child("Hurtbox") as Hurtbox
	if not hurtbox:
		hurtbox = boss.target.get_node_or_null("Hurtbox") as Hurtbox

	# 1. Direct Overlap Check via Hitbox
	if hitbox:
		var overlapping = hitbox.get_overlapping_areas()
		for area in overlapping:
			if area is Hurtbox and not hit_targets.has(area):
				_apply_hit_to_hurtbox(area as Hurtbox)

	# 2. Multi-point Swept Trajectory Check (Torso, Feet, Head)
	if hurtbox and not hit_targets.has(hurtbox):
		var target_body = boss.target
		var points_to_check = [
			target_body.global_position + Vector2(0, -21), # Torso
			target_body.global_position,                  # Feet
			target_body.global_position + Vector2(0, -42)  # Head
		]
		
		var hit_registered = false
		for pt in points_to_check:
			var closest_point = Geometry2D.get_closest_point_to_segment(pt, segment_start, segment_end)
			if closest_point.distance_to(pt) <= 85.0: # Generous 85px hit radius matching visual dash width
				hit_registered = true
				break
				
		if hit_registered:
			_apply_hit_to_hurtbox(hurtbox)

func _apply_hit_to_hurtbox(hurtbox: Hurtbox) -> void:
	var victim = hurtbox.owner if hurtbox.owner else hurtbox.get_parent()
	if victim != character:
		hit_targets.append(hurtbox)
		var kb_dir = strike_direction
		if kb_dir == Vector2.ZERO:
			kb_dir = Vector2.RIGHT
			
		# Call receive_hit on hurtbox which correctly dispatches damage, knockback, and signals!
		hurtbox.receive_hit(strike_damage, kb_dir * strike_knockback_force, strike_stun_duration, character, false, 0.0, 0.0)

func _start_recovery() -> void:
	current_phase = Phase.RECOVERY
	phase_timer = 0.0

	if hitbox_shape:
		hitbox_shape.set_deferred("disabled", true)

	if target_laser:
		target_laser.visible = false
	if target_reticle:
		target_reticle.visible = false

	# Trigger particle touchdown burst
	if particle_emitter:
		particle_emitter.restart()

func _finish_state() -> void:
	SubBossCoordinator.release_attack(character)
	_cleanup_vfx()
	_restore_collisions()
	
	var boss = character as VeilWalkerBoss
	if boss:
		boss.special_attack_cooldown_timer = boss.special_attack_cooldown

	if character.is_grounded():
		state_machine.change_state("walk")
	else:
		state_machine.change_state("idle")

func exit() -> void:
	SubBossCoordinator.release_attack(character)
	_cleanup_vfx()
	_restore_collisions()

	if hitbox_shape:
		hitbox_shape.set_deferred("disabled", true)
		hitbox_shape.position = original_hitbox_pos

	if hitbox:
		hitbox.damage = original_hitbox_damage

func _spawn_overhead_warning(dur: float, col: Color) -> void:
	var warn = AttackWarningIndicator.new()
	warn.setup(dur, col)
	character.add_child(warn)

	if hitbox:
		hitbox.damage = original_hitbox_damage

func _restore_collisions() -> void:
	if original_collision_mask != 0:
		character.collision_mask = original_collision_mask
		character.collision_layer = original_collision_layer

# --- VFX SETUP & EXECUTION FUNCTIONS ---

func _setup_laser_line() -> void:
	target_laser = character.find_child("TargetLaser", true, false) as Line2D
	if not target_laser:
		target_laser = Line2D.new()
		target_laser.name = "TargetLaser"
		target_laser.width = telegraph_line_width
		target_laser.default_color = telegraph_line_color
		target_laser.z_index = 10
		character.add_child(target_laser)
	else:
		target_laser.width = telegraph_line_width
		target_laser.default_color = telegraph_line_color
	target_laser.visible = false

func _setup_target_reticle() -> void:
	target_reticle = character.get_parent().find_child("ReticleNode", true, false) as Node2D
	if not target_reticle:
		target_reticle = ReticleDrawer.new()
		target_reticle.name = "ReticleNode"
		character.get_parent().add_child(target_reticle)
	target_reticle.visible = false

func _setup_particle_emitter() -> void:
	particle_emitter = character.find_child("ShadowEmbers", true, false) as CPUParticles2D
	if not particle_emitter:
		particle_emitter = CPUParticles2D.new()
		particle_emitter.name = "ShadowEmbers"
		particle_emitter.amount = 24
		particle_emitter.lifetime = 0.5
		particle_emitter.direction = Vector2(0, -1)
		particle_emitter.spread = 45.0
		particle_emitter.gravity = Vector2(0, -50)
		particle_emitter.initial_velocity_min = 40.0
		particle_emitter.initial_velocity_max = 80.0
		particle_emitter.scale_amount_min = 2.0
		particle_emitter.scale_amount_max = 4.0
		particle_emitter.color = Color(1.0, 0.25, 0.35, 0.8)
		character.add_child(particle_emitter)

func _spawn_ghost_afterimage() -> void:
	var sprite = character.find_child("AnimatedSprite2D") as AnimatedSprite2D
	if not sprite or not sprite.sprite_frames:
		return

	var current_texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if not current_texture:
		return

	var ghost = Sprite2D.new()
	ghost.texture = current_texture
	ghost.centered = sprite.centered
	ghost.offset = sprite.offset

	character.get_parent().add_child(ghost)

	var dir = character.facing_direction if "facing_direction" in character else 1
	var ghost_x = sprite.global_position.x - (dir * 12.0)
	var ghost_y = sprite.global_position.y
	ghost.global_position = Vector2(ghost_x, ghost_y)

	ghost.global_scale = sprite.global_scale
	ghost.global_rotation = sprite.global_rotation
	ghost.flip_h = sprite.flip_h
	ghost.flip_v = sprite.flip_v
	ghost.modulate = Color(1.0, 0.25, 0.3, 0.5) # Clean crimson shadow ghost
	
	var parent_z = character.z_index if "z_index" in character else 2
	ghost.z_index = max(1, parent_z - 1)

	# Tween alpha to 0 and auto-free
	var tween = ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.25)
	tween.tween_callback(ghost.queue_free)

func _cleanup_vfx() -> void:
	if target_laser:
		target_laser.visible = false
	if target_reticle:
		target_reticle.visible = false
	if particle_emitter:
		particle_emitter.emitting = false

func _trigger_aim_lock_event() -> void:
	if target_reticle:
		var tween = target_reticle.create_tween()
		target_reticle.scale = Vector2(2.8, 2.8)
		tween.tween_property(target_reticle, "scale", Vector2(0.8, 0.8), 0.15)

	if target_laser:
		target_laser.width = 16.0

# Helper Node class to draw a sleek precision target lock-on sight procedurally
class ReticleDrawer extends Node2D:
	var reticle_color: Color = Color(1.0, 0.25, 0.35, 0.95)

	func _ready() -> void:
		z_index = 15

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if not visible:
			return
			
		var sz = 12.0
		var b_len = 4.0
		var c = reticle_color
		var w = 1.5
		
		# Top-Left Bracket
		draw_line(Vector2(-sz, -sz), Vector2(-sz + b_len, -sz), c, w)
		draw_line(Vector2(-sz, -sz), Vector2(-sz, -sz + b_len), c, w)
		
		# Top-Right Bracket
		draw_line(Vector2(sz, -sz), Vector2(sz - b_len, -sz), c, w)
		draw_line(Vector2(sz, -sz), Vector2(sz, -sz + b_len), c, w)
		
		# Bottom-Left Bracket
		draw_line(Vector2(-sz, sz), Vector2(-sz + b_len, sz), c, w)
		draw_line(Vector2(-sz, sz), Vector2(-sz, sz - b_len), c, w)
		
		# Bottom-Right Bracket
		draw_line(Vector2(sz, sz), Vector2(sz - b_len, sz), c, w)
		draw_line(Vector2(sz, sz), Vector2(sz, sz - b_len), c, w)
		
		# Center precision point
		draw_circle(Vector2.ZERO, 1.2, Color.WHITE)
