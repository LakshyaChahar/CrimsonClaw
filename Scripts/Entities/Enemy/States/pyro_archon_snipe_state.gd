# Special Snipe Attack & Ground Teleport State for Pyro-Archon Sub-Boss
extends CharacterState
class_name PyroArchonSnipeState

enum Phase { TELEGRAPH, FIRE, RECOVERY_STAND_STILL, GROUND_TELEPORT }

@export var snipe_cooldown: float = 3.5
@export var telegraph_duration: float = 0.8
@export var recovery_duration: float = 1.5
@export var projectile_speed: float = 1200.0
@export var projectile_damage: float = 35.0
@export var projectile_knockback: float = 250.0
@export var min_teleport_distance: float = 180.0
@export var max_teleport_distance: float = 400.0
@export var laser_color: Color = Color(1.0, 0.25, 0.05, 0.85)

var current_phase: Phase = Phase.TELEGRAPH
var phase_timer: float = 0.0
var shoot_direction: Vector2 = Vector2.RIGHT
var is_aim_locked: bool = false
var target_laser: Line2D = null
var target_reticle: Node2D = null
var tele_particles: CPUParticles2D = null

func enter() -> void:
	var boss = character as PyroArchonBoss
	if boss:
		snipe_cooldown = boss.snipe_cooldown
		telegraph_duration = boss.telegraph_duration
		recovery_duration = boss.recovery_duration
		projectile_speed = boss.projectile_speed
		projectile_damage = boss.projectile_damage
		projectile_knockback = boss.projectile_knockback
		min_teleport_distance = boss.min_teleport_distance
		max_teleport_distance = boss.max_teleport_distance
		laser_color = boss.laser_color

	SubBossCoordinator.request_attack(character)
	_spawn_overhead_warning(telegraph_duration, laser_color)

	current_phase = Phase.TELEGRAPH
	phase_timer = 0.0
	is_aim_locked = false
	character.velocity = Vector2.ZERO

	_setup_laser_line()
	_setup_target_reticle()

	if character.animation_manager:
		var sprite = character.animation_manager.sprite
		if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("snipe"):
			character.animation_manager.play_anim("snipe", 2)
		else:
			character.animation_manager.play_anim("attack", 2)

func physics_update(delta: float) -> void:
	phase_timer += delta

	match current_phase:
		Phase.TELEGRAPH:
			character.velocity = Vector2.ZERO
			character.move_and_slide()

			# Aim straight-line sniper laser at player torso
			var boss = character as Enemy
			if boss and boss.target:
				var spawn_pos = character.global_position + Vector2(character.facing_direction * 16, -18)
				var player_torso = boss.target.global_position + Vector2(0, -21)
				
				# 2-Phase Aiming: Track for first part, then SNAP & FREEZE 0.45s before firing!
				var time_left = telegraph_duration - phase_timer
				var lock_threshold = 0.45

				if time_left > lock_threshold:
					# Phase 1: Smoothly tracking player
					shoot_direction = (player_torso - spawn_pos).normalized()
					if target_reticle:
						target_reticle.global_position = player_torso

				# Calculate laser end pos based on locked/tracking direction
				var end_pos = target_laser.to_local(spawn_pos + shoot_direction * 1200.0)
				target_laser.points = PackedVector2Array([target_laser.to_local(spawn_pos), end_pos])
				target_laser.visible = true

				# Reticle scaling
				if target_reticle:
					target_reticle.visible = true
					var progress = clamp(phase_timer / telegraph_duration, 0.0, 1.0)
					var reticle_scale = lerp(2.2, 0.6, progress)
					target_reticle.scale = Vector2(reticle_scale, reticle_scale)

				# Phase 2: Visual & Audio Lock Indicator when frozen
				if time_left <= lock_threshold:
					if not is_aim_locked:
						is_aim_locked = true
						_trigger_aim_lock_event()

					# Rapid flash to signal AIM IS LOCKED - DODGE NOW!
					var flash = (sin(phase_timer * 40.0) + 1.0) * 0.5
					target_laser.default_color = lerp(Color(1.0, 0.2, 0.05, 1.0), Color.WHITE, flash)
					target_laser.width = lerp(6.0, 12.0, flash * 0.5)
				else:
					target_laser.default_color = laser_color
					target_laser.width = 3.0

				if shoot_direction.x != 0.0:
					character.input_direction.x = sign(shoot_direction.x)
					character.update_facing_direction()

			if phase_timer >= telegraph_duration:
				_fire_sniper_shot()

		Phase.FIRE:
			# Single frame transition state to recovery
			pass

		Phase.RECOVERY_STAND_STILL:
			# Stand completely still for y seconds
			character.velocity = Vector2.ZERO
			character.move_and_slide()

			if phase_timer >= recovery_duration:
				_perform_ground_teleport()

		Phase.GROUND_TELEPORT:
			# Handled in async sequence
			pass

func _fire_sniper_shot() -> void:
	current_phase = Phase.FIRE
	phase_timer = 0.0

	_cleanup_laser_and_reticle()

	var boss = character as PyroArchonBoss
	var spawn_pos = character.global_position + Vector2(character.facing_direction * 16, -18)
	
	# Instantiate Sniper Projectile
	var proj_scene = boss.projectile_scene if (boss and boss.projectile_scene) else load("res://Scenes/Entities/Enemy/sniper_beam_projectile.tscn")
	if proj_scene:
		var projectile = proj_scene.instantiate()
		character.get_tree().current_scene.add_child(projectile)
		if projectile.has_method("setup"):
			projectile.setup(spawn_pos, shoot_direction, projectile_speed, projectile_damage)
	else:
		# Fallback direct beam script if scene is unassigned
		_spawn_procedural_sniper_beam(spawn_pos, shoot_direction)

	# Trigger Muzzle Recoil Blast
	_trigger_muzzle_flash(spawn_pos)

	# Transition to standing still for y seconds
	current_phase = Phase.RECOVERY_STAND_STILL

func _perform_ground_teleport() -> void:
	current_phase = Phase.GROUND_TELEPORT
	phase_timer = 0.0

	# 1. Spawn pyro departure ember burst
	_spawn_pyro_teleport_burst(character.global_position)

	# 2. Fade out sprite
	var sprite = character.find_child("AnimatedSprite2D") as AnimatedSprite2D
	if sprite:
		var tween_out = sprite.create_tween()
		tween_out.tween_property(sprite, "modulate:a", 0.0, 0.2)

	# 3. Calculate safe new ground location within min/max teleport distance
	await character.get_tree().create_timer(0.25).timeout

	var boss = character as Enemy
	var target_pos = boss.target.global_position if (boss and boss.target) else character.global_position
	
	# Random left or right direction away from player
	var side = -1.0 if randf() < 0.5 else 1.0
	var dist = randf_range(min_teleport_distance, max_teleport_distance)
	var new_x = target_pos.x + (side * dist)
	
	# Keep on ground level
	var ground_y = character.global_position.y
	character.global_position = Vector2(new_x, ground_y)
	
	if boss and boss.target:
		character.input_direction.x = sign(boss.target.global_position.x - character.global_position.x)
		character.update_facing_direction()

	# 4. Spawn arrival burst & fade sprite back in
	_spawn_pyro_teleport_burst(character.global_position)
	if sprite:
		var tween_in = sprite.create_tween()
		tween_in.tween_property(sprite, "modulate:a", 1.0, 0.2)

	await character.get_tree().create_timer(0.25).timeout

	_finish_state()

func _finish_state() -> void:
	SubBossCoordinator.release_attack(character)
	_cleanup_laser_and_reticle()

	var boss = character as PyroArchonBoss
	if boss:
		boss.snipe_cooldown_timer = boss.snipe_cooldown

	if character.is_grounded():
		state_machine.change_state("walk")
	else:
		state_machine.change_state("idle")

func exit() -> void:
	SubBossCoordinator.release_attack(character)
	_cleanup_laser_and_reticle()

func _spawn_overhead_warning(dur: float, col: Color) -> void:
	var warn = AttackWarningIndicator.new()
	warn.setup(dur, col)
	character.add_child(warn)

func _trigger_aim_lock_event() -> void:
	if target_reticle:
		var tween = target_reticle.create_tween()
		target_reticle.scale = Vector2(2.8, 2.8)
		tween.tween_property(target_reticle, "scale", Vector2(0.8, 0.8), 0.15)

	if target_laser:
		target_laser.width = 16.0

func _setup_laser_line() -> void:
	target_laser = character.find_child("PyroLaser", true, false) as Line2D
	if not target_laser:
		target_laser = Line2D.new()
		target_laser.name = "PyroLaser"
		target_laser.width = 4.0
		target_laser.default_color = laser_color
		target_laser.z_index = 10
		character.add_child(target_laser)
	target_laser.visible = false

func _setup_target_reticle() -> void:
	target_reticle = character.get_parent().find_child("PyroReticle", true, false) as Node2D
	if not target_reticle:
		target_reticle = VeilWalkerPhaseStrikeState.ReticleDrawer.new()
		target_reticle.name = "PyroReticle"
		character.get_parent().add_child(target_reticle)
	target_reticle.visible = false

func _cleanup_laser_and_reticle() -> void:
	if target_laser:
		target_laser.visible = false
	if target_reticle:
		target_reticle.visible = false

func _trigger_muzzle_flash(spawn_pos: Vector2) -> void:
	var flash = CPUParticles2D.new()
	flash.amount = 20
	flash.lifetime = 0.3
	flash.one_shot = true
	flash.explosiveness = 0.95
	flash.direction = shoot_direction
	flash.spread = 40.0
	flash.gravity = Vector2.ZERO
	flash.initial_velocity_min = 100.0
	flash.initial_velocity_max = 200.0
	flash.scale_amount_min = 3.0
	flash.scale_amount_max = 6.0
	flash.color = Color(1.0, 0.4, 0.05, 0.9)
	flash.global_position = spawn_pos
	
	character.get_parent().add_child(flash)
	flash.emitting = true
	character.get_tree().create_timer(0.35).timeout.connect(flash.queue_free)

func _spawn_pyro_teleport_burst(pos: Vector2) -> void:
	var burst = CPUParticles2D.new()
	burst.amount = 30
	burst.lifetime = 0.4
	burst.one_shot = true
	burst.explosiveness = 0.9
	burst.direction = Vector2(0, -1)
	burst.spread = 180.0
	burst.gravity = Vector2(0, -100)
	burst.initial_velocity_min = 60.0
	burst.initial_velocity_max = 140.0
	burst.scale_amount_min = 2.5
	burst.scale_amount_max = 5.5
	burst.color = Color(1.0, 0.3, 0.05, 0.95)
	burst.global_position = pos + Vector2(0, -18)
	
	character.get_parent().add_child(burst)
	burst.emitting = true
	character.get_tree().create_timer(0.45).timeout.connect(burst.queue_free)

func _spawn_procedural_sniper_beam(start_pos: Vector2, dir: Vector2) -> void:
	var beam_hitbox = Hitbox.new()
	beam_hitbox.damage = projectile_damage
	beam_hitbox.knockback_force = projectile_knockback
	beam_hitbox.knockback_direction = dir
	beam_hitbox.collision_layer = 16
	beam_hitbox.collision_mask = 2
	beam_hitbox.global_position = start_pos
	
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(1200, 16)
	shape.shape = rect
	shape.position = Vector2(600, 0)
	beam_hitbox.rotation = dir.angle()
	beam_hitbox.add_child(shape)
	
	character.get_tree().current_scene.add_child(beam_hitbox)
	character.get_tree().create_timer(0.1).timeout.connect(beam_hitbox.queue_free)
