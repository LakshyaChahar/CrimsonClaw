class_name Trap extends Area2D

@export var damage_per_hit: int = 1
@export var knockback: Vector2 = Vector2.ZERO

func _ready() -> void:
	area_entered.connect(self._on_area_entered)
	
func _on_area_entered(area: Area2D):
	if area.has_method("receive_hit"):
		area.receive_hit(damage_per_hit, knockback, 0.0, owner)
