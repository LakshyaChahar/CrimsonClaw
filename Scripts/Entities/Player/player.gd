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

@export_group("Bloodthirst System")
@export var max_bloodthirst: float = 100.0
@export var current_bloodthirst: float = 0.0
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
## Minimum required bloodthirst to perform basic attack.
@export var melee_min_required_bloodthirst: float = 0.0
## Bloodthirst gained on hit with basic attack.
@export var melee_bloodthirst_gain: float = 10.0

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
## Minimum required bloodthirst to perform Ignis Claw.
@export var ignis_min_required_bloodthirst: float = 20.0
## Bloodthirst gained on hit with Ignis Claw skill.
@export var ignis_bloodthirst_gain: float = 15.0

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
## Minimum required bloodthirst to perform Hellforge Dive.
@export var hellforge_min_required_bloodthirst: float = 60.0
## Bloodthirst gained on hit with Hellforge Dive skill.
@export var hellforge_bloodthirst_gain: float = 15.0
## Camera shake intensity on impact.
@export var hellforge_shake_intensity: float = 8.0
## Camera shake duration on impact.
@export var hellforge_shake_duration: float = 0.25

@onready var health_bar: ProgressBar = $HUD/VBoxContainer/HealthBar
@onready var bloodthirst_bar: ProgressBar = $HUD/VBoxContainer/BloodthirstBar

func _ready() -> void:
	super._ready()
	add_to_group("Player")
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

	setup_camera_limits()
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND

func _on_health_changed(_old_value: float, new_value: float) -> void:
	if health_bar:
		health_bar.value = new_value

func _on_bloodthirst_changed(_old_value: float, new_value: float) -> void:
	if bloodthirst_bar:
		bloodthirst_bar.value = new_value

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

func activate_tyrant_mode() -> void:
	if is_tyrant:
		return
		
	is_tyrant = true
	tyrant_timer = tyrant_duration
	ghost_trail_timer = 0.0

	trigger_screen_shake(14.0, 0.45)
	_setup_tyrant_screen_vignette()
	_spawn_tyrant_transformation_burst()
	_apply_tyrant_sprite_glow(true)

func deactivate_tyrant_mode() -> void:
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
	if not sprite:
		return

	var ghost = Sprite2D.new()
	var current_texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	ghost.texture = current_texture
	ghost.global_position = sprite.global_position
	ghost.scale = sprite.global_scale
	ghost.rotation = sprite.global_rotation
	ghost.flip_h = sprite.flip_h
	ghost.modulate = Color(1.2, 0.15, 0.25, 0.65)
	ghost.z_index = sprite.z_index - 1

	get_parent().add_child(ghost)

	var tween = ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.25)
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

## Automatically detects a child Camera2D and sets its boundaries to the TileMap/TileMapLayer limits.
func setup_camera_limits() -> void:
	var camera = find_child("Camera2D", true, false) as Camera2D
	if not camera:
		return
	
	var tilemap = get_tree().get_first_node_in_group("TileMap")
	if not tilemap:
		var root_scene = get_tree().current_scene
		if root_scene:
			tilemap = root_scene.find_child("*TileMap*", true, false)
			if not tilemap:
				tilemap = root_scene.find_child("*TileMapLayer*", true, false)
				
	if tilemap:
		var rect: Rect2i
		if tilemap.has_method("get_used_rect"):
			rect = tilemap.get_used_rect()
		
		if rect != Rect2i() and "tile_set" in tilemap and tilemap.tile_set:
			var cell_size = tilemap.tile_set.tile_size
			camera.limit_left = rect.position.x * cell_size.x
			camera.limit_top = rect.position.y * cell_size.y
			camera.limit_right = rect.end.x * cell_size.x
			camera.limit_bottom = rect.end.y * cell_size.y

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

	var melee_state = find_child("Skill", true, false) as MeleeAttackState
	if melee_state:
		melee_state.damage = melee_damage * mult_dmg
		melee_state.knockback_force = melee_knockback_force * mult_kb
		melee_state.stun_duration = melee_stun_duration * mult_stun
		melee_state.attack_duration = melee_attack_duration
		melee_state.min_required_bloodthirst = melee_min_required_bloodthirst
		
	var ignis_state = find_child("IgnisClaw", true, false) as IgnisClawState
	if ignis_state:
		ignis_state.initial_damage = ignis_damage * mult_dmg
		ignis_state.knockback_force = ignis_knockback_force * mult_kb
		ignis_state.fire_duration = ignis_fire_duration
		ignis_state.fire_dps = ignis_fire_dps * mult_dmg
		ignis_state.stun_duration = ignis_stun_duration * mult_stun
		ignis_state.attack_duration = ignis_attack_duration
		ignis_state.min_required_bloodthirst = ignis_min_required_bloodthirst
		
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
		hellforge_state.min_required_bloodthirst = hellforge_min_required_bloodthirst
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
