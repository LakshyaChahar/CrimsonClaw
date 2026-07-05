extends CharacterBody2D
class_name Character

# --- Signals ---
signal health_changed(old_value: float, new_value: float)
signal died()

# --- Movement Properties ---
@export_group("Horizontal Movement")
@export var move_speed: float = 200.0
@export var acceleration: float = 1200.0
@export var friction: float = 1500.0
@export var air_control: float = 0.75 # Multiplier for acceleration in the air

@export_group("Jump Parameters")
@export var jump_force: float = -420.0
@export var gravity_scale: float = 1.0
@export var max_fall_speed: float = 800.0

@export_group("Dash Properties")
@export var dash_speed: float = 650.0
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 0.8

@export_group("Health System")
@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var health_regen_rate: float = 1.0 # Health regenerated per second
@export var is_dead: bool = false

# --- Child Node References ---
var animation_manager: CharacterAnimationManager
var state_machine: CharacterStateMachine

# --- Input registers (populated by Player Input or Enemy AI) ---
var input_direction: Vector2 = Vector2.ZERO
var wants_jump: bool = false
var wants_dash: bool = false
var wants_skill: bool = false

# --- State Registers ---
var facing_direction: int = 1 # 1 for Right, -1 for Left
var dash_direction: Vector2 = Vector2.RIGHT
var is_dashing: bool = false
var can_dash: bool = true
var force_on_floor: bool = false


# Local gravity cache based on project settings or custom settings
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)

func _ready() -> void:
	# Retrieve helper managers if attached
	animation_manager = get_node_or_null("CharacterAnimationManager")
	if not animation_manager:
		animation_manager = find_child("*CharacterAnimationManager*")
		
	state_machine = get_node_or_null("CharacterStateMachine")
	if not state_machine:
		state_machine = find_child("*CharacterStateMachine*")

func _physics_process(delta: float) -> void:
	# Manage dash cooldown timer in the background
	if not can_dash and not is_dashing:
		# Cooldown tick can be handled here or in a state
		pass
		
	# Passive health regeneration slowly over time
	if not is_dead and current_health < max_health:
		heal(health_regen_rate * delta)

## Applies default gravity to the character's velocity
func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * gravity_scale * delta
		velocity.y = min(velocity.y, max_fall_speed)

## Applies horizontal movement towards a target speed using acceleration/friction
func apply_horizontal_movement(delta: float, target_speed: float, accel: float, deaccel: float) -> void:
	var target_vel = target_speed
	
	# Determine if we are accelerating or applying friction/decelerating
	var rate = accel if abs(target_vel) > 0.0 else deaccel
	
	# If we are in the air, reduce acceleration/friction by air control
	if not is_on_floor():
		rate *= air_control
		
	velocity.x = move_toward(velocity.x, target_vel, rate * delta)

## Updates character facing direction based on input movement
func update_facing_direction() -> void:
	if input_direction.x != 0.0:
		facing_direction = sign(input_direction.x)
		if animation_manager and animation_manager.sprite:
			animation_manager.sprite.flip_h = (facing_direction == -1)

## Returns true if the character is physically on the floor or if the floor state is forced.
func is_grounded() -> bool:
	return is_on_floor() or force_on_floor

## Restores health by a certain amount, capped at max_health
func heal(amount: float) -> void:
	if is_dead:
		return
	var old_health = current_health
	current_health = min(current_health + amount, max_health)
	if old_health != current_health:
		health_changed.emit(old_health, current_health)

## Deals damage to the character, clamping at 0 and triggering death if health reaches 0
func take_damage(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	var old_health = current_health
	current_health = max(current_health - amount, 0.0)
	print(current_health)
	
	if old_health != current_health:
		health_changed.emit(old_health, current_health)
		
	if current_health <= 0.0:
		die()

## Handles death logic and triggers death state if configured
func die() -> void:
	is_dead = true
	died.emit()
	if state_machine:
		# If a death state is registered, transition to it
		if state_machine.states.has("dead"):
			state_machine.change_state("dead")
