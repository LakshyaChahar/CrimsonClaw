# Straight-Line High Speed Piercing Sniper Beam Projectile for Pyro-Archon Sub-Boss
extends Hitbox
class_name SniperBeamProjectile

@export_group("Sniper Beam Properties")
## Speed of the straight-line beam projectile (pixels/sec)
@export var speed: float = 1200.0

## Maximum lifetime before auto-despawning (seconds)
@export var lifetime: float = 2.0

## Fire element damage over time
@export var inflicts_burn: bool = false

@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
@onready var anim_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var line_trail: Line2D = get_node_or_null("LineTrail")
@onready var particles: CPUParticles2D = get_node_or_null("EmberParticles")

var direction: Vector2 = Vector2.RIGHT
var distance_traveled: float = 0.0
var max_distance: float = 1500.0
var is_active: bool = false
var trail_points: Array[Vector2] = []
var max_trail_length: int = 8

func _ready() -> void:
	super._ready()
	inflicts_fire = false
	fire_dps = 0.0
	fire_duration = 0.0
	hit_registered.connect(_on_hit_registered)
	
	if anim_sprite and anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation("flying"):
		anim_sprite.play("flying")
		
	# Auto cleanup timer
	get_tree().create_timer(lifetime).timeout.connect(_on_lifetime_timeout)

func setup(start_pos: Vector2, shoot_direction: Vector2, custom_speed: float = -1.0, custom_damage: float = -1.0) -> void:
	global_position = start_pos
	direction = shoot_direction.normalized()
	rotation = direction.angle()
	
	if custom_speed > 0.0:
		speed = custom_speed
	if custom_damage > 0.0:
		damage = custom_damage
		
	is_active = true
	
	_setup_visual_trail()
	_setup_ember_particles()

func _physics_process(delta: float) -> void:
	if not is_active:
		return
		
	var step = direction * speed * delta
	global_position += step
	distance_traveled += step.length()
	
	_update_line_trail()
	
	if distance_traveled >= max_distance:
		_explode_and_free()

func _update_line_trail() -> void:
	if line_trail:
		trail_points.push_front(global_position)
		if trail_points.size() > max_trail_length:
			trail_points.pop_back()
			
		var local_points: PackedVector2Array = []
		for p in trail_points:
			local_points.append(to_local(p))
		line_trail.points = local_points

func _setup_visual_trail() -> void:
	if not line_trail:
		line_trail = Line2D.new()
		line_trail.name = "LineTrail"
		line_trail.width = 6.0
		line_trail.default_color = Color(1.0, 0.4, 0.1, 0.9) # Bright glowing pyro orange
		line_trail.z_index = 5
		add_child(line_trail)

func _setup_ember_particles() -> void:
	if not particles:
		particles = CPUParticles2D.new()
		particles.name = "EmberParticles"
		particles.amount = 16
		particles.lifetime = 0.3
		particles.direction = -direction
		particles.spread = 20.0
		particles.gravity = Vector2.ZERO
		particles.initial_velocity_min = 30.0
		particles.initial_velocity_max = 60.0
		particles.scale_amount_min = 2.0
		particles.scale_amount_max = 4.0
		particles.color = Color(1.0, 0.6, 0.1, 0.8)
		add_child(particles)
		particles.emitting = true

func _on_hit_registered(_hurtbox: Hurtbox) -> void:
	_explode_and_free()

func _on_lifetime_timeout() -> void:
	if is_active:
		_explode_and_free()

func _explode_and_free() -> void:
	if not is_active:
		return
	is_active = false
	
	# Disable collision shape so it doesn't hit again
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
		
	if line_trail:
		line_trail.visible = false
	if particles:
		particles.emitting = false
		
	_create_impact_burst()

	if anim_sprite and anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation("explode"):
		anim_sprite.play("explode")
		anim_sprite.animation_finished.connect(func(): queue_free(), CONNECT_ONE_SHOT)
	else:
		queue_free()

func _create_impact_burst() -> void:
	var burst = CPUParticles2D.new()
	burst.amount = 20
	burst.lifetime = 0.3
	burst.one_shot = true
	burst.explosiveness = 0.95
	burst.spread = 180.0
	burst.gravity = Vector2.ZERO
	burst.initial_velocity_min = 60.0
	burst.initial_velocity_max = 120.0
	burst.scale_amount_min = 2.5
	burst.scale_amount_max = 5.0
	burst.color = Color(1.0, 0.3, 0.05, 0.9)
	burst.global_position = global_position
	
	if get_parent():
		get_parent().add_child(burst)
		burst.emitting = true
		get_tree().create_timer(0.35).timeout.connect(burst.queue_free)

