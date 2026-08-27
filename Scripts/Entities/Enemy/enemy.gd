# Enemy controller class handling basic AI targeting
extends Character
class_name Enemy

@export_group("Combat Stats")
@export var contact_damage: float = 10.0
## Horizontal knockback force applied to target when attacking (pixels/sec)
@export var attack_knockback_force: float = 220.0
## Duration of hit stagger/stun applied to target (seconds)
@export var attack_stun_duration: float = 0.1

@export_group("AI Settings")
@export var detection_range: float = 300.0
@export var attack_range: float = 55.0
@export var attack_cooldown: float = 1.0

@export_group("Stealth Settings")
@export var is_stealth: bool = false
@export var reveal_range: float = 120.0
@export var detect_from_above: bool = false

@export_group("Ambush Settings")
@export var ambush_damage: float = 25.0
@export var ambush_lunge_speed: float = 350.0

var target: Node2D = null
var attack_cooldown_timer: float = 0.0
var is_revealed: bool = true
var _original_collision_layer: int = 2
var is_burning: bool = false
var current_fire_dps: float = 0.0
var burn_timer: float = 0.0
var sprite_node: CanvasItem = null
var burn_material: ShaderMaterial = null

func _init() -> void:
	move_speed = 100.0
	max_health = 30.0
	current_health = 30.0
	health_regen_rate = 0.0

func _ready() -> void:
	super._ready()
	_original_collision_layer = collision_layer
	_find_target()
	
	# Automatically apply exported combat stats to the Hitbox component
	var hitbox = find_child("Hitbox") as Hitbox
	if hitbox:
		hitbox.damage = contact_damage
		hitbox.knockback_force = attack_knockback_force
		hitbox.stun_duration = attack_stun_duration
	
	if is_stealth:
		is_revealed = false
		set_stealth_mode(true)

	_setup_floating_health_bar()

func _setup_floating_health_bar() -> void:
	var bar = find_child("FloatingHealthBar", false, false) as FloatingHealthBar
	if not bar:
		bar = FloatingHealthBar.new()
		bar.name = "FloatingHealthBar"
		
		# Option B for Bosses/Sub-Bosses, Option A for Normal Enemies
		var is_boss = (self is VeilWalkerBoss) or (self is PyroArchonBoss) or (self is DreadVanguardBoss) or ("is_sub_boss" in self)
		bar.is_boss_bar = is_boss
		bar.bar_width = 48.0 if is_boss else 34.0
		bar.offset_y = -44.0 if is_boss else -36.0
		
		add_child(bar)

func apply_burn(dps: float, duration: float) -> void:
	if is_dead:
		return
		
	current_fire_dps = dps
	burn_timer = max(burn_timer, duration) 
	
	if not is_burning:
		is_burning = true
		_setup_burn_shader()
		
func _setup_burn_shader() -> void:
	sprite_node = find_child("AnimatedSprite2D", true, false) as CanvasItem
	if not sprite_node:
		sprite_node = find_child("Sprite2D", true, false) as CanvasItem
		
	if sprite_node:
		var shader = load("res://Scripts/Entities/Enemy/Shaders/enemy_shader.gdshader") as Shader
		if shader:
			burn_material = ShaderMaterial.new()
			burn_material.shader = shader
			sprite_node.material = burn_material

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta
		
	if not target:
		_find_target()
		
	if is_stealth and not is_revealed and target:
		var dist = global_position.distance_to(target.global_position)
		if dist <= reveal_range:
			if detect_from_above:
				# Only reveal if the player is generally below us (Y is greater) and horizontally close
				var horiz_dist = abs(global_position.x - target.global_position.x)
				if target.global_position.y > global_position.y and horiz_dist < (reveal_range * 0.8):
					reveal_enemy()
			else:
				reveal_enemy()
	if is_burning and not is_dead:
		burn_timer -= delta
		
		# Drive the shader burning effect dynamically
		if burn_material:
			burn_material.set_shader_parameter("burn_intensity", 1.0)
		
		# Apply smooth continuous damage (dps * delta)
		current_health -= (current_fire_dps * delta) 
		health_changed.emit(current_health + (current_fire_dps * delta), current_health)
		
		if current_health <= 0:
			die()
			
		if burn_timer <= 0.0:
			extinguish_fire()

func extinguish_fire(_immediate: bool = false) -> void:
	is_burning = false
	
	if burn_material and sprite_node:
		burn_material.set_shader_parameter("burn_intensity", 0.0)
		sprite_node.material = null
		burn_material = null
		
	sprite_node = null
	
# Sets visibility, collision layers, and toggles Hitbox/Hurtbox monitoring
func set_stealth_mode(enabled: bool) -> void:
	visible = not enabled
	
	if enabled:
		collision_layer = 0
	else:
		collision_layer = _original_collision_layer
		
	var hitbox = find_child("Hitbox") as Area2D
	if hitbox:
		hitbox.monitoring = not enabled
		hitbox.monitorable = not enabled
		var shape = hitbox.find_child("CollisionShape2D") as CollisionShape2D
		if shape:
			shape.set_deferred("disabled", enabled)
			
	var hurtbox = find_child("Hurtbox") as Area2D
	if hurtbox:
		hurtbox.monitoring = not enabled
		hurtbox.monitorable = not enabled
		var shape = hurtbox.find_child("CollisionShape2D") as CollisionShape2D
		if shape:
			shape.set_deferred("disabled", enabled)

# Reveals the enemy and transitions the state machine to start combat
func reveal_enemy() -> void:
	is_revealed = true
	set_stealth_mode(false)
	
	if state_machine:
		if state_machine.states.has("ambush"):
			state_machine.change_state("ambush")
		elif state_machine.states.has("walk"):
			state_machine.change_state("walk")

## Checks if the enemy is currently inside the player's active camera screen bounds
func is_visible_in_screen(margin: float = 40.0) -> bool:
	var vp = get_viewport()
	if not vp:
		return true
	var cam = vp.get_camera_2d()
	if not cam:
		return true

	var screen_rect = vp.get_visible_rect()
	var cam_center = cam.get_screen_center_position()
	var half_size = (screen_rect.size * 0.5) / cam.zoom + Vector2(margin, margin)
	var cam_bounds = Rect2(cam_center - half_size, half_size * 2.0)

	return cam_bounds.has_point(global_position)

# Searches the scene tree to locate the player character
func _find_target() -> void:
	if not is_inside_tree() or not get_tree():
		return
		
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		target = players[0]
		return
		
	var root_node = get_tree().current_scene if get_tree().current_scene else get_tree().root
	if root_node:
		var player_node = root_node.find_child("Player", true, false)
		if player_node is Node2D:
			target = player_node

## Calculates perpendicular outer horizontal distance between enemy collision shape and target collision shape
func get_outer_distance_to_target() -> float:
	if not target:
		return 999999.0
		
	var my_center_x: float = global_position.x
	var my_radius: float = 16.0
	var my_shape = find_child("CollisionShape2D", false, false) as CollisionShape2D
	if my_shape and my_shape.shape:
		my_center_x = my_shape.global_position.x
		if my_shape.shape is CapsuleShape2D or my_shape.shape is CircleShape2D:
			my_radius = my_shape.shape.radius * abs(global_transform.get_scale().x)
		elif my_shape.shape is RectangleShape2D:
			my_radius = (my_shape.shape.size.x * 0.5) * abs(global_transform.get_scale().x)

	var target_center_x: float = target.global_position.x
	var target_radius: float = 16.0
	var target_shape = target.find_child("CollisionShape2D", false, false) as CollisionShape2D
	if target_shape and target_shape.shape:
		target_center_x = target_shape.global_position.x
		if target_shape.shape is CapsuleShape2D or target_shape.shape is CircleShape2D:
			target_radius = target_shape.shape.radius * abs(target.global_transform.get_scale().x)
		elif target_shape.shape is RectangleShape2D:
			target_radius = (target_shape.shape.size.x * 0.5) * abs(target.global_transform.get_scale().x)

	var center_dist_x = abs(my_center_x - target_center_x)
	return max(0.0, center_dist_x - (my_radius + target_radius))

