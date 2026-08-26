# Lobbed Arc Projectile thrown by Ranged Enemies using parabolic trajectory
extends Hitbox
class_name LobbedProjectile

@export_group("Flight Settings")
## Base movement speed along the ground plane (pixels per second).
@export var speed: float = 300.0

## Maximum height of the parabolic arc (in pixels) at the midpoint.
@export var arc_height: float = 60.0

## If true, damage hitbox is only active upon landing at target position.
@export var damage_on_impact_only: bool = true

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shadow: Polygon2D = $ShadowSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var start_position: Vector2
var target_position: Vector2
var travel_time: float = 1.0
var elapsed_time: float = 0.0
var is_flying: bool = false
var is_exploding: bool = false

func _ready() -> void:
	super._ready()
	hit_registered.connect(_on_hit_registered)
	if animated_sprite:
		animated_sprite.play("moving")

## Initializes target, calculates dynamic flight time based on distance and speed, and starts motion
func setup(start_pos: Vector2, target_pos: Vector2, custom_speed: float = -1.0) -> void:
	start_position = start_pos
	target_position = target_pos
	global_position = start_pos
	
	var active_speed = custom_speed if custom_speed > 0.0 else speed
	var distance = start_position.distance_to(target_position)
	
	# Dynamic travel time formula: Time = Distance / Speed
	travel_time = max(distance / max(active_speed, 1.0), 0.1)
	elapsed_time = 0.0
	is_flying = true
	
	# If impact-only damage, keep collision disabled while airborne
	if damage_on_impact_only and collision_shape:
		collision_shape.set_deferred("disabled", true)

func _physics_process(delta: float) -> void:
	if not is_flying or is_exploding:
		return
		
	elapsed_time += delta
	var progress: float = clamp(elapsed_time / travel_time, 0.0, 1.0)
	
	# 1. Ground plane movement: Interpolate linearly from start to target
	global_position = start_position.lerp(target_position, progress)
	
	# 2. Altitude Parabola: h(t) = 4 * max_height * t * (1 - t)
	var current_height: float = 4.0 * arc_height * progress * (1.0 - progress)
	
	# Offset sprite Y position to visually loft into the air
	if animated_sprite:
		animated_sprite.position.y = -current_height
		
	# 3. Handle flight completion / landing
	if progress >= 1.0:
		_on_landed()

func _on_landed() -> void:
	if is_exploding:
		return
	is_exploding = true
	is_flying = false
	
	# Enable collision shape upon impact to register hit with target
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
		
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("explode"):
		animated_sprite.position.y = 0.0
		animated_sprite.play("explode")
		await animated_sprite.animation_finished
		
	queue_free()

func _on_hit_registered(_hurtbox: Hurtbox) -> void:
	_on_landed()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
