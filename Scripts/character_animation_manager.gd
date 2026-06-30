extends Node
class_name CharacterAnimationManager


@export var sprite: AnimatedSprite2D

# Tracks the name and priority of the currently playing animation.
var current_anim: String = ""
var current_priority: int = 0

func _ready() -> void:
	
	if not sprite:
		sprite = get_parent().get_node_or_null("AnimatedSprite2D")
		if not sprite:
			push_warning("CharacterAnimationManager: No AnimatedSprite2D found!")
			return

	
	sprite.animation_finished.connect(_on_animation_finished)

## Requests to play a new animation.
## - anim_name: The name of the animation (e.g. "idle", "run", "attack", "die").
## - priority: Higher numbers mean more important animations
## - force: If true, plays it immediately regardless of priority
func play_anim(anim_name: String, priority: int = 0, force: bool = false) -> void:
	if not sprite:
		return

	
	if priority < current_priority and not force:
		return

	
	if sprite.animation == anim_name and sprite.is_playing() and not force:
		current_priority = priority # Update priority
		return

	# 3. PLAY ANIMATION
	sprite.play(anim_name)
	current_anim = anim_name
	current_priority = priority

func _on_animation_finished() -> void:

	current_priority = 0
