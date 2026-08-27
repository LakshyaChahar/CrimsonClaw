extends Area2D
class_name Hitbox

## The amount of damage dealt by this hitbox.
@export var damage: float = 10.0

## The base force of the knockback.
@export var knockback_force: float = 150.0

## The direction of the knockback. If (0,0), it will be calculated dynamically based on relative position.
@export var knockback_direction: Vector2 = Vector2.ZERO

## The duration of stun applied to the victim.
@export var stun_duration: float = 0.2

@export_group("Bloodthirst")
## Bloodthirst gained by attacker when this hitbox strikes a target.
@export var bloodthirst_gain: float = 10.0

@export_group("Fire Status Properties")
## Whether this hitbox causes victims to catch fire.
@export var inflicts_fire: bool = false

## Damage per second inflicted while on fire.
@export var fire_dps: float = 5.0

## Duration of the burn effect in seconds.
@export var fire_duration: float = 3.0

## Emitted when this hitbox successfully strikes a hurtbox.
signal hit_registered(hurtbox: Hurtbox)

func _ready() -> void:
	# Performance Optimization:
	# Hitboxes detect hurtboxes, so they need monitoring = true.
	# Hitboxes do not need to be detected by other areas, so monitorable = false.
	monitoring = true
	monitorable = false
	
	area_entered.connect(_on_area_entered)
 
func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		var hurtbox = area as Hurtbox
		
		var attacker = owner if owner else get_parent()
		var victim = hurtbox.owner if hurtbox.owner else hurtbox.get_parent()
		
		# Prevent hitting own owner (only if both are valid and equal)
		if attacker != null and victim != null and attacker == victim:
			return
			
		# Determine dynamic knockback direction if none is set (purely horizontal by default)
		var kb_dir = knockback_direction
		if kb_dir == Vector2.ZERO:
			var target_pos = victim.global_position if victim else hurtbox.global_position
			var source_pos = attacker.global_position if attacker else global_position
			var diff_x = target_pos.x - source_pos.x
			var dir_x = sign(diff_x) if diff_x != 0 else (attacker.facing_direction if ("facing_direction" in attacker) else 1.0)
			kb_dir = Vector2(dir_x, 0.0)
		
		# Apply hit to the hurtbox
		hurtbox.receive_hit(damage, kb_dir * knockback_force, stun_duration, attacker, inflicts_fire, fire_dps, fire_duration)
		hit_registered.emit(hurtbox)

func check_overlapping_hits() -> void:
	for area in get_overlapping_areas():
		_on_area_entered(area)
