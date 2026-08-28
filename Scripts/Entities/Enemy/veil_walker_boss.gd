extends Enemy
class_name VeilWalkerBoss

@export_group("Special Phase Strike Ability")
## Cooldown between special phase strike attacks in seconds.
@export var special_attack_cooldown: float = 5.0

## Minimum distance to player required to trigger special attack.
@export var special_attack_min_range: float = 60.0

## Maximum distance to player required to trigger special attack.
@export var special_attack_max_range: float = 400.0

## Upward force launching boss into air during phase strike setup.
@export var rise_force: float = 450.0

## Time spent hovering in air while red laser aims at player.
@export var telegraph_duration: float = 0.75

## Speed during the downward phase strike through the player.
@export var strike_speed: float = 650.0

## Damage dealt when strike passes through player.
@export var strike_damage: float = 25.0

## Knockback force applied to player on strike hit.
@export var strike_knockback_force: float = 300.0

## Duration of stun applied to player on hit.
@export var strike_stun_duration: float = 0.3

## Recovery pause duration on ground after strike lands.
@export var recovery_duration: float = 0.8

## Color of the warning laser line pointing at the player.
@export var telegraph_line_color: Color = Color(1.0, 0.2, 0.35, 0.95)

## Width of the warning laser line in pixels.
@export var telegraph_line_width: float = 2.0

var special_attack_cooldown_timer: float = 0.0

func _ready() -> void:
	super._ready()
	# Standard clean sprite colors & sub-boss defaults
	modulate = Color(1.0, 1.0, 1.0)
	if max_health == 100.0:
		max_health = 300.0
		current_health = max_health
	if move_speed == 100.0:
		move_speed = 130.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_dead:
		return
	special_attack_cooldown_timer = max(0.0, special_attack_cooldown_timer - delta)

## Checks if the special phase strike attack can be performed right now.
func can_perform_special_attack() -> bool:
	if special_attack_cooldown_timer > 0.0 or target == null:
		return false
	var dist = global_position.distance_to(target.global_position)
	return dist >= special_attack_min_range and dist <= special_attack_max_range
