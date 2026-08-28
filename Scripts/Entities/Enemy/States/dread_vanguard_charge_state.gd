# Special Attack State B: Shield Charge for Dread Vanguard
extends CharacterState
class_name DreadVanguardChargeState

enum Phase { TELEGRAPH, CHARGE, RECOVERY }

@export var telegraph_duration: float = 0.5
@export var charge_duration: float = 0.6
@export var recovery_duration: float = 0.5
@export var charge_speed: float = 500.0
@export var charge_damage: float = 35.0

var current_phase: Phase = Phase.TELEGRAPH
var phase_timer: float = 0.0
var charge_dir: float = 1.0
var ghost_timer: float = 0.0

func enter() -> void:
	var boss = character as DreadVanguardBoss
	if boss:
		charge_speed = boss.charge_speed
		charge_damage = boss.charge_damage

	SubBossCoordinator.request_attack(character)
	_spawn_overhead_warning(telegraph_duration, Color(1.0, 0.85, 0.15, 0.95))

	current_phase = Phase.TELEGRAPH
	phase_timer = 0.0
	ghost_timer = 0.0
	character.velocity = Vector2.ZERO

	var target_node = (character as Enemy).target if (character is Enemy) else null
	if target_node:
		charge_dir = sign(target_node.global_position.x - character.global_position.x)
		if charge_dir == 0:
			charge_dir = character.facing_direction
		character.input_direction.x = charge_dir
		character.update_facing_direction()

	if character.animation_manager:
		var sprite = character.animation_manager.sprite
		if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("charge"):
			character.animation_manager.play_anim("charge", 2)
		else:
			character.animation_manager.play_anim("attack", 2)

func physics_update(delta: float) -> void:
	phase_timer += delta

	match current_phase:
		Phase.TELEGRAPH:
			character.velocity = Vector2.ZERO
			character.move_and_slide()

			if phase_timer >= telegraph_duration:
				_start_charge()

		Phase.CHARGE:
			character.apply_gravity(delta)
			character.velocity.x = charge_dir * charge_speed
			character.move_and_slide()

			# Spawn dust ghost trail
			ghost_timer += delta
			if ghost_timer >= 0.06:
				ghost_timer = 0.0
				_spawn_charge_dust()

			if phase_timer >= charge_duration or character.is_on_wall():
				_start_recovery()

		Phase.RECOVERY:
			character.apply_gravity(delta)
			character.apply_horizontal_movement(delta, 0.0, character.acceleration, character.friction)
			character.move_and_slide()

			if phase_timer >= recovery_duration:
				_finish_state()

func _start_charge() -> void:
	current_phase = Phase.CHARGE
	phase_timer = 0.0
	_enable_charge_hitbox(true)

func _start_recovery() -> void:
	current_phase = Phase.RECOVERY
	phase_timer = 0.0
	_enable_charge_hitbox(false)

func _finish_state() -> void:
	SubBossCoordinator.release_attack(character)
	_enable_charge_hitbox(false)

	var boss = character as DreadVanguardBoss
	if boss:
		boss.charge_cooldown_timer = boss.charge_cooldown

	state_machine.change_state("walk")

func exit() -> void:
	SubBossCoordinator.release_attack(character)
	_enable_charge_hitbox(false)

func _spawn_overhead_warning(dur: float, col: Color) -> void:
	var warn = AttackWarningIndicator.new()
	warn.setup(dur, col)
	character.add_child(warn)

func _enable_charge_hitbox(active: bool) -> void:
	var hitbox = character.find_child("Hitbox") as Hitbox
	if hitbox:
		hitbox.damage = charge_damage
		hitbox.knockback_force = 580.0
		hitbox.knockback_direction = Vector2(charge_dir * 0.75, -1.05).normalized()
		hitbox.stun_duration = 0.35
		var col = hitbox.find_child("CollisionShape2D") as CollisionShape2D
		if col:
			col.set_deferred("disabled", not active)
			
		if hitbox.hit_registered.is_connected(_on_charge_hit):
			hitbox.hit_registered.disconnect(_on_charge_hit)
		if active:
			hitbox.hit_registered.connect(_on_charge_hit)

func _on_charge_hit(_hurtbox: Hurtbox) -> void:
	if current_phase == Phase.CHARGE:
		# Pause for a few impact frames (0.05s) then transition to recovery, stopping forward rush
		character.get_tree().create_timer(0.05).timeout.connect(func():
			if current_phase == Phase.CHARGE:
				_start_recovery()
		)

func _spawn_charge_dust() -> void:
	var dust = CPUParticles2D.new()
	dust.amount = 8
	dust.lifetime = 0.3
	dust.one_shot = true
	dust.direction = Vector2(-charge_dir, -0.5).normalized()
	dust.spread = 25.0
	dust.gravity = Vector2(0, 200)
	dust.initial_velocity_min = 40.0
	dust.initial_velocity_max = 80.0
	dust.scale_amount_min = 2.0
	dust.scale_amount_max = 4.5
	dust.color = Color(0.85, 0.7, 0.4, 0.8)
	dust.global_position = character.global_position + Vector2(0, -5)

	character.get_parent().add_child(dust)
	dust.emitting = true
	character.get_tree().create_timer(0.35).timeout.connect(dust.queue_free)
