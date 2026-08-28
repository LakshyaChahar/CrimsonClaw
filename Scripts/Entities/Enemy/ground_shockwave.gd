extends Hitbox
class_name GroundShockwave

@export_group("Shockwave Settings")
@export var speed: float = 750.0 
@export var max_travel_distance: float = 600.0
@export var lifetime: float = 1.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var direction: float = 1.0 
var distance_traveled: float = 0.0

var wave_aura: Polygon2D = null
var wave_core: Polygon2D = null
var energy_sparks: CPUParticles2D = null

func _ready() -> void:
	super._ready()
	hit_registered.connect(_on_hit_registered)
	_setup_visuals()
	get_tree().create_timer(lifetime).timeout.connect(_fade_out_and_destroy)

func setup(start_pos: Vector2, move_direction: float, custom_speed: float = -1.0, custom_damage: float = -1.0) -> void:
	global_position = start_pos
	direction = sign(move_direction)
	if direction == 0: direction = 1.0
		
	if custom_speed > 0.0: speed = custom_speed
	if custom_damage > 0.0: damage = custom_damage

	# Native node scaling: Flips the entire visual node perfectly when moving left
	scale.x = direction

	knockback_force = 520.0
	knockback_direction = Vector2(direction * 0.6, -1.0).normalized()

## Configures the shockwave to use a yellowish fire color theme and inflict fire status on hit targets.
func set_fire_theme(dps: float = 10.0, duration: float = 4.0) -> void:
	inflicts_fire = true
	fire_dps = dps
	fire_duration = duration
	
	if not is_node_ready():
		await ready
		
	if wave_aura:
		wave_aura.color = Color(1.0, 0.75, 0.15, 0.8)
	if wave_core:
		wave_core.color = Color(1.0, 0.95, 0.6, 1.0)
	if energy_sparks:
		var spark_grad = Gradient.new()
		spark_grad.add_point(0.0, Color(1.0, 1.0, 0.8, 1.0))
		spark_grad.add_point(0.5, Color(1.0, 0.65, 0.1, 0.9))
		spark_grad.add_point(1.0, Color(0.85, 0.2, 0.0, 0.0))
		energy_sparks.color_ramp = spark_grad

func _physics_process(delta: float) -> void:
	var step = direction * speed * delta
	global_position.x += step
	distance_traveled += abs(step)
	
	if distance_traveled >= max_travel_distance:
		_fade_out_and_destroy()

func _setup_visuals() -> void:
	
	# 1. THE AURA
	wave_aura = Polygon2D.new()
	wave_aura.color = Color(0.6, 0.9, 1.0, 0.7) 
	wave_aura.polygon = PackedVector2Array([
		Vector2(-15, 0),
		Vector2(10, -10),
		Vector2(30, -45),
		Vector2(10, -80),
		Vector2(-15, -90),
		Vector2(-25, -90),
		Vector2(-5, -75),
		Vector2(5, -45),
		Vector2(-5, -15),
		Vector2(-25, 0)
	])
	add_child(wave_aura)

	# 2. THE CORE
	wave_core = Polygon2D.new()
	wave_core.color = Color(1.0, 1.0, 1.0, 1.0)
	wave_core.polygon = PackedVector2Array([
		Vector2(-8, -10),
		Vector2(8, -20),
		Vector2(20, -45),
		Vector2(8, -70),
		Vector2(-8, -80),
		Vector2(-15, -80),
		Vector2(0, -65),
		Vector2(8, -45),
		Vector2(0, -25),
		Vector2(-15, -10)
	])
	add_child(wave_core)

	# 3. ENERGY PEEL PARTICLES 
	energy_sparks = CPUParticles2D.new()
	energy_sparks.amount = 75
	energy_sparks.lifetime = 0.4
	energy_sparks.local_coords = false
	energy_sparks.position = Vector2(-15, -45)
	energy_sparks.direction = Vector2(-1, 0).normalized()
	energy_sparks.spread = 25.0
	energy_sparks.initial_velocity_min = 200.0
	energy_sparks.initial_velocity_max = 350.0
	energy_sparks.scale_amount_min = 1.0
	energy_sparks.scale_amount_max = 3.0
	
	var scale_curve = Curve.new()
	scale_curve.add_point(Vector2(0.0, 1.0))
	scale_curve.add_point(Vector2(1.0, 0.0))
	energy_sparks.scale_amount_curve = scale_curve
	
	var spark_grad = Gradient.new()
	spark_grad.add_point(0.0, Color(1.0, 1.0, 1.0, 1.0))
	spark_grad.add_point(0.7, Color(0.4, 0.8, 1.0, 0.8))
	spark_grad.add_point(1.0, Color(0.0, 0.0, 0.0, 0.0))
	energy_sparks.color_ramp = spark_grad
	
	add_child(energy_sparks)
	energy_sparks.emitting = true
	
	scale.y = 0.1
	var tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale:y", 1.0, 0.15)

func _on_hit_registered(_hurtbox: Hurtbox) -> void:
	pass

func _fade_out_and_destroy() -> void:
	set_physics_process(false)
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
		
	var tween = create_tween().set_parallel(true)
	if wave_aura: tween.tween_property(wave_aura, "scale:x", 0.0, 0.15)
	if wave_core: tween.tween_property(wave_core, "scale:x", 0.0, 0.15)
		
	if energy_sparks: energy_sparks.emitting = false
		
	get_tree().create_timer(0.4).timeout.connect(queue_free)
