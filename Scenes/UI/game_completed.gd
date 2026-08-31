extends Control

@onready var replay_button: Button = find_child("ReplayButton", true, false) as Button
@onready var levels_button: Button = find_child("LevelsButton", true, false) as Button
@onready var menu_button: Button = find_child("MenuButton", true, false) as Button
@onready var quit_button: Button = find_child("QuitButton", true, false) as Button

@onready var fade_overlay: ColorRect = find_child("FadeOverlay", true, false) as ColorRect
@onready var blood_fill: ColorRect = find_child("BloodBarFill", true, false) as ColorRect

const LEVEL_1_SCENE := "res://Scenes/Levels/Level 1/Level 1.tscn"
const LEVEL_SELECT_SCENE := "res://levels.tscn"
const MAIN_MENU_SCENE := "res://StartScreen.tscn"

var _buttons: Array[Button] = []
var _is_transitioning := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	_is_transitioning = false

	if has_node("/root/SceneTransition"):
		get_node("/root/SceneTransition").force_reset()

	_buttons.clear()
	if replay_button:
		_buttons.append(replay_button)
		replay_button.pressed.connect(_on_replay_pressed)
	if levels_button:
		_buttons.append(levels_button)
		levels_button.pressed.connect(_on_levels_pressed)
	if menu_button:
		_buttons.append(menu_button)
		menu_button.pressed.connect(_on_menu_pressed)
	if quit_button:
		_buttons.append(quit_button)
		quit_button.pressed.connect(_on_quit_pressed)

	for b in _buttons:
		if b:
			b.pivot_offset = b.size / 2.0
			b.mouse_entered.connect(_on_button_hover.bind(b))
			b.mouse_exited.connect(_on_button_unhover.bind(b))
			b.focus_entered.connect(_on_button_hover.bind(b))
			b.focus_exited.connect(_on_button_unhover.bind(b))
			b.button_down.connect(_on_button_down.bind(b))
			b.button_up.connect(_on_button_up.bind(b))

	call_deferred("_setup_initial_focus")
	_fade_in()
	_pulse_blood_bar()

func _setup_initial_focus() -> void:
	if replay_button and replay_button.is_inside_tree():
		replay_button.grab_focus()

func _animate_button(b: Button, target_scale: Vector2, duration: float, trans_type: Tween.TransitionType = Tween.TRANS_SINE) -> void:
	if not (b and b.is_inside_tree() and is_inside_tree()):
		return
	if b.pivot_offset == Vector2.ZERO and b.size != Vector2.ZERO:
		b.pivot_offset = b.size / 2.0

	if b.has_meta("active_tween"):
		var old_tween = b.get_meta("active_tween") as Tween
		if old_tween and old_tween.is_valid():
			old_tween.kill()

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(b, "scale", target_scale, duration).set_trans(trans_type)
	b.set_meta("active_tween", tween)

func _on_button_down(b: Button) -> void:
	_animate_button(b, Vector2(0.96, 0.96), 0.06)

func _on_button_up(b: Button) -> void:
	_animate_button(b, Vector2(1.05, 1.05), 0.08, Tween.TRANS_BACK)

func _on_button_hover(b: Button) -> void:
	_animate_button(b, Vector2(1.05, 1.05), 0.12, Tween.TRANS_BACK)

func _on_button_unhover(b: Button) -> void:
	_animate_button(b, Vector2.ONE, 0.12, Tween.TRANS_SINE)

func _fade_in() -> void:
	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.color.a = 1.0
		var tween := create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(fade_overlay, "color:a", 0.0, 1.2).set_trans(Tween.TRANS_SINE)

func _pulse_blood_bar() -> void:
	if blood_fill:
		var tween := create_tween().set_loops()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(blood_fill, "modulate:a", 0.4, 1.0).set_trans(Tween.TRANS_SINE)
		tween.tween_property(blood_fill, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)

func _on_replay_pressed() -> void:
	_transition_to(LEVEL_1_SCENE)

func _on_levels_pressed() -> void:
	_transition_to(LEVEL_SELECT_SCENE)

func _on_menu_pressed() -> void:
	_transition_to(MAIN_MENU_SCENE)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _transition_to(scene_path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	if has_node("/root/SceneTransition"):
		get_node("/root/SceneTransition").change_scene_to_file(scene_path)
	elif ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		_is_transitioning = false

