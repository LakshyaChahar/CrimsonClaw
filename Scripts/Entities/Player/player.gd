extends Character
class_name Player

@export_group("Input Action Names")
@export var action_left: String = "move_left"
@export var action_right: String = "move_right"
@export var action_jump: String = "jump"
@export var action_dash: String = "dash"
@export var action_skill: String = "attack"
@export var action_ignis_claw: String = "ignis_claw"

# Fallback actions if the custom input map is not defined
var final_left: String
var final_right: String
var final_jump: String
var final_dash: String
var final_skill: String
var final_ignis_claw: String
var wants_ignis_claw: bool = false

# Buffer timers to make the controls feel smooth
var jump_buffer_timer: float = 0.0
@export var jump_buffer_time: float = 0.1

@export_group("Bloodthirst System")
@export var max_bloodthirst: float = 100.0
@export var current_bloodthirst: float = 0.0
signal bloodthirst_changed(old_value: float, new_value: float)

@export_group("Basic Melee Attack")
## Damage dealt by basic sword swing.
@export var melee_damage: float = 10.0
## Knockback force pushing targets back.
@export var melee_knockback_force: float = 150.0
## Duration of stun applied on basic hit.
@export var melee_stun_duration: float = 0.2
## Duration of the basic attack swing.
@export var melee_attack_duration: float = 0.4
## Minimum required bloodthirst to perform basic attack.
@export var melee_min_required_bloodthirst: float = 0.0
## Bloodthirst gained on hit with basic attack.
@export var melee_bloodthirst_gain: float = 10.0

@export_group("Ignis Claw Skill")
## Initial hit damage dealt when Ignis Claw strikes.
@export var ignis_damage: float = 25.0
## Knockback force pushing targets on strike.
@export var ignis_knockback_force: float = 400.0
## Duration of fire burn effect in seconds.
@export var ignis_fire_duration: float = 3.0
## Damage per second inflicted while target is on fire.
@export var ignis_fire_dps: float = 8.0
## Duration of stun applied on hit.
@export var ignis_stun_duration: float = 0.3
## Duration of the Ignis Claw attack state.
@export var ignis_attack_duration: float = 0.45
## Minimum required bloodthirst to perform Ignis Claw.
@export var ignis_min_required_bloodthirst: float = 20.0
## Bloodthirst gained on hit with Ignis Claw skill.
@export var ignis_bloodthirst_gain: float = 15.0

@onready var health_bar: ProgressBar = $HUD/VBoxContainer/HealthBar
@onready var bloodthirst_bar: ProgressBar = $HUD/VBoxContainer/BloodthirstBar

func _ready() -> void:
	super._ready()
	add_to_group("Player")
	_init_input_actions()
	_sync_attack_properties()
	
	# Connect to all child hitboxes recursively to increase bloodthirst on successful hits
	var hitboxes = find_children("*", "Hitbox", true, false)
	for hitbox in hitboxes:
		if hitbox is Hitbox:
			hitbox.hit_registered.connect(_on_attack_hit.bind(hitbox))

	# Initialize HUD ProgressBars
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	if bloodthirst_bar:
		bloodthirst_bar.max_value = max_bloodthirst
		bloodthirst_bar.value = current_bloodthirst

	# Connect change signals
	health_changed.connect(_on_health_changed)
	bloodthirst_changed.connect(_on_bloodthirst_changed)

	setup_camera_limits()

func _on_health_changed(_old_value: float, new_value: float) -> void:
	if health_bar:
		health_bar.value = new_value

func _on_bloodthirst_changed(_old_value: float, new_value: float) -> void:
	if bloodthirst_bar:
		bloodthirst_bar.value = new_value

## Safely increases bloodthirst, capped at max_bloodthirst
func add_bloodthirst(amount: float) -> void:
	var old_value = current_bloodthirst
	current_bloodthirst = clamp(current_bloodthirst + amount, 0.0, max_bloodthirst)
	if old_value != current_bloodthirst:
		bloodthirst_changed.emit(old_value, current_bloodthirst)

## Consumes bloodthirst if enough is available. Returns true if successful.
func consume_bloodthirst(amount: float) -> bool:
	if current_bloodthirst >= amount:
		var old_value = current_bloodthirst
		current_bloodthirst -= amount
		bloodthirst_changed.emit(old_value, current_bloodthirst)
		return true
	return false

func _on_attack_hit(_hurtbox: Hurtbox, hitbox: Hitbox = null) -> void:
	var gain = hitbox.bloodthirst_gain if hitbox else 10.0
	add_bloodthirst(gain)

var dash_buffer_timer: float = 0.0
@export var dash_buffer_time: float = 0.15

var skill_buffer_timer: float = 0.0
@export var skill_buffer_time: float = 0.15

var ignis_claw_buffer_timer: float = 0.0
@export var ignis_claw_buffer_time: float = 0.15

func _process(delta: float) -> void:
	if is_dead:
		return
		
	# Tick input buffers
	jump_buffer_timer = max(0.0, jump_buffer_timer - delta)
	dash_buffer_timer = max(0.0, dash_buffer_timer - delta)
	skill_buffer_timer = max(0.0, skill_buffer_timer - delta)
	ignis_claw_buffer_timer = max(0.0, ignis_claw_buffer_timer - delta)
	
	# Read movement inputs
	input_direction.x = Input.get_axis(final_left, final_right)
	input_direction.y = Input.get_axis("look_up", "look_down")
	
	# Update action flags with buffered inputs
	if Input.is_action_just_pressed(final_jump):
		jump_buffer_timer = jump_buffer_time
	wants_jump = jump_buffer_timer > 0.0
	
	if Input.is_action_just_pressed(final_dash):
		dash_buffer_timer = dash_buffer_time
	wants_dash = dash_buffer_timer > 0.0
		
	if Input.is_action_just_pressed(final_skill):
		skill_buffer_timer = skill_buffer_time
	wants_skill = skill_buffer_timer > 0.0
	
	if Input.is_action_just_pressed(final_ignis_claw):
		ignis_claw_buffer_timer = ignis_claw_buffer_time
	wants_ignis_claw = ignis_claw_buffer_timer > 0.0

func _init_input_actions() -> void:
	final_left = action_left if InputMap.has_action(action_left) else "ui_left"
	final_right = action_right if InputMap.has_action(action_right) else "ui_right"
	final_jump = action_jump if InputMap.has_action(action_jump) else "ui_accept"
	final_dash = action_dash if InputMap.has_action(action_dash) else "ui_select"
	final_skill = action_skill if InputMap.has_action(action_skill) else "ui_focus_next"
	final_ignis_claw = action_ignis_claw if InputMap.has_action(action_ignis_claw) else "ignis_claw"

## Automatically detects a child Camera2D and sets its boundaries to the TileMap/TileMapLayer limits.
func setup_camera_limits() -> void:
	var camera = find_child("Camera2D", true, false) as Camera2D
	if not camera:
		return
	
	# First check for any node in the "TileMap" group
	var tilemap = get_tree().get_first_node_in_group("TileMap")
	
	# If not found, look for any TileMap or TileMapLayer node in the active scene tree
	if not tilemap:
		var root_scene = get_tree().current_scene
		if root_scene:
			tilemap = root_scene.find_child("*TileMap*", true, false)
			if not tilemap:
				tilemap = root_scene.find_child("*TileMapLayer*", true, false)
				
	if tilemap:
		var rect: Rect2i
		# Check if get_used_rect method exists (both TileMap and TileMapLayer have it)
		if tilemap.has_method("get_used_rect"):
			rect = tilemap.get_used_rect()
		
		# If the node has a tile_set, calculate limits in pixels
		if rect != Rect2i() and "tile_set" in tilemap and tilemap.tile_set:
			var cell_size = tilemap.tile_set.tile_size
			camera.limit_left = rect.position.x * cell_size.x
			camera.limit_top = rect.position.y * cell_size.y
			camera.limit_right = rect.end.x * cell_size.x
			camera.limit_bottom = rect.end.y * cell_size.y

## Synchronizes root Player exported parameters to states and hitboxes
func _sync_attack_properties() -> void:
	var melee_state = find_child("Skill", true, false) as MeleeAttackState
	if melee_state:
		melee_state.damage = melee_damage
		melee_state.knockback_force = melee_knockback_force
		melee_state.stun_duration = melee_stun_duration
		melee_state.attack_duration = melee_attack_duration
		melee_state.min_required_bloodthirst = melee_min_required_bloodthirst
		
	var ignis_state = find_child("IgnisClaw", true, false) as IgnisClawState
	if ignis_state:
		ignis_state.initial_damage = ignis_damage
		ignis_state.knockback_force = ignis_knockback_force
		ignis_state.fire_duration = ignis_fire_duration
		ignis_state.fire_dps = ignis_fire_dps
		ignis_state.stun_duration = ignis_stun_duration
		ignis_state.attack_duration = ignis_attack_duration
		ignis_state.min_required_bloodthirst = ignis_min_required_bloodthirst
		
	var sword_hitbox = find_child("SwordHitbox", true, false) as Hitbox
	if sword_hitbox:
		sword_hitbox.damage = melee_damage
		sword_hitbox.knockback_force = melee_knockback_force
		sword_hitbox.stun_duration = melee_stun_duration
		sword_hitbox.bloodthirst_gain = melee_bloodthirst_gain
		
	var ignis_hitbox = find_child("IgnisClawHitbox", true, false) as Hitbox
	if ignis_hitbox:
		ignis_hitbox.damage = ignis_damage
		ignis_hitbox.knockback_force = ignis_knockback_force
		ignis_hitbox.stun_duration = ignis_stun_duration
		ignis_hitbox.fire_dps = ignis_fire_dps
		ignis_hitbox.fire_duration = ignis_fire_duration
		ignis_hitbox.bloodthirst_gain = ignis_bloodthirst_gain

	var dash_state = find_child("Dash", true, false) as DashState
	if dash_state:
		dash_state.dash_speed = dash_speed
		dash_state.dash_duration = dash_duration
		dash_state.dash_cooldown = dash_cooldown
		dash_state.post_dash_iframe_duration = post_dash_iframe_duration
		dash_state.min_required_bloodthirst = dash_min_required_bloodthirst
