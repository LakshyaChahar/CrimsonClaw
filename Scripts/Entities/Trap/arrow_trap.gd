extends Trap

@export var arrow_scene: PackedScene

func _on_enter_area_area_entered(area: Area2D) -> void:
	print("Someone entered the ArrowTrap Region")
	if area.has_method("receive_hit"):
		$"../AnimationPlayer".play("ArrowTrapAnimation")

func shoot_arrow():
	if not arrow_scene:
		push_warning("Arrow Trap has no arrow_scene assigned!")
		return

	var arrow = arrow_scene.instantiate()
	
	get_tree().current_scene.add_child(arrow)

	arrow.global_position = $SpawnPoint.global_position
	arrow.global_rotation = $SpawnPoint.global_rotation + PI
