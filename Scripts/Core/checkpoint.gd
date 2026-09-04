class_name Checkpoint
extends Area2D

## Signal emitted when player activates this checkpoint
signal checkpoint_reached(checkpoint_pos: Vector2)

@export var is_active: bool = false
@export var active_color: Color = Color(0.85, 0.45, 1.0, 1.0)
@export var inactive_color: Color = Color(0.4, 0.25, 0.55, 0.5)

static var active_checkpoints: Array[Checkpoint] = []
static var saved_respawn_position: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $PortalSprite if has_node("PortalSprite") else ($Sprite2D if has_node("Sprite2D") else null)
@onready var particles: CPUParticles2D = $CPUParticles2D if has_node("CPUParticles2D") else null
@onready var label: Label = $Label if has_node("Label") else ($DestinationLabel if has_node("DestinationLabel") else null)
@onready var light: PointLight2D = $PointLight2D if has_node("PointLight2D") else null

func _ready() -> void:
	add_to_group("checkpoints")
	body_entered.connect(_on_body_entered)
	if saved_respawn_position != Vector2.ZERO and global_position.distance_to(saved_respawn_position) < 48.0:
		is_active = true
		if not active_checkpoints.has(self):
			active_checkpoints.append(self)
	_update_visuals()

func _on_body_entered(body: Node2D) -> void:
	if not is_active and (body.is_in_group("player") or body.name.begins_with("Player") or "player" in body.name.to_lower()):
		activate()

func activate() -> void:
	if is_active:
		return
	is_active = true
	saved_respawn_position = global_position
	if not active_checkpoints.has(self):
		active_checkpoints.append(self)
	_update_visuals()
	checkpoint_reached.emit(global_position)
	print("[Checkpoint] Activated at position: ", global_position)

func _update_visuals() -> void:
	if sprite:
		sprite.modulate = active_color if is_active else inactive_color
	if particles:
		particles.emitting = true
		particles.modulate = active_color if is_active else inactive_color
	if label:
		label.text = "CHECKPOINT ACTIVATED" if is_active else "CHECKPOINT"
		label.modulate = Color(1.0, 1.0, 1.0, 1.0) if is_active else Color(0.7, 0.5, 0.85, 0.75)
	if light:
		light.enabled = is_active

static func reset_checkpoint_memory() -> void:
	saved_respawn_position = Vector2.ZERO
	active_checkpoints.clear()

## Finds nearest reached checkpoint with priority on same or close Y level
static func get_best_respawn_position(player_pos: Vector2, fallback_pos: Vector2) -> Vector2:
	if saved_respawn_position != Vector2.ZERO:
		return saved_respawn_position

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
