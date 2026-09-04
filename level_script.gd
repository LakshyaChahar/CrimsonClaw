extends Control

@onready var level0_button: Button = _find_button(["Level0", "Level 0", "CombatDemoButton", "DemoButton"])
@onready var level1_button: Button = _find_button(["Level1", "Level 1", "LevelButton"])
@onready var level2_button: Button = _find_button(["Level2", "Level 2", "SettingsButton"])
@onready var level3_button: Button = _find_button(["Level3", "Level 3"])
@onready var back_button: Button = _find_button(["QuitButton", "BackButton", "Quit", "ExitButton"])

@onready var fade_overlay: ColorRect = find_child("FadeOverlay", true, false) as ColorRect
@onready var blood_fill: ColorRect = find_child("BloodBarFill", true, false) as ColorRect

const LEVEL_0_SCENE := "res://Scenes/Levels/combat_demo_level.tscn"
const LEVEL_1_SCENE := "res://Scenes/Levels/Level 1/Level 1.tscn"
const LEVEL_2_SCENE := "res://Level2.tscn"
const LEVEL_3_SCENE := "res://level3.tscn"

var _menu_buttons: Array[Button] = []
var _is_transitioning := false

func _find_button(candidate_names: Array[String]) -> Button:
	for cname in candidate_names:
		var btn = find_child(cname, true, false) as Button
		if btn:
			return btn
	return null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	_is_transitioning = false

	if has_node("/root/SceneTransition"):
		get_node("/root/SceneTransition").force_reset()

	_menu_buttons.clear()
	if level0_button:
		_menu_buttons.append(level0_button)
		level0_button.pressed.connect(_on_level0_pressed)
	if level1_button:
		_menu_buttons.append(level1_button)
		level1_button.pressed.connect(_on_level1_pressed)
	if level2_button:
		_menu_buttons.append(level2_button)
		level2_button.pressed.connect(_on_level2_pressed)
	if level3_button:
		_menu_buttons.append(level3_button)
		level3_button.pressed.connect(_on_level3_pressed)
	if back_button:
		_menu_buttons.append(back_button)
		back_button.pressed.connect(_on_back_pressed)

	for b in _menu_buttons:
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
	if level0_button and level0_button.is_inside_tree():
		level0_button.grab_focus()
	elif level1_button and level1_button.is_inside_tree():
		level1_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _is_transitioning:
		get_viewport().set_input_as_handled()
		_on_back_pressed()

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

func _fade_in() -> void:
	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.color.a = 1.0
		var tween := create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(fade_overlay, "color:a", 0.0, 1.2).set_trans(Tween.TRANS_SINE)

func _pulse_blood_bar() -> void:
	if blood_fill and blood_fill.is_inside_tree() and is_inside_tree():
		var tween := create_tween().set_loops()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(blood_fill, "modulate:a", 0.55, 0.9).set_trans(Tween.TRANS_SINE)
		tween.tween_property(blood_fill, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)

func _on_button_hover(b: Button) -> void:
	_animate_button(b, Vector2(1.05, 1.05), 0.12, Tween.TRANS_BACK)

func _on_button_unhover(b: Button) -> void:
	_animate_button(b, Vector2.ONE, 0.12, Tween.TRANS_SINE)

func _on_level0_pressed() -> void:
	_transition_to(LEVEL_0_SCENE)

func _on_level1_pressed() -> void:
	_transition_to(LEVEL_1_SCENE)

func _on_level2_pressed() -> void:
	_transition_to(LEVEL_2_SCENE)

func _on_level3_pressed() -> void:
	_transition_to(LEVEL_3_SCENE)

func _on_back_pressed() -> void:
	_transition_to("res://StartScreen.tscn")

func _transition_to(scene_path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	print("[level_script] Transitioning to scene: ", scene_path)
	if has_node("/root/SceneTransition"):
		get_node("/root/SceneTransition").change_scene_to_file(scene_path)
	elif ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		_is_transitioning = false
		push_error("[level_script] Scene path not found: " + scene_path)
