extends Area2D
class_name LevelTeleporter

@export_file("*.tscn") var target_scene: String = "res://Level2.tscn"
@export var fade_duration: float = 0.5

var _triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = 0
	collision_mask = 2 # Player layer

func _on_body_entered(body: Node2D) -> void:
	if _triggered:
		return
		
	if body.is_in_group("Player") or body.name.begins_with("Player") or body is Character:
		_triggered = true
		print("[LevelTeleporter] Player touched portal. Teleporting to: ", target_scene)
		
		if has_node("/root/SceneTransition"):
			get_node("/root/SceneTransition").change_scene_to_file(target_scene, fade_duration, fade_duration)
		elif ResourceLoader.exists(target_scene):
			get_tree().change_scene_to_file(target_scene)
