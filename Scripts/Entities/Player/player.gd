extends Character
class_name Player

@export_group("Input Action Names")
@export var action_left: String = "move_left"
@export var action_right: String = "move_right"
@export var action_jump: String = "jump"
@export var action_dash: String = "dash"
@export var action_skill: String = "attack"

# Fallback actions if the custom input map is not defined
var final_left: String
var final_right: String
var final_jump: String
var final_dash: String
var final_skill: String

# Buffer timers to make the controls feel smooth
var jump_buffer_timer: float = 0.0
@export var jump_buffer_time: float = 0.1

@export_group("Bloodthirst System")
@export var max_bloodthirst: float = 100.0
@export var current_bloodthirst: float = 0.0
signal bloodthirst_changed(old_value: float, new_value: float)

@onready var health_bar: ProgressBar = $HUD/VBoxContainer/HealthBar
@onready var bloodthirst_bar: ProgressBar = $HUD/VBoxContainer/BloodthirstBar

func _ready() -> void:
	super._ready()
	add_to_group("Player")
	_init_input_actions()
	
	# Connect to all child hitboxes recursively to increase bloodthirst on successful hits
	var hitboxes = find_children("*", "Hitbox", true, false)
	for hitbox in hitboxes:
		if hitbox is Hitbox:
			hitbox.hit_registered.connect(_on_attack_hit)

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

func _on_attack_hit(_hurtbox: Hurtbox) -> void:
	# Gain 10 bloodthirst per hit (adjust as needed or read custom stats from hitbox)
	add_bloodthirst(10.0)

func _process(delta: float) -> void:
	# Tick buffers
	jump_buffer_timer = max(0.0, jump_buffer_timer - delta)
	
	# Read horizontal movement
	input_direction.x = Input.get_axis(final_left, final_right)
	input_direction.y = Input.get_axis("ui_up", "ui_down") # for aiming dash/skills
	
	# Handle jump input with buffering
	if Input.is_action_just_pressed(final_jump):
		jump_buffer_timer = jump_buffer_time
		
	wants_jump = jump_buffer_timer > 0.0
	
	# Clear wants_jump if the state machine transitions to jump (handled inside states)
	
	# Handle dash input
	if Input.is_action_just_pressed(final_dash):
		wants_dash = true
		
	# Handle skill input
	if Input.is_action_just_pressed(final_skill):
		wants_skill = true

func _init_input_actions() -> void:
	final_left = action_left if InputMap.has_action(action_left) else "ui_left"
	final_right = action_right if InputMap.has_action(action_right) else "ui_right"
	final_jump = action_jump if InputMap.has_action(action_jump) else "ui_accept"
	final_dash = action_dash if InputMap.has_action(action_dash) else "ui_select"
	final_skill = action_skill if InputMap.has_action(action_skill) else "ui_focus_next"

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
