# Sorceress enemy controller that summons phasing bats and fires linear flying magic projectiles to attack the player
extends Enemy
class_name Sorceress

@export_group("Sorceress Bat Settings")
## Damage dealt by each summoned bat
@export var damage_per_bat: float = 12.0

## Number of bats spawned per summon cast wave
@export var number_of_bats: int = 3

## Time in seconds between bat summon casts
@export var bat_spawn_frequency: float = 4.0

## PackedScene of the Bat entity to spawn
@export var bat_scene: PackedScene

@export_group("Sorceress Projectile Settings")
## Enable launching linear magic projectiles alongside bat summons
@export var spawn_projectiles: bool = true

## Damage dealt per magic projectile
@export var damage_per_projectile: float = 8.0

## Number of projectiles fired per attack wave
@export var number_of_projectiles: int = 2

## Speed of linear magic projectiles
@export var projectile_speed: float = 240.0

## PackedScene of the Witch projectile entity (Moving.png -> Explode.png)
@export var projectile_scene: PackedScene

@onready var muzzle: Marker2D = get_node_or_null("Muzzle")

func _init() -> void:
	super._init()
	# Sorceress stats: operates from range, moderate health
	move_speed = 70.0
	max_health = 60.0
	current_health = 60.0
	detection_range = 450.0
	attack_range = 260.0
	attack_cooldown = bat_spawn_frequency

func _ready() -> void:
	super._ready()
	attack_cooldown = bat_spawn_frequency
	if not bat_scene:
		bat_scene = load("res://Scenes/Entities/Enemy/Bat.tscn")
	if not projectile_scene:
		projectile_scene = load("res://Scenes/Entities/Projectiles/WitchProjectile.tscn")

## Called during the Sorceress Attack state to launch bat swarm and linear magic projectiles
func execute_attack() -> void:
	summon_bats()
	if spawn_projectiles:
		fire_projectiles()

## Instantiates and launches bat swarm directly in front of her
func summon_bats() -> void:
	if not bat_scene:
		bat_scene = load("res://Scenes/Entities/Enemy/Bat.tscn")
	if not bat_scene:
		print("[Sorceress] Error: bat_scene not set and could not be loaded!")
		return
		
	# Determine spawn origin directly in front of the Sorceress based on facing direction
	var forward_x = facing_direction * 22.0
	var spawn_origin: Vector2 = global_position + Vector2(forward_x, -16.0)
	if muzzle:
		spawn_origin = global_position + Vector2(facing_direction * abs(muzzle.position.x), muzzle.position.y)
		
	var main_scene = get_tree().current_scene if get_tree() and get_tree().current_scene else get_parent()
	
	print("[Sorceress] Summoning ", number_of_bats, " bats in front (Facing: ", facing_direction, ", Damage: ", damage_per_bat, ")")
	
	var count = max(1, number_of_bats)
	for i in range(count):
		var bat_instance = bat_scene.instantiate()
		if not bat_instance:
			continue
			
		# Configure exported bat parameters
		if "facing_direction" in bat_instance:
			bat_instance.facing_direction = facing_direction
		if "damage" in bat_instance:
			bat_instance.damage = damage_per_bat
		if "contact_damage" in bat_instance:
			bat_instance.contact_damage = damage_per_bat
		if "target" in bat_instance:
			bat_instance.target = target
			
		# Add to tree BEFORE setting global_position to avoid transform matrix calculation glitches
		main_scene.add_child(bat_instance)
		
		# Fan out spawn locations vertically and slightly forward in front of her staff/hands
		var vert_offset = (float(i) - float(count - 1) / 2.0) * 14.0
		var horiz_offset = facing_direction * (abs(i - count / 2) * 6.0)
		bat_instance.global_position = spawn_origin + Vector2(horiz_offset, vert_offset)

## Instantiates and fires linear magic projectiles (Moving.png -> Explode.png) toward player chest
func fire_projectiles() -> void:
	if not projectile_scene:
		projectile_scene = load("res://Scenes/Entities/Projectiles/WitchProjectile.tscn")
	if not projectile_scene:
		return
		
	var forward_x = facing_direction * 22.0
	var spawn_origin: Vector2 = global_position + Vector2(forward_x, -16.0)
	if muzzle:
		spawn_origin = global_position + Vector2(facing_direction * abs(muzzle.position.x), muzzle.position.y)
		
	var main_scene = get_tree().current_scene if get_tree() and get_tree().current_scene else get_parent()
	var count = max(1, number_of_projectiles)
	
	print("[Sorceress] Firing ", count, " linear magic projectiles (Moving.png -> Explode.png)")
	
	for i in range(count):
		var proj_instance = projectile_scene.instantiate()
		if not proj_instance:
			continue
			
		if "damage" in proj_instance:
			proj_instance.damage = damage_per_projectile
		if "speed" in proj_instance:
			proj_instance.speed = projectile_speed
		
		# Add to tree BEFORE setting global_position
		main_scene.add_child(proj_instance)
		
		var vert_offset = (float(i) - float(count - 1) / 2.0) * 16.0
		proj_instance.global_position = spawn_origin + Vector2(0.0, vert_offset)
		
		# Direct towards player chest or facing direction
		var target_pos = global_position + Vector2(facing_direction * 200.0, -16.0)
		if target:
			target_pos = target.global_position + Vector2(0.0, -20.0)
			
		var dir = (target_pos - proj_instance.global_position).normalized()
		if "direction" in proj_instance:
			proj_instance.direction = dir
