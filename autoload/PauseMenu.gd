extends CanvasLayer
## Autoload this scene as "PauseMenu" (Project Settings > Autoload).
## Works on top of any level scene without being instanced per-level.
##
## A level only becomes pausable once its root is added to the
## "pausable" group — this stops ESC from doing anything on the start
## screen or during a cutscene where pausing shouldn't be possible.
## In the editor: select your level's root node > Node dock > Groups >
## add "pausable". Or in code: add_to_group("pausable") in the level's _ready().

const MAIN_MENU_SCENE := "res://StartScreen.tscn"

@onready var dim_overlay: ColorRect = $DimOverlay
@onready var panel: PanelContainer = $Panel
@onready var resume_button: Button = $Panel/VBox/ResumeButton
@onready var settings_button: Button = $Panel/VBox/SettingsButton
@onready var quit_to_menu_button: Button = $Panel/VBox/QuitToMenuButton
@onready var quit_desktop_button: Button = $Panel/VBox/QuitDesktopButton

var _is_open := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	dim_overlay.color.a = 0.0
	dim_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	_ensure_controller_input_mappings()

	resume_button.pressed.connect(close)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_to_menu_button.pressed.connect(_on_quit_to_menu)
	quit_desktop_button.pressed.connect(_on_quit_desktop)

func _ensure_controller_input_mappings() -> void:
	# Ensure Controller A button (JOY_BUTTON_A = 0) is bound to ui_accept for menu selection
	if InputMap.has_action("ui_accept"):
		var has_a := false
		for ev in InputMap.action_get_events("ui_accept"):
			if ev is InputEventJoypadButton and ev.button_index == JOY_BUTTON_A:
				has_a = true
				break
		if not has_a:
			var joy_a := InputEventJoypadButton.new()
			joy_a.button_index = JOY_BUTTON_A
			InputMap.action_add_event("ui_accept", joy_a)

	# Ensure Controller Start (JOY_BUTTON_START = 6) and Back (JOY_BUTTON_BACK = 4) trigger pause/ui_cancel.
	# Remove JOY_BUTTON_B from ui_cancel so B button is reserved exclusively for Dash!
	if InputMap.has_action("ui_cancel"):
		for ev in InputMap.action_get_events("ui_cancel"):
			if ev is InputEventJoypadButton and ev.button_index == JOY_BUTTON_B:
				InputMap.action_erase_event("ui_cancel", ev)

		var buttons_to_add := [JOY_BUTTON_START, JOY_BUTTON_BACK]
		var existing_buttons: Array = []
		for ev in InputMap.action_get_events("ui_cancel"):
			if ev is InputEventJoypadButton:
				existing_buttons.append(ev.button_index)
		for btn in buttons_to_add:
			if not existing_buttons.has(btn):
				var joy_btn := InputEventJoypadButton.new()
				joy_btn.button_index = btn
				InputMap.action_add_event("ui_cancel", joy_btn)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	if _is_open:
		close()
		get_viewport().set_input_as_handled()
		return

	var scene := get_tree().current_scene
	if _is_scene_pausable(scene):
		open()
		get_viewport().set_input_as_handled()

func _is_scene_pausable(scene: Node) -> bool:
	if not scene:
		return false
	if scene.is_in_group("pausable"):
		return true
	var scene_path := scene.scene_file_path.to_lower()
	var scene_name := scene.name.to_lower()
	if "startscreen" in scene_name or "startscreen" in scene_path or "levels" in scene_name or "levels" in scene_path:
		return false
	if "level" in scene_name or "level" in scene_path or "demo" in scene_name or "demo" in scene_path or "combat" in scene_path:
		return true
	return false

func open() -> void:
	if _is_open:
		return
	_is_open = true
	visible = true
	get_tree().paused = true
	resume_button.grab_focus()

	panel.modulate.a = 0.0
	panel.scale = Vector2(0.94, 0.94)

	var dim_tween := create_tween()
	dim_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	dim_tween.tween_property(dim_overlay, "color:a", 0.55, 0.18)

	var panel_tween := create_tween().set_parallel(true)
	panel_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	panel_tween.tween_property(panel, "modulate:a", 1.0, 0.18)
	panel_tween.tween_property(panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)

func close() -> void:
	if not _is_open:
		return
	_is_open = false

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(dim_overlay, "color:a", 0.0, 0.15)
	tween.finished.connect(func():
		visible = false
		get_tree().paused = false
	)

func _on_settings_pressed() -> void:
	# TODO: open the same settings panel/scene the start screen uses.
	pass

func _on_quit_to_menu() -> void:
	get_tree().paused = false
	visible = false
	_is_open = false
	if has_node("/root/SceneTransition"):
		var st = get_node("/root/SceneTransition")
		st.force_reset()
		st.change_scene_to_file(MAIN_MENU_SCENE)
	else:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _on_quit_desktop() -> void:
	get_tree().quit()
