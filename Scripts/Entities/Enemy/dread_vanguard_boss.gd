# Sub-Boss 3: Dread Vanguard (Breakable Frontal Shield Tank)
extends Enemy
class_name DreadVanguardBoss

signal shield_changed(old_value: float, new_value: float)
signal shield_broken()

@export_group("Shield System (Designer Choices)")
## Maximum health of the breakable shield
@export var max_shield_health: float = 80.0

## Current health of the breakable shield
@export var current_shield_health: float = 80.0

## Percentage of damage blocked from front when shield is active (0.85 = 85% blocked)
@export var shield_damage_reduction: float = 0.85

## Duration boss is stunned when shield shatters (seconds)
@export var stun_on_shield_break_duration: float = 3.0

@export_group("Special Abilities (Designer Choices)")
## Cooldown between Ground Slam Shockwave attacks (seconds)
@export var slam_cooldown: float = 5.0

## Cooldown between Shield Charge attacks (seconds)
@export var charge_cooldown: float = 7.0

## Speed of floor shockwaves (pixels/sec)
@export var shockwave_speed: float = 450.0

## Speed during shield charge (pixels/sec)
@export var charge_speed: float = 500.0

## Damage dealt by Ground Slam shockwave
@export var slam_damage: float = 18.0

## Damage dealt by Shield Charge
@export var charge_damage: float = 20.0

## Scene of the Ground Shockwave Projectile
@export var shockwave_scene: PackedScene

var is_shield_broken: bool = false
var is_shield_raised: bool = true
var slam_cooldown_timer: float = 0.0
var charge_cooldown_timer: float = 0.0
var next_special_attack: String = "slam" # "slam" or "charge"

func _ready() -> void:
	super._ready()
	modulate = Color(0.82, 0.85, 0.75)
	max_health = 250.0
	current_health = 250.0
	move_speed = 45.0
	detection_range = 500.0
	attack_range = 50.0
	attack_cooldown = 2.0
	
	current_shield_health = max_shield_health
	slam_cooldown_timer = 2.0
	charge_cooldown_timer = 4.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if slam_cooldown_timer > 0.0:
		slam_cooldown_timer -= delta
	if charge_cooldown_timer > 0.0:
		charge_cooldown_timer -= delta

## Checks if any special attack can be performed right now
func can_perform_special_attack() -> bool:
	if is_dead or target == null:
		return false
		
	var dist = global_position.distance_to(target.global_position)
	if dist > detection_range:
		return false

	if slam_cooldown_timer <= 0.0:
		next_special_attack = "slam"
		return true
	elif charge_cooldown_timer <= 0.0:
		next_special_attack = "charge"
		return true

	return false

## Process damage with directional frontal shield check
func process_shield_damage(amount: float, attacker_global_pos: Vector2) -> float:
	if is_dead or amount <= 0.0:
		return amount
		
	# Determine if attack came from the FRONT
	var attack_dir = sign(attacker_global_pos.x - global_position.x)
	var is_frontal_attack = (attack_dir == facing_direction) or (attack_dir == 0)

	if is_shield_raised and not is_shield_broken and is_frontal_attack:
		# Deal damage to Shield HP
		var old_shield = current_shield_health
		current_shield_health = max(0.0, current_shield_health - amount)
		shield_changed.emit(old_shield, current_shield_health)

		_play_shield_block_sparks(attacker_global_pos)

		print("🛡️ [SHIELD BLOCK] Shield took ", amount, " damage. Shield HP: ", current_shield_health, "/", max_shield_health)

		# Check for Shield Shatter
		if current_shield_health <= 0.0:
			_shatter_shield()

		# Reduced leak-through damage to boss body
		var final_body_damage = amount * (1.0 - shield_damage_reduction)
		return final_body_damage
	else:
		# Flanked attack from behind! Full damage to boss body
		if not is_frontal_attack:
			print("🗡️ [FLANKED WEAKSPOT!] Attack passed behind shield for FULL damage!")
		return amount

func _shatter_shield() -> void:
	is_shield_broken = true
	is_shield_raised = false
	shield_broken.emit()

	print("💥 [SHIELD BROKEN!] Dread Vanguard shield shattered! Boss Stunned!")

	_spawn_shield_shatter_particles()

	# Stun the boss on shield break!
	stun(stun_on_shield_break_duration)

func _play_shield_block_sparks(pos: Vector2) -> void:
	var sparks = CPUParticles2D.new()
	sparks.amount = 18
	sparks.lifetime = 0.25
	sparks.one_shot = true
	sparks.explosiveness = 0.95
	sparks.direction = Vector2(facing_direction, -0.5).normalized()
	sparks.spread = 45.0
	sparks.gravity = Vector2(0, 400)
	sparks.initial_velocity_min = 120.0
	sparks.initial_velocity_max = 240.0
	sparks.scale_amount_min = 2.5
	sparks.scale_amount_max = 5.0
	sparks.color = Color(1.0, 0.85, 0.3, 0.95)
	sparks.global_position = pos

	get_parent().add_child(sparks)
	sparks.emitting = true
	get_tree().create_timer(0.3).timeout.connect(sparks.queue_free)

func _spawn_shield_shatter_particles() -> void:
	var burst = CPUParticles2D.new()
	burst.amount = 40
	burst.lifetime = 0.5
	burst.one_shot = true
	burst.explosiveness = 0.95
	burst.direction = Vector2(0, -1)
	burst.spread = 180.0
	burst.gravity = Vector2(0, 500)
	burst.initial_velocity_min = 150.0
	burst.initial_velocity_max = 300.0
	burst.scale_amount_min = 3.5
	burst.scale_amount_max = 8.0
	burst.color = Color(1.0, 0.75, 0.2, 0.95)
	burst.global_position = global_position + Vector2(facing_direction * 10, -20)

	get_parent().add_child(burst)
	burst.emitting = true
	get_tree().create_timer(0.6).timeout.connect(burst.queue_free)
