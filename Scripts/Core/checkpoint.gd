class_name Checkpoint
extends Area2D

## Signal emitted when player activates this checkpoint
signal checkpoint_reached(checkpoint_pos: Vector2)

@export var is_active: bool = false
@export var active_color: Color = Color(0.2, 1.0, 0.4, 1.0)
@export var inactive_color: Color = Color(0.6, 0.6, 0.6, 0.6)

static var active_checkpoints: Array[Checkpoint] = []

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var light: PointLight2D = $PointLight2D if has_node("PointLight2D") else null

func _ready() -> void:
	add_to_group("checkpoints")
	body_entered.connect(_on_body_entered)
	_update_visuals()

func _on_body_entered(body: Node2D) -> void:
	if not is_active and (body.is_in_group("player") or body.name.begins_with("Player") or "player" in body.name.to_lower()):
		activate()

func activate() -> void:
	if is_active:
		return
	is_active = true
	if not active_checkpoints.has(self):
		active_checkpoints.append(self)
	_update_visuals()
	checkpoint_reached.emit(global_position)
	print("[Checkpoint] Activated at position: ", global_position)

func _update_visuals() -> void:
	if sprite:
		sprite.modulate = active_color if is_active else inactive_color
	if light:
		light.enabled = is_active

## Finds nearest reached checkpoint with priority on same or close Y level
static func get_best_respawn_position(player_pos: Vector2, fallback_pos: Vector2) -> Vector2:
	# Clean up freed checkpoints
	active_checkpoints = active_checkpoints.filter(func(c): return is_instance_valid(c) and c.is_active)
	
	if active_checkpoints.is_empty():
		return fallback_pos
		
	var best_checkpoint: Checkpoint = null
	var lowest_score: float = INF
	
	for cp in active_checkpoints:
		var x_diff = abs(cp.global_position.x - player_pos.x)
		var y_diff = abs(cp.global_position.y - player_pos.y)
		# Weight Y distance higher so player respawns on vertical platforms close to death height
		var score = x_diff + (y_diff * 3.0)
		
		if score < lowest_score:
			lowest_score = score
			best_checkpoint = cp
			
	if best_checkpoint:
		return best_checkpoint.global_position
		
	return fallback_pos
