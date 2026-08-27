@tool
extends SceneTree

func _init() -> void:
	print("--- BUILDING ANIMATED SNIPER BEAM PROJECTILE SCENE ---")
	
	var moving_tex = load("res://Assets/Spritesheets/Evil Wizard 3/Sprites/Projectile/Moving.png") as Texture2D
	var explode_tex = load("res://Assets/Spritesheets/Evil Wizard 3/Sprites/Projectile/Explode.png") as Texture2D
	
	assert(moving_tex != null, "Failed to load Moving.png")
	assert(explode_tex != null, "Failed to load Explode.png")
	
	var sf = SpriteFrames.new()
	sf.remove_animation("default")
	
	# 1. Add "flying" animation (4 frames of 50x50)
	sf.add_animation("flying")
	sf.set_animation_speed("flying", 12.0)
	sf.set_animation_loop("flying", true)
	
	for i in range(4):
		var atlas = AtlasTexture.new()
		atlas.atlas = moving_tex
		atlas.region = Rect2(i * 50, 0, 50, 50)
		sf.add_frame("flying", atlas)
		
	# 2. Add "explode" animation (7 frames of 50x50)
	sf.add_animation("explode")
	sf.set_animation_speed("explode", 15.0)
	sf.set_animation_loop("explode", false)
	
	for i in range(7):
		var atlas = AtlasTexture.new()
		atlas.atlas = explode_tex
		atlas.region = Rect2(i * 50, 0, 50, 50)
		sf.add_frame("explode", atlas)
		
	# Build the Scene Tree
	var root = Area2D.new()
	root.name = "SniperBeamProjectile"
	root.collision_layer = 16 # Enemy Hitbox layer
	root.collision_mask = 2 # Player Hurtbox layer
	
	var script = load("res://Scripts/Entities/Enemy/sniper_beam_projectile.gd")
	root.set_script(script)
	root.set("damage", 35.0)
	
	# Add AnimatedSprite2D
	var anim_sprite = AnimatedSprite2D.new()
	anim_sprite.name = "AnimatedSprite2D"
	anim_sprite.sprite_frames = sf
	anim_sprite.animation = &"flying"
	anim_sprite.autoplay = "flying"
	root.add_child(anim_sprite)
	anim_sprite.owner = root
	
	# Add CollisionShape2D
	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var shape = CapsuleShape2D.new()
	shape.radius = 8.0
	shape.height = 28.0
	col.shape = shape
	col.rotation_degrees = 90.0 # Horizontal capsule shape
	root.add_child(col)
	col.owner = root
	
	# Add VisibleOnScreenNotifier2D
	var notifier = VisibleOnScreenNotifier2D.new()
	notifier.name = "VisibleOnScreenNotifier2D"
	notifier.rect = Rect2(-25, -25, 50, 50)
	root.add_child(notifier)
	notifier.owner = root
	
	# Connect screen_exited signal
	notifier.screen_exited.connect(Callable(root, "_on_visible_on_screen_notifier_2d_screen_exited"))
	
	# Save Scene to file
	var packed = PackedScene.new()
	packed.pack(root)
	var err = ResourceSaver.save(packed, "res://Scenes/Entities/Enemy/sniper_beam_projectile.tscn")
	if err == OK:
		print("Successfully saved sniper_beam_projectile.tscn!")
	else:
		print("Failed to save scene. Error code: ", err)
		
	quit()
