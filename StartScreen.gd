extends Control

@onready var start_button: Button = $MenuButtons/StartButton
@onready var settings_button: Button = $MenuButtons/SettingsButton
@onready var quit_button: Button = $MenuButtons/QuitButton

@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var blood_fill: ColorRect = $HUDPreview/BloodBarBG/BloodBarFill
@onready var health_fill: ColorRect = $HUDPreview/HealthBarBG/HealthBarFill

const SAVE_PATH := "user://savegame.dat"
const GAME_SCENE := "res://Scenes/Levels/Level 1/Level 1.tscn"

var _menu_buttons: Array[Button] = []

func _ready() -> void:
	_menu_buttons = [start_button, settings_button, quit_button]

	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	for b in _menu_buttons:
		b.mouse_entered.connect(_on_button_hover.bind(b))
		b.mouse_exited.connect(_on_button_unhover.bind(b))
		b.focus_entered.connect(_on_button_hover.bind(b))
		b.focus_exited.connect(_on_button_unhover.bind(b))
		b.button_down.connect(_on_button_down.bind(b))
		b.button_up.connect(_on_button_up.bind(b))

func _on_button_down(b: Button) -> void:
	var tween := create_tween()
	tween.tween_property(b, "scale", Vector2(0.96, 0.96), 0.06)

func _on_button_up(b: Button) -> void:
	var tween := create_tween()
	tween.tween_property(b, "scale", Vector2(1.05, 1.05), 0.08).set_trans(Tween.TRANS_BACK)

	start_button.grab_focus()
	_fade_in()
	_pulse_blood_bar()

func _fade_in() -> void:
	fade_overlay.color.a = 1.0
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, 1.2).set_trans(Tween.TRANS_SINE)

func _pulse_blood_bar() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(blood_fill, "modulate:a", 0.55, 0.9).set_trans(Tween.TRANS_SINE)
	tween.tween_property(blood_fill, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)

func _on_button_hover(b: Button) -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(b, "scale", Vector2(1.05, 1.05), 0.12).set_trans(Tween.TRANS_BACK)

func _on_button_unhover(b: Button) -> void:
	var tween := create_tween()
	tween.tween_property(b, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE)

func _on_start_pressed() -> void:
	_transition_to(GAME_SCENE)

func _on_settings_pressed() -> void:
	pass

func _on_quit_pressed() -> void:
	get_tree().quit()
var _is_transitioning := false

func _transition_to(scene_path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	for b in _menu_buttons:
		b.disabled = true
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	tween.finished.connect(func():
		if ResourceLoader.exists(scene_path):
			get_tree().change_scene_to_file(scene_path)
		else:
			push_warning("Scene not found: %s — update GAME_SCENE in StartScreen.gd" % scene_path)
			for b in _menu_buttons:
				b.disabled = false
			fade_overlay.color.a = 0.0
	)
