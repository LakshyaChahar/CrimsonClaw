extends Control

@onready var level1_button: Button = _find_button(["Level1", "Level 1", "LevelButton"])
@onready var level2_button: Button = _find_button(["Level2", "Level 2", "SettingsButton"])
@onready var back_button: Button = _find_button(["QuitButton", "BackButton", "Quit", "ExitButton"])

@onready var fade_overlay: ColorRect = find_child("FadeOverlay", true, false) as ColorRect
@onready var blood_fill: ColorRect = find_child("BloodBarFill", true, false) as ColorRect

const LEVEL_1_SCENE := "res://Scenes/Levels/Level 1/Level 1.tscn"
const LEVEL_2_SCENE := "res://Level2.tscn"

var _menu_buttons: Array[Button] = []
var _is_transitioning := false

func _find_button(candidate_names: Array[String]) -> Button:
	for cname in candidate_names:
		var btn = find_child(cname, true, false) as Button
		if btn:
			return btn
	return null

func _ready() -> void:
	_menu_buttons.clear()
	if level1_button:
		_menu_buttons.append(level1_button)
		level1_button.pressed.connect(_on_level1_pressed)
	if level2_button:
		_menu_buttons.append(level2_button)
		level2_button.pressed.connect(_on_level2_pressed)
	if back_button:
		_menu_buttons.append(back_button)
		back_button.pressed.connect(_on_back_pressed)

	for b in _menu_buttons:
		if b:
			b.mouse_entered.connect(_on_button_hover.bind(b))
			b.mouse_exited.connect(_on_button_unhover.bind(b))
			b.focus_entered.connect(_on_button_hover.bind(b))
			b.focus_exited.connect(_on_button_unhover.bind(b))
			b.button_down.connect(_on_button_down.bind(b))
			b.button_up.connect(_on_button_up.bind(b))

	if level1_button:
		level1_button.grab_focus()
	_fade_in()
	_pulse_blood_bar()

func _on_button_down(b: Button) -> void:
	if b:
		var tween := create_tween()
		tween.tween_property(b, "scale", Vector2(0.96, 0.96), 0.06)

func _on_button_up(b: Button) -> void:
	if b:
		var tween := create_tween()
		tween.tween_property(b, "scale", Vector2(1.05, 1.05), 0.08).set_trans(Tween.TRANS_BACK)

func _fade_in() -> void:
	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.color.a = 1.0
		var tween := create_tween()
		tween.tween_property(fade_overlay, "color:a", 0.0, 1.2).set_trans(Tween.TRANS_SINE)

func _pulse_blood_bar() -> void:
	if blood_fill:
		var tween := create_tween().set_loops()
		tween.tween_property(blood_fill, "modulate:a", 0.55, 0.9).set_trans(Tween.TRANS_SINE)
		tween.tween_property(blood_fill, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)

func _on_button_hover(b: Button) -> void:
	if b:
		var tween := create_tween().set_parallel(true)
		tween.tween_property(b, "scale", Vector2(1.05, 1.05), 0.12).set_trans(Tween.TRANS_BACK)

func _on_button_unhover(b: Button) -> void:
	if b:
		var tween := create_tween()
		tween.tween_property(b, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE)

func _on_level1_pressed() -> void:
	_transition_to(LEVEL_1_SCENE)

func _on_level2_pressed() -> void:
	_transition_to(LEVEL_2_SCENE)

func _on_back_pressed() -> void:
	_transition_to("res://StartScreen.tscn")

func _transition_to(scene_path: String) -> void:
	if has_node("/root/SceneTransition"):
		get_node("/root/SceneTransition").change_scene_to_file(scene_path)
	elif ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
