extends Character
class_name Player

@export_group("Input Action Names")
@export var action_left: String = "move_left"
@export var action_right: String = "move_right"
@export var action_jump: String = "jump"
@export var action_dash: String = "dash"
@export var action_skill: String = "attack"
@export var action_ignis_claw: String = "ignis_claw"
@export var action_hellforge_dive: String = "hellforge_dive"
@export var action_tyrant: String = "tyrant_transform"

# Fallback actions if the custom input map is not defined
var final_left: String
var final_right: String
var final_jump: String
var final_dash: String
var final_skill: String
var final_ignis_claw: String
var final_hellforge_dive: String
var final_tyrant: String

var wants_ignis_claw: bool = false
var wants_hellforge_dive: bool = false
var wants_tyrant: bool = false

# Buffer timers to make the controls feel smooth
var jump_buffer_timer: float = 0.0
@export var jump_buffer_time: float = 0.1

@export_group("Spawn & Respawn System")
## Respawn position where the player returns upon death
@export var spawn_position: Vector2 = Vector2.ZERO
## Y-coordinate boundary below which falling into a pit triggers player death
@export var pit_death_y: float = 1200.0

@export_group("Bloodthirst System")
@export var max_bloodthirst: float = 100.0
@export var current_bloodthirst: float = 100.0
## Bloodthirst gained immediately upon performing a dash.
@export var dash_bloodthirst_gain: float = 10.0
signal bloodthirst_changed(old_value: float, new_value: float)


@export_group("Crimson Tyrant Transformation (Designer Panel)")
## Key/Action duration of Crimson Tyrant state in seconds
@export var tyrant_duration: float = 10.0

## Multiplier for player damage in Tyrant mode (e.g. 2.0 = 2x damage)
@export var tyrant_damage_multiplier: float = 2.0

## Multiplier for player knockback in Tyrant mode (e.g. 1.8 = 1.8x knockback)
@export var tyrant_knockback_multiplier: float = 1.8

## Multiplier for player stun duration in Tyrant mode (e.g. 1.5 = 1.5x stun)
@export var tyrant_stun_multiplier: float = 1.5

## Health regenerated per second while in Crimson Tyrant mode (e.g. 5.0 = 5 HP/sec)
@export var tyrant_health_regen: float = 5.0

## Minimum required bloodthirst to enter Crimson Tyrant transformation
@export var tyrant_min_required_bloodthirst: float = 100.0

var is_tyrant: bool = false:
	set(val):
		is_tyrant = val
		_sync_attack_properties()

@export_group("Basic Melee Attack")
## Damage dealt by basic sword swing.
@export var melee_damage: float = 10.0
## Knockback force pushing targets back.
@export var melee_knockback_force: float = 150.0
## Duration of stun applied on basic hit.
@export var melee_stun_duration: float = 0.2
## Duration of the basic attack swing.
@export var melee_attack_duration: float = 0.4
## Minimum required bloodthirst to perform basic attack (0.0 = free).
@export var melee_min_required_bloodthirst: float = 0.0
## Bloodthirst cost consumed when performing basic attack (0.0 = free).
@export var melee_bloodthirst_cost: float = 0.0
## Bloodthirst gained on hit with basic attack.
@export var melee_bloodthirst_gain: float = 15.0

@export_group("Ignis Claw Skill")
## Initial hit damage dealt when Ignis Claw strikes.
@export var ignis_damage: float = 25.0
## Knockback force pushing targets on strike.
@export var ignis_knockback_force: float = 400.0
## Duration of fire burn effect in seconds.
@export var ignis_fire_duration: float = 3.0
## Damage per second inflicted while target is on fire.
@export var ignis_fire_dps: float = 8.0
## Duration of stun applied on hit.
@export var ignis_stun_duration: float = 0.3
## Duration of the Ignis Claw attack state.
@export var ignis_attack_duration: float = 0.45
## Bloodthirst cost to execute Ignis Claw skill.
@export var ignis_bloodthirst_cost: float = 6.0
## Minimum required bloodthirst to perform Ignis Claw.
@export var ignis_min_required_bloodthirst: float = 6.0
## Bloodthirst gained on hit with Ignis Claw skill (0.0 = non-basic attack).
@export var ignis_bloodthirst_gain: float = 0.0
## Cooldown in seconds before Ignis Claw can be used again.
@export var ignis_claw_cooldown: float = 3.0
var ignis_claw_cooldown_timer: float = 0.0

@export_group("Hellforge Dive Skill")
## Upward force launching player into dive rise phase.
@export var hellforge_rise_force: float = 500.0
## Downward speed when slamming down.
@export var hellforge_slam_speed: float = 900.0
## Maximum duration of the rising phase in seconds.
@export var hellforge_max_rise_duration: float = 0.25
## Duration of ground impact recovery state in seconds.
@export var hellforge_impact_duration: float = 0.35
## Base physical damage dealt on ground impact.
@export var hellforge_impact_damage: float = 30.0
## Radial knockback force pushing targets away.
@export var hellforge_knockback_force: float = 450.0
## Duration of stun applied on impact hit.
@export var hellforge_stun_duration: float = 0.4
## Whether impact causes targets to catch fire.
@export var hellforge_inflicts_fire: bool = true
## Damage per second while target is on fire.
@export var hellforge_fire_dps: float = 10.0
## Duration of fire burn effect in seconds.
@export var hellforge_fire_duration: float = 4.0
## Bloodthirst cost to execute Hellforge Dive skill.
@export var hellforge_bloodthirst_cost: float = 7.0
## Minimum required bloodthirst to perform Hellforge Dive.
@export var hellforge_min_required_bloodthirst: float = 7.0
## Bloodthirst gained on hit with Hellforge Dive skill (0.0 = non-basic attack).
@export var hellforge_bloodthirst_gain: float = 0.0
## Camera shake intensity on impact.
@export var hellforge_shake_intensity: float = 8.0
## Camera shake duration on impact.
@export var hellforge_shake_duration: float = 0.25
## Cooldown in seconds before Hellforge Dive can be used again.
@export var hellforge_dive_cooldown: float = 4.0
var hellforge_dive_cooldown_timer: float = 0.0

@export_group("Showcase & Move Unlock Tutorials")
## If true, triggers move unlock tutorial popups when reaching bloodthirst thresholds
@export var enable_move_unlock_tutorials: bool = true
static var shown_tutorials_this_session: Dictionary = {}
var popup_scene: PackedScene = preload("res://Scenes/UI/move_unlock_popup.tscn")

@onready var health_bar: TextureProgressBar = $HUD/VBoxContainer/HealthBar
@onready var bloodthirst_bar: TextureProgressBar = $HUD/VBoxContainer/BloodthirstBar

func _ready() -> void:
	super._ready()
	add_to_group("Player")
	if spawn_position == Vector2.ZERO:
		spawn_position = global_position
	if Checkpoint.saved_respawn_position != Vector2.ZERO:
		global_position = Checkpoint.saved_respawn_position
	_init_input_actions()
	_sync_attack_properties()
	
	# Connect to all child hitboxes recursively to increase bloodthirst on successful hits
	var hitboxes = find_children("*", "Hitbox", true, false)
	for hitbox in hitboxes:
		if hitbox is Hitbox:
			hitbox.hit_registered.connect(_on_attack_hit.bind(hitbox))

	# Initialize HUD ProgressBars
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	if bloodthirst_bar:
		bloodthirst_bar.max_value = max_bloodthirst
		bloodthirst_bar.value = current_bloodthirst



	# Connect change signals
	health_changed.connect(_on_health_changed)
	bloodthirst_changed.connect(_on_bloodthirst_changed)

	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND

func _on_health_changed(_old_value: float, new_value: float) -> void:
	if health_bar:
		health_bar.value = new_value

func _on_bloodthirst_changed(_old_value: float, new_value: float) -> void:
	if bloodthirst_bar:
		bloodthirst_bar.value = new_value
	_check_move_unlock_tutorials(new_value)

func _check_move_unlock_tutorials(current_bt: float) -> void:
	if not enable_move_unlock_tutorials or is_dead or is_tyrant:
		return

	# Deferred to prevent opening during node instantiation before first physics frame
	call_deferred("_eval_tutorials_deferred", current_bt)

func _eval_tutorials_deferred(current_bt: float) -> void:
	if not enable_move_unlock_tutorials or is_dead or is_tyrant or get_tree().paused:
		return

	# Only trigger move unlock demo popups in combat demo levels
	if get_tree().current_scene:
		var scene_file: String = get_tree().current_scene.scene_file_path.get_file().to_lower()
		var scene_name: String = get_tree().current_scene.name.to_lower()
		var is_combat_demo: bool = ("combat" in scene_file or "demo" in scene_file or 
									"combat" in scene_name or "demo" in scene_name or 
									"level0" in scene_file or "level 0" in scene_file or
									"level_0" in scene_file)
		if not is_combat_demo:
			return

	# Dash Tutorial (triggers when bloodthirst >= dash_min_required_bloodthirst)
	if current_bt >= dash_min_required_bloodthirst and not shown_tutorials_this_session.get("dash", false):
		shown_tutorials_this_session["dash"] = true
		_trigger_move_popup({
			"header": "MOVEMENT ABILITY UNLOCKED!",
			"title": "CRIMSON DASH",
			"input_prompt": "Press B / Shift to Dash",
			"min_bloodthirst": dash_min_required_bloodthirst,
			"description": "Perform a rapid horizontal evade, granting complete invincibility during the dash while leaving crimson afterimages.",
			"anim_name": "dash"
		})
		return

	# Ignis Claw Tutorial (triggers when bloodthirst >= ignis_min_required_bloodthirst)
	if ignis_min_required_bloodthirst > 0.0 and current_bt >= ignis_min_required_bloodthirst and not shown_tutorials_this_session.get("ignis_claw", false):
		shown_tutorials_this_session["ignis_claw"] = true
		_trigger_move_popup({
			"header": "NEW SKILL UNLOCKED!",
			"title": "IGNIS CLAW",
			"input_prompt": "Press Y / RMB / [E] to perform Ignis Claw",
			"min_bloodthirst": ignis_min_required_bloodthirst,
			"description": "Unleash a fierce demonic claw strike forward, igniting enemies with persistent fire damage.",
			"anim_name": "ignis_claw"
		})
		return

	# Hellforge Dive Tutorial (triggers when bloodthirst >= hellforge_min_required_bloodthirst)
	if hellforge_min_required_bloodthirst > 0.0 and current_bt >= hellforge_min_required_bloodthirst and not shown_tutorials_this_session.get("hellforge_dive", false):
		shown_tutorials_this_session["hellforge_dive"] = true
		_trigger_move_popup({
			"header": "NEW MOVE UNLOCKED!",
			"title": "HELLFORGE DIVE",
			"input_prompt": "Press RB / [R] while in mid-air",
			"min_bloodthirst": hellforge_min_required_bloodthirst,
			"description": "Slam into the earth from mid-air to create a devastating crimson shockwave that burns surrounding foes.",
			"anim_name": "hellforge_fall"
		})
		return

	# Crimson Tyrant Tutorial (triggers when bloodthirst >= tyrant_min_required_bloodthirst)
	if tyrant_min_required_bloodthirst > 0.0 and current_bt >= tyrant_min_required_bloodthirst and not shown_tutorials_this_session.get("tyrant", false):
		shown_tutorials_this_session["tyrant"] = true
		_trigger_move_popup({
			"header": "ULTIMATE FORM UNLOCKED!",
			"title": "CRIMSON TYRANT",
			"input_prompt": "Press LB / [T] to unleash Crimson Tyrant",
			"min_bloodthirst": tyrant_min_required_bloodthirst,
			"description": "Transcends mortal limits! Gain maximum movement speed, doubled damage, massive knockback, and rapid health regeneration.",
			"anim_name": "attack_1"
		})
		return

var _level0_tutorial_queue: Array[Dictionary] = []
var _on_tutorials_complete_callback: Callable = Callable()

func show_remaining_level0_tutorials(on_complete_callback: Callable = Callable()) -> void:
	_on_tutorials_complete_callback = on_complete_callback
	_level0_tutorial_queue.clear()
	
	var all_tutorials = [
		{
			"key": "dash",
			"header": "MOVEMENT ABILITY UNLOCKED!",
			"title": "CRIMSON DASH",
			"input_prompt": "Press B / Shift to Dash",
			"min_bloodthirst": dash_min_required_bloodthirst,
			"description": "Perform a rapid horizontal evade, granting complete invincibility during the dash while leaving crimson afterimages.",
			"anim_name": "dash"
		},
		{
			"key": "ignis_claw",
			"header": "NEW SKILL UNLOCKED!",
			"title": "IGNIS CLAW",
			"input_prompt": "Press Y / RMB / [E] to perform Ignis Claw",
			"min_bloodthirst": ignis_min_required_bloodthirst,
			"description": "Unleash a fierce demonic claw strike forward, igniting enemies with persistent fire damage.",
			"anim_name": "ignis_claw"
		},
		{
			"key": "hellforge_dive",
			"header": "NEW MOVE UNLOCKED!",
			"title": "HELLFORGE DIVE",
			"input_prompt": "Press RB / [R] while in mid-air",
			"min_bloodthirst": hellforge_min_required_bloodthirst,
			"description": "Slam into the earth from mid-air to create a devastating crimson shockwave that burns surrounding foes.",
			"anim_name": "hellforge_fall"
		},
		{
			"key": "tyrant",
			"header": "ULTIMATE FORM UNLOCKED!",
			"title": "CRIMSON TYRANT",
			"input_prompt": "Press LB / [T] to unleash Crimson Tyrant",
			"min_bloodthirst": tyrant_min_required_bloodthirst,
			"description": "Transcends mortal limits! Gain maximum movement speed, doubled damage, massive knockback, and rapid health regeneration.",
			"anim_name": "attack_1"
		}
	]
	
	for tut in all_tutorials:
		var key: String = tut.get("key", "")
		if not shown_tutorials_this_session.get(key, false):
			_level0_tutorial_queue.append(tut)
			
	if _level0_tutorial_queue.is_empty():
		if _on_tutorials_complete_callback.is_valid():
			var cb = _on_tutorials_complete_callback
			_on_tutorials_complete_callback = Callable()
			cb.call()
		return
		
	_process_next_level0_tutorial()

func _process_next_level0_tutorial() -> void:
	if _level0_tutorial_queue.is_empty():
		if _on_tutorials_complete_callback.is_valid():
			var cb = _on_tutorials_complete_callback
			_on_tutorials_complete_callback = Callable()
			cb.call()
		return
	
	var data = _level0_tutorial_queue.pop_front()
	var key: String = data.get("key", "")
	if key != "":
		shown_tutorials_this_session[key] = true
	
	var popup = _trigger_move_popup(data)
	if popup and popup.has_signal("popup_dismissed"):
		popup.popup_dismissed.connect(func(): call_deferred("_process_next_level0_tutorial"), CONNECT_ONE_SHOT)
	else:
		call_deferred("_process_next_level0_tutorial")

func _trigger_move_popup(data: Dictionary) -> MoveUnlockPopup:
	if not popup_scene:
		return null

	get_tree().paused = true
	var popup = popup_scene.instantiate() as MoveUnlockPopup
	var sprite_node = find_child("AnimatedSprite2D") as AnimatedSprite2D
	var sprite_frames = sprite_node.sprite_frames if sprite_node else null
	
	get_tree().root.add_child(popup)
	popup.setup_move_info(data, sprite_frames)
	return popup


## Safely increases bloodthirst, capped at max_bloodthirst
func add_bloodthirst(amount: float) -> void:
	var old_value = current_bloodthirst
	current_bloodthirst = clamp(current_bloodthirst + amount, 0.0, max_bloodthirst)
	if old_value != current_bloodthirst:
		bloodthirst_changed.emit(old_value, current_bloodthirst)

## Consumes bloodthirst if enough is available. Returns true if successful.
func consume_bloodthirst(amount: float) -> bool:
	if is_tyrant:
		return true # Special skills are free during Tyrant Mode!
	if current_bloodthirst >= amount:
		var old_value = current_bloodthirst
		current_bloodthirst -= amount
		bloodthirst_changed.emit(old_value, current_bloodthirst)
		return true
	return false

## Returns true if player can execute Hellforge Dive (has enough bloodthirst and no active cooldown).
func can_hellforge_dive() -> bool:
	if is_dead:
		return false
	if hellforge_dive_cooldown_timer > 0.0:
		return false
	if is_tyrant:
		return true
	var cost = hellforge_bloodthirst_cost if hellforge_bloodthirst_cost > 0.0 else hellforge_min_required_bloodthirst
	return current_bloodthirst >= cost

func _on_attack_hit(_hurtbox: Hurtbox, hitbox: Hitbox = null) -> void:
	if not is_tyrant:
		var gain = hitbox.bloodthirst_gain if hitbox else 10.0
		add_bloodthirst(gain)

var dash_buffer_timer: float = 0.0
@export var dash_buffer_time: float = 0.15

var skill_buffer_timer: float = 0.0
@export var skill_buffer_time: float = 0.15

var ignis_claw_buffer_timer: float = 0.0
@export var ignis_claw_buffer_time: float = 0.15

var hellforge_dive_buffer_timer: float = 0.0
@export var hellforge_dive_buffer_time: float = 0.15

var tyrant_buffer_timer: float = 0.0
@export var tyrant_buffer_time: float = 0.15

var tyrant_timer: float = 0.0
var ghost_trail_timer: float = 0.0
var tyrant_overlay_canvas: CanvasLayer = null
var tyrant_overlay_rect: ColorRect = null
var _base_health_regen_rate: float = 1.0

func activate_tyrant_mode() -> void:
	if is_tyrant:
		return
		
	_base_health_regen_rate = health_regen_rate
	health_regen_rate = tyrant_health_regen
	is_tyrant = true
	tyrant_timer = tyrant_duration
	ghost_trail_timer = 0.0

	trigger_screen_shake(14.0, 0.45)
	_setup_tyrant_screen_vignette()
	_spawn_tyrant_transformation_burst()
	_apply_tyrant_sprite_glow(true)

func deactivate_tyrant_mode() -> void:
	health_regen_rate = _base_health_regen_rate
	is_tyrant = false
	tyrant_timer = 0.0
	_apply_tyrant_sprite_glow(false)
	_cleanup_tyrant_vfx()

func _setup_tyrant_screen_vignette() -> void:
	tyrant_overlay_canvas = find_child("TyrantOverlayCanvas", true, false) as CanvasLayer
	if not tyrant_overlay_canvas:
		tyrant_overlay_canvas = CanvasLayer.new()
		tyrant_overlay_canvas.name = "TyrantOverlayCanvas"
		tyrant_overlay_canvas.layer = 100
		add_child(tyrant_overlay_canvas)

	tyrant_overlay_rect = tyrant_overlay_canvas.find_child("BloodVignette", false, false) as ColorRect
	if not tyrant_overlay_rect:
		tyrant_overlay_rect = ColorRect.new()
		tyrant_overlay_rect.name = "BloodVignette"
		tyrant_overlay_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		tyrant_overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tyrant_overlay_rect.color = Color(0.28, 0.08, 0.11, 0.48)
		tyrant_overlay_canvas.add_child(tyrant_overlay_rect)

	tyrant_overlay_canvas.visible = true

func _spawn_tyrant_transformation_burst() -> void:
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
	blast.global_position = global_position + Vector2(0, -18)
	
	get_parent().add_child(blast)
	blast.emitting = true
	get_tree().create_timer(0.5).timeout.connect(blast.queue_free)

func _spawn_tyrant_ghost_afterimage() -> void:
	var sprite = find_child("AnimatedSprite2D") as AnimatedSprite2D
	if not sprite or not sprite.sprite_frames:
		return

	var current_texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if not current_texture:
		return

	var ghost = Sprite2D.new()
	ghost.texture = current_texture
	ghost.centered = sprite.centered
	ghost.offset = sprite.offset

	# Must add child to scene tree FIRST in Godot 4 before setting global_position
	get_parent().add_child(ghost)

	var ghost_x = sprite.global_position.x - (facing_direction * 12.0)
	var ghost_y = sprite.global_position.y
	ghost.global_position = Vector2(ghost_x, ghost_y)

	ghost.global_scale = sprite.global_scale
	ghost.global_rotation = sprite.global_rotation
	ghost.flip_h = sprite.flip_h
	ghost.flip_v = sprite.flip_v
	ghost.modulate = Color(1.2, 0.15, 0.25, 0.65)
	ghost.z_index = max(1, z_index - 1)

	var tween = ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.25)
	tween.tween_callback(ghost.queue_free)
	
func spawn_dash_afterimage() -> void:
	var sprite = find_child("AnimatedSprite2D") as AnimatedSprite2D
	if not sprite or not sprite.sprite_frames:
		return

	var current_texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if not current_texture:
		return

	var ghost = Sprite2D.new()
	ghost.texture = current_texture
	ghost.centered = sprite.centered
	ghost.offset = sprite.offset

	# Must add child to scene tree FIRST in Godot 4 before setting global_position
	get_parent().add_child(ghost)

	# Position ghost at exact same Y level, slightly trailing behind the player X position
	var ghost_x = sprite.global_position.x - (facing_direction * 14.0)
	var ghost_y = sprite.global_position.y
	ghost.global_position = Vector2(ghost_x, ghost_y)

	ghost.global_scale = sprite.global_scale
	ghost.global_rotation = sprite.global_rotation
	ghost.flip_h = sprite.flip_h
	ghost.flip_v = sprite.flip_v
	ghost.modulate = Color(0.8, 0.1, 0.1, 0.6) 
	ghost.z_index = max(1, z_index - 1)

	var tween = ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.3)
	tween.tween_callback(ghost.queue_free)

func _apply_tyrant_sprite_glow(enable: bool) -> void:
	var sprite = find_child("AnimatedSprite2D") as AnimatedSprite2D
	if sprite:
		if enable:
			sprite.modulate = Color(1.35, 0.7, 0.7, 1.0)
		else:
			sprite.modulate = Color.WHITE

func _cleanup_tyrant_vfx() -> void:
	if tyrant_overlay_rect:
		var tween = tyrant_overlay_rect.create_tween()
		tween.tween_property(tyrant_overlay_rect, "color:a", 0.0, 0.5)
		tween.tween_callback(func(): if tyrant_overlay_canvas: tyrant_overlay_canvas.visible = false)

func _process(delta: float) -> void:
	if is_dead:
		return
		
	# Tick input buffers
	jump_buffer_timer = max(0.0, jump_buffer_timer - delta)
	dash_buffer_timer = max(0.0, dash_buffer_timer - delta)
	skill_buffer_timer = max(0.0, skill_buffer_timer - delta)
	ignis_claw_buffer_timer = max(0.0, ignis_claw_buffer_timer - delta)
	hellforge_dive_buffer_timer = max(0.0, hellforge_dive_buffer_timer - delta)
	tyrant_buffer_timer = max(0.0, tyrant_buffer_timer - delta)

	# Tick skill cooldowns
	ignis_claw_cooldown_timer = max(0.0, ignis_claw_cooldown_timer - delta)
	hellforge_dive_cooldown_timer = max(0.0, hellforge_dive_cooldown_timer - delta)

	# Read movement inputs
	input_direction.x = Input.get_axis(final_left, final_right)
	input_direction.y = Input.get_axis("look_up", "look_down")
	
	# Update action flags with buffered inputs
	if Input.is_action_just_pressed(final_jump):
		jump_buffer_timer = jump_buffer_time
	wants_jump = jump_buffer_timer > 0.0
	
	if Input.is_action_just_pressed(final_dash):
		dash_buffer_timer = dash_buffer_time
	wants_dash = dash_buffer_timer > 0.0
		
	if Input.is_action_just_pressed(final_skill):
		skill_buffer_timer = skill_buffer_time
	wants_skill = skill_buffer_timer > 0.0
	
	if Input.is_action_just_pressed(final_ignis_claw):
		ignis_claw_buffer_timer = ignis_claw_buffer_time
	wants_ignis_claw = ignis_claw_buffer_timer > 0.0

	if Input.is_action_just_pressed(final_hellforge_dive):
		hellforge_dive_buffer_timer = hellforge_dive_buffer_time
	wants_hellforge_dive = hellforge_dive_buffer_timer > 0.0

	# Check for Crimson Tyrant activation (Action 'tyrant_transform', Key 'T', or Controller LB)
	var lb_pressed = Input.is_joy_button_pressed(0, JOY_BUTTON_LEFT_SHOULDER)
	if Input.is_action_just_pressed(final_tyrant) or Input.is_action_just_pressed("tyrant_transform") or Input.is_key_pressed(KEY_T) or lb_pressed:
		tyrant_buffer_timer = tyrant_buffer_time

	wants_tyrant = tyrant_buffer_timer > 0.0

	if wants_tyrant and not is_tyrant and current_bloodthirst >= tyrant_min_required_bloodthirst:
		wants_tyrant = false
		tyrant_buffer_timer = 0.0
		activate_tyrant_mode()
	# Tick Crimson Tyrant Mode duration buff
	if is_tyrant:
		tyrant_timer -= delta

		# Smoothly drain bloodthirst bar from max_bloodthirst to 0 over tyrant_duration
		var old_bt = current_bloodthirst
		current_bloodthirst = max(0.0, (tyrant_timer / tyrant_duration) * max_bloodthirst)
		if old_bt != current_bloodthirst:
			bloodthirst_changed.emit(old_bt, current_bloodthirst)

		# Pulse dark grey/red blood vignette overlay for full duration
		if tyrant_overlay_rect:
			var pulse = (sin(tyrant_timer * 6.0) + 1.0) * 0.5
			tyrant_overlay_rect.color = Color(0.28, 0.08, 0.11, lerp(0.42, 0.56, pulse))

		# Spawn Ghost Afterimage Trail every 0.05s while in Tyrant Mode
		ghost_trail_timer += delta
		if ghost_trail_timer >= 0.05:
			ghost_trail_timer = 0.0
			_spawn_tyrant_ghost_afterimage()

		if tyrant_timer <= 0.0:
			deactivate_tyrant_mode()

	# Toggle Fullscreen with F11
	if Input.is_key_pressed(KEY_F11):
		_toggle_fullscreen()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not is_dead and global_position.y > pit_death_y:
		die()

## Triggers a smooth level reload on player death via SceneTransition
func respawn() -> void:
	if SceneTransition and SceneTransition.has_method("reload_current_scene"):
		SceneTransition.reload_current_scene(0.4, 0.4)
	elif get_tree():
		get_tree().reload_current_scene()

func consume_jump_buffer() -> void:
	jump_buffer_timer = 0.0
	wants_jump = false

func _toggle_fullscreen() -> void:
	var window = get_window()
	if window:
		if window.mode == Window.MODE_FULLSCREEN or window.mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
			window.mode = Window.MODE_WINDOWED
		else:
			window.mode = Window.MODE_FULLSCREEN

func _init_input_actions() -> void:
	if not InputMap.has_action("tyrant_transform"):
		InputMap.add_action("tyrant_transform")
		var ev_key = InputEventKey.new()
		ev_key.keycode = KEY_T
		InputMap.action_add_event("tyrant_transform", ev_key)
		
		var ev_joy = InputEventJoypadButton.new()
		ev_joy.button_index = JOY_BUTTON_LEFT_SHOULDER
		InputMap.action_add_event("tyrant_transform", ev_joy)

	final_left = action_left if InputMap.has_action(action_left) else "ui_left"
	final_right = action_right if InputMap.has_action(action_right) else "ui_right"
	final_jump = action_jump if InputMap.has_action(action_jump) else "ui_accept"
	final_dash = action_dash if InputMap.has_action(action_dash) else "ui_select"
	final_skill = action_skill if InputMap.has_action(action_skill) else "ui_focus_next"
	final_ignis_claw = action_ignis_claw if InputMap.has_action(action_ignis_claw) else "ignis_claw"
	final_hellforge_dive = action_hellforge_dive if InputMap.has_action(action_hellforge_dive) else "hellforge_dive"
	final_tyrant = action_tyrant if InputMap.has_action(action_tyrant) else "tyrant_transform"




## Triggers a screen shake effect on the child Camera2D.
func trigger_screen_shake(intensity: float = 8.0, duration: float = 0.25) -> void:
	var camera = find_child("Camera2D", true, false) as Camera2D
	if not camera:
		return
	var tween = create_tween()
	var shake_count = 10
	var step_duration = duration / shake_count
	for i in range(shake_count):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(camera, "offset", offset, step_duration)
	tween.tween_property(camera, "offset", Vector2.ZERO, step_duration)

## Synchronizes root Player exported parameters to states and hitboxes (applying Tyrant multipliers if active!)
func _sync_attack_properties() -> void:
	var mult_dmg = tyrant_damage_multiplier if is_tyrant else 1.0
	var mult_kb = tyrant_knockback_multiplier if is_tyrant else 1.0
	var mult_stun = tyrant_stun_multiplier if is_tyrant else 1.0

	var dash_state = find_child("Dash", true, false) as DashState
	if dash_state:
		dash_state.bloodthirst_gain = dash_bloodthirst_gain

	var melee_state = find_child("Skill", true, false) as MeleeAttackState
	if melee_state:
		melee_state.damage = melee_damage * mult_dmg
		melee_state.knockback_force = melee_knockback_force * mult_kb
		melee_state.stun_duration = melee_stun_duration * mult_stun
		melee_state.attack_duration = melee_attack_duration
		melee_state.min_required_bloodthirst = melee_min_required_bloodthirst
		if "bloodthirst_cost" in melee_state:
			melee_state.bloodthirst_cost = melee_bloodthirst_cost
		
	var ignis_state = find_child("IgnisClaw", true, false) as IgnisClawState
	if ignis_state:
		ignis_state.initial_damage = ignis_damage * mult_dmg
		ignis_state.knockback_force = ignis_knockback_force * mult_kb
		ignis_state.fire_duration = ignis_fire_duration
		ignis_state.fire_dps = ignis_fire_dps * mult_dmg
		ignis_state.stun_duration = ignis_stun_duration * mult_stun
		ignis_state.attack_duration = ignis_attack_duration
		ignis_state.min_required_bloodthirst = ignis_bloodthirst_cost
		if "bloodthirst_cost" in ignis_state:
			ignis_state.bloodthirst_cost = ignis_bloodthirst_cost
		if "cooldown" in ignis_state:
			ignis_state.cooldown = ignis_claw_cooldown
		
	var hellforge_state = find_child("HellforgeDive", true, false) as HellforgeDiveState
	if hellforge_state:
		hellforge_state.rise_force = hellforge_rise_force
		hellforge_state.slam_speed = hellforge_slam_speed
		hellforge_state.max_rise_duration = hellforge_max_rise_duration
		hellforge_state.impact_duration = hellforge_impact_duration
		hellforge_state.impact_damage = hellforge_impact_damage * mult_dmg
		hellforge_state.knockback_force = hellforge_knockback_force * mult_kb
		hellforge_state.stun_duration = hellforge_stun_duration * mult_stun
		hellforge_state.inflicts_fire = hellforge_inflicts_fire
		hellforge_state.fire_dps = hellforge_fire_dps * mult_dmg
		hellforge_state.fire_duration = hellforge_fire_duration
		hellforge_state.min_required_bloodthirst = hellforge_bloodthirst_cost
		if "bloodthirst_cost" in hellforge_state:
			hellforge_state.bloodthirst_cost = hellforge_bloodthirst_cost
		if "cooldown" in hellforge_state:
			hellforge_state.cooldown = hellforge_dive_cooldown
		hellforge_state.shake_intensity = hellforge_shake_intensity
		hellforge_state.shake_duration = hellforge_shake_duration

	var sword_hitbox = find_child("SwordHitbox", true, false) as Hitbox
	if sword_hitbox:
		sword_hitbox.damage = melee_damage * mult_dmg
		sword_hitbox.knockback_force = melee_knockback_force * mult_kb
		sword_hitbox.stun_duration = melee_stun_duration * mult_stun
		sword_hitbox.bloodthirst_gain = melee_bloodthirst_gain
		
	var ignis_hitbox = find_child("IgnisClawHitbox", true, false) as Hitbox
	if ignis_hitbox:
		ignis_hitbox.damage = ignis_damage * mult_dmg
		ignis_hitbox.knockback_force = ignis_knockback_force * mult_kb
		ignis_hitbox.stun_duration = ignis_stun_duration * mult_stun
		ignis_hitbox.fire_dps = ignis_fire_dps * mult_dmg
		ignis_hitbox.fire_duration = ignis_fire_duration
		ignis_hitbox.bloodthirst_gain = ignis_bloodthirst_gain

	var hellforge_hitbox = find_child("HellforgeHitbox", true, false) as Hitbox
	if hellforge_hitbox:
		hellforge_hitbox.damage = hellforge_impact_damage * mult_dmg
		hellforge_hitbox.knockback_force = hellforge_knockback_force * mult_kb
		hellforge_hitbox.stun_duration = hellforge_stun_duration * mult_stun
		hellforge_hitbox.inflicts_fire = hellforge_inflicts_fire
		hellforge_hitbox.fire_dps = hellforge_fire_dps * mult_dmg
		hellforge_hitbox.fire_duration = hellforge_fire_duration
		hellforge_hitbox.bloodthirst_gain = hellforge_bloodthirst_gain
