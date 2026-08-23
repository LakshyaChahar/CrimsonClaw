extends Area2D
class_name Hurtbox

## Emitted when the hurtbox takes a hit.
signal hit_received(damage: float, knockback: Vector2, stun_duration: float, attacker: Node2D)

## Emitted when invincibility starts.
signal invincibility_started()

## Emitted when invincibility ends.
signal invincibility_ended()

## Duration of invincibility frames (i-frames) after being hit.
@export var invincibility_duration: float = 0.08

## Multiplier for incoming damage (useful for defenses, weak points, etc.).
@export var damage_multiplier: float = 1.0

# Reference to the collision shape of the hurtbox
@onready var collision_shape: CollisionShape2D = find_child("CollisionShape2D")

# Invincibility state tracker
var is_invincible: bool = false

func _ready() -> void:
	# Performance Optimization:
	# Hurtboxes are passive receivers, so they don't need to scan for other areas.
	# monitoring = false, monitorable = true.
	monitoring = false
	monitorable = true

## Handles taking a hit from a hitbox.
func receive_hit(damage: float, knockback: Vector2, stun_duration: float, attacker: Node2D, inflicts_fire: bool = false, fire_dps: float = 0.0, fire_duration: float = 0.0) -> void:
	if is_invincible:
		return
		
	var entity = owner if owner else get_parent()
		
	# Ignore hit if the entity is currently dashing
	if entity and "is_dashing" in entity and entity.is_dashing:
		return
		
	var final_damage = damage * damage_multiplier
	
	# Emit signal for custom visual effects, sound, or state changes
	hit_received.emit(final_damage, knockback, stun_duration, attacker)
	
	# If entity has a directional shield (e.g. DreadVanguardBoss), process shield damage first
	if entity and entity.has_method("process_shield_damage") and attacker:
		final_damage = entity.process_shield_damage(final_damage, attacker.global_position)

	# If the entity is a Character, apply the final damage
	if entity and entity.has_method("take_damage"):
		entity.take_damage(final_damage)
		
	# Apply fire status if enabled
	if inflicts_fire and entity:
		var burn_comp = entity.find_child("BurnComponent") as BurnComponent
		if not burn_comp:
			burn_comp = BurnComponent.new()
			burn_comp.name = "BurnComponent"
			entity.call_deferred("add_child", burn_comp)
		burn_comp.apply_burn(fire_dps, fire_duration)
		
	# Apply knockback/stun if the entity is a Character and we can manipulate its velocity
	if entity is Character:
		# Apply knockback directly to character velocity if desired, or handle it via signal in a state
		if knockback != Vector2.ZERO:
			entity.velocity = knockback
		if stun_duration > 0.0 and entity.has_method("stun"):
			entity.stun(stun_duration)
			
	# Start i-frames
	if invincibility_duration > 0.0:
		start_invincibility()

## Starts the invincibility period.
func start_invincibility() -> void:
	is_invincible = true
	invincibility_started.emit()
		
	# Trigger a timer to end invincibility
	if is_inside_tree():
		await get_tree().create_timer(invincibility_duration).timeout
	end_invincibility()

## Ends the invincibility period.
func end_invincibility() -> void:
	is_invincible = false
	invincibility_ended.emit()
