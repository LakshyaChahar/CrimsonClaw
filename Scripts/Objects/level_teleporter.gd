@tool
extends Area2D
class_name LevelTeleporter

## Target scene file path to transition to upon contact.
@export_file("*.tscn") var target_scene: String = "res://Scenes/Levels/Level 1/Level 1.tscn":
	set(val):
		target_scene = val
		_update_label()

## Friendly destination name displayed above portal (e.g. "Level 1", "Level 2", "Boss Arena").
@export var destination_display_name: String = "Level 1":
	set(val):
		destination_display_name = val
		_update_label()

## Custom prefix/prompt format for floating label (e.g. "TO: %s" or "PORTAL TO: %s").
@export var label_prefix: String = "TO: %s":
	set(val):
		label_prefix = val
		_update_label()

## Duration of cross-fade scene transition in seconds.
@export var fade_duration: float = 0.5

var _triggered: bool = false

func _ready() -> void:
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)
		collision_layer = 0
		collision_mask = 2 # Player layer
	_update_label()

func _update_label() -> void:
	var label = get_node_or_null("DestinationLabel") as Label
	if not label:
		return

	var display_name: String = destination_display_name
	if display_name.strip_edges().is_empty():
		if not target_scene.is_empty():
			display_name = target_scene.get_file().get_basename().capitalize()
		else:
			display_name = "Unknown Zone"

	if "%s" in label_prefix:
		label.text = label_prefix % display_name
	else:
		label.text = label_prefix + " " + display_name

func _on_body_entered(body: Node2D) -> void:
	if _triggered or Engine.is_editor_hint():
		return
		
	if body.is_in_group("Player") or body.name.begins_with("Player") or body is Character:
		_triggered = true
		print("[LevelTeleporter] Player touched portal. Teleporting to: ", target_scene)
		
		var scene_file: String = get_tree().current_scene.scene_file_path.get_file().to_lower() if get_tree().current_scene else ""
		var scene_name: String = get_tree().current_scene.name.to_lower() if get_tree().current_scene else ""
		var is_level0: bool = ("combat" in scene_file or "demo" in scene_file or 
							   "combat" in scene_name or "demo" in scene_name or 
							   "level0" in scene_file or "level 0" in scene_file or
							   "level_0" in scene_file)
							
		if is_level0 and body.has_method("show_remaining_level0_tutorials"):
			body.show_remaining_level0_tutorials(func(): _proceed_teleport())
		else:
			_proceed_teleport()

func _proceed_teleport() -> void:
	if has_node("/root/SceneTransition"):
		get_node("/root/SceneTransition").change_scene_to_file(target_scene, fade_duration, fade_duration)
	elif ResourceLoader.exists(target_scene):
		get_tree().change_scene_to_file(target_scene)
