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

	resume_button.pressed.connect(close)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_to_menu_button.pressed.connect(_on_quit_to_menu)
	quit_desktop_button.pressed.connect(_on_quit_desktop)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	if _is_open:
		close()
		get_viewport().set_input_as_handled()
		return

	var scene := get_tree().current_scene
	if scene and scene.is_in_group("pausable"):
		open()
		get_viewport().set_input_as_handled()

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
		get_node("/root/SceneTransition").change_scene_to_file(MAIN_MENU_SCENE)
	else:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _on_quit_desktop() -> void:
	get_tree().quit()
