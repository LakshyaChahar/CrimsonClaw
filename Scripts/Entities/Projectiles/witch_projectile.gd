# Witch projectile script: flies forward, deals damage to player, and explodes on contact/timeout
extends Area2D
class_name WitchProjectile

@export var speed: float = 240.0
@export var damage: float = 8.0
@export var max_lifespan: float = 4.0

var direction: Vector2 = Vector2.RIGHT
var is_exploding: bool = false
var lifespan_timer: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	lifespan_timer = max_lifespan
	
	# Configure Hitbox script if attached
	if has_method("set_damage"):
		call("set_damage", damage)
	elif "damage" in self:
		set("damage", damage)
		
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	if animated_sprite:
		animated_sprite.play("moving")

func _physics_process(delta: float) -> void:
	if is_exploding:
		return
		
	global_position += direction * speed * delta
	rotation = direction.angle()
	
	lifespan_timer -= delta
	if lifespan_timer <= 0.0:
		explode()

func _on_area_entered(area: Area2D) -> void:
	if is_exploding:
		return
		
	if area is Hurtbox:
		# Check if hurtbox belongs to player (Layer 2)
		var entity = area.owner if area.owner else area.get_parent()
		if entity and entity.name.to_lower().contains("player"):
			area.receive_hit(damage, direction * 80.0, 0.1, self)
			explode()

func _on_body_entered(body: Node2D) -> void:
	if is_exploding:
		return
		
	# Explode on contact with environment / player body
	if body is TileMap or body is TileMapLayer or body is StaticBody2D or body.name.to_lower().contains("player"):
		explode()

func explode() -> void:
	if is_exploding:
		return
	is_exploding = true
	
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
		
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("explode"):
		animated_sprite.play("explode")
		await animated_sprite.animation_finished
		
	queue_free()
