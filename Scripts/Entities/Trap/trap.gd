# Base trap class that inherits from Hitbox
extends Hitbox
class_name Trap

@export var damage_per_hit: float = 10.0
@export var knockback: Vector2 = Vector2.ZERO

func _ready() -> void:
	if damage_per_hit != 10.0:
		damage = damage_per_hit
	else:
		damage_per_hit = damage
		
	super._ready()
