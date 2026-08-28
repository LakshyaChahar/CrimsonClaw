extends Button
## Drop-in "feel" for menu buttons: hover lift, press punch, optional SFX.
## Assign this script directly on any Button node (Start, Resume, Quit, etc.)
## instead of wiring hover/press tweens by hand in each screen's controller.
## Works fine under get_tree().paused = true as long as this node's
## process_mode (or an ancestor's) is set to Always.

@export var hover_scale := Vector2(1.05, 1.05)
@export var press_scale := Vector2(0.96, 0.96)
@export var hover_sfx: AudioStream
@export var confirm_sfx: AudioStream

var _sfx_player: AudioStreamPlayer

func _ready() -> void:
	pivot_offset = size / 2.0
	resized.connect(func(): pivot_offset = size / 2.0)

	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)
	focus_entered.connect(_on_hover)
	focus_exited.connect(_on_unhover)
	button_down.connect(_on_press)
	button_up.connect(_on_release)
	pressed.connect(_on_confirm)

	if hover_sfx or confirm_sfx:
		_sfx_player = AudioStreamPlayer.new()
		_sfx_player.bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
		add_child(_sfx_player)

func _on_hover() -> void:
	_play(hover_sfx)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "scale", hover_scale, 0.12).set_trans(Tween.TRANS_BACK)

func _on_unhover() -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE)

func _on_press() -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "scale", press_scale, 0.06)

func _on_release() -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "scale", hover_scale, 0.08).set_trans(Tween.TRANS_BACK)

func _on_confirm() -> void:
	_play(confirm_sfx)

func _play(stream: AudioStream) -> void:
	if stream and _sfx_player:
		_sfx_player.stream = stream
		_sfx_player.play()
