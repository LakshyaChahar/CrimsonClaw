# Central Coordinator for Sub-Boss Group Encounters (Prevents simultaneous dogpile attacks)
extends Node
class_name SubBossCoordinator

static var instance: SubBossCoordinator = null

@export var max_simultaneous_special_attacks: int = 1
@export var min_stagger_delay_between_attacks: float = 1.0

var active_attackers: Array[Node2D] = []
var attack_cooldown_timer: float = 0.0

func _enter_tree() -> void:
	instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null

func _process(delta: float) -> void:
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta

## Returns true if the requesting boss is granted permission to begin a heavy special attack
static func can_attack(boss: Node2D) -> bool:
	if not instance:
		return true

	# Prevent off-screen attacks! Boss must be visible in the player's camera viewport
	if boss.has_method("is_visible_in_screen") and not boss.is_visible_in_screen():
		return false

	if instance.active_attackers.has(boss):
		return true

	if instance.attack_cooldown_timer > 0.0:
		return false

	return instance.active_attackers.size() < instance.max_simultaneous_special_attacks

## Registers that a boss has started a heavy special attack
static func request_attack(boss: Node2D) -> bool:
	if not instance:
		return true

	if not can_attack(boss):
		return false

	if not instance.active_attackers.has(boss):
		instance.active_attackers.append(boss)
	return true

## Releases the attack token when a boss finishes their special attack
static func release_attack(boss: Node2D) -> void:
	if not instance:
		return

	if instance.active_attackers.has(boss):
		instance.active_attackers.erase(boss)
		instance.attack_cooldown_timer = instance.min_stagger_delay_between_attacks
