# Expanding Radial Shockwave Blast for Sub-Boss Shield Slam Attack
extends Area2D
class_name RadialShieldBlast

@export var max_radius: float = 115.0
@export var blast_duration: float = 0.35
@export var damage: float = 22.0
@export var knockback_force: float = 180.0

var current_radius: float = 10.0
var active_timer: float = 0.0
var col_shape: CollisionShape2D
var circle: CircleShape2D
var hit_targets: Array[Node2D] = []

func setup(pos: Vector2, blast_dmg: float = 22.0, max_rad: float = 115.0) -> void:
	global_position = pos
	damage = blast_dmg
	max_radius = max_rad

func _ready() -> void:
	collision_layer = 16 # Hazard layer
	collision_mask = 2 # Player layer

	col_shape = CollisionShape2D.new()
	circle = CircleShape2D.new()
	circle.radius = current_radius
	col_shape.shape = circle
	add_child(col_shape)

	body_entered.connect(_on_body_entered)
	_spawn_blast_particles()
	queue_redraw()

func _process(delta: float) -> void:
	active_timer += delta
	var progress = clamp(active_timer / blast_duration, 0.0, 1.0)
	current_radius = lerp(10.0, max_radius, ease(progress, 0.4))

	if circle:
		circle.radius = current_radius
	queue_redraw()

	if active_timer >= blast_duration:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if hit_targets.has(body):
		return
	hit_targets.append(body)

	var push_dir = (body.global_position - global_position).normalized()
	if push_dir == Vector2.ZERO:
		push_dir = Vector2.UP

	var hurtbox = body.find_child("Hurtbox", true, false) as Hurtbox
	if hurtbox:
		hurtbox.receive_hit(damage, push_dir * knockback_force, 0.4, self)
	elif body.has_method("take_damage"):
		body.take_damage(damage)
		if body is Character:
			(body as Character).velocity += push_dir * knockback_force
			(body as Character).stun(0.4)

func _draw() -> void:
	if active_timer >= blast_duration:
		return

	var progress = active_timer / blast_duration
	var alpha = (1.0 - progress) * 0.95

	# Inner filled shockwave blast disc
	draw_circle(Vector2.ZERO, current_radius, Color(1.0, 0.75, 0.15, alpha * 0.45))
	# Outer radiant shockwave ring
	draw_arc(Vector2.ZERO, current_radius, 0, TAU, 36, Color(1.0, 0.9, 0.35, alpha), 6.0)
	draw_arc(Vector2.ZERO, max(1.0, current_radius - 8.0), 0, TAU, 36, Color(1.0, 0.55, 0.1, alpha * 0.75), 3.0)

func _spawn_blast_particles() -> void:
	var particles = CPUParticles2D.new()
	particles.amount = 50
	particles.lifetime = 0.4
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.direction = Vector2.ZERO
	particles.spread = 180.0
	particles.gravity = Vector2(0, 250)
	particles.initial_velocity_min = 150.0
	particles.initial_velocity_max = 320.0
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 7.5
	particles.color = Color(1.0, 0.82, 0.2, 0.95)
	add_child(particles)
	particles.emitting = true
