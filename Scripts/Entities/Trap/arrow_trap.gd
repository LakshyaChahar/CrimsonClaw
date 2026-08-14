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
	
	var spawn_parent: Node = null
	if is_inside_tree() and get_tree().current_scene:
		spawn_parent = get_tree().current_scene
	elif owner and owner.get_parent():
		spawn_parent = owner.get_parent()
	else:
		spawn_parent = get_parent()
		
	if spawn_parent:
		spawn_parent.add_child(arrow)

	arrow.global_position = $SpawnPoint.global_position
	arrow.global_rotation = $SpawnPoint.global_rotation + PI
