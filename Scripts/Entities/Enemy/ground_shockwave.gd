# Floor-traveling Shockwave Projectile spawned by Dread Vanguard Ground Slam
extends Hitbox
class_name GroundShockwave

@export_group("Shockwave Settings")
## Speed of the floor shockwave (pixels/sec)
@export var speed: float = 450.0

## Maximum travel distance before despawning
@export var max_travel_distance: float = 500.0

## Lifetime in seconds
@export var lifetime: float = 1.5

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var direction: float = 1.0 # 1.0 for Right, -1.0 for Left
var distance_traveled: float = 0.0
var line_visual: Line2D = null
var particle_dust: CPUParticles2D = null

func _ready() -> void:
	super._ready()
	hit_registered.connect(_on_hit_registered)
	_setup_visuals()
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func setup(start_pos: Vector2, move_direction: float, custom_speed: float = -1.0, custom_damage: float = -1.0) -> void:
	global_position = start_pos
	direction = sign(move_direction)
	if direction == 0:
		direction = 1.0
		
	if custom_speed > 0.0:
		speed = custom_speed
	if custom_damage > 0.0:
		damage = custom_damage

	knockback_force = 120.0
	knockback_direction = Vector2(direction, -0.4).normalized()

func _physics_process(delta: float) -> void:
	var step = direction * speed * delta
	global_position.x += step
	distance_traveled += abs(step)
	
	if distance_traveled >= max_travel_distance:
		queue_free()

func _setup_visuals() -> void:
	# Create jagged rock/earth shockwave line visual
	line_visual = Line2D.new()
	line_visual.name = "ShockwaveLine"
	line_visual.width = 12.0
	line_visual.default_color = Color(1.0, 0.7, 0.2, 0.95) # Glowing Earth/Gold
	line_visual.points = PackedVector2Array([
		Vector2(-15, 0), Vector2(-10, -18), Vector2(0, -32), Vector2(10, -18), Vector2(15, 0)
	])
	add_child(line_visual)

	# Create dust/rock particle trail
	particle_dust = CPUParticles2D.new()
	particle_dust.amount = 20
	particle_dust.lifetime = 0.4
	particle_dust.direction = Vector2(-direction, -0.8).normalized()
	particle_dust.spread = 30.0
	particle_dust.gravity = Vector2(0, 300)
	particle_dust.initial_velocity_min = 60.0
	particle_dust.initial_velocity_max = 120.0
	particle_dust.scale_amount_min = 3.0
	particle_dust.scale_amount_max = 6.0
	particle_dust.color = Color(0.9, 0.6, 0.25, 0.8)
	add_child(particle_dust)
	particle_dust.emitting = true

func _on_hit_registered(_hurtbox: Hurtbox) -> void:
	# Keep traveling past targets to force all entities to jump!
	pass
