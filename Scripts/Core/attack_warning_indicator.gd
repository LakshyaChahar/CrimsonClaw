# Procedural Overhead Warning Flash Indicator (!) for Enemy Telegraph Phase
extends Node2D
class_name AttackWarningIndicator

@export var icon_color: Color = Color(1.0, 0.2, 0.2, 0.95)
@export var icon_scale: float = 1.0
@export var offset_y: float = -55.0

var active_timer: float = 0.0
var total_duration: float = 1.0

func _ready() -> void:
	z_index = 25
	position = Vector2(0, offset_y)
	scale = Vector2.ZERO

	# Pop up animation
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.15)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func setup(duration: float, custom_color: Color = Color.RED) -> void:
	total_duration = max(0.1, duration)
	active_timer = total_duration
	icon_color = custom_color
	queue_redraw()

func _process(delta: float) -> void:
	active_timer -= delta
	queue_redraw()

	if active_timer <= 0.0:
		queue_free()

func _draw() -> void:
	if active_timer <= 0.0:
		return

	# Rapid pulse effect
	var pulse = (sin(active_timer * 30.0) + 1.0) * 0.5
	var draw_col = lerp(icon_color, Color.WHITE, pulse * 0.5)

	# 1. Background Warning Glow Badge
	draw_circle(Vector2.ZERO, 12.0, Color(0.1, 0.1, 0.12, 0.85))
	draw_arc(Vector2.ZERO, 12.0, 0, TAU, 24, draw_col, 2.0)

	# 2. Draw '!' Symbol
	# Top bar of '!'
	draw_line(Vector2(0, -7), Vector2(0, 0), draw_col, 3.5)
	# Bottom dot of '!'
	draw_circle(Vector2(0, 5), 2.0, draw_col)
