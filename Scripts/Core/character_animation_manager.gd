extends Node
class_name CharacterAnimationManager

@export var sprite: AnimatedSprite2D

@export_group("Movement Audio")
## Optional fallback SFX key if entity has no move_sfx_name set. Leave empty to disable by default.
@export var step_sfx_name: String = ""
## Frame indices within movement animations that trigger step audio (e.g. frames 1 and 3).
@export var step_frames: Array[int] = [1, 3]
## Animation names that trigger step audio.
@export var step_animations: Array[String] = ["walk", "run", "chase", "fly"]
## Slight pitch variation to prevent audio monotony.
@export var step_pitch_randomness: float = 0.1

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
	sprite.frame_changed.connect(_on_frame_changed)

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

	# PLAY ANIMATION
	sprite.play(anim_name)
	current_anim = anim_name
	current_priority = priority

func _on_animation_finished() -> void:
	current_priority = 0

func _on_frame_changed() -> void:
	if not sprite:
		return
		
	if sprite.animation in step_animations:
		if sprite.frame in step_frames:
			var entity = owner if owner else get_parent()
			if not entity or not ("global_position" in entity):
				return
				
			# Determine character-specific movement SFX key
			var sfx: String = ""
			if "move_sfx_name" in entity and entity.move_sfx_name != "":
				sfx = entity.move_sfx_name
			elif step_sfx_name != "":
				sfx = step_sfx_name
				
			# Only play if a sound key is set for this character
			if sfx != "":
				SfxManager.play_2d(sfx, entity.global_position, 0.0, 1.0, step_pitch_randomness)
