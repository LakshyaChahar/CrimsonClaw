extends CanvasLayer

var color_rect: ColorRect = null
var is_transitioning: bool = false

func _ready() -> void:
	layer = 128
	
	# Create overlay ColorRect for ultra smooth cinematic scene transitions
	color_rect = ColorRect.new()
	color_rect.anchors_preset = Control.PRESET_FULL_RECT
	color_rect.color = Color(0.04, 0.02, 0.03, 0.0)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.visible = false
	add_child(color_rect)

## Smoothly fades out current scene to black, changes scene, and smoothly fades in new scene
func change_scene_to_file(target_scene_path: String, fade_out_time: float = 0.45, fade_in_time: float = 0.45) -> void:
	if is_transitioning:
		return
		
	if not ResourceLoader.exists(target_scene_path):
		push_warning("[SceneTransition] Target scene path does not exist: %s" % target_scene_path)
		return

	is_transitioning = true
	color_rect.visible = true
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP # Block UI clicks during transition

	# Smooth Fade Out
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(color_rect, "color:a", 1.0, fade_out_time)
	await tween.finished

	# Allow engine to process frame while screen is dark
	await get_tree().process_frame
	await get_tree().process_frame

	# Change scene
	var err = get_tree().change_scene_to_file(target_scene_path)
	if err != OK:
		push_error("[SceneTransition] Failed to change scene to %s (Error %d)" % [target_scene_path, err])
		color_rect.visible = false
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		is_transitioning = false
		return

	# Wait for new scene initialization
	await get_tree().process_frame
	await get_tree().process_frame

	# Smooth Fade In
	var fade_in_tween = create_tween()
	fade_in_tween.set_trans(Tween.TRANS_CUBIC)
	fade_in_tween.set_ease(Tween.EASE_IN_OUT)
	fade_in_tween.tween_property(color_rect, "color:a", 0.0, fade_in_time)
	await fade_in_tween.finished

	color_rect.visible = false
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false
