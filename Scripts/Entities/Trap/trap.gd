class_name Trap extends Area2D

@export var damage_per_hit: int = 1

func _ready() -> void:
	body_entered.connect(self._on_body_entered)
	
func _on_body_entered(body: Node2D):
	if body.has_method("take_damage"):
		body.take_damage(damage_per_hit)
