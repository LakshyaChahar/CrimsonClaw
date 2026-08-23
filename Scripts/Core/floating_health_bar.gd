# Floating Health & Shield Bar Component for Normal Enemies (Option A) and Bosses (Option B)
extends Node2D
class_name FloatingHealthBar

@export var is_boss_bar: bool = false
@export var bar_width: float = 36.0
@export var bar_height: float = 5.0
@export var offset_y: float = -38.0
@export var fade_delay: float = 2.5

var character: Character = null
var current_health_pct: float = 1.0
var current_shield_pct: float = 1.0
var has_shield: bool = false
var fade_tween: Tween = null
var is_visible_active: bool = false

func _ready() -> void:
	character = get_parent() as Character
	if not character:
		return
		
	current_health_pct = clamp(character.current_health / max(character.max_health, 1.0), 0.0, 1.0)
	
	if "max_shield_health" in character:
		has_shield = true
		var max_s = character.get("max_shield_health")
		var cur_s = character.get("current_shield_health")
		current_shield_pct = clamp(cur_s / max(max_s, 1.0), 0.0, 1.0)

	character.health_changed.connect(_on_health_changed)
	character.died.connect(_on_died)
	
	if character.has_signal("shield_changed"):
		character.connect("shield_changed", _on_shield_changed)

	position = Vector2(0, offset_y)
	z_index = 20

	if is_boss_bar:
		# Option B: Sub-Boss bar is always visible
		modulate.a = 1.0
		is_visible_active = true
	else:
		# Option A: Normal enemy bar is hidden by default
		modulate.a = 0.0
		is_visible_active = false

func _draw() -> void:
	if modulate.a <= 0.01:
		return

	var w = bar_width
	var h = bar_height
	var half_w = w * 0.5

	# 1. Draw Background Box
	draw_rect(Rect2(-half_w - 1, -h - 1, w + 2, h + 2), Color(0.1, 0.1, 0.12, 0.85))

	# 2. Draw Health Fill (Red/Crimson)
	var fill_w = w * current_health_pct
	var hp_color = Color(0.9, 0.2, 0.25, 0.95) if not is_boss_bar else Color(0.95, 0.25, 0.2, 0.95)
	draw_rect(Rect2(-half_w, -h, fill_w, h), hp_color)

	# 3. Draw Shield Bar (Gold) above Health Bar if entity has a shield (Dread Vanguard)
	if has_shield and current_shield_pct > 0.0:
		var sh_h = 3.0
		var sh_y = -h - sh_h - 2.0
		draw_rect(Rect2(-half_w - 1, sh_y - 1, w + 2, sh_h + 2), Color(0.1, 0.1, 0.12, 0.85))
		var shield_w = w * current_shield_pct
		draw_rect(Rect2(-half_w, sh_y, shield_w, sh_h), Color(1.0, 0.8, 0.2, 0.95))

	# 4. Draw Border Frame
	draw_rect(Rect2(-half_w - 1, -h - 1, w + 2, h + 2), Color(0.0, 0.0, 0.0, 0.9), false, 1.0)

func _on_health_changed(_old_val: float, new_val: float) -> void:
	if not character:
		return
		
	current_health_pct = clamp(new_val / max(character.max_health, 1.0), 0.0, 1.0)
	queue_redraw()

	if not is_boss_bar:
		_trigger_contextual_fade_in()

func _on_shield_changed(_old_val: float, new_val: float) -> void:
	if not character:
		return
		
	var max_s = character.get("max_shield_health")
	current_shield_pct = clamp(new_val / max(max_s, 1.0), 0.0, 1.0)
	queue_redraw()

	if not is_boss_bar:
		_trigger_contextual_fade_in()

func _trigger_contextual_fade_in() -> void:
	# Fade in bar immediately when damaged
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()

	modulate.a = 1.0
	is_visible_active = true

	# Wait fade_delay seconds, then fade out to 0.0
	fade_tween = create_tween()
	fade_tween.tween_interval(fade_delay)
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.5)

func _on_died() -> void:
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	modulate.a = 0.0
