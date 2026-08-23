# Crimson Tyrant Transformation State for Player
extends CharacterState
class_name CrimsonTyrantState

@export var duration: float = 10.0
@export var damage_multiplier: float = 2.0
@export var knockback_multiplier: float = 1.8
@export var stun_multiplier: float = 1.5
@export var min_required_bloodthirst: float = 100.0

var active_timer: float = 0.0
var ghost_timer: float = 0.0
var overlay_canvas: CanvasLayer = null
var overlay_rect: ColorRect = null

func enter() -> void:
	var player = character as Player
	if player:
		player.activate_tyrant_mode()

	if character.is_grounded():
		state_machine.change_state("walk" if character.input_direction.x != 0 else "idle")
	else:
		state_machine.change_state("fall")

func physics_update(delta: float) -> void:
	active_timer -= delta

	# Pulse dark grey/red atmospheric blood vignette overlay for entire duration
	if overlay_rect:
		var pulse = (sin(active_timer * 6.0) + 1.0) * 0.5
		overlay_rect.color = Color(0.28, 0.08, 0.11, lerp(0.42, 0.56, pulse))

	# Spawn Ghost Afterimage Motion Trail every 0.05s while active
	ghost_timer += delta
	if ghost_timer >= 0.05:
		ghost_timer = 0.0
		_spawn_ghost_afterimage()

	if active_timer <= 0.0:
		_finish_tyrant_mode()
		return

	# Player can move, jump, and attack normally while in Tyrant state!
	character.apply_gravity(delta)

	var target_speed = character.input_direction.x * (character.move_speed * 1.25)
	character.apply_horizontal_movement(delta, target_speed, character.acceleration, character.friction)
	character.move_and_slide()

	if character.wants_jump and character.is_grounded():
		character.velocity.y = -character.jump_force

func _setup_screen_vignette() -> void:
	overlay_canvas = character.find_child("TyrantOverlayCanvas", true, false) as CanvasLayer
	if not overlay_canvas:
		overlay_canvas = CanvasLayer.new()
		overlay_canvas.name = "TyrantOverlayCanvas"
		overlay_canvas.layer = 100
		character.add_child(overlay_canvas)

	overlay_rect = overlay_canvas.find_child("BloodVignette", false, false) as ColorRect
	if not overlay_rect:
		overlay_rect = ColorRect.new()
		overlay_rect.name = "BloodVignette"
		overlay_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay_rect.color = Color(0.28, 0.08, 0.11, 0.48)
		overlay_canvas.add_child(overlay_rect)

	overlay_canvas.visible = true

func _spawn_transformation_burst() -> void:
	var blast = CPUParticles2D.new()
	blast.amount = 40
	blast.lifetime = 0.45
	blast.one_shot = true
	blast.explosiveness = 0.95
	blast.direction = Vector2.ZERO
	blast.spread = 180.0
	blast.gravity = Vector2(0, 150)
	blast.initial_velocity_min = 120.0
	blast.initial_velocity_max = 260.0
	blast.scale_amount_min = 3.5
	blast.scale_amount_max = 7.0
	blast.color = Color(0.95, 0.1, 0.18, 0.95)
	blast.global_position = character.global_position + Vector2(0, -18)
	
	character.get_parent().add_child(blast)
	blast.emitting = true
	character.get_tree().create_timer(0.5).timeout.connect(blast.queue_free)

func _spawn_ghost_afterimage() -> void:
	var sprite = character.find_child("AnimatedSprite2D") as AnimatedSprite2D
	if not sprite:
		return

	var ghost = Sprite2D.new()
	var current_texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	ghost.texture = current_texture
	ghost.global_position = sprite.global_position
	ghost.scale = sprite.global_scale
	ghost.rotation = sprite.global_rotation
	ghost.flip_h = sprite.flip_h
	ghost.modulate = Color(1.2, 0.15, 0.25, 0.65) # Deep glowing Crimson Tyrant clone
	ghost.z_index = sprite.z_index - 1

	character.get_parent().add_child(ghost)

	var tween = ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.25)
	tween.tween_callback(ghost.queue_free)

func _apply_tyrant_sprite_glow(enable: bool) -> void:
	var sprite = character.find_child("AnimatedSprite2D") as AnimatedSprite2D
	if sprite:
		if enable:
			sprite.modulate = Color(1.35, 0.7, 0.7, 1.0)
		else:
			sprite.modulate = Color.WHITE

func _finish_tyrant_mode() -> void:
	var player = character as Player
	if player:
		player.is_tyrant = false

	_cleanup_vfx()

	if character.is_grounded():
		state_machine.change_state("idle")
	else:
		state_machine.change_state("fall")

func _cleanup_vfx() -> void:
	_apply_tyrant_sprite_glow(false)

	if overlay_rect:
		var tween = overlay_rect.create_tween()
		tween.tween_property(overlay_rect, "color:a", 0.0, 0.5)
		tween.tween_callback(func(): if overlay_canvas: overlay_canvas.visible = false)

func exit() -> void:
	_cleanup_vfx()
