# Sub-Boss 2: Pyro-Archon Ranged Sniper Boss
extends Enemy
class_name PyroArchonBoss

@export_group("Pyro-Archon Special Ability (Designer Choices)")
## Time in seconds between Snipe Special Attacks (x seconds)
@export var snipe_cooldown: float = 5.5

## Duration of laser telegraph lock-on aiming before firing (seconds)
@export var telegraph_duration: float = 1.2

## Time standing completely still in place after firing (y seconds)
@export var recovery_duration: float = 2.2

## Speed of the straight-line piercing sniper projectile (pixels/sec)
@export var projectile_speed: float = 1200.0

## Damage dealt by the sniper beam
@export var projectile_damage: float = 20.0

## Knockback force applied by the sniper beam
@export var projectile_knockback: float = 250.0

## Minimum ground teleport distance away from player
@export var min_teleport_distance: float = 180.0

## Maximum ground teleport distance away from player
@export var max_teleport_distance: float = 400.0

## Color of the targeting laser & pyro effects
@export var laser_color: Color = Color(1.0, 0.35, 0.05, 0.95)

## PackedScene of the Sniper Beam Projectile
@export var projectile_scene: PackedScene

var snipe_cooldown_timer: float = 0.0

func _ready() -> void:
	super._ready()
	modulate = Color(1.0, 0.82, 0.72)
	max_health = 180.0
	current_health = 180.0
	move_speed = 60.0
	detection_range = 600.0
	attack_range = 500.0
	attack_cooldown = 3.5
	snipe_cooldown_timer = 1.0 # Start initial snipe after 1s

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if snipe_cooldown_timer > 0.0:
		snipe_cooldown_timer -= delta

## Checked by AI State Machine to decide when to trigger Snipe Special Attack
func can_perform_special_attack() -> bool:
	return not is_dead and target != null and snipe_cooldown_timer <= 0.0 and global_position.distance_to(target.global_position) <= detection_range
