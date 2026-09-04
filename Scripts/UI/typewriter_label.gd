class_name TypewriterLabel
extends RichTextLabel

signal typing_finished

@export var chars_per_second: float = 35.0
@export var auto_start: bool = false

var _tween: Tween
var _is_typing: bool = false

func _ready() -> void:
	if auto_start and not text.is_empty():
		start_typing()

func start_typing(new_text: String = "") -> void:
	if not new_text.is_empty():
		text = new_text

	if _tween and _tween.is_running():
		_tween.kill()

	visible_ratio = 0.0
	_is_typing = true
	
	# Strip BBCode tags to calculate visible character count safely
	var regex := RegEx.new()
	regex.compile("\\[[^\\]]*\\]")
	var clean_text := regex.sub(text, "", true)
	var char_count := clean_text.length()
	
	if char_count <= 0:
		visible_ratio = 1.0
		_is_typing = false
		typing_finished.emit()
		return

	var duration: float = float(char_count) / max(1.0, chars_per_second)
	
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(self, "visible_ratio", 1.0, duration)
	_tween.finished.connect(_on_typing_completed)

func skip_typing() -> void:
	if _is_typing:
		if _tween and _tween.is_running():
			_tween.kill()
		visible_ratio = 1.0
		_on_typing_completed()

func is_typing() -> bool:
	return _is_typing

func _on_typing_completed() -> void:
	if _is_typing:
		_is_typing = false
		typing_finished.emit()
