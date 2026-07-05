# Enemy controller class handling basic AI targeting
extends Character
class_name Enemy

@export_group("AI Settings")
@export var detection_range: float = 300.0
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 1.5

var target: Node2D = null
var attack_cooldown_timer: float = 0.0

func _init() -> void:
	move_speed = 100.0

func _ready() -> void:
	super._ready()
	_find_target()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta
		
	if not target:
		_find_target()

# Searches the scene tree to locate the player character
func _find_target() -> void:
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		target = players[0]
	else:
		var player_node = get_tree().root.find_child("Player", true, false)
		if player_node:
			target = player_node
