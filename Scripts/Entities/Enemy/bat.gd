# Bat enemy controller that initially phases through the player once, then switches to normal combat at chest level
extends Enemy
class_name Bat

@export_group("Bat Settings")
## Damage dealt when phasing or attacking
@export var damage: float = 10.0

## Speed during the initial phase pass-through fly
@export var phase_fly_speed: float = 280.0

## Duration in seconds of the initial phase pass-through fly
@export var phase_duration: float = 1.2

## Flying movement speed during normal chase after phasing
@export var normal_fly_speed: float = 120.0

## Height offset for player chest level targeting (negative Y = up)
@export var chest_offset_y: float = -20.0

## Maximum lifespan in seconds before auto-despawning
@export var max_lifespan: float = 12.0

## Health of the bat
@export var bat_health: float = 25.0

## Indicates if entity flies and ignores gravity while alive
@export var is_flying: bool = true

var lifespan_timer: float = 0.0

func _init() -> void:
	super._init()
	max_health = 25.0
	current_health = 25.0
	move_speed = 120.0
	detection_range = 600.0
	attack_range = 35.0
	attack_cooldown = 1.2
	contact_damage = 10.0

func _ready() -> void:
	max_health = bat_health
	current_health = bat_health
	contact_damage = damage
	move_speed = normal_fly_speed
	
	super._ready()
	
	lifespan_timer = max_lifespan
	
	# Configure Hitbox Area2D to detect Player Hurtbox (Layer 2)
	var hitbox = find_child("Hitbox") as Hitbox
	if hitbox:
		hitbox.damage = damage
		
	# Ensure Hurtbox has short i-frames for satisfying multi-hit combos
	var hurtbox = find_child("Hurtbox") as Hurtbox
	if hurtbox:
		hurtbox.invincibility_duration = 0.05

func apply_gravity(delta: float) -> void:
	if is_flying and not is_dead:
		# Flying entities do not fall due to gravity while alive
		return
	super.apply_gravity(delta)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	lifespan_timer -= delta
	if lifespan_timer <= 0.0:
		spawn_pop_vfx()
		queue_free()
		return
		
	super._physics_process(delta)

## Takes damage with punchy white hit flash and squash/stretch hit reaction
func take_damage(amount: float) -> void:
	super.take_damage(amount)
	
	if not is_dead and animation_manager and animation_manager.sprite:
		var sprite = animation_manager.sprite
		# Bright white flash on hit
		sprite.modulate = Color(2.5, 2.5, 2.5, 1.0)
		var tween = create_tween()
		if tween:
			# Micro squash & stretch hit punch
			tween.tween_property(sprite, "scale", Vector2(1.3, 0.7), 0.04)
			tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.08)
			tween.tween_property(sprite, "modulate", get_base_modulate(), 0.06)

## Handles death with a scale pop and crimson particle explosion
func die() -> void:
	if is_dead:
		return
	is_dead = true
	died.emit()
	
	# Scale pop & flash right before bursting
	if animation_manager and animation_manager.sprite:
		var sprite = animation_manager.sprite
		sprite.modulate = Color(3.0, 3.0, 3.0, 1.0)
		var tween = create_tween()
		if tween:
			tween.tween_property(sprite, "scale", Vector2(1.4, 1.4), 0.04)
			tween.tween_callback(spawn_pop_vfx)
			tween.tween_callback(queue_free)
			return
			
	spawn_pop_vfx()
	queue_free()

## Spawns a punchy radial particle burst on bat death
func spawn_pop_vfx() -> void:
	var main_scene = get_tree().current_scene if get_tree() and get_tree().current_scene else get_parent()
	if not main_scene:
		return
		
	var particles = CPUParticles2D.new()
	particles.global_position = global_position
	particles.amount = 16
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.lifetime = 0.45
	particles.direction = Vector2.ZERO
	particles.spread = 180.0
	particles.gravity = Vector2(0.0, 140.0) # Soft downward arc
	particles.initial_velocity_min = 110.0
	particles.initial_velocity_max = 240.0
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.5
	
	# Crimson/Dark purple blood burst color gradient
	var grad = Gradient.new()
	grad.set_color(0, Color(1.0, 0.2, 0.35, 1.0))
	grad.set_color(1, Color(0.35, 0.05, 0.15, 0.0))
	particles.color_ramp = grad
	
	main_scene.add_child(particles)
	particles.emitting = true
	
	# Cleanup particle node after lifetime
	var cleanup_timer = get_tree().create_timer(0.6)
	cleanup_timer.timeout.connect(particles.queue_free)
