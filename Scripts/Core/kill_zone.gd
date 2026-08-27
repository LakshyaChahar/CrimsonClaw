@tool
extends Area2D
class_name KillZone

@export_group("Kill Zone Settings")
## If enabled, the killzone acts as an infinite horizontal boundary line across the entire world level.
@export var is_infinite: bool = true:
	set(value):
		is_infinite = value
		_update_collision_shape()

## Width of the killzone rectangle when is_infinite is false.
@export var zone_length: float = 2000.0:
	set(value):
		zone_length = max(1.0, value)
		_update_collision_shape()

## Thickness/height of the killzone collision box.
@export var zone_height: float = 100.0:
	set(value):
		zone_height = max(1.0, value)
		_update_collision_shape()

## Amount of damage inflicted when an entity touches the killzone (default 9999 for instant kill).
@export var fatal_damage: float = 9999.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	_update_collision_shape()
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		if scale != Vector2.ONE:
			if not is_infinite:
				zone_length = max(1.0, zone_length * abs(scale.x))
				zone_height = max(1.0, zone_height * abs(scale.y))
			scale = Vector2.ONE

func _update_collision_shape() -> void:
	if not is_node_ready():
		await ready

	if not collision_shape:
		collision_shape = get_node_or_null("CollisionShape2D")
		if not collision_shape:
			return

	if is_infinite:
		# Use WorldBoundaryShape2D for infinite boundary line
		if not (collision_shape.shape is WorldBoundaryShape2D):
			collision_shape.shape = WorldBoundaryShape2D.new()
	else:
		# Use RectangleShape2D with custom length & height
		var rect_shape: RectangleShape2D
		if collision_shape.shape is RectangleShape2D:
			rect_shape = collision_shape.shape as RectangleShape2D
		else:
			rect_shape = RectangleShape2D.new()
			collision_shape.shape = rect_shape
		
		# Ensure unique shape instance so resizing one KillZone does not affect others
		if not rect_shape.resource_local_to_scene:
			rect_shape = rect_shape.duplicate()
			collision_shape.shape = rect_shape
		
		rect_shape.size = Vector2(zone_length, zone_height)

func _on_body_entered(body: Node2D) -> void:
	if Engine.is_editor_hint():
		return
		
	if body is Character or body.has_method("take_damage") or body.has_method("die"):
		print("[KillZone] Entity entered killzone: ", body.name)
		if body.has_method("take_damage"):
			body.take_damage(fatal_damage)
		elif body.has_method("die"):
			body.die()
