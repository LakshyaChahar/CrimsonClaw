extends Node
class_name BurnComponent

## Signal emitted when burn starts
signal burn_started

## Signal emitted when burn ends
signal burn_ended

## Frequency of DPS damage ticks in seconds
@export var tick_interval: float = 0.5

var is_on_fire: bool = false
var burn_dps: float = 0.0
var burn_duration_remaining: float = 0.0
var tick_timer: float = 0.0

@onready var character: Character = get_parent() as Character
var fire_spread_area: Area2D = null

func _ready() -> void:
	_setup_fire_spread_area()

func _setup_fire_spread_area() -> void:
	if not character:
		return
		
	fire_spread_area = character.get_node_or_null("FireSpreadArea") as Area2D
	if not fire_spread_area:
		# Dynamically create the FireSpreadArea overlay on the character
		fire_spread_area = Area2D.new()
		fire_spread_area.name = "FireSpreadArea"
		fire_spread_area.collision_layer = 0
		fire_spread_area.collision_mask = 8 # Target Enemy hurtbox collision layer
		
		var shape = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = 24.0
		shape.shape = circle
		fire_spread_area.add_child(shape)
		
		character.call_deferred("add_child", fire_spread_area)
		
	fire_spread_area.set_deferred("monitoring", false)
	fire_spread_area.set_deferred("monitorable", false)
	
	if not fire_spread_area.area_entered.is_connected(_on_spread_area_entered):
		fire_spread_area.area_entered.connect(_on_spread_area_entered)

func _process(delta: float) -> void:
	if not is_on_fire or not character or character.is_dead:
		return
		
	# Countdown duration
	burn_duration_remaining -= delta
	if burn_duration_remaining <= 0.0:
		extinguish()
		return
		
	# Countdown tick timer for DPS
	tick_timer -= delta
	if tick_timer <= 0.0:
		tick_timer = tick_interval
		var tick_damage = burn_dps * tick_interval
		character.take_damage(tick_damage)

## Ignites or refreshes the burn status
func apply_burn(dps: float, duration: float) -> void:
	burn_dps = max(burn_dps, dps)
	burn_duration_remaining = max(burn_duration_remaining, duration)
	
	if not is_on_fire:
		is_on_fire = true
		tick_timer = tick_interval
		_apply_visuals(true)
		
		if fire_spread_area:
			fire_spread_area.set_deferred("monitoring", true)
			
		burn_started.emit()

## Extinguishes the fire
func extinguish() -> void:
	if not is_on_fire:
		return
		
	is_on_fire = false
	burn_dps = 0.0
	burn_duration_remaining = 0.0
	_apply_visuals(false)
	
	if fire_spread_area:
		fire_spread_area.set_deferred("monitoring", false)
		
	burn_ended.emit()

## Visual Tint Feedback (Orange tint while on fire)
func _apply_visuals(on_fire: bool) -> void:
	var target_color = Color(1.0, 0.45, 0.1) if on_fire else Color.WHITE
	
	if character:
		if character.animation_manager and character.animation_manager.sprite:
			character.animation_manager.sprite.modulate = target_color
		else:
			# Fallback for any enemy structure: find child Sprite / AnimatedSprite2D or modulate character root
			var sprite = character.find_child("*Sprite*", true, false) as CanvasItem
			if sprite:
				sprite.modulate = target_color
			else:
				character.modulate = target_color

## Spreads fire when FireSpreadArea overlaps another enemy's hurtbox.
## NOTE: Spreads ONLY the burn status (fire DPS + orange tint). No knockback is applied to secondary targets.
func _on_spread_area_entered(area: Area2D) -> void:
	if not is_on_fire:
		return
		
	if area is Hurtbox:
		var victim = area.owner if area.owner else area.get_parent()
		if victim != null and victim != character:
			var target_burn = victim.find_child("BurnComponent") as BurnComponent
			# If target is already actively on fire, avoid redundant ignition / signal loops
			if target_burn and target_burn.is_on_fire:
				return
				
			if not target_burn:
				target_burn = BurnComponent.new()
				target_burn.name = "BurnComponent"
				victim.call_deferred("add_child", target_burn)
			# Applies ONLY fire status and DPS tick, zero knockback transferred
			target_burn.apply_burn(burn_dps, burn_duration_remaining)
