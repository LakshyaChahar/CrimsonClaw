# Witch linear beam attack script: creates an instant horizontal beam extending in front of the witch
extends Area2D
class_name WitchLinearBeam

@export var beam_length: float = 280.0
@export var beam_height: float = 24.0
@export var damage: float = 12.0
@export var beam_duration: float = 0.4

var facing_direction: int = 1
var timer: float = 0.0
var has_hit_player: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	timer = 0.0
	has_hit_player = false
	
	# Setup rectangular beam shape based on beam_length
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(beam_length, beam_height)
	if collision_shape:
		collision_shape.shape = rect_shape
		collision_shape.position = Vector2(facing_direction * (beam_length / 2.0), 0.0)
		
	if animated_sprite:
		animated_sprite.position = Vector2(facing_direction * (beam_length / 2.0), 0.0)
		animated_sprite.scale = Vector2((beam_length / 50.0) * facing_direction, beam_height / 50.0)
		animated_sprite.play("moving")
		
	area_entered.connect(_on_area_entered)
	
	# Instantly check for overlapping hurtboxes on spawn
	call_deferred("_check_initial_overlaps")

func _check_initial_overlaps() -> void:
	for area in get_overlapping_areas():
		_on_area_entered(area)

func _physics_process(delta: float) -> void:
	timer += delta
	if timer >= beam_duration:
		_end_beam()

func _on_area_entered(area: Area2D) -> void:
	if has_hit_player:
		return
		
	if area is Hurtbox:
		var entity = area.owner if area.owner else area.get_parent()
		if entity and entity.name.to_lower().contains("player"):
			has_hit_player = true
			area.receive_hit(damage, Vector2(facing_direction * 120.0, -20.0), 0.15, self)

func _end_beam() -> void:
	set_physics_process(false)
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("explode"):
		animated_sprite.play("explode")
		await animated_sprite.animation_finished
	queue_free()
