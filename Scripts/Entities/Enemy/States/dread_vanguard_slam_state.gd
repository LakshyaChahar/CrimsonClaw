# Special Attack State A: Ground Slam Shockwave for Dread Vanguard
extends CharacterState
class_name DreadVanguardSlamState

enum Phase { RISE_TELEGRAPH, SLAM_IMPACT, RECOVERY }

@export var telegraph_duration: float = 1.0
@export var recovery_duration: float = 0.5
@export var shockwave_speed: float = 450.0
@export var shockwave_damage: float = 30.0

var current_phase: Phase = Phase.RISE_TELEGRAPH
var phase_timer: float = 0.0
var warning_polygon: Polygon2D = null

func enter() -> void:
	var boss = character as DreadVanguardBoss
	if boss:
		shockwave_speed = boss.shockwave_speed
		shockwave_damage = boss.slam_damage

	SubBossCoordinator.request_attack(character)
	_spawn_overhead_warning(telegraph_duration, Color(1.0, 0.85, 0.15, 0.95))

	current_phase = Phase.RISE_TELEGRAPH
	phase_timer = 0.0
	character.velocity = Vector2.ZERO

	_setup_warning_telegraph()

	if character.animation_manager:
		var sprite = character.animation_manager.sprite
		if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("slam"):
			character.animation_manager.play_anim("slam", 2)
		else:
			character.animation_manager.play_anim("attack", 2)

func physics_update(delta: float) -> void:
	phase_timer += delta

	match current_phase:
		Phase.RISE_TELEGRAPH:
			character.velocity = Vector2.ZERO
			character.move_and_slide()

			# Pulse golden warning floor zone
			if warning_polygon:
				var pulse = (sin(phase_timer * 20.0) + 1.0) * 0.5
				warning_polygon.color = Color(1.0, 0.7, 0.1, lerp(0.3, 0.7, pulse))

			if phase_timer >= telegraph_duration:
				_perform_slam_impact()

		Phase.SLAM_IMPACT:
			pass

		Phase.RECOVERY:
			character.velocity = Vector2.ZERO
			character.move_and_slide()

			if phase_timer >= recovery_duration:
				_finish_state()

func _perform_slam_impact() -> void:
	current_phase = Phase.SLAM_IMPACT
	phase_timer = 0.0

	_cleanup_warning_telegraph()

	var _boss = character as DreadVanguardBoss
	var slam_pos = character.global_position + Vector2(character.facing_direction * 15, 0)

	# 1. Spawn Radial Circular Blast Shockwave expanding outward
	var blast = RadialShieldBlast.new()
	blast.setup(slam_pos, shockwave_damage, 115.0)
	character.get_tree().current_scene.add_child(blast)

	# 2. Spawn 2 floor-traveling shockwaves (Left & Right)
	_spawn_shockwave(slam_pos, -1.0)
	_spawn_shockwave(slam_pos, 1.0)

	current_phase = Phase.RECOVERY

func _spawn_shockwave(pos: Vector2, dir: float) -> void:
	var boss = character as DreadVanguardBoss
	var wave_scene = boss.shockwave_scene if (boss and boss.shockwave_scene) else load("res://Scenes/Entities/Enemy/ground_shockwave.tscn")
	
	if wave_scene:
		var wave = wave_scene.instantiate()
		character.get_tree().current_scene.add_child(wave)
		if wave.has_method("setup"):
			wave.setup(pos, dir, shockwave_speed, shockwave_damage)
	else:
		_spawn_procedural_shockwave(pos, dir)

func _spawn_procedural_shockwave(pos: Vector2, dir: float) -> void:
	var wave = GroundShockwave.new()
	wave.setup(pos, dir, shockwave_speed, shockwave_damage)
	character.get_tree().current_scene.add_child(wave)

func _setup_warning_telegraph() -> void:
	warning_polygon = character.find_child("SlamWarning", true, false) as Polygon2D
	if not warning_polygon:
		warning_polygon = Polygon2D.new()
		warning_polygon.name = "SlamWarning"
		warning_polygon.color = Color(1.0, 0.85, 0.15, 0.35)
		
		# Generate 24-point radial circle warning area
		var points = PackedVector2Array()
		for i in range(24):
			var angle = (float(i) / 24.0) * TAU
			points.append(Vector2(cos(angle), sin(angle)) * 115.0)
		warning_polygon.polygon = points
		character.add_child(warning_polygon)
	warning_polygon.visible = true

func _cleanup_warning_telegraph() -> void:
	if warning_polygon:
		warning_polygon.visible = false

func _spawn_slam_impact_particles(pos: Vector2) -> void:
	var burst = CPUParticles2D.new()
	burst.amount = 35
	burst.lifetime = 0.4
	burst.one_shot = true
	burst.explosiveness = 0.95
	burst.direction = Vector2(0, -1)
	burst.spread = 120.0
	burst.gravity = Vector2(0, 600)
	burst.initial_velocity_min = 100.0
	burst.initial_velocity_max = 250.0
	burst.scale_amount_min = 3.0
	burst.scale_amount_max = 7.0
	burst.color = Color(1.0, 0.65, 0.15, 0.95)
	burst.global_position = pos

	character.get_parent().add_child(burst)
	burst.emitting = true
	character.get_tree().create_timer(0.5).timeout.connect(burst.queue_free)

func _finish_state() -> void:
	SubBossCoordinator.release_attack(character)
	_cleanup_warning_telegraph()

	var boss = character as DreadVanguardBoss
	if boss:
		boss.slam_cooldown_timer = boss.slam_cooldown

	state_machine.change_state("walk")

func exit() -> void:
	SubBossCoordinator.release_attack(character)
	_cleanup_warning_telegraph()

func _spawn_overhead_warning(dur: float, col: Color) -> void:
	var warn = AttackWarningIndicator.new()
	warn.setup(dur, col)
	character.add_child(warn)
