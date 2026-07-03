extends Trap

func _on_enter_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		$"../AnimationPlayer".play("ArrowTrapAnimation")
