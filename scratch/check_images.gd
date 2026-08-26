extends SceneTree

func _init() -> void:
	var moving_img = Image.load_from_file("res://Assets/Spritesheets/Evil Wizard 3/Sprites/Projectile/Moving.png")
	if moving_img:
		print("Moving.png size: ", moving_img.get_width(), "x", moving_img.get_height())
		
	var explode_img = Image.load_from_file("res://Assets/Spritesheets/Evil Wizard 3/Sprites/Projectile/Explode.png")
	if explode_img:
		print("Explode.png size: ", explode_img.get_width(), "x", explode_img.get_height())

	var atk_img = Image.load_from_file("res://Assets/Spritesheets/Evil Wizard 3/Sprites/Attack.png")
	if atk_img:
		print("Attack.png size: ", atk_img.get_width(), "x", atk_img.get_height())
		
	var idle_img = Image.load_from_file("res://Assets/Spritesheets/Evil Wizard 3/Sprites/Idle.png")
	if idle_img:
		print("Idle.png size: ", idle_img.get_width(), "x", idle_img.get_height())

	quit(0)
