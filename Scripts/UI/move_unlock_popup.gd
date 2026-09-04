class_name MoveUnlockPopup
extends CanvasLayer

signal popup_dismissed

@onready var backdrop: ColorRect = $Backdrop
@onready var panel_container: PanelContainer = $CenterContainer/PanelContainer
@onready var header_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HeaderLabel
@onready var title_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var sprite_preview: AnimatedSprite2D = find_child("SpritePreview", true, false) as AnimatedSprite2D
@onready var input_prompt_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/InputPromptLabel
@onready var min_bloodthirst_label: Label = find_child("MinBloodthirstLabel", true, false) as Label
@onready var description_label: TypewriterLabel = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/DescriptionLabel
@onready var continue_prompt: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContinuePrompt

var _move_data: Dictionary = {}
var _can_dismiss: bool = false
var _pulse_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if continue_prompt:
		continue_prompt.modulate.a = 0.0
	if description_label:
		description_label.typing_finished.connect(_on_typing_finished)

	if not _move_data.is_empty():
		_apply_move_data()

func setup_move_info(data: Dictionary, player_sprite_frames: SpriteFrames = null) -> void:
	_move_data = data
	if player_sprite_frames:
		_move_data["sprite_frames"] = player_sprite_frames

	if is_node_ready():
		_apply_move_data()

func _apply_move_data() -> void:
	if header_label and _move_data.has("header"):
		header_label.text = _move_data["header"]
	elif header_label:
		header_label.text = "NEW MOVE UNLOCKED!"

	if title_label and _move_data.has("title"):
		title_label.text = _move_data["title"]

	if input_prompt_label and _move_data.has("input_prompt"):
		input_prompt_label.text = _move_data["input_prompt"]

	if min_bloodthirst_label:
		if _move_data.has("min_bloodthirst"):
			var val: float = float(_move_data["min_bloodthirst"])
			min_bloodthirst_label.text = "REQ. BLOODTHIRST: " + str(snappedf(val, 0.1))
			min_bloodthirst_label.visible = true
		else:
			min_bloodthirst_label.visible = false

	if sprite_preview:
		if _move_data.has("sprite_frames") and _move_data["sprite_frames"] != null:
			sprite_preview.sprite_frames = _move_data["sprite_frames"]

		var anim_name: String = _move_data.get("anim_name", "idle")
		if sprite_preview.sprite_frames and sprite_preview.sprite_frames.has_animation(anim_name):
			sprite_preview.play(anim_name)
	
	if description_label:
		var desc: String = _move_data.get("description", "")
		description_label.start_typing(desc)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_pressed() and not event.is_echo():
		# Accept any key, gamepad button, or mouse click to advance/dismiss
		if event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton:
			get_viewport().set_input_as_handled()
			_on_interacted()

func _on_interacted() -> void:
	if description_label.is_typing():
		description_label.skip_typing()
	elif _can_dismiss:
		_dismiss()

func _on_typing_finished() -> void:
	_can_dismiss = true
	_start_continue_prompt_pulse()

func _start_continue_prompt_pulse() -> void:
	if _pulse_tween and _pulse_tween.is_running():
		_pulse_tween.kill()

	continue_prompt.modulate.a = 1.0
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_pulse_tween.tween_property(continue_prompt, "modulate:a", 0.2, 0.6).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(continue_prompt, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)

func _dismiss() -> void:
	if _pulse_tween and _pulse_tween.is_running():
		_pulse_tween.kill()

	get_tree().paused = false
	popup_dismissed.emit()
	queue_free()
