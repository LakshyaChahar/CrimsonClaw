# Enemy controller class handling basic AI targeting
extends Character
class_name Enemy

@export_group("Combat Stats")
@export var contact_damage: float = 10.0

@export_group("AI Settings")
@export var detection_range: float = 300.0
@export var attack_range: float = 40.0
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

func _init() -> void:
	move_speed = 100.0
	max_health = 30.0
	current_health = 30.0
	health_regen_rate = 0.0

func _ready() -> void:
	super._ready()
	_original_collision_layer = collision_layer
	_find_target()
	
	# Automatically apply the exported contact damage to the Hitbox component
	var hitbox = find_child("Hitbox") as Hitbox
	if hitbox:
		hitbox.damage = contact_damage
	
	if is_stealth:
		is_revealed = false
		set_stealth_mode(true)

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
