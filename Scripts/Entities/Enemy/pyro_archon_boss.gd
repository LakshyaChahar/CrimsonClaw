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
@export var min_teleport_distance: float = 200.0

## Maximum ground teleport distance away from player
@export var max_teleport_distance: float = 380.0

## Color of the targeting laser & pyro effects
@export var laser_color: Color = Color(1.0, 0.35, 0.05, 0.95)

## Preferred standoff distance to keep away from player (pixels)
@export var keep_distance: float = 280.0

## Proximity distance that triggers an emergency teleport escape
@export var escape_distance: float = 110.0

## Cooldown before Pyro Archon can execute another emergency teleport escape (seconds)
@export var emergency_teleport_cooldown: float = 5.0

## PackedScene of the Sniper Beam Projectile
@export var projectile_scene: PackedScene

## Disable standard basic melee attacks (Pyro Archon only uses Snipe & Teleport)
@export var disable_basic_attack: bool = true

var snipe_cooldown_timer: float = 0.0
var proximity_escape_cooldown_timer: float = 0.0

func _ready() -> void:
	super._ready()
	modulate = Color(1.0, 0.82, 0.72)
	max_health = 180.0
	current_health = 180.0
	move_speed = 60.0
	detection_range = 600.0
	attack_range = 0.0 # Disabled basic attack range
	attack_cooldown = 999.0
	disable_basic_attack = true
	snipe_cooldown_timer = 1.0 # Start initial snipe after 1s
	
	# Disable contact hitbox so standing near Pyro Archon never deals contact damage
	var hb = find_child("Hitbox")
	if hb:
		for child in hb.get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", true)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if snipe_cooldown_timer > 0.0:
		snipe_cooldown_timer -= delta
	if proximity_escape_cooldown_timer > 0.0:
		proximity_escape_cooldown_timer -= delta

	# Emergency teleport escape only triggers when NOT attacking, NOT stunned, and NOT on cooldown
	if not is_dead and target != null and proximity_escape_cooldown_timer <= 0.0:
		var dist = global_position.distance_to(target.global_position)
		if dist <= escape_distance:
			if state_machine and (state_machine.current_state_name == "walk" or state_machine.current_state_name == "idle"):
				trigger_emergency_teleport()

func trigger_emergency_teleport() -> void:
	# Put emergency escape on a 5-second cooldown so player can close in with Dash and punish!
	proximity_escape_cooldown_timer = emergency_teleport_cooldown
	if state_machine and state_machine.has_node("Snipe"):
		var snipe_state = state_machine.get_node("Snipe")
		if snipe_state and snipe_state.has_method("start_emergency_teleport"):
			state_machine.change_state("snipe")
			snipe_state.start_emergency_teleport()

## Checked by AI State Machine to decide when to trigger Snipe Special Attack
func can_perform_special_attack() -> bool:
	return not is_dead and target != null and snipe_cooldown_timer <= 0.0 and global_position.distance_to(target.global_position) <= detection_range
