# Unique class for the Stalker Ghoul to show clearly in the Inspector
extends Enemy
class_name StalkerGhoul

@export var fly_offset_y: float = -30.0 # Target flight height (chest/head level)

func _init() -> void:
	super._init()
	sprite_faces_left = false
	gravity_scale = 0.0
