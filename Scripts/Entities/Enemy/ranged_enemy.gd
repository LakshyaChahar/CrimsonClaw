# Ranged enemy controller that shoots lobbed projectiles at the player
extends Enemy
class_name RangedEnemy

@export_group("Ranged Settings")
## Base movement speed of the projectile along the ground plane (pixels per second)
@export var throw_speed: float = 320.0

## Maximum height of the parabolic arc at the midpoint of flight
@export var arc_height: float = 70.0

## The damage dealt by the projectile when it hits the player
@export var projectile_damage: float = 15.0

## PackedScene of the Lobbed Projectile to spawn
@export var projectile_scene: PackedScene

@onready var muzzle: Marker2D = $Muzzle

func _init() -> void:
	super._init()
	# Ranged enemy prefers staying further away and firing from range
	detection_range = 400.0
	attack_range = 300.0
	attack_cooldown = 1.5
	move_speed = 70.0
	max_health = 30.0
	current_health = 30.0
	health_regen_rate = 0.0

## Called during the Attack State at the precise throw frame to instantiate and launch a projectile
func fire_projectile() -> void:
	if not target or not projectile_scene:
		return
		
	var spawn_pos: Vector2 = (global_position + Vector2(facing_direction * abs(muzzle.position.x), muzzle.position.y)) if muzzle else (global_position + Vector2(facing_direction * 16, -30))
	var target_pos: Vector2 = target.global_position
	
	# 1. Instantiate the projectile scene dynamically
	var projectile = projectile_scene.instantiate()
	
	# 2. Configure properties on the projectile
	if "arc_height" in projectile:
		projectile.arc_height = arc_height
	if "damage" in projectile:
		projectile.damage = projectile_damage
		
	# 3. Add projectile to the main level scene tree so it moves independently of the enemy
	get_tree().current_scene.add_child(projectile)
	
	# 4. Initialize start/target positions & compute dynamic travel time
	if projectile.has_method("setup"):
		projectile.setup(spawn_pos, target_pos, throw_speed)
